//! 記事メディアの管理。
//!
//! - 管理下メディアは「key」(`blog/<slug>/<filename>`) で同一視し、
//!   `state/media/<slug>.json` (manifest) に記録する
//! - 記事ファイルには常に **RustFS 側の URL** を書き込む (draft の新規管理メディアのみ。
//!   公開済み記事が参照する R2 URL は変更しない — 計画 §2.6 の適用範囲)
//! - 本文の対応形式は `<post-image url width height alt>` と Markdown 画像 `![alt](url)` の両方
//! - 昇格 (RustFS → R2) は key 単位で行い、URL は base 部分だけ差し替える

use crate::model::FrontMatter;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};

/// アップロードで許可する MIME タイプと拡張子。
pub const ALLOWED_TYPES: &[(&str, &str)] = &[
    ("image/jpeg", "jpg"),
    ("image/png", "png"),
    ("image/gif", "gif"),
    ("image/webp", "webp"),
];

/// 1 ファイルの上限 (bytes)。
pub const MAX_UPLOAD_BYTES: usize = 10 * 1024 * 1024;

/// multipart **リクエスト全体**のボディ上限。
///
/// `MAX_UPLOAD_BYTES` は画像ファイル単体の検証上限で、multipart のボディには
/// 境界マーカーや他のフォーム項目 (title / body / hidden の revision など) も含まれる。
/// 同一値をリクエスト上限に使うと、10MB ちょうど有効な画像が他の項目と同時に
/// 通らない (axum は上限超過でボディを切るため、検証前に失敗する)。
/// フォーム項目分の余裕を持たせ、ファイル単体の 10MB 検証は `validate_upload` で維持する。
pub const MAX_REQUEST_BYTES: usize = MAX_UPLOAD_BYTES + 2 * 1024 * 1024;

/// manifest の 1 アイテム。
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MediaItem {
    pub key: String,
    pub content_type: String,
    pub width: u32,
    pub height: u32,
    pub alt: String,
    pub created_at: String,
    pub promoted: bool,
    pub promoted_at: Option<String>,
}

/// 記事 1 件ぶんの manifest。
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct MediaManifest {
    pub slug: String,
    pub items: Vec<MediaItem>,
}

impl MediaManifest {
    pub fn load(dir: &Path, slug: &str) -> Self {
        let path = manifest_path(dir, slug);
        if let Ok(raw) = fs::read_to_string(&path) {
            if let Ok(manifest) = serde_json::from_str(&raw) {
                return manifest;
            }
        }
        Self {
            slug: slug.to_string(),
            items: Vec::new(),
        }
    }

    pub fn try_load(dir: &Path, slug: &str) -> Result<Self, String> {
        let path = manifest_path(dir, slug);
        match fs::read_to_string(path) {
            Ok(raw) => {
                let manifest: Self = serde_json::from_str(&raw)
                    .map_err(|e| format!("メディアmanifestを読み込めません: {e}"))?;
                if manifest.slug != slug {
                    return Err("メディアmanifestのslugが一致しません".into());
                }
                Ok(manifest)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Self {
                slug: slug.into(),
                items: Vec::new(),
            }),
            Err(e) => Err(e.to_string()),
        }
    }
    pub fn referenced_keys_at(&self, fm: &FrontMatter, body: &str, bases: &[&str]) -> Vec<String> {
        let urls = image_urls(body);
        self.items
            .iter()
            .filter(|item| {
                bases.iter().any(|base| {
                    let url = format!("{}/{}", base.trim_end_matches('/'), item.key);
                    fm.cover_image
                        .as_ref()
                        .is_some_and(|cover| cover.url == url)
                        || urls.iter().any(|(_, value)| value == &url)
                })
            })
            .map(|item| item.key.clone())
            .collect()
    }
    pub fn save(&self, dir: &Path) -> std::io::Result<()> {
        fs::create_dir_all(dir)?;
        let path = manifest_path(dir, &self.slug);
        let raw = serde_json::to_string_pretty(self).expect("manifest is serializable");
        crate::repository::atomic_write(&path, &raw)
    }

    pub fn item(&self, key: &str) -> Option<&MediaItem> {
        self.items.iter().find(|item| item.key == key)
    }

