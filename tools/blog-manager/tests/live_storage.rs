//! 実ストレージ (RustFS / R2) との疎通テスト。
//!
//! `.env` に RUSTFS_* / R2_* が設定されていない環境では自動的にスキップされる。
//! 実行: `cargo test --test live_storage -- --ignored` (CI では実行しない)。

use blog_manager::storage::{BackendConfig, StorageBackend};

fn env_value(key: &str) -> Option<String> {
    std::env::var(key).ok().and_then(|v| {
        let t = v.trim().to_string();
        (!t.is_empty()).then_some(t)
    })
}

fn load_env() {
    // cargo test は .env を読まないため、ここで明示的に読み込む
    let _ = dotenvy::dotenv();
}

fn backend(prefix: &str, name: &'static str) -> Option<StorageBackend> {
    let config = BackendConfig {
        name,
        endpoint: env_value(&format!("{prefix}_ENDPOINT"))?,
        bucket: env_value(&format!("{prefix}_BUCKET"))?,
        access_key_id: env_value(&format!("{prefix}_ACCESS_KEY_ID"))?,
        secret_access_key: env_value(&format!("{prefix}_SECRET_ACCESS_KEY"))?,
        region: env_value(&format!("{prefix}_REGION")),
        public_base: env_value(&format!("{prefix}_PUBLIC_BASE"))?,
    };
    StorageBackend::from_config(&config).ok()
}

#[tokio::test]
#[ignore = "live test: requires RUSTFS_* credentials"]
async fn rustfs_put_get_roundtrip() {
    load_env();
    let Some(storage) = backend("RUSTFS", "RustFS") else {
        eprintln!("skipping: RUSTFS_* not configured");
        return;
    };

    let key = format!(
        "blog-manager-live-test/{}.txt",
        uuid::Uuid::new_v4().simple()
    );
    let body = format!("rustfs probe at {}", chrono::Utc::now().to_rfc3339());

    storage
        .put(&key, body.clone().into_bytes(), "text/plain")
        .await
        .expect("PUT to RustFS");
    let (fetched, content_type) = storage.get(&key).await.expect("GET from RustFS");
    assert_eq!(fetched, body.as_bytes());
    assert!(content_type.starts_with("text/plain"), "{content_type}");

    storage.delete(&key).await.expect("DELETE on RustFS");
}

#[tokio::test]
#[ignore = "live test: requires R2_* credentials"]
async fn r2_put_get_delete_roundtrip() {
    load_env();
    let Some(storage) = backend("R2", "R2") else {
        eprintln!("skipping: R2_* not configured");
        return;
    };

    let key = format!(
        "blog-manager-live-test/{}.txt",
        uuid::Uuid::new_v4().simple()
    );
    let body = format!("r2 probe at {}", chrono::Utc::now().to_rfc3339());

    storage
        .put(&key, body.clone().into_bytes(), "text/plain")
        .await
        .expect("PUT to R2");
    let (fetched, _) = storage.get(&key).await.expect("GET from R2");
    assert_eq!(fetched, body.as_bytes());

    storage.delete(&key).await.expect("DELETE on R2");
}
