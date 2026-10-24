use axum::routing::get;
use axum::Router;
use blog_manager::handlers::{self, AppState};
use blog_manager::repository::Repository;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::path::PathBuf;
use std::sync::Arc;
use tower_http::services::ServeDir;
use tower_http::trace::TraceLayer;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "blog_manager=info,tower_http=warn".into()),
        )
        .init();

    let content_dir = match std::env::var("CONTENT_DIR") {
        Ok(value) if !value.trim().is_empty() => PathBuf::from(value),
        _ => default_content_dir(),
    };
    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|value| value.parse().ok())
        .unwrap_or(3001);

    let repo = Repository::new(&content_dir);
    tracing::info!(content_dir = %content_dir.display(), "starting blog-manager");

    let state = AppState {
        repo: Arc::new(repo),
    };

    let static_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static");

    let app = Router::new()
        .route("/", get(handlers::list))
        .route("/posts/{slug}", get(handlers::detail))
        .nest_service("/static", ServeDir::new(static_dir))
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    let addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), port);
    let listener = match tokio::net::TcpListener::bind(addr).await {
        Ok(listener) => listener,
        Err(err) => {
            tracing::error!("failed to bind {addr}: {err}");
            std::process::exit(1);
        }
    };

    // 認証を持たないツールのため、必ずループバックにのみ公開する。
    tracing::info!("listening on http://{addr}");

    if let Err(err) = axum::serve(listener, app).await {
        tracing::error!("server error: {err}");
        std::process::exit(1);
    }
}

/// `tools/blog-manager/` からリポジトリ直下の `content/` を既定値にする。
fn default_content_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../content")
}