    /// key を持つアイテムを更新 (なければ何もしない)。
    pub fn update_item(&mut self, key: &str, promoted: bool, promoted_at: Option<String>) {
        if let Some(item) = self.items.iter_mut().find(|item| item.key == key) {
            item.promoted = promoted;
            item.promoted_at = promoted_at;
        }
    }

    /// **記事が実際に参照している** key の集合。
    ///
    /// manifest に記録されていても、挿入を取り消した未使用メディアは含めない
    /// (未使用メディアの昇格失敗で公開を妨げないため — 計画 §2.5 state モデル)。
    pub fn referenced_keys(&self, front_matter: &FrontMatter, body: &str) -> Vec<String> {
        self.items
            .iter()
            .filter(|item| {
                front_matter
                    .cover_image
                    .as_ref()
                    .is_some_and(|cover| cover.url.ends_with(&item.key))
                    || body_contains_key(body, &item.key)
            })
            .map(|item| item.key.clone())
            .collect()
    }
}

fn manifest_path(dir: &Path, slug: &str) -> PathBuf {
    dir.join(format!("{slug}.json"))
}

fn body_contains_key(body: &str, key: &str) -> bool {
    body.contains(key)
}

// ---------------------------------------------------------------------------
// アップロードの検証と key 生成
// ---------------------------------------------------------------------------

