use crate::handlers;
use crate::handlers::AppState;
use crate::handlers_media;
use crate::media::MAX_UPLOAD_BYTES;
use axum::extract::DefaultBodyLimit;
use axum::routing::{get, post};
use axum::Router;
use std::path::PathBuf;
use tower_http::services::ServeDir;
use tower_http::trace::TraceLayer;

/// カバー画像つきフォームを受け入れるルートに適用するボディ上限。
///
/// axum 既定の 2MB だとカバー画像 (最大 10MB) が読み取れないため、
/// `validate_upload` の上限と揃える。
fn upload_body_limit() -> DefaultBodyLimit {
    DefaultBodyLimit::max(MAX_UPLOAD_BYTES)
}

/// ルーターを組み立てる (テストからも同じ構成を使う)。
pub fn router(state: AppState, static_dir: PathBuf) -> Router {
    Router::new()
        .route(
            "/git/{id}/{slug}",
            get(crate::handlers_publish::inspect_git).post(crate::handlers_publish::retry_git),
        )
        .route("/", get(handlers::list))
        .route(
            "/posts/{slug}/publish",
            get(crate::handlers_publish::form).post(crate::handlers_publish::publish),
        )
        .route("/posts/{slug}/gmb", post(crate::handlers_publish::gmb))
        .route("/posts/new", get(handlers::new_form))
        .route("/posts", post(handlers::create).layer(upload_body_limit()))
        .route("/posts/{slug}", get(handlers::detail_with_flash))
        .route(
            "/posts/{slug}",
            post(handlers::update).layer(upload_body_limit()),
        )
        .route("/posts/{slug}/edit", get(handlers::edit_form))
        .route("/posts/{slug}/delete", get(handlers::delete_confirm))
        .route("/posts/{slug}/delete", post(handlers::delete))
        // 解析できなかった記事は slug を持たないため、状態 + ファイル名で開く
        .route("/files/{status}/{file_name}", get(handlers::file_detail))
        .route("/posts/{slug}/media/new", get(handlers_media::upload_form))
        .route(
            "/posts/{slug}/media/new",
            post(handlers_media::save_and_open_upload).layer(upload_body_limit()),
        )
        .route(
            "/media/{slug}",
            post(handlers_media::upload).layer(upload_body_limit()),
        )
        .route("/media-preview/{*key}", get(handlers_media::media_preview))
        .nest_service("/static", ServeDir::new(static_dir))
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}
