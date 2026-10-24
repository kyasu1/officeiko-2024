use blog_manager::app::router;
use blog_manager::handlers::AppState;
use blog_manager::repository::Repository;
use blog_manager::storage::{BackendConfig, StorageBackend};
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::path::PathBuf;
use std::sync::Arc;

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

    let trash_dir = match std::env::var("TRASH_DIR") {
        Ok(value) if !value.trim().is_empty() => PathBuf::from(value),
        _ => PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(".trash"),
    };

    let media_dir = match std::env::var("MEDIA_DIR") {
        Ok(value) if !value.trim().is_empty() => PathBuf::from(value),
        _ => PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("state/media"),
    };

    let repo = Repository::new(&content_dir, &trash_dir);
    tracing::info!(
        content_dir = %content_dir.display(),
        trash_dir = %trash_dir.display(),
        "starting blog-manager"
    );

    let rustfs = match build_backend("RUSTFS", "RustFS") {
        Ok(backend) => backend,
        Err(err) => {
            tracing::error!("{err}");
            std::process::exit(1);
        }
    };
    let r2 = match build_backend("R2", "R2") {
        Ok(backend) => backend,
        Err(err) => {
            tracing::error!("{err}");
            std::process::exit(1);
        }
    };

    let state = AppState {
        repo: Arc::new(repo),
        write_lock: Arc::new(tokio::sync::Mutex::new(())),
        media_dir,
        rustfs,
        r2,
        gmb: Arc::new(blog_manager::gmb::EnvironmentGmb::default()),
    };

    let static_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static");

    let app = router(state, static_dir);

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

fn env_value(key: &str) -> Option<String> {
    std::env::var(key).ok().and_then(|value| {
        let trimmed = value.trim().to_string();
        (!trimmed.is_empty()).then_some(trimmed)
    })
}

fn build_backend(prefix: &str, name: &'static str) -> Result<StorageBackend, String> {
    let config = BackendConfig {
        name,
        endpoint: env_value(&format!("{prefix}_ENDPOINT"))
            .ok_or_else(|| format!("{prefix}_ENDPOINT が設定されていません"))?,
        bucket: env_value(&format!("{prefix}_BUCKET"))
            .ok_or_else(|| format!("{prefix}_BUCKET が設定されていません"))?,
        access_key_id: env_value(&format!("{prefix}_ACCESS_KEY_ID"))
            .ok_or_else(|| format!("{prefix}_ACCESS_KEY_ID が設定されていません"))?,
        secret_access_key: env_value(&format!("{prefix}_SECRET_ACCESS_KEY"))
            .ok_or_else(|| format!("{prefix}_SECRET_ACCESS_KEY が設定されていません"))?,
        region: env_value(&format!("{prefix}_REGION")),
        public_base: env_value(&format!("{prefix}_PUBLIC_BASE"))
            .ok_or_else(|| format!("{prefix}_PUBLIC_BASE が設定されていません"))?,
    };

    StorageBackend::from_config(&config).map_err(|err| format!("{name} の設定が不正です: {err}"))
}

/// `tools/blog-manager/` からリポジトリ直下の `content/` を既定値にする。
fn default_content_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../content")
}
