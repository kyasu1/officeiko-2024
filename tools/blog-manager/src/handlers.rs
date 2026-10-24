use crate::model::{merge_tags_input, tags_to_input, Category, CoverImage, FrontMatter};
use crate::repository::{PostFile, RepoError, Repository, Status};
use crate::storage::StorageBackend;
use askama::Template;
use axum::extract::{Path, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Form;
use serde::Deserialize;
use std::collections::BTreeMap;
use std::path::PathBuf;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub repo: Arc<Repository>,
    /// 書き込み系の操作を直列化する (同時保存・二重送信の防止)
    pub write_lock: Arc<tokio::sync::Mutex<()>>,
    /// メディア manifest の保存先 (`state/media/`)
    pub media_dir: PathBuf,
    /// 下書きメディアの置き場所 (RustFS)
    pub rustfs: StorageBackend,
    /// 公開メディアの置き場所 (R2)
    pub r2: StorageBackend,
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
    flash: String,
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

/// 一覧のクエリ (`?flash=created` など)
#[derive(Deserialize)]
pub struct ListQuery {
    #[serde(default)]
    pub flash: String,
}

pub async fn list(
    State(state): State<AppState>,
    query: axum::extract::Query<ListQuery>,
) -> Response {
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
        flash: flash_message(&query.flash).to_string(),
    })
}

fn flash_message(flash: &str) -> &'static str {
    match flash {
        "created" => "下書きを作成しました。",
        "media-added" => "メディアを追加しました。",
        "updated" => "保存しました。",
        "deleted" => "削除しました (.trash に退避)。",
        _ => "",
    }
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
    /// 編集・削除できるか (解析できていること)
    editable: bool,
    /// 一覧へ戻る前の通知
    flash: String,
    /// 削除確認へのリンク用
    delete_path: String,
    edit_path: String,
}

pub async fn detail(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    match state.repo.find(&slug) {
        Some(post) => render_detail(post, ""),
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
        Some(post) => render_detail(post, ""),
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

fn render_detail(post: PostFile, flash: &str) -> Response {
    let front_matter = post.front_matter.clone();
    // 編集・削除リンクは `/posts/{slug}` 配下のルートを使うため、
    // ルートに乗る記事 (slug が有効) だけ操作できる
    let editable = post.is_routable();
    let error = post.error_summary();
    let detail_path = post.detail_path();

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
            error,
            unparseable: false,
            editable,
            flash: flash.to_string(),
            delete_path: format!("{detail_path}/delete"),
            edit_path: format!("{detail_path}/edit"),
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
            error,
            unparseable: true,
            editable,
            flash: flash.to_string(),
            delete_path: format!("{detail_path}/delete"),
            edit_path: format!("{detail_path}/edit"),
        },
    };

    render_template(template)
}

// ---------------------------------------------------------------------------
// 作成 / 編集フォーム
// ---------------------------------------------------------------------------

#[derive(Template)]
#[template(path = "form.html")]
struct FormTemplate {
    heading: &'static str,
    is_edit: bool,
    action: String,
    /// 公開済み記事は slug / category を変更できない
    slug_readonly: bool,
    category_readonly: bool,
    /// 編集対象のファイル (表示用)
    file_path: String,
    /// 楽観ロック用の hidden 値
    revision: String,
    errors: Vec<String>,
    values: FormValues,
    /// 楽観ロック衝突。再読み込みを促し、revision は空にして再送も拒否する。
    conflict: bool,
}

#[derive(Default, Clone)]
struct FormValues {
    title: String,
    slug: String,
    category: String,
    published_on: String,
    author: String,
    cover_url: String,
    cover_width: String,
    cover_height: String,
    cover_alt: String,
    tags: String,
    body: String,
}

impl FormValues {
    fn from_front_matter(front_matter: &FrontMatter, body: &str) -> Self {
        Self {
            title: front_matter.title.clone(),
            slug: front_matter.slug.clone(),
            category: front_matter.category.as_str().to_string(),
            published_on: front_matter.published_on.clone(),
            author: front_matter.author.clone().unwrap_or_default(),
            cover_url: front_matter.cover_image.url.clone(),
            cover_width: front_matter.cover_image.width.to_string(),
            cover_height: front_matter.cover_image.height.to_string(),
            cover_alt: front_matter
                .cover_image
                .alternative_text
                .clone()
                .unwrap_or_default(),
            tags: tags_to_input(&front_matter.tags),
            body: body.to_string(),
        }
    }
}

#[derive(Deserialize, Default)]
pub struct PostForm {
    #[serde(default)]
    pub title: String,
    #[serde(default)]
    pub slug: String,
    #[serde(default)]
    pub category: String,
    #[serde(default)]
    pub published_on: String,
    #[serde(default)]
    pub author: String,
    #[serde(default)]
    pub cover_url: String,
    #[serde(default)]
    pub cover_width: String,
    #[serde(default)]
    pub cover_height: String,
    #[serde(default)]
    pub cover_alt: String,
    #[serde(default)]
    pub tags: String,
    #[serde(default)]
    pub body: String,
    #[serde(default)]
    pub expected_revision: String,
}

