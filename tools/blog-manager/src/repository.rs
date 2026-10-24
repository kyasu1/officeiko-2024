use crate::model::{is_valid_slug, FrontMatter};
use std::fmt;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const FRONT_MATTER_DELIMITER: &str = "---";

#[derive(Debug, thiserror::Error)]
pub enum RepoError {
    #[error("frontmatter が見つかりません (先頭が `---` で始まっていません)")]
    MissingFrontMatter,
    #[error("frontmatter の終端 `---` が見つかりません")]
    MissingFrontMatterEnd,
    #[error("frontmatter の解析に失敗しました: {0}")]
    Yaml(#[from] serde_yaml::Error),
    #[error("ファイル入出力に失敗しました: {0}")]
    Io(#[from] io::Error),
    #[error("バリデーションエラー: {0}")]
    Validation(String),
    #[error("他の編集が先に保存されました。再読み込みしてやり直してください")]
    Conflict,
    #[error("更新には編集開始時の revision が必要です。編集画面を開き直してください")]
    RevisionRequired,
}

impl RepoError {
    /// 画面にそのまま出すメッセージ (内部の型名などを含めない)
    pub fn display_message(&self) -> String {
        match self {
            RepoError::Validation(message) => message.clone(),
            other => other.to_string(),
        }
    }
}

/// 記事の状態。`content/posts/` は公開済み、`content/drafts/` は下書き。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Draft,
    Published,
}

impl Status {
    pub fn as_str(self) -> &'static str {
        match self {
            Status::Draft => "draft",
            Status::Published => "published",
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Status::Draft => "下書き",
            Status::Published => "公開済み",
        }
    }
}

/// 1つの記事ファイル。**パスは必ず保持する**。
///
/// slug からファイル名を組み立ててはいけない (ファイル名と slug が一致しない記事が
/// 過去に存在したため。§2.3)。slug → ファイルの解決は常に一覧から索引を作って行う。
#[derive(Debug, Clone)]
pub struct PostFile {
    pub status: Status,
    pub path: PathBuf,
    pub file_name: String,
    /// 解析に失敗した記事でも一覧に出せるよう Option
    pub front_matter: Option<FrontMatter>,
    /// 本文 (frontmatter 境界より後ろをそのまま保持)
    pub body: String,
    pub raw_front_matter: String,
    pub parse_error: Option<String>,
    /// 解析はできたが frontmatter の内容が不正な場合の理由
    pub validation_errors: Vec<String>,
    /// 読み込み時点の内容ハッシュ。楽観ロック (同時編集の検出) に使う。
    pub revision: String,
}

impl PostFile {
    pub fn slug(&self) -> Option<&str> {
        self.front_matter.as_ref().map(|fm| fm.slug.as_str())
    }

    /// 解析自体に失敗した記事 (slug を持たない)
    pub fn is_unparseable(&self) -> bool {
        self.front_matter.is_none()
    }

    /// 要修正 (解析失敗 または frontmatter の検証エラー)
    pub fn has_errors(&self) -> bool {
        self.is_unparseable() || !self.validation_errors.is_empty()
    }

    /// 要修正の理由 (空なら問題なし)
    pub fn error_summary(&self) -> String {
        if let Some(error) = &self.parse_error {
            return error.clone();
        }
        self.validation_errors.join(" / ")
    }

    /// `/posts/{slug}` で開けるか。
    ///
    /// slug が存在しても書式が不正 (`bad/slug`, 空, `?`/`#` 入りなど) なら
    /// ルートに一致しないため、ファイル名経由で開く必要がある。
    pub fn is_routable(&self) -> bool {
        self.front_matter
            .as_ref()
            .map(|front_matter| is_valid_slug(&front_matter.slug))
            .unwrap_or(false)
    }

    /// 詳細ページの URL。
    ///
    /// slug が有効なら `/posts/{slug}`、それ以外 (解析不能・slug 不正) は
    /// **状態 + ファイル名** で引く。slug 空間とファイル名空間を混ぜない。
    pub fn detail_path(&self) -> String {
        match (&self.front_matter, self.is_routable()) {
            (Some(front_matter), true) => format!("/posts/{}", front_matter.slug),
            _ => format!(
                "/files/{}/{}",
                self.status.as_str(),
                percent_encode(&self.file_name)
            ),
        }
    }

    pub fn title(&self) -> &str {
        self.front_matter
            .as_ref()
            .map(|fm| fm.title.as_str())
            .unwrap_or(&self.file_name)
    }

