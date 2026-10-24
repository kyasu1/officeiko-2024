use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// 記事カテゴリ。`src/Post.elm` の `categoryDecoder` と対応する。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Category {
    News,
    Blog,
}

impl Category {
    pub fn as_str(self) -> &'static str {
        match self {
            Category::News => "news",
            Category::Blog => "blog",
        }
    }

    /// サイト上の表示ラベル (`Post.categoryToLabel` と一致させる)
    pub fn label(self) -> &'static str {
        match self {
            Category::News => "お知らせ",
            Category::Blog => "ブログ",
        }
    }

    /// 公開URLのパス接頭辞。`/post/:slug` は News、`/blog/:slug` は Blog。
    pub fn url_prefix(self) -> &'static str {
        match self {
            Category::News => "post",
            Category::Blog => "blog",
        }
    }
}

/// Elm 側 `tagDecoder` が `attributes.name` / `attributes.slug` を要求する。
/// 未知キーはタグを編集しない保存でも失われないよう保持する。
#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct TagAttributes {
    pub name: String,
    pub slug: String,
    /// 未知キーの保護 (ネストした未知キーも保持する)
    #[serde(flatten, default)]
    pub extra: BTreeMap<String, serde_yaml::Value>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct Tag {
    #[serde(default)]
    pub attributes: TagAttributes,
    /// 未知キーの保護 (例: `id` など)
    #[serde(flatten, default)]
    pub extra: BTreeMap<String, serde_yaml::Value>,
}

/// カバー画像。`alternativeText` は Elm の `JD.field` が必須のため、
/// 未設定でも `null` として必ず出力する (skip しない)。
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct CoverImage {
    pub url: String,
    pub width: u32,
    pub height: u32,
    #[serde(rename = "alternativeText")]
    pub alternative_text: Option<String>,
    /// 未知キーの保護 (ネストした未知キーも保持する)
    #[serde(flatten, default)]
    pub extra: BTreeMap<String, serde_yaml::Value>,
}

/// 記事の frontmatter。既存記事のスキーマと同一。
///
/// `extra` は未知のトップレベルキーを保持するためのもの。
/// 既存記事を壊さずに読み書きするために必要。
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FrontMatter {
    pub title: String,
    pub slug: String,
    #[serde(default)]
    pub author: Option<String>,
    #[serde(rename = "publishedOn")]
    pub published_on: String,
    pub category: Category,
    #[serde(default)]
    pub tags: Vec<Tag>,
    #[serde(rename = "coverImage")]
    pub cover_image: CoverImage,
    #[serde(flatten, default)]
    pub extra: BTreeMap<String, serde_yaml::Value>,
}

/// タグ入力欄 (1行 1 件 `表示名,slug`) をパースする。
///
/// Elm 側は `{ attributes: { name, slug } }` を要求するが、slug を日本語から
/// 自動生成できないため、表示名と slug を両方入力してもらう。
pub fn parse_tags_input(input: &str) -> Result<Vec<Tag>, String> {
    let mut tags = Vec::new();
    for (index, line) in input.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.split(',').map(str::trim).collect();
        let (name, slug) = match parts.as_slice() {
            [name, slug] if !name.is_empty() && !slug.is_empty() => (*name, *slug),
            _ => {
                return Err(format!(
                    "{} 行目のタグは `表示名,slug` の形式で入力してください (現在: {line:?})",
                    index + 1
                ))
            }
        };
        if !is_valid_slug(slug) {
            return Err(format!(
                "{} 行目のタグ slug は英小文字・数字・ハイフンのみ使用できます (現在: {slug:?})",
                index + 1
            ));
        }
        tags.push(Tag {
            attributes: TagAttributes {
                name: name.to_string(),
                slug: slug.to_string(),
                extra: BTreeMap::new(),
            },
            extra: BTreeMap::new(),
        });
    }
    Ok(tags)
}

/// タグをフォーム入力欄の文字列に戻す。
pub fn tags_to_input(tags: &[Tag]) -> String {
    tags.iter()
        .map(|tag| format!("{},{}", tag.attributes.name, tag.attributes.slug))
        .collect::<Vec<_>>()
        .join("\n")
}