impl PostForm {
    fn values(&self) -> FormValues {
        FormValues {
            title: self.title.clone(),
            slug: self.slug.clone(),
            category: self.category.clone(),
            published_on: self.published_on.clone(),
            author: self.author.clone(),
            cover_url: self.cover_url.clone(),
            cover_width: self.cover_width.clone(),
            cover_height: self.cover_height.clone(),
            cover_alt: self.cover_alt.clone(),
            tags: self.tags.clone(),
            body: self.body.clone(),
        }
    }

    /// フォーム入力を検証して frontmatter に変換する。
    fn to_front_matter(&self, base: FrontMatter) -> Result<FrontMatter, Vec<String>> {
        let mut errors = Vec::new();

        let category = match self.category.trim() {
            "news" => Category::News,
            "blog" => Category::Blog,
            other => {
                errors.push(format!(
                    "カテゴリは news / blog のいずれかです (現在: {other:?})"
                ));
                base.category
            }
        };

        let cover_width = parse_dimension(&self.cover_width, "coverImage.width", &mut errors);
        let cover_height = parse_dimension(&self.cover_height, "coverImage.height", &mut errors);

        let tags = match merge_tags_input(&self.tags, &base.tags) {
            Ok(tags) => tags,
            Err(error) => {
                errors.push(error);
                base.tags.clone()
            }
        };

        let alternative_text = {
            let value = self.cover_alt.trim();
            if value.is_empty() {
                Some(String::new())
            } else {
                Some(value.to_string())
            }
        };

        let front_matter = FrontMatter {
            title: self.title.trim().to_string(),
            slug: self.slug.trim().to_string(),
            author: {
                let author = self.author.trim();
                if author.is_empty() {
                    None
                } else {
                    Some(author.to_string())
                }
            },
            published_on: self.published_on.trim().to_string(),
            category,
            tags,
            cover_image: CoverImage {
                url: self.cover_url.trim().to_string(),
                width: cover_width,
                height: cover_height,
                alternative_text,
                extra: base.cover_image.extra.clone(),
            },
            extra: base.extra.clone(),
        };

        // モデル側の検証 (slug 形式・日付・URL など)
        errors.extend(front_matter.validate());
        errors.dedup();

        if errors.is_empty() {
            Ok(front_matter)
        } else {
            Err(errors)
        }
    }
}

fn parse_dimension(value: &str, field: &str, errors: &mut Vec<String>) -> u32 {
    match value.trim().parse::<u32>() {
        Ok(number) if number > 0 => number,
        _ => {
            errors.push(format!("{field} は 1 以上の整数で指定してください"));
            0
        }
    }
}

pub async fn new_form() -> Response {
    render_template(form_template_new(
        FormValues {
            published_on: chrono::Local::now().format("%Y-%m-%d").to_string(),
            category: "blog".to_string(),
            ..FormValues::from_front_matter(&FrontMatter::new_draft(String::new()), "")
        },
        Vec::new(),
    ))
}

fn form_template_new(values: FormValues, errors: Vec<String>) -> FormTemplate {
    FormTemplate {
        heading: "新規記事 (下書き)",
        is_edit: false,
        action: "/posts".to_string(),
        slug_readonly: false,
        category_readonly: false,
        file_path: String::new(),
        revision: String::new(),
        errors,
        values,
        conflict: false,
    }
}

pub async fn create(State(state): State<AppState>, Form(form): Form<PostForm>) -> Response {
    let _guard = state.write_lock.lock().await;

    let base = FrontMatter::new_draft(form.published_on.clone());
    let front_matter = match form.to_front_matter(base) {
        Ok(front_matter) => front_matter,
        Err(errors) => {
            return render_template(form_template_new(form.values(), errors));
        }
    };

    match state.repo.create(&front_matter, &form.body) {
        Ok(_) => Redirect::to("/?flash=created").into_response(),
        Err(err) => render_template(form_template_new(
            form.values(),
            vec![err.display_message()],
        )),
    }
}