    pub fn is_broken(&self) -> bool {
        self.front_matter.is_none()
    }
}

#[derive(Debug, Clone)]
pub struct Repository {
    content_dir: PathBuf,
    trash_dir: PathBuf,
}

impl Repository {
    pub fn new(content_dir: impl Into<PathBuf>, trash_dir: impl Into<PathBuf>) -> Self {
        Self {
            content_dir: content_dir.into(),
            trash_dir: trash_dir.into(),
        }
    }

    pub fn trash_dir(&self) -> &Path {
        &self.trash_dir
    }

    pub fn content_dir(&self) -> &Path {
        &self.content_dir
    }

    pub fn posts_dir(&self) -> PathBuf {
        self.content_dir.join("posts")
    }

    pub fn drafts_dir(&self) -> PathBuf {
        self.content_dir.join("drafts")
    }

    pub fn path_for(&self, status: Status, file_name: &str) -> PathBuf {
        match status {
            Status::Draft => self.drafts_dir().join(file_name),
            Status::Published => self.posts_dir().join(file_name),
        }
    }

    /// 公開済み・下書きの全記事 (壊れたものも含む) を返す。
    /// 公開日 → タイトル順 (新しい順) に並べる。
    pub fn list(&self) -> Vec<PostFile> {
        let mut posts = Vec::new();
        posts.extend(self.list_dir(&self.posts_dir(), Status::Published));
        posts.extend(self.list_dir(&self.drafts_dir(), Status::Draft));
        posts.sort_by(|a, b| {
            let a_date = a
                .front_matter
                .as_ref()
                .map(|fm| fm.published_on.clone())
                .unwrap_or_default();
            let b_date = b
                .front_matter
                .as_ref()
                .map(|fm| fm.published_on.clone())
                .unwrap_or_default();
            b_date
                .cmp(&a_date)
                .then_with(|| a.file_name.cmp(&b.file_name))
        });
        posts
    }

    fn list_dir(&self, dir: &Path, status: Status) -> Vec<PostFile> {
        let Ok(entries) = fs::read_dir(dir) else {
            return Vec::new();
        };

        let mut files: Vec<PathBuf> = entries
            .filter_map(Result::ok)
            .map(|entry| entry.path())
            .filter(|path| path.extension().map(|ext| ext == "md").unwrap_or(false))
            .collect();
        files.sort();

        files
            .into_iter()
            .map(|path| self.load(&path, status))
            .collect()
    }

    pub fn load(&self, path: &Path, status: Status) -> PostFile {
        let file_name = path
            .file_name()
            .map(|name| name.to_string_lossy().to_string())
            .unwrap_or_default();

        let raw = match fs::read_to_string(path) {
            Ok(raw) => raw,
            Err(err) => {
                return PostFile {
                    status,
                    path: path.to_path_buf(),
                    file_name,
                    front_matter: None,
                    body: String::new(),
                    raw_front_matter: String::new(),
                    parse_error: Some(format!("読み込みに失敗しました: {err}")),
                    validation_errors: Vec::new(),
                    revision: String::new(),
                }
            }
        };

        match parse(&raw) {
            Ok(parsed) => {
                // 構造として読めても、値が不正ならサイトのビルドを壊す。
                // 一覧で「要修正」として見えるようにする。
                let validation_errors = parsed.front_matter.validate();
                PostFile {
                    status,
                    path: path.to_path_buf(),
                    file_name,
                    front_matter: Some(parsed.front_matter),
                    body: parsed.body,
                    raw_front_matter: parsed.raw_front_matter,
                    parse_error: None,
                    validation_errors,
                    revision: hash_revision(&raw),
                }
            }
            Err(err) => PostFile {
                status,
                path: path.to_path_buf(),
                file_name,
                front_matter: None,
                body: String::new(),
                raw_front_matter: String::new(),
                parse_error: Some(err.to_string()),
                validation_errors: Vec::new(),
                revision: hash_revision(&raw),
            },
        }
    }

    /// slug で記事を引く (slug 空間のみ)。
    pub fn find(&self, slug: &str) -> Option<PostFile> {
        self.list()
            .into_iter()
            .find(|post| post.slug() == Some(slug))
    }

    /// **解析できなかった記事** を状態 + ファイル名で引く。
    ///
    /// 任意のパスを join せず、一覧に実在するファイルだけを対象にする。
    pub fn find_file(&self, status: Status, file_name: &str) -> Option<PostFile> {
        self.list().into_iter().find(|post| {
            post.status == status && post.file_name == file_name && !post.is_routable()
        })
    }

