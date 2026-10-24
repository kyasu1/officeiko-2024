use crate::model::Category;
use crate::repository::{PostFile, Repository, Status};
use askama::Template;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::{Html, IntoResponse, Response};
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub repo: Arc<Repository>,
}

/// askama テンプレートの `render()` を HTTP レスポンスにする。
fn render_template<T: Template>(template: T) -> Response {
    match template.render() {
        Ok(html) => Html(html).into_response(),
        Err(err) => {
            tracing::error!("template rendering failed: {err}");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("テンプレートの描画に失敗しました: {err}"),
            )
                .into_response()
        }
    }
}

// ---------------------------------------------------------------------------
// 一覧
// ---------------------------------------------------------------------------

#[derive(Template)]
#[template(path = "list.html")]
struct ListTemplate {
    content_dir: String,
    rows: Vec<PostRow>,
    published_count: usize,
    draft_count: usize,
    broken_count: usize,
}

pub struct PostRow {
    pub title: String,
    pub slug: String,
    /// 詳細ページの URL (正常=slug / 解析不能=状態+ファイル名)
    pub detail_path: String,
    pub status_label: &'static str,
    pub status_class: &'static str,
    pub category_label: &'static str,
    pub published_on: String,
    pub file_name: String,
    pub has_errors: bool,
    pub error: String,
}

impl PostRow {
    fn from_post(post: &PostFile) -> Self {
        let has_errors = post.has_errors();
        let error = post.error_summary();

        match &post.front_matter {
            Some(front_matter) => Self {
                title: front_matter.title.clone(),
                slug: front_matter.slug.clone(),
                detail_path: post.detail_path(),
                status_label: post.status.label(),
                status_class: status_class(post.status),
                category_label: front_matter.category.label(),
                published_on: front_matter.published_on.clone(),
                file_name: post.file_name.clone(),
                has_errors,
                error,
            },
            None => Self {
                title: post.title().to_string(),
                slug: String::new(),
                detail_path: post.detail_path(),
                status_label: post.status.label(),
                status_class: status_class(post.status),
                category_label: "-",
                published_on: "-".to_string(),
                file_name: post.file_name.clone(),
                has_errors,
                error,
            },
        }
    }
}

fn status_class(status: Status) -> &'static str {
    match status {
        Status::Published => "badge-success",
        Status::Draft => "badge-warning",
    }
}

pub async fn list(State(state): State<AppState>) -> Response {
    let posts = state.repo.list();
    let rows: Vec<PostRow> = posts.iter().map(PostRow::from_post).collect();

    let published_count = posts
        .iter()
        .filter(|post| post.status == Status::Published)
        .count();
    let draft_count = posts
        .iter()
        .filter(|post| post.status == Status::Draft)
        .count();
    let broken_count = posts.iter().filter(|post| post.has_errors()).count();

    render_template(ListTemplate {
        content_dir: state.repo.content_dir().display().to_string(),
        rows,
        published_count,
        draft_count,
        broken_count,
    })
}

// ---------------------------------------------------------------------------
// 詳細
// ---------------------------------------------------------------------------

#[derive(Template)]
#[template(path = "detail.html")]
struct DetailTemplate {
    title: String,
    slug: String,
    category_label: &'static str,
    published_on: String,
    author: String,
    status_label: &'static str,
    status_class: &'static str,
    url_path: String,
    cover_url: String,
    cover_width: u32,
    cover_height: u32,
    cover_alt: String,
    tags: Vec<String>,
    body: String,
    raw_front_matter: String,
    file_path: String,
    /// 要修正の理由 (空なら問題なし)
    error: String,
    /// frontmatter を解析できなかったか (本文を表示できない)
    unparseable: bool,
}

pub async fn detail(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    match state.repo.find(&slug) {
        Some(post) => render_detail(post),
        None => not_found(&format!("slug: {slug}")),
    }
}

/// 解析できなかった記事を状態 + ファイル名で表示する (slug 空間と混ぜない)。
pub async fn file_detail(
    State(state): State<AppState>,
    Path((status, file_name)): Path<(String, String)>,
) -> Response {
    let Some(status) = parse_status(&status) else {
        return not_found(&format!("status: {status}"));
    };
    match state.repo.find_file(status, &file_name) {
        Some(post) => render_detail(post),
        None => not_found(&format!("file: {file_name}")),
    }
}

fn parse_status(value: &str) -> Option<Status> {
    match value {
        "published" => Some(Status::Published),
        "draft" => Some(Status::Draft),
        _ => None,
    }
}

fn not_found(detail: &str) -> Response {
    (
        StatusCode::NOT_FOUND,
        Html(format!(
            "<h1>記事が見つかりません</h1><p><code>{}</code></p><p><a href=\"/\">一覧へ戻る</a></p>",
            html_escape(detail)
        )),
    )
        .into_response()
}

fn render_detail(post: PostFile) -> Response {
    let front_matter = post.front_matter.clone();
    let template = match front_matter {
        Some(fm) => DetailTemplate {
            title: fm.title.clone(),
            slug: fm.slug.clone(),
            category_label: fm.category.label(),
            published_on: fm.published_on.clone(),
            author: fm.author.clone().unwrap_or_else(|| "-".to_string()),
            status_label: post.status.label(),
            status_class: status_class(post.status),
            url_path: fm.url_path(),
            cover_url: fm.cover_image.url.clone(),
            cover_width: fm.cover_image.width,
            cover_height: fm.cover_image.height,
            cover_alt: fm.cover_image.alternative_text.clone().unwrap_or_default(),
            tags: fm
                .tags
                .iter()
                .map(|tag| tag.attributes.name.clone())
                .collect(),
            body: post.body.clone(),
            raw_front_matter: post.raw_front_matter.clone(),
            file_path: post.path.display().to_string(),
            error: post.error_summary(),
            unparseable: false,
        },
        None => DetailTemplate {
            title: post.file_name.clone(),
            slug: post.slug().unwrap_or_default().to_string(),
            category_label: "-",
            published_on: "-".to_string(),
            author: "-".to_string(),
            status_label: post.status.label(),
            status_class: status_class(post.status),
            url_path: String::new(),
            cover_url: String::new(),
            cover_width: 0,
            cover_height: 0,
            cover_alt: String::new(),
            tags: Vec::new(),
            body: String::new(),
            raw_front_matter: String::new(),
            file_path: post.path.display().to_string(),
            error: post.error_summary(),
            unparseable: post.is_unparseable(),
        },
    };

    render_template(template)
}

fn html_escape(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

/// テスト用にカテゴリ表示の対応を確認する
#[allow(dead_code)]
fn category_label(category: Category) -> &'static str {
    category.label()
}