pub async fn edit_form(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    let Some(post) = state.repo.find(&slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let Some(front_matter) = post.front_matter.clone() else {
        return not_found(&format!(
            "frontmatter を解析できないため編集できません: {}",
            post.file_name
        ));
    };

    render_template(FormTemplate {
        heading: "記事を編集",
        is_edit: true,
        action: post.detail_path(),
        slug_readonly: post.status == Status::Published,
        category_readonly: post.status == Status::Published,
        file_path: post.path.display().to_string(),
        revision: post.revision.clone(),
        errors: Vec::new(),
        values: FormValues::from_front_matter(&front_matter, &post.body),
        conflict: false,
    })
}

pub async fn update(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    Form(form): Form<PostForm>,
) -> Response {
    save_article(&state, &slug, form, |saved_slug| {
        let target = state
            .repo
            .find(saved_slug)
            .map(|saved| saved.detail_path())
            .unwrap_or_else(|| "/".to_string());
        Redirect::to(&format!("{target}?flash=updated")).into_response()
    })
    .await
}

/// 編集フォームの内容を保存する共通処理 (`update` と「保存してメディアを追加」で使う)。
///
/// 保存に成功したら `on_success`(保存後の slug) のレスポンスを返す。
/// 失敗時 (入力エラー・楽観ロック衝突) はフォームの再描画を返す。
pub async fn save_article(
    state: &AppState,
    slug: &str,
    form: PostForm,
    on_success: impl Fn(&str) -> Response,
) -> Response {
    let _guard = state.write_lock.lock().await;

    let Some(post) = state.repo.find(slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let Some(current) = post.front_matter.clone() else {
        return not_found("frontmatter を解析できないため編集できません");
    };

    let front_matter = match form.to_front_matter(current.clone()) {
        Ok(front_matter) => front_matter,
        Err(errors) => {
            // 入力エラー時は **フォームが持ってきた revision を維持**する。
            // 最新の revision を返すと、再送信で他人の保存内容を上書きできてしまう。
            return render_template(form_template_error(post, form, errors, false));
        }
    };

    let updated = PostFile {
        front_matter: Some(front_matter),
        body: form.body.clone(),
        ..post.clone()
    };

    match state.repo.save(&updated, &form.expected_revision) {
        Ok(()) => {
            let saved_slug = updated.slug().unwrap_or(slug).to_string();
            on_success(&saved_slug)
        }
        Err(err) => {
            let conflict = matches!(err, RepoError::Conflict | RepoError::RevisionRequired);
            render_template(form_template_error(
                post,
                form,
                vec![err.display_message()],
                conflict,
            ))
        }
    }
}

/// 保存失敗時のフォーム再描画 (衝突時は revision を空にして再送信も拒否)。
fn form_template_error(
    post: PostFile,
    form: PostForm,
    errors: Vec<String>,
    conflict: bool,
) -> FormTemplate {
    FormTemplate {
        heading: "記事を編集",
        is_edit: true,
        action: post.detail_path(),
        slug_readonly: post.status == Status::Published,
        category_readonly: post.status == Status::Published,
        file_path: post.path.display().to_string(),
        // 衝突時は revision を空にして、再送信でも保存できないようにする
        revision: if conflict {
            String::new()
        } else {
            form.expected_revision.clone()
        },
        errors,
        values: form.values(),
        conflict,
    }
}

// ---------------------------------------------------------------------------
// 削除
// ---------------------------------------------------------------------------

#[derive(Template)]
#[template(path = "delete_confirm.html")]
struct DeleteTemplate {
    title: String,
    slug: String,
    status_label: &'static str,
    status_class: &'static str,
    file_path: String,
    action: String,
    revision: String,
    back_path: String,
}

pub async fn delete_confirm(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    let Some(post) = state.repo.find(&slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let detail_path = post.detail_path();

    render_template(DeleteTemplate {
        title: post.title().to_string(),
        slug: post.slug().unwrap_or_default().to_string(),
        status_label: post.status.label(),
        status_class: status_class(post.status),
        file_path: post.path.display().to_string(),
        action: format!("{detail_path}/delete"),
        revision: post.revision.clone(),
        back_path: detail_path,
    })
}

pub async fn delete(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    Form(form): Form<PostForm>,
) -> Response {
    let _guard = state.write_lock.lock().await;

    let Some(post) = state.repo.find(&slug) else {
        return not_found(&format!("slug: {slug}"));
    };

    match state.repo.delete(&post, &form.expected_revision) {
        Ok(trash_path) => {
            tracing::info!(path = %trash_path.display(), "moved article to trash");
            Redirect::to("/?flash=deleted").into_response()
        }
        Err(err) => (
            StatusCode::BAD_REQUEST,
            Html(format!(
                "<h1>削除できませんでした</h1><p>{}</p><p><a href=\"{}\">戻る</a></p>",
                html_escape(&err.to_string()),
                html_escape(&post.detail_path())
            )),
        )
            .into_response(),
    }
}

// ---------------------------------------------------------------------------
// 詳細ページのフラッシュ (?flash=updated を表示するため)
// ---------------------------------------------------------------------------

pub async fn detail_with_flash(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    query: axum::extract::Query<ListQuery>,
) -> Response {
    match state.repo.find(&slug) {
        Some(post) => render_detail(post, flash_message(&query.flash)),
        None => not_found(&format!("slug: {slug}")),
    }
}

fn html_escape(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

#[allow(dead_code)]
fn category_label(category: Category) -> &'static str {
    category.label()
}

#[allow(dead_code)]
fn empty_extra() -> BTreeMap<String, serde_yaml::Value> {
    BTreeMap::new()
}

#[allow(dead_code)]
fn content_type_html() -> ([(header::HeaderName, &'static str); 1], StatusCode) {
    (
        [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
        StatusCode::OK,
    )
}