    /// slug が既に使われているか (公開済み・下書きの両方を見る)。
    pub fn slug_in_use(&self, slug: &str, exclude: Option<&Path>) -> bool {
        self.list().iter().any(|post| {
            post.slug() == Some(slug) && exclude.map(|path| path != post.path).unwrap_or(true)
        })
    }

    /// 記事を保存する。一時ファイルへ書いてから rename する (atomic write)。
    ///
    /// `expected_revision` が渡された場合、ディスク上の内容が読み込み時から
    /// 変わっていれば **他の編集と衝突した** とみなして拒否する (楽観ロック)。
    pub fn save(&self, post: &PostFile, expected_revision: &str) -> Result<(), RepoError> {
        let front_matter = post.front_matter.as_ref().ok_or_else(|| {
            RepoError::Validation("frontmatter のない記事は保存できません".into())
        })?;

        let errors = front_matter.validate();
        if !errors.is_empty() {
            return Err(RepoError::Validation(errors.join(" / ")));
        }

        if self.slug_in_use(&front_matter.slug, Some(&post.path)) {
            return Err(RepoError::Validation(format!(
                "slug `{}` は既に別の記事で使われています",
                front_matter.slug
            )));
        }

        self.ensure_revision_matches(&post.path, expected_revision)?;

        // 公開済み記事の slug / category は URL と GMB リンクを守るため変更できない。
        if post.status == Status::Published {
            if let Some(current) = self.load(&post.path, Status::Published).front_matter {
                if current.slug != front_matter.slug {
                    return Err(RepoError::Validation(
                        "公開済み記事の slug は変更できません (URL が変わります)".into(),
                    ));
                }
                if current.category != front_matter.category {
                    return Err(RepoError::Validation(
                        "公開済み記事のカテゴリは変更できません (URL が変わります)".into(),
                    ));
                }
            }
        }

        let contents = render(front_matter, &post.body)?;
        atomic_write(&post.path, &contents)?;
        Ok(())
    }

    /// 新しい記事を下書きとして作成する。
    ///
    /// 新規ファイルに限り slug からファイル名を作ってよい (§2.3)。
    /// 既存ファイルがある場合は上書きせず失敗する。
    pub fn create(&self, front_matter: &FrontMatter, body: &str) -> Result<PathBuf, RepoError> {
        let errors = front_matter.validate();
        if !errors.is_empty() {
            return Err(RepoError::Validation(errors.join(" / ")));
        }

        if self.slug_in_use(&front_matter.slug, None) {
            return Err(RepoError::Validation(format!(
                "slug `{}` は既に別の記事で使われています",
                front_matter.slug
            )));
        }

        let path = self.path_for(Status::Draft, &format!("{}.md", front_matter.slug));
        // 既存記事の体裁に合わせ、本文の前には空行を 1 行置く
        // (保存時は本文をバイト単位で保持するため、ここでのみ補正する)
        let body = if body.is_empty() || body.starts_with('\n') {
            body.to_string()
        } else {
            format!("\n{body}")
        };
        let contents = render(front_matter, &body)?;
        fs::create_dir_all(self.drafts_dir())?;
        // create_new で「存在しないこと」を原子的に確認する (上書きを防ぐ)
        write_new(&path, &contents)?;
        Ok(path)
    }

    /// 記事を削除する。ファイルは `.trash/` へ退避し、復元できるようにする。
    pub fn delete(&self, post: &PostFile, expected_revision: &str) -> Result<PathBuf, RepoError> {
        self.ensure_revision_matches(&post.path, expected_revision)?;

        move_to_trash(&self.trash_dir, &post.path, post.status, &post.file_name)
    }

    /// 楽観ロック。空の revision は「検査をスキップ」ではなく **エラー** とする
    /// (hidden フィールドを消すだけで上書きできてしまうため)。
    fn ensure_revision_matches(
        &self,
        path: &Path,
        expected_revision: &str,
    ) -> Result<(), RepoError> {
        if expected_revision.is_empty() {
            return Err(RepoError::RevisionRequired);
        }
        let current = fs::read_to_string(path)
            .map(|raw| hash_revision(&raw))
            .unwrap_or_default();
        if current != expected_revision {
            return Err(RepoError::Conflict);
        }
        Ok(())
    }
}

pub struct ParsedPost {
    pub front_matter: FrontMatter,
    pub raw_front_matter: String,
    pub body: String,
}

