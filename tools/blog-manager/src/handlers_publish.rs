use crate::{
    handlers::AppState,
    publish::{self, PublishOptions, PublishRecord},
};
use askama::Template;
use axum::{
    extract::{Path, State},
    response::{Html, IntoResponse, Response},
    Form,
};
use serde::Deserialize;
#[derive(Default, Deserialize)]
pub struct PublishForm {
    #[serde(default)]
    pub expected_revision: String,
    #[serde(default)]
    pub git: Option<String>,
    #[serde(default)]
    pub gmb: Option<String>,
    #[serde(default)]
    pub deployed: Option<String>,
    #[serde(default)]
    pub retry_unknown: Option<String>,
}
#[derive(Template)]
#[template(path = "publish.html")]
struct PublishTemplate {
    slug: String,
    revision: String,
    record: Option<PublishRecord>,
    error: String,
}
pub async fn form(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    let Some(post) = state.repo.find(&slug) else {
        return (axum::http::StatusCode::NOT_FOUND, "記事が見つかりません").into_response();
    };
    let record = publish::PublishRecord::load(&publish::state_dir(&state), &slug);
    let (record, error) = match record {
        Ok(r) => (r, String::new()),
        Err(e) => (None, e),
    };
    render(PublishTemplate {
        slug,
        revision: post.revision,
        record,
        error,
    })
}
pub async fn publish(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    Form(form): Form<PublishForm>,
) -> Response {
    execute(state, slug, form, false).await
}
pub async fn gmb(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    Form(form): Form<PublishForm>,
) -> Response {
    execute(state, slug, form, true).await
}
async fn execute(state: AppState, slug: String, form: PublishForm, gmb_only: bool) -> Response {
    if gmb_only
        && state
            .repo
            .find(&slug)
            .is_none_or(|p| p.status != crate::repository::Status::Published)
    {
        return (
            axum::http::StatusCode::BAD_REQUEST,
            "公開済みの記事からGMB投稿してください",
        )
            .into_response();
    }
    let options = PublishOptions {
        git: !gmb_only && form.git.is_some(),
        gmb: gmb_only || form.gmb.is_some(),
        retry_unknown: form.retry_unknown.is_some(),
        deployed: form.deployed.is_some(),
    };
    let result = publish::run(&state, &slug, &form.expected_revision, options).await;
    let (record, error) = match result {
        Ok(r) => {
            let error = r.error.clone().unwrap_or_default();
            (Some(r), error)
        }
        Err(e) => (None, e),
    };
    let revision = state
        .repo
        .find(&slug)
        .map(|p| p.revision)
        .unwrap_or_default();
    render(PublishTemplate {
        slug,
        revision,
        record,
        error,
    })
}
fn render(template: PublishTemplate) -> Response {
    match template.render() {
        Ok(html) => Html(html).into_response(),
        Err(_) => (
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            "結果の表示に失敗しました",
        )
            .into_response(),
    }
}

#[derive(Template)]
#[template(path = "git_result.html")]
struct GitTemplate {
    record: PublishRecord,
}
pub(crate) fn git_result(record: PublishRecord) -> Response {
    match (GitTemplate { record }).render() {
        Ok(html) => Html(html).into_response(),
        Err(_) => (
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            "結果表示に失敗しました",
        )
            .into_response(),
    }
}
pub async fn retry_git(
    State(state): State<AppState>,
    Path((id, slug)): Path<(String, String)>,
) -> Response {
    let _guard = state.write_lock.lock().await;
    match publish::retry_change(&state, &slug, &id).await {
        Ok(r) => git_result(r),
        Err(e) => (axum::http::StatusCode::BAD_REQUEST, e).into_response(),
    }
}

pub async fn inspect_git(
    State(state): State<AppState>,
    Path((id, slug)): Path<(String, String)>,
) -> Response {
    match publish::inspect_change(&state, &slug, &id) {
        Ok(r) => git_result(r),
        Err(e) => (axum::http::StatusCode::BAD_REQUEST, e).into_response(),
    }
}