impl FrontMatter {
    /// フォームの既定値 (新規作成用)
    pub fn new_draft(published_on: String) -> Self {
        Self {
            title: String::new(),
            slug: String::new(),
            author: Some("小松原 康行".to_string()),
            published_on,
            category: Category::Blog,
            tags: Vec::new(),
            cover_image: CoverImage {
                url: String::new(),
                width: 1200,
                height: 630,
                alternative_text: Some(String::new()),
                extra: BTreeMap::new(),
            },
            extra: BTreeMap::new(),
        }
    }

    /// 公開済み記事の URL パス (例: `/blog/fake-site-alert`)
    pub fn url_path(&self) -> String {
        format!("/{}/{}", self.category.url_prefix(), self.slug)
    }

    pub fn validate(&self) -> Vec<String> {
        let mut errors = Vec::new();

        if self.title.trim().is_empty() {
            errors.push("title は必須です".to_string());
        }
        if !is_valid_slug(&self.slug) {
            errors.push(format!(
                "slug は英小文字・数字・ハイフンのみ使用できます (現在: {:?})",
                self.slug
            ));
        }
        if chrono::NaiveDate::parse_from_str(&self.published_on, "%Y-%m-%d").is_err() {
            errors.push(format!(
                "publishedOn は YYYY-MM-DD 形式で指定してください (現在: {:?})",
                self.published_on
            ));
        }
        if self.cover_image.url.trim().is_empty() {
            errors.push("coverImage.url は必須です".to_string());
        } else if !is_absolute_http_url(&self.cover_image.url) {
            // Elm の `Image.decoder` は `Url.fromString` を使うため、
            // 絶対 URL でないとサイトのビルドが壊れる。
            errors.push(format!(
                "coverImage.url は http(s) の絶対 URL で指定してください (現在: {:?})",
                self.cover_image.url
            ));
        }
        if self.cover_image.width == 0 || self.cover_image.height == 0 {
            errors.push("coverImage の width/height は 1 以上で指定してください".to_string());
        }
        for (index, tag) in self.tags.iter().enumerate() {
            if tag.attributes.name.is_empty() || tag.attributes.slug.is_empty() {
                errors.push(format!(
                    "tags[{index}] は attributes.name / attributes.slug が必須です"
                ));
            }
        }

        errors
    }
}

/// slug は `^[a-z0-9][a-z0-9-]*$` (パス横断や大文字を許さない)
pub fn is_valid_slug(slug: &str) -> bool {
    static RE: std::sync::OnceLock<regex::Regex> = std::sync::OnceLock::new();
    let re = RE.get_or_init(|| regex::Regex::new(r"^[a-z0-9][a-z0-9-]*$").expect("valid regex"));
    re.is_match(slug)
}