/// frontmatter と本文を分離する。**本文はバイト単位でそのまま保持する**。
pub fn parse(raw: &str) -> Result<ParsedPost, RepoError> {
    let rest = raw
        .strip_prefix(FRONT_MATTER_DELIMITER)
        .ok_or(RepoError::MissingFrontMatter)?;
    let rest = rest
        .strip_prefix("\r\n")
        .or_else(|| rest.strip_prefix('\n'))
        .ok_or(RepoError::MissingFrontMatter)?;

    let mut offset = 0usize;
    for line in rest.split_inclusive('\n') {
        if line.trim_end_matches(['\n', '\r']) == FRONT_MATTER_DELIMITER {
            let yaml = &rest[..offset];
            let body = &rest[offset + line.len()..];
            let front_matter: FrontMatter = serde_yaml::from_str(yaml)?;
            return Ok(ParsedPost {
                front_matter,
                raw_front_matter: yaml.to_string(),
                body: body.to_string(),
            });
        }
        offset += line.len();
    }

    Err(RepoError::MissingFrontMatterEnd)
}

/// frontmatter + 本文を markdown 文字列に戻す。
///
/// コメント・キー順・クォートは元通りにならない (YAML の正規化)。
/// 本文は呼び出し側が保持しているものをそのまま使う。
pub fn render(front_matter: &FrontMatter, body: &str) -> Result<String, RepoError> {
    let yaml = serde_yaml::to_string(front_matter)?;
    Ok(format!(
        "{FRONT_MATTER_DELIMITER}\n{yaml}{FRONT_MATTER_DELIMITER}\n{body}"
    ))
}

/// 同一ディレクトリに一時ファイルを作り rename する。
/// 書き込み途中のクラッシュで既存記事が壊れないようにするため。
pub fn atomic_write(path: &Path, contents: &str) -> io::Result<()> {
    let dir = path.parent().unwrap_or_else(|| Path::new("."));
    fs::create_dir_all(dir)?;

    let file_name = path
        .file_name()
        .map(|name| name.to_string_lossy().to_string())
        .unwrap_or_else(|| "post.md".to_string());
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or_default();
    let temp_path = dir.join(format!(".{file_name}.tmp-{}-{nanos}", std::process::id()));

    if let Err(err) = fs::write(&temp_path, contents) {
        let _ = fs::remove_file(&temp_path);
        return Err(err);
    }

    match fs::rename(&temp_path, path) {
        Ok(()) => Ok(()),
        Err(err) => {
            let _ = fs::remove_file(&temp_path);
            Err(err)
        }
    }
}

/// 記事ファイルを `.trash/` へ退避する。
///
/// 宛先は **create_new で新規作成してから中身を書き込む** ので、既存の退避ファイルを
/// 上書きしない (秒精度のタイムスタンプだけでは同一秒の削除で衝突する)。
fn move_to_trash(
    trash_dir: &Path,
    source: &Path,
    status: Status,
    file_name: &str,
) -> Result<PathBuf, RepoError> {
    use std::io::Write;
    use std::sync::atomic::{AtomicU64, Ordering};

    static COUNTER: AtomicU64 = AtomicU64::new(0);

    fs::create_dir_all(trash_dir)?;
    let bytes = fs::read(source)?;
    let stamp = chrono::Local::now().format("%Y%m%d%H%M%S%.9f");

    for _ in 0..1000 {
        let sequence = COUNTER.fetch_add(1, Ordering::Relaxed);
        let candidate = trash_dir.join(format!(
            "{stamp}-{}-{sequence}-{}-{file_name}",
            std::process::id(),
            status.as_str()
        ));

        match fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&candidate)
        {
            Ok(mut file) => {
                file.write_all(&bytes)?;
                file.sync_all()?;
                drop(file);
                // 退避先の書き込みが終わってから元を消す (失敗しても元は残る)
                fs::remove_file(source)?;
                return Ok(candidate);
            }
            Err(err) if err.kind() == io::ErrorKind::AlreadyExists => continue,
            Err(err) => return Err(RepoError::Io(err)),
        }
    }

    Err(RepoError::Validation(
        "退避ファイル名を確保できませんでした".into(),
    ))
}

/// 内容のハッシュ (楽観ロック用)
pub fn hash_revision(raw: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(raw.as_bytes());
    format!("{:x}", hasher.finalize())
}

