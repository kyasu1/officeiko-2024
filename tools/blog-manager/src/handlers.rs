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
    /// 詳細ページの URL に使う鍵 (正常=slug / 壊れ=ファイル名)
    pub key: String,
    pub status_label: &'static str,
    pub status_class: &'static str,
    pub category_label: &'static str,
    pub published_on: String,
    pub file_name: String,
    pub is_broken: bool,
    pub error: String,
}

impl PostRow {
    fn from_post(post: &PostFile) -> Self {
        match &post.front_matter {
            Some(front_matter) => Self {
                title: front_matter.title.clone(),
                slug: front_matter.slug.clone(),
                key: front_matter.slug.clone(),
                status_label: post.status.label(),
                status_class: status_class(post.status),
                category_label: front_matter.category.label(),
                published_on: front_matter.published_on.clone(),
                file_name: post.file_name.clone(),
                is_broken: false,
                error: String::new(),
            },
            None => Self {
                title: post.title().to_string(),
                slug: String::new(),
                key: post.lookup_key(),
                status_label: post.status.label(),
                status_class: status_class(post.status),
                category_label: "-",
                published_on: "-".to_string(),
                file_name: post.file_name.clone(),
                is_broken: true,
                error: post.parse_error.clone().unwrap_or_default(),
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
    let broken_count = posts.iter().filter(|post| post.is_broken()).count();

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
    error: String,
}

pub async fn detail(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    let Some(post) = state.repo.find(&slug) else {
        return (
            StatusCode::NOT_FOUND,
            Html(format!(
                "<h1>記事が見つかりません</h1><p>slug: <code>{}</code></p><p><a href=\"/\">一覧へ戻る</a></p>",
                html_escape(&slug)
            )),
        )
            .into_response();
    };

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
            error: String::new(),
        },
        None => DetailTemplate {
            title: post.file_name.clone(),
            slug: slug.clone(),
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
            error: post.parse_error.clone().unwrap_or_default(),
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