/// `http://` または `https://` で始まる絶対 URL か。
///
/// Elm の `Url.fromString` (elm/url 1.0.0) が受理する範囲に合わせて検証する。
/// 受理しない URL を保存すると `Image.decoder` が失敗しサイトのビルドが壊れるため。
///
/// Elm 側の制約:
///   - スキームは小文字の `http://` / `https://` のみ
///   - authority に `@` (userinfo) を含むと `Nothing`
///   - port は `String.toInt` で数値にできる必要がある (コロンは最大1つ)
///   - host が空だと `Nothing`
///
/// Elm よりわずかに厳しく、authority 内の空白も拒否する (実用上無効なため)。
pub fn is_absolute_http_url(url: &str) -> bool {
    let rest = match url.strip_prefix("http://") {
        Some(rest) => rest,
        None => match url.strip_prefix("https://") {
            Some(rest) => rest,
            None => return false,
        },
    };

    // Elm は fragment → query → path の順に切り落とし、残りを authority として扱う。
    let rest = rest.split('#').next().unwrap_or_default();
    let rest = rest.split('?').next().unwrap_or_default();
    let authority = rest.split('/').next().unwrap_or_default();

    if authority.is_empty() || authority.contains('@') || authority.contains(char::is_whitespace) {
        return false;
    }

    let mut parts = authority.split(':');
    let host = parts.next().unwrap_or_default();
    let port = parts.next();
    if parts.next().is_some() {
        // コロンが2つ以上
        return false;
    }
    if host.is_empty() {
        return false;
    }
    match port {
        Some(port) => !port.is_empty() && port.chars().all(|c| c.is_ascii_digit()),
        None => true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_slugs() {
        for slug in ["a", "post-2024", "summer-vacation-2026", "0", "a1-b2"] {
            assert!(is_valid_slug(slug), "{slug} should be valid");
        }
    }

    #[test]
    fn invalid_slugs() {
        for slug in ["", "-a", "A", "a_b", "a/b", "../etc/passwd", "a b", "日本"] {
            assert!(!is_valid_slug(slug), "{slug} should be invalid");
        }
    }

    #[test]
    fn url_path_uses_category_prefix() {
        let news = front_matter_with(Category::News, "summer-vacation-2026");
        let blog = front_matter_with(Category::Blog, "fake-site-alert");
        assert_eq!(news.url_path(), "/post/summer-vacation-2026");
        assert_eq!(blog.url_path(), "/blog/fake-site-alert");
    }

    #[test]
    fn absolute_http_urls() {
        for url in [
            "https://image.officeiko.work/cover_summer_vacation.jpg",
            "http://example.com/a.png",
            "https://example.com",
            "https://example.com/a.jpg?v=1#frag",
            "https://example.com:8443/a.jpg",
        ] {
            assert!(is_absolute_http_url(url), "{url} should be valid");
        }
    }

    #[test]
    fn rejects_non_absolute_or_unsupported_urls() {
        for url in [
            "",
            "not-a-url",
            "/images/a.jpg",
            "image.officeiko.work/a.jpg",
            "ftp://example.com/a.jpg",
            "https://exa mple.com/a.jpg",
            "https://",
            "https:///path.jpg",
            "https://example.com:/x.jpg",
            // Elm が拒否する (port が数値でない)
            "https://example.com:abc/x.jpg",
            // Elm が拒否する (userinfo)
            "https://user@example.com/x.jpg",
            "https://example.com:80:80/x.jpg",
        ] {
            assert!(!is_absolute_http_url(url), "{url} should be invalid");
        }
    }

    #[test]
    fn parses_tags_input() {
        let tags = parse_tags_input("買取,trade-in\n\n  質預かり , pawn \n").unwrap();
        assert_eq!(tags.len(), 2);
        assert_eq!(tags[0].attributes.name, "買取");
        assert_eq!(tags[0].attributes.slug, "trade-in");
        assert_eq!(tags[1].attributes.name, "質預かり");
        assert_eq!(tags[1].attributes.slug, "pawn");
        assert_eq!(tags_to_input(&tags), "買取,trade-in\n質預かり,pawn");
    }

    #[test]
    fn rejects_malformed_tags_input() {
        assert!(parse_tags_input("買取").is_err(), "slug がない");
        assert!(parse_tags_input("買取,").is_err(), "slug が空");
        assert!(parse_tags_input(",trade-in").is_err(), "name が空");
        assert!(parse_tags_input("買取,TradeIn").is_err(), "slug が不正");
        assert!(
            parse_tags_input("買取,trade-in,extra").is_err(),
            "項目が多い"
        );
    }

    #[test]
    fn validate_rejects_relative_cover_image_url() {
        let mut front_matter = front_matter_with(Category::Blog, "a");
        front_matter.cover_image.url = "not-a-url".to_string();
        let errors = front_matter.validate();
        assert!(errors.iter().any(|error| error.contains("絶対 URL")));
    }

    fn front_matter_with(category: Category, slug: &str) -> FrontMatter {
        FrontMatter {
            title: "t".to_string(),
            slug: slug.to_string(),
            author: None,
            published_on: "2026-01-01".to_string(),
            category,
            tags: vec![],
            cover_image: CoverImage {
                url: "https://example.com/a.jpg".to_string(),
                width: 1,
                height: 1,
                alternative_text: None,
                extra: BTreeMap::new(),
            },
            extra: BTreeMap::new(),
        }
    }
}