/// 既存ファイルを上書きしない書き込み (`create_new`)。
fn write_new(path: &Path, contents: &str) -> io::Result<()> {
    use std::io::Write;
    let mut file = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(path)?;
    file.write_all(contents.as_bytes())?;
    file.sync_all()?;
    Ok(())
}

/// パスセグメント用の最小パーセントエンコード (非予約文字以外をエスケープ)。
fn percent_encode(input: &str) -> String {
    const UNRESERVED: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
    let mut encoded = String::with_capacity(input.len());
    for byte in input.as_bytes() {
        if UNRESERVED.contains(byte) {
            encoded.push(*byte as char);
        } else {
            encoded.push_str(&format!("%{byte:02X}"));
        }
    }
    encoded
}

impl fmt::Display for Status {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn trash_for(content_dir: &Path) -> PathBuf {
        content_dir.join(".trash")
    }

    fn repo_content_dir() -> PathBuf {
        Path::new(env!("CARGO_MANIFEST_DIR")).join("../../content")
    }

    fn real_article_paths() -> Vec<PathBuf> {
        let dir = repo_content_dir().join("posts");
        let mut paths: Vec<PathBuf> = fs::read_dir(dir)
            .expect("content/posts readable")
            .filter_map(Result::ok)
            .map(|entry| entry.path())
            .filter(|path| path.extension().map(|ext| ext == "md").unwrap_or(false))
            .collect();
        paths.sort();
        paths
    }

    /// 運用中の `content/posts` を全件パースできること。
    /// 記事は増えるので件数は固定しない (件数固定は記事追加のたびに落ちてしまう)。
    #[test]
    fn parses_all_existing_articles() {
        let paths = real_article_paths();
        assert!(!paths.is_empty(), "content/posts に記事があること");

        for path in paths {
            let raw = fs::read_to_string(&path).expect("readable");
            let parsed = parse(&raw).unwrap_or_else(|err| panic!("{}: {err}", path.display()));
            assert!(parsed.front_matter.validate().is_empty());
            assert!(!parsed.front_matter.slug.is_empty());
        }
    }

    /// frontmatter の再シリアライズで値が変わらず、本文がバイト単位で一致すること。
    #[test]
    fn roundtrip_preserves_values_and_body() {
        for path in real_article_paths() {
            let raw = fs::read_to_string(&path).expect("readable");
            let parsed = parse(&raw).unwrap();

            let rendered = render(&parsed.front_matter, &parsed.body).unwrap();
            let reparsed = parse(&rendered).unwrap();

            assert_eq!(
                parsed.front_matter,
                reparsed.front_matter,
                "{}: frontmatter mismatch",
                path.display()
            );
            assert_eq!(
                parsed.body,
                reparsed.body,
                "{}: body must be byte-identical",
                path.display()
            );
        }
    }

    #[test]
    fn body_is_preserved_verbatim() {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("sample.md");
        let raw = "---\ntitle: t\nslug: s\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 10\n  height: 20\n  alternativeText: null\n---\n\n# 見出し\r\n\r\n本文  \n行末空白\n";
        fs::write(&path, raw).unwrap();

        let parsed = parse(raw).unwrap();
        assert_eq!(
            parsed.body, "\n# 見出し\r\n\r\n本文  \n行末空白\n",
            "本文は CRLF や行末空白もそのまま保持する"
        );
    }

    #[test]
    fn keeps_unknown_top_level_and_nested_keys() {
        let raw = "---\ntitle: t\nslug: s\npublishedOn: 2026-01-01\ncategory: blog\ntags: []\ncustomTop: keep-me\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 10\n  height: 20\n  alternativeText: alt\n  customNested: keep-me-too\n---\nbody\n";

        let parsed = parse(raw).unwrap();
        let rendered = render(&parsed.front_matter, &parsed.body).unwrap();

        assert!(rendered.contains("customTop: keep-me"));
        assert!(rendered.contains("customNested: keep-me-too"));

        let reparsed = parse(&rendered).unwrap();
        assert_eq!(parsed.front_matter, reparsed.front_matter);
    }

    /// Elm の decoder は `alternativeText` と `tags` を必須で参照する。
    #[test]
    fn always_emits_alternativetext_and_tags() {
        let raw = "---\ntitle: t\nslug: s\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 10\n  height: 20\n---\nbody\n";
        let parsed = parse(raw).unwrap();
        let rendered = render(&parsed.front_matter, &parsed.body).unwrap();

        assert!(rendered.contains("alternativeText: null"), "{rendered}");
        assert!(rendered.contains("tags: []"), "{rendered}");
    }