#[derive(Debug, thiserror::Error)]
pub enum MediaError {
    #[error("ファイルサイズが上限 ({limit_kb}KB) を超えています (現在 {actual_kb}KB)")]
    TooLarge { limit_kb: usize, actual_kb: usize },
    #[error("画像形式は JPEG / PNG / GIF / WebP のみアップロードできます (現在: {0})")]
    UnsupportedType(String),
    #[error("画像の寸法を検出できませんでした (ファイルが壊れている可能性があります)")]
    UnknownDimensions,
    #[error("ファイル名から有効な名前を作れませんでした")]
    InvalidFileName,
    #[error("入出力に失敗しました: {0}")]
    Io(#[from] std::io::Error),
}

/// アップロードされたファイル 1 つぶんの検証結果。
#[derive(Debug, Clone)]
pub struct ValidatedMedia {
    pub key: String,
    pub content_type: String,
    pub width: u32,
    pub height: u32,
}

/// ファイル名・内容・寸法を検証して、保存先 key を生成する。
///
/// key は `blog/<slug>/<name>-<id>.<ext>`。元のファイル名はサニタイズし、
/// 日本語などがすべて落ちた場合は `image` を使う。
pub fn validate_upload(
    slug: &str,
    original_file_name: &str,
    bytes: Vec<u8>,
    content_type: &str,
) -> Result<ValidatedMedia, MediaError> {
    let limit = MAX_UPLOAD_BYTES;
    if bytes.len() > limit {
        return Err(MediaError::TooLarge {
            limit_kb: limit / 1024,
            actual_kb: bytes.len() / 1024,
        });
    }

    let (canonical_type, ext) = ALLOWED_TYPES
        .iter()
        .find(|(allowed, _)| *allowed == content_type)
        .ok_or_else(|| MediaError::UnsupportedType(content_type.to_string()))?;

    let (width, height) = image_dimensions(&bytes)?;
    if width == 0 || height == 0 {
        return Err(MediaError::UnknownDimensions);
    }

    let stem = sanitize_file_stem(original_file_name);
    let id = uuid::Uuid::new_v4().simple().to_string()[..8].to_string();
    let key = format!("blog/{slug}/{stem}-{id}.{ext}");

    Ok(ValidatedMedia {
        key,
        content_type: canonical_type.to_string(),
        width,
        height,
    })
}

/// 画像のヘッダだけ読んで寸法を返す (フルデコードはしない)。
fn image_dimensions(bytes: &[u8]) -> Result<(u32, u32), MediaError> {
    let reader = image::ImageReader::new(Cursor::new(bytes))
        .with_guessed_format()
        .map_err(|_| MediaError::UnknownDimensions)?;
    reader
        .into_dimensions()
        .map_err(|_| MediaError::UnknownDimensions)
}

/// ファイル名の stem を `[a-z0-9-]` に落とす。
///
/// 日本語などがすべて落ちた場合は `image` を返す。連続する区切りは 1 つにまとめる。
fn sanitize_file_stem(original: &str) -> String {
    let original = original.rsplit('/').next().unwrap_or(original);
    let original = original.rsplit('.').next_back().unwrap_or(original);
    let mut sanitized = String::new();
    let mut last_dash = true; // 先頭のハイフンを防ぐ
    for ch in original.chars() {
        let mapped = match ch {
            'A'..='Z' => ch.to_ascii_lowercase(),
            'a'..='z' | '0'..='9' => ch,
            _ => '-',
        };
        if mapped == '-' {
            if !last_dash {
                sanitized.push('-');
                last_dash = true;
            }
        } else {
            sanitized.push(mapped);
            last_dash = false;
        }
    }
    let sanitized = sanitized.trim_matches('-').to_string();
    if sanitized.is_empty() {
        "image".to_string()
    } else {
        sanitized
    }
}

// ---------------------------------------------------------------------------
// 記事への挿入と URL 置換
// ---------------------------------------------------------------------------

/// 既存記事の体裁に合わせた `<post-image>` 要素。
pub fn render_post_image(url: &str, width: u32, height: u32, alt: &str) -> String {
    format!("\n<post-image\n    url=\"{url}\"\n    width=\"{width}\"\n    height=\"{height}\"\n    alt=\"{alt}\">\n</post-image>\n")
}

/// 記事内の RustFS URL を R2 URL に置き換える (昇格)。
///
/// 置換は管理下 key との厳密一致 (`<base>/<key>` の全体一致) で行い、
/// 対象は frontmatter `coverImage.url` と本文 (`<post-image>` / Markdown 画像の両方を含む body 全体)。
/// 本文の他の部分は一切書き換えない。
pub fn promote_urls(
    front_matter: &mut FrontMatter,
    body: &str,
    rustfs_base: &str,
    r2_base: &str,
    keys: &[String],
) -> String {
    let mut replacements = Vec::new();
    for (range, value) in image_urls(body) {
        for key in keys {
            let from = format!("{}/{}", rustfs_base.trim_end_matches('/'), key);
            if value == from {
                replacements.push((
                    range.clone(),
                    format!("{}/{}", r2_base.trim_end_matches('/'), key),
                ));
            }
        }
    }
    let mut new_body = body.to_string();
    replacements.sort_by_key(|(range, _)| std::cmp::Reverse(range.start));
    for (range, value) in replacements {
        new_body.replace_range(range, &value);
    }
    for key in keys {
        let from = format!("{}/{}", rustfs_base.trim_end_matches('/'), key);
        let to = format!("{}/{}", r2_base.trim_end_matches('/'), key);
        if let Some(cover) = front_matter.cover_image.as_mut() {
            if cover.url == from {
                cover.url = to.clone();
            }
        }
    }
    new_body
}

/// Destination spans only: never replace text, code, or a URL sharing a prefix.
fn image_urls(body: &str) -> Vec<(std::ops::Range<usize>, String)> {
    use pulldown_cmark::{Event, Tag};
    let mut urls = Vec::new();
    let html =
        regex::Regex::new(r#"(?s)<post-image\b[^>]*?\burl\s*=\s*(?:"([^"]*)"|'([^']*)')"#).unwrap();
    for (event, range) in pulldown_cmark::Parser::new(body).into_offset_iter() {
        match event {
            Event::Start(Tag::Image { dest_url, .. }) => {
                let source = &body[range.clone()];
                if let Some(start) = source
                    .find("](")
                    .and_then(|i| source[i + 2..].find(dest_url.as_ref()).map(|n| i + 2 + n))
                {
                    urls.push((
                        range.start + start..range.start + start + dest_url.len(),
                        dest_url.to_string(),
                    ));
                }
            }
            Event::Html(_) | Event::InlineHtml(_) => {
                for captures in html.captures_iter(&body[range.clone()]) {
                    if let Some(value) = captures.get(1).or_else(|| captures.get(2)) {
                        urls.push((
                            range.start + value.start()..range.start + value.end(),
                            value.as_str().into(),
                        ));
                    }
                }
            }
            _ => {}
        }
    }
    urls
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::{Category, CoverImage, Tag};
    use std::collections::BTreeMap;

    fn front_matter_with_cover(url: &str) -> FrontMatter {
        FrontMatter {
            title: "t".to_string(),
            slug: "s".to_string(),
            author: None,
            published_on: "2026-01-01".to_string(),
            category: Category::Blog,
            tags: vec![Tag::default()],
            cover_image: Some(CoverImage {
                url: url.to_string(),
                width: 10,
                height: 10,
                alternative_text: Some(String::new()),
                extra: BTreeMap::new(),
            }),
            extra: BTreeMap::new(),
        }
    }

    #[test]
    fn sanitize_stem_handles_japanese_and_paths() {
        assert_eq!(sanitize_file_stem("photo.jpg"), "photo");
        assert_eq!(sanitize_file_stem("Cover Image.PNG"), "cover-image");
        assert_eq!(
            sanitize_file_stem("/some/dir/夏休み.png"),
            "image",
            "日本語は落ちる"
        );
        assert_eq!(sanitize_file_stem("a--b!.gif"), "a-b");
        assert_eq!(sanitize_file_stem("---"), "image", "記号のみ");
        assert_eq!(sanitize_file_stem(""), "image");
    }

    #[test]
    fn validate_upload_rejects_unsupported_and_oversize() {
        let err = validate_upload("s", "a.jpg", vec![0; 10], "image/bmp").unwrap_err();
        assert!(err.to_string().contains("JPEG / PNG / GIF / WebP"), "{err}");

        let err =
            validate_upload("s", "a.jpg", vec![0; MAX_UPLOAD_BYTES + 1], "image/jpeg").unwrap_err();
        assert!(err.to_string().contains("上限"), "{err}");
    }

    #[test]
    fn validate_upload_generates_key() {
        // 1x1 PNG (完全な画像)
        let png: Vec<u8> = vec![
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48,
            0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00,
            0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x78,
            0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0x00, 0x05, 0xFE, 0x02, 0xFE, 0x0D, 0xEF, 0x46,
            0xB8, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ];
        let media = validate_upload("my-slug", "休み.png", png, "image/png").unwrap();
        assert_eq!(media.content_type, "image/png");
        assert_eq!(media.width, 1);
        assert_eq!(media.height, 1);
        assert!(
            media.key.starts_with("blog/my-slug/"),
            "key は blog/<slug>/ から始まる: {}",
            media.key
        );
        let name = media.key.rsplit('/').next().unwrap();
        assert!(
            name.starts_with("image-"),
            "日本語 stem は image になる: {name}"
        );
        assert!(name.ends_with(".png"));
    }

    #[test]
    fn post_image_renders_existing_format() {
        let html = render_post_image("https://example.test/x.jpg", 800, 600, "代替テキスト");
        assert!(html.contains("<post-image\n    url=\"https://example.test/x.jpg\""));
        assert!(html.contains("width=\"800\""));
        assert!(html.contains("alt=\"代替テキスト\">"));
        assert!(html.trim_end().ends_with("</post-image>"));
    }

    #[test]
    fn promote_urls_replaces_only_managed_keys() {
        let rustfs = "https://rustfs.mf.officeiko.co.jp/blog";
        let r2 = "https://image.officeiko.work";
        let managed = "blog/s/managed-1.jpg";

        let mut front_matter = front_matter_with_cover(&format!("{rustfs}/{managed}"));
        let body = format!(
            "先頭\n\n<post-image url=\"{rustfs}/{managed}\" width=\"1\" height=\"1\" alt=\"a\">\n\n既存の R2 画像 ![既存](https://image.officeiko.work/other.jpg) は触らない\n"
        );

        let new_body = promote_urls(&mut front_matter, &body, rustfs, r2, &[managed.to_string()]);

        assert_eq!(
            front_matter.cover_image.as_ref().unwrap().url,
            "https://image.officeiko.work/blog/s/managed-1.jpg"
        );
        assert!(new_body.contains("https://image.officeiko.work/blog/s/managed-1.jpg"));
        assert!(
            !new_body.contains(rustfs),
            "RustFS URL は残らない: {new_body}"
        );
        // 未管理の R2 URL はそのまま
        assert!(new_body.contains("https://image.officeiko.work/other.jpg"));
    }

    #[test]
    fn promote_and_reference_checks_tolerate_a_missing_cover() {
        let rustfs = "https://rustfs.mf.officeiko.co.jp/blog";
        let r2 = "https://image.officeiko.work";
        let managed = "blog/s/managed-1.jpg";

        let mut front_matter = front_matter_with_cover("");
        front_matter.cover_image = None;
        let body =
            format!("<post-image url=\"{rustfs}/{managed}\" width=\"1\" height=\"1\" alt=\"a\">");

        let manifest = MediaManifest {
            slug: "s".to_string(),
            items: vec![MediaItem {
                key: managed.to_string(),
                content_type: "image/jpeg".to_string(),
                width: 1,
                height: 1,
                alt: String::new(),
                created_at: String::new(),
                promoted: false,
                promoted_at: None,
            }],
        };
        // カバーなしでも本文参照だけで key を拾う (panic しない)
        assert_eq!(
            manifest.referenced_keys(&front_matter, &body),
            vec![managed.to_string()]
        );

        let new_body = promote_urls(&mut front_matter, &body, rustfs, r2, &[managed.to_string()]);
        assert!(
            front_matter.cover_image.is_none(),
            "カバーなしの記事に勝手にカバーを作らない"
        );
        assert!(new_body.contains("https://image.officeiko.work/blog/s/managed-1.jpg"));
    }

    #[test]
    fn referenced_keys_only_include_used_media() {
        let dir = tempfile::tempdir().unwrap();
        let used = MediaItem {
            key: "blog/s/used.jpg".to_string(),
            content_type: "image/jpeg".to_string(),
            width: 1,
            height: 1,
            alt: String::new(),
            created_at: String::new(),
            promoted: false,
            promoted_at: None,
        };
        let unused = MediaItem {
            key: "blog/s/unused.jpg".to_string(),
            ..used.clone()
        };
        let cover = MediaItem {
            key: "blog/s/cover.jpg".to_string(),
            ..used.clone()
        };

        let manifest = MediaManifest {
            slug: "s".to_string(),
            items: vec![used, unused, cover],
        };
        manifest.save(dir.path()).unwrap();

        let loaded = MediaManifest::load(dir.path(), "s");
        assert_eq!(loaded.items.len(), 3, "manifest の roundtrip");

        let front_matter =
            front_matter_with_cover("https://rustfs.mf.officeiko.co.jp/blog/blog/s/cover.jpg");
        let body =
            "\n<post-image url=\"https://rustfs.mf.officeiko.co.jp/blog/blog/s/used.jpg\">\n"
                .to_string();

        let mut referenced = loaded.referenced_keys(&front_matter, &body);
        referenced.sort();
        assert_eq!(
            referenced,
            vec![
                "blog/s/cover.jpg".to_string(),
                "blog/s/used.jpg".to_string()
            ],
            "参照されている (cover と body) のみ。未使用の unused.jpg は含まない"
        );
    }

    #[test]
    fn manifest_save_and_update_item() {
        let dir = tempfile::tempdir().unwrap();
        let mut manifest = MediaManifest {
            slug: "s".to_string(),
            items: vec![MediaItem {
                key: "blog/s/a.jpg".to_string(),
                content_type: "image/jpeg".to_string(),
                width: 1,
                height: 1,
                alt: String::new(),
                created_at: "2026-01-01T00:00:00Z".to_string(),
                promoted: false,
                promoted_at: None,
            }],
        };
        manifest.update_item(
            "blog/s/a.jpg",
            true,
            Some("2026-02-01T00:00:00Z".to_string()),
        );
        manifest.save(dir.path()).unwrap();

        let loaded = MediaManifest::load(dir.path(), "s");
        assert!(loaded.items[0].promoted);
        assert_eq!(
            loaded.items[0].promoted_at.as_deref(),
            Some("2026-02-01T00:00:00Z")
        );

        // 存在しない key は無視
        let mut again = loaded.clone();
        again.update_item("blog/s/missing.jpg", true, None);
        assert!(again.items.iter().all(|item| item.promoted_at.is_some()));
    }
}