    /// ファイル名と slug が一致しない記事でも slug で引けること (§2.3)。
    #[test]
    fn find_resolves_slug_not_filename() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::write(
            content.join("posts/typo-file-name.md"),
            "---\ntitle: T\nslug: actual-slug\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let found = repo.find("actual-slug").expect("found by frontmatter slug");
        assert_eq!(found.path, content.join("posts/typo-file-name.md"));
        assert!(
            repo.find("typo-file-name").is_none(),
            "filename is not a slug"
        );
    }

    #[test]
    fn list_includes_posts_and_drafts() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::create_dir_all(content.join("drafts")).unwrap();
        let article = |slug: &str, date: &str| {
            format!("---\ntitle: {slug}\nslug: {slug}\npublishedOn: {date}\ncategory: blog\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n")
        };
        fs::write(
            content.join("posts/published.md"),
            article("published", "2026-01-01"),
        )
        .unwrap();
        fs::write(
            content.join("drafts/draft.md"),
            article("draft", "2026-02-01"),
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let posts = repo.list();
        assert_eq!(posts.len(), 2);
        assert_eq!(posts[0].slug(), Some("draft"), "新しい順");
        assert_eq!(posts[0].status, Status::Draft);
        assert_eq!(posts[1].status, Status::Published);
    }

    #[test]
    fn broken_article_is_listed_with_error() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::write(content.join("posts/broken.md"), "no frontmatter here\n").unwrap();

        let repo = Repository::new(content, trash_for(content));
        let posts = repo.list();
        assert_eq!(posts.len(), 1);
        assert!(posts[0].is_broken());
        assert!(posts[0].parse_error.is_some(), "壊れた記事は理由を持つ");

        // 一覧から壊れた記事を開けること (状態 + ファイル名で引く)
        let found = repo
            .find_file(Status::Published, "broken.md")
            .expect("broken article is reachable");
        assert!(found.is_unparseable());
        assert_eq!(found.detail_path(), "/files/published/broken.md");
        // slug 空間には現れない
        assert!(repo.find("broken").is_none());
    }

    /// 正常 slug・posts の壊れファイル・drafts の同名壊れファイルが併存しても、
    /// それぞれが意図したファイルを指すこと。
    #[test]
    fn slug_and_broken_file_identifiers_do_not_collide() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::create_dir_all(content.join("drafts")).unwrap();
        fs::write(
            content.join("posts/valid.md"),
            "---\ntitle: V\nslug: shadowed\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();
        fs::write(content.join("posts/shadowed.md"), "broken posts\n").unwrap();
        fs::write(content.join("drafts/shadowed.md"), "broken drafts\n").unwrap();

        let repo = Repository::new(content, trash_for(content));

        let valid = repo.find("shadowed").expect("slug lookup");
        assert!(!valid.is_unparseable());
        assert_eq!(valid.detail_path(), "/posts/shadowed");

        let published_broken = repo
            .find_file(Status::Published, "shadowed.md")
            .expect("published broken file");
        assert_eq!(published_broken.body, String::new());
        assert_eq!(
            published_broken.detail_path(),
            "/files/published/shadowed.md"
        );

        let draft_broken = repo
            .find_file(Status::Draft, "shadowed.md")
            .expect("draft broken file");
        assert_eq!(draft_broken.detail_path(), "/files/draft/shadowed.md");

        // 一覧の各行が別々の detail_path を持つこと
        let paths: Vec<String> = repo.list().iter().map(PostFile::detail_path).collect();
        assert_eq!(paths.len(), 3);
        assert_eq!(
            paths
                .iter()
                .collect::<std::collections::BTreeSet<_>>()
                .len(),
            3,
            "各行が一意な詳細URLを持つ: {paths:?}"
        );
    }

    /// slug が不正 (空・区切り記号入り) な記事は `/posts/{slug}` に載らないため、
    /// ファイル名経由で開けること。detail_path と find_file の条件が一致していること。
    #[test]
    fn invalid_slugs_stay_reachable_via_files_route() {
        for slug in ["bad/slug", "", "a?b", "a#b", "UPPER"] {
            let tmp = tempfile::tempdir().unwrap();
            let content = tmp.path();
            fs::create_dir_all(content.join("posts")).unwrap();
            fs::write(
                content.join("posts/entry.md"),
                format!("---\ntitle: T\nslug: \"{slug}\"\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n"),
            )
            .unwrap();

            let repo = Repository::new(content, trash_for(content));
            let post = repo.list().into_iter().next().expect("listed");
            assert!(post.has_errors(), "slug {slug:?} は要修正");
            assert!(!post.is_routable(), "slug {slug:?} は /posts で開けない");
            assert_eq!(
                post.detail_path(),
                "/files/published/entry.md",
                "slug {slug:?}"
            );

            let found = repo
                .find_file(Status::Published, "entry.md")
                .unwrap_or_else(|| panic!("slug {slug:?} はファイル経由で開ける"));
            assert_eq!(found.file_name, "entry.md");
        }
    }

    /// 正常な slug の記事はファイル経由のルートには現れない (slug 空間を汚さない)。
    #[test]
    fn routable_articles_are_not_reachable_via_files_route() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::write(
            content.join("posts/entry.md"),
            "---\ntitle: T\nslug: entry\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        assert!(repo.find_file(Status::Published, "entry.md").is_none());
    }

    /// 解析はできても値が不正な記事は「要修正」として扱う (サイトのビルドを壊すため)。
    #[test]
    fn invalid_values_are_reported_as_errors() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::write(
            content.join("posts/relative-url.md"),
            "---\ntitle: T\nslug: relative-url\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: not-a-url\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let post = repo.find("relative-url").expect("parseable");
        assert!(!post.is_unparseable());
        assert!(post.has_errors());
        assert!(post.error_summary().contains("絶対 URL"));
    }

    /// タグ内の未知キーが保存で失われないこと (codex 指摘)。
    #[test]
    fn keeps_unknown_keys_inside_tags() {
        let raw = "---\ntitle: t\nslug: s\npublishedOn: 2026-01-01\ncategory: blog\ntags:\n  - id: 42\n    attributes:\n      name: タグ\n      slug: tag\n      customNested: keep-me\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n";

        let parsed = parse(raw).unwrap();
        let rendered = render(&parsed.front_matter, &parsed.body).unwrap();
        let reparsed = parse(&rendered).unwrap();

        assert!(
            rendered.contains("id: 42"),
            "tag 直下の未知キー: {rendered}"
        );
        assert!(
            rendered.contains("customNested: keep-me"),
            "attributes 内の未知キー: {rendered}"
        );
        assert_eq!(parsed.front_matter, reparsed.front_matter);
    }

    #[test]
    fn save_is_atomic_and_roundtrips() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let path = content.join("posts/note.md");
        let raw = "---\ntitle: T\nslug: note\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\n\nbody\n";
        fs::write(&path, raw).unwrap();

        let repo = Repository::new(content, trash_for(content));
        let mut post = repo.find("note").unwrap();
        post.body = "\n\n更新後の本文\n".to_string();
        repo.save(&post, &post.revision.clone()).unwrap();

        let saved = fs::read_to_string(&path).unwrap();
        assert!(saved.ends_with("\n\n更新後の本文\n"));
        // 一時ファイルが残っていないこと
        let leftovers: Vec<_> = fs::read_dir(content.join("posts"))
            .unwrap()
            .filter_map(Result::ok)
            .filter(|entry| entry.file_name().to_string_lossy().contains(".tmp-"))
            .collect();
        assert!(leftovers.is_empty(), "一時ファイルが残っている");
    }

    fn sample_front_matter(slug: &str) -> FrontMatter {
        FrontMatter {
            title: format!("title {slug}"),
            slug: slug.to_string(),
            author: Some("著者".to_string()),
            published_on: "2026-01-01".to_string(),
            category: crate::model::Category::Blog,
            tags: Vec::new(),
            cover_image: Some(crate::model::CoverImage {
                url: "https://example.com/a.jpg".to_string(),
                width: 10,
                height: 10,
                alternative_text: Some(String::new()),
                extra: std::collections::BTreeMap::new(),
            }),
            extra: std::collections::BTreeMap::new(),
        }
    }

    #[test]
    fn create_writes_draft_and_rejects_existing_file() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        let repo = Repository::new(content, trash_for(content));

        let path = repo
            .create(&sample_front_matter("new-post"), "本文\n")
            .unwrap();
        assert_eq!(path, content.join("drafts/new-post.md"));
        assert!(path.exists(), "下書きとして作成される");

        let created = repo.find("new-post").expect("作成した記事を引ける");
        assert_eq!(created.status, Status::Draft);
        assert_eq!(
            created.body, "\n本文\n",
            "本文の前に空行が入る (既存記事の体裁)"
        );

        // 2 回目は上書きせず失敗する
        let err = repo
            .create(&sample_front_matter("new-post"), "別の本文")
            .unwrap_err();
        assert!(err.to_string().contains("既に"));
        assert!(fs::read_to_string(&path).unwrap().contains("本文"));

        // 同じ slug の既存ファイル名が違っても作れない (slug 一意)
        fs::write(content.join("drafts/other-file.md"), "").unwrap();
        assert!(repo.create(&sample_front_matter("new-post"), "x").is_err());
    }

    #[test]
    fn save_rejects_stale_revision() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let path = content.join("posts/note.md");
        fs::write(
            &path,
            "---\ntitle: T\nslug: note\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let post = repo.find("note").unwrap();
        let stale = post.revision.clone();

        // 別の編集が先に保存された状況を作る
        fs::write(
            &path,
            format!("{}\n追記\n", fs::read_to_string(&path).unwrap()),
        )
        .unwrap();

        let err = repo.save(&post, &stale).unwrap_err();
        assert!(matches!(
            err,
            RepoError::Conflict | RepoError::Validation(_)
        ));
        assert!(err.to_string().contains("再読み込み"));

        // 最新の revision なら保存できる
        let fresh = repo.find("note").unwrap();
        repo.save(&fresh, &fresh.revision).unwrap();
    }

    #[test]
    fn save_rejects_slug_and_category_change_for_published() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::write(
            content.join("posts/published.md"),
            "---\ntitle: T\nslug: published\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));

        let mut post = repo.find("published").unwrap();
        post.front_matter.as_mut().unwrap().slug = "renamed".to_string();
        let err = repo.save(&post, &post.revision.clone()).unwrap_err();
        assert!(err.to_string().contains("slug は変更できません"));

        let mut post = repo.find("published").unwrap();
        post.front_matter.as_mut().unwrap().category = crate::model::Category::Blog;
        let err = repo.save(&post, &post.revision.clone()).unwrap_err();
        assert!(err.to_string().contains("カテゴリは変更できません"));
    }

    #[test]
    fn delete_moves_file_to_trash() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let path = content.join("posts/gone.md");
        fs::write(
            &path,
            "---\ntitle: T\nslug: gone\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let post = repo.find("gone").unwrap();
        let trashed = repo.delete(&post, &post.revision.clone()).unwrap();

        assert!(!path.exists(), "元ファイルは消える");
        assert!(trashed.exists(), "trash に退避される");
        assert!(trashed
            .file_name()
            .unwrap()
            .to_string_lossy()
            .contains("gone.md"));
        assert!(repo.find("gone").is_none());
    }

    #[test]
    fn delete_rejects_stale_revision() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let path = content.join("posts/keep.md");
        fs::write(
            &path,
            "---\ntitle: T\nslug: keep\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let post = repo.find("keep").unwrap();
        fs::write(&path, "changed\n").unwrap();

        assert!(matches!(
            repo.delete(&post, &post.revision.clone()).unwrap_err(),
            RepoError::Conflict
        ));
        assert!(path.exists(), "衝突時は削除しない");
    }

    #[test]
    fn save_rejects_duplicate_slug() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let article = |slug: &str, title: &str| {
            format!("---\ntitle: {title}\nslug: {slug}\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n")
        };
        fs::write(content.join("posts/a.md"), article("a", "A")).unwrap();
        fs::write(content.join("posts/b.md"), article("b", "B")).unwrap();

        let repo = Repository::new(content, trash_for(content));
        let mut post = repo.find("b").unwrap();
        post.front_matter.as_mut().unwrap().slug = "a".to_string();

        let err = repo.save(&post, &post.revision.clone()).unwrap_err();
        assert!(err.to_string().contains("既に別の記事"));
    }

    #[test]
    fn save_rejects_invalid_front_matter() {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path();
        fs::create_dir_all(content.join("posts")).unwrap();
        let path = content.join("posts/a.md");
        fs::write(
            &path,
            "---\ntitle: A\nslug: a\npublishedOn: 2026-01-01\ncategory: news\ntags: []\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 1\n  height: 1\n  alternativeText: null\n---\nbody\n",
        )
        .unwrap();

        let repo = Repository::new(content, trash_for(content));
        let mut post = repo.find("a").unwrap();
        post.front_matter.as_mut().unwrap().slug = "../evil".to_string();

        assert!(repo.save(&post, &post.revision.clone()).is_err());
    }
}
