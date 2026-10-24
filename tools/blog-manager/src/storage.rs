//! S3 互換オブジェクトストレージへのクライアント。
//!
//! RustFS (下書き) と Cloudflare R2 (本番) の両方に、同一の SigV4 presigned URL 方式
//! (`rusty-s3`) でアクセスする。HTTP は reqwest (rustls) を使うため、openssl に依存しない。

use rusty_s3::actions::{DeleteObject, GetObject, PutObject};
use rusty_s3::{Bucket, Credentials, S3Action, UrlStyle};
use std::time::Duration;
use url::Url;

/// S3 互換バックエンド 1 つぶんのクライアント。
#[derive(Clone)]
pub struct StorageBackend {
    name: &'static str,
    bucket: Bucket,
    credentials: Credentials,
    region: String,
    /// 記事に書き込む URL のベース (例: `https://rustfs.mf.officeiko.co.jp/blog`)
    public_base: Url,
    client: reqwest::Client,
}

#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("{name}: PUT {key} が失敗しました: {status} {body}")]
    Put {
        name: &'static str,
        key: String,
        status: u16,
        body: String,
    },
    #[error("{name}: GET {key} が失敗しました: {status} {body}")]
    Get {
        name: &'static str,
        key: String,
        status: u16,
        body: String,
    },
    #[error("{name}: DELETE {key} が失敗しました: {status} {body}")]
    Delete {
        name: &'static str,
        key: String,
        status: u16,
        body: String,
    },
    #[error("HTTP リクエストに失敗しました: {0}")]
    Request(#[from] reqwest::Error),
    #[error("URL の解析に失敗しました: {0}")]
    Url(#[from] url::ParseError),
    #[error("バックエンドの構築に失敗しました: {0}")]
    Config(String),
}

/// `.env` から読み込むバックエンド設定。
#[derive(Debug, Clone)]
pub struct BackendConfig {
    pub name: &'static str,
    pub endpoint: String,
    pub bucket: String,
    pub access_key_id: String,
    pub secret_access_key: String,
    /// 未設定なら `auto`
    pub region: Option<String>,
    pub public_base: String,
}

impl StorageBackend {
    pub fn from_config(config: &BackendConfig) -> Result<Self, StorageError> {
        let endpoint = Url::parse(&config.endpoint)?;
        let region = config.region.clone().unwrap_or_else(|| "auto".to_string());
        let bucket = Bucket::new(
            endpoint,
            UrlStyle::Path,
            config.bucket.clone(),
            region.clone(),
        )
        .map_err(|err| StorageError::Config(format!("bucket: {err:?}")))?;
        let credentials = Credentials::new(
            config.access_key_id.clone(),
            config.secret_access_key.clone(),
        );

        Ok(Self {
            name: config.name,
            bucket,
            credentials,
            region,
            public_base: Url::parse(&config.public_base)?,
            client: reqwest::Client::new(),
        })
    }

    pub fn name(&self) -> &'static str {
        self.name
    }

    pub fn region(&self) -> &str {
        &self.region
    }

    /// 管理下オブジェクトの公開 URL。
    ///
    /// 記事には常にこの形式で書き込む (RustFS → R2 の昇格は URL 置換で行うため、
    /// ベース部分だけ差し替えられる形にしておく)。
    pub fn public_url(&self, key: &str) -> String {
        format!("{}/{key}", self.public_base.as_str().trim_end_matches('/'))
    }

    /// オブジェクトを PUT する。
    ///
    /// Content-Type は **署名対象に含めない** (SignedHeaders は host のみ)。
    /// rusty-s3 が `headers_mut` に Content-Type を入れると R2 の presigned PUT で
    /// `SignatureDoesNotMatch` になる (R2 は signed headers を小文字で検証するが、
    /// rusty-s3 は入力された名前をそのまま使うため)。Content-Type は署名外の
    /// ヘッダとして送ってもよい。
    pub async fn put(
        &self,
        key: &str,
        body: Vec<u8>,
        content_type: &str,
    ) -> Result<(), StorageError> {
        let action = PutObject::new(&self.bucket, Some(&self.credentials), key);
        let url = action.sign(SIGN_DURATION);

        let response = self
            .client
            .put(url)
            .header("Content-Type", content_type)
            .body(body)
            .send()
            .await?;

        let status = response.status();
        if status.is_success() {
            Ok(())
        } else {
            let body = response.text().await.unwrap_or_default();
            Err(StorageError::Put {
                name: self.name,
                key: key.to_string(),
                status: status.as_u16(),
                body: truncate_error_body(&body),
            })
        }
    }

    /// オブジェクトを GET する。
    pub async fn get(&self, key: &str) -> Result<(Vec<u8>, String), StorageError> {
        let action = GetObject::new(&self.bucket, Some(&self.credentials), key);
        let url = action.sign(SIGN_DURATION);

        let response = self.client.get(url).send().await?;

        let status = response.status();
        let content_type = response
            .headers()
            .get(reqwest::header::CONTENT_TYPE)
            .and_then(|value| value.to_str().ok())
            .unwrap_or("application/octet-stream")
            .to_string();

        if status.is_success() {
            let body = response.bytes().await?;
            Ok((body.to_vec(), content_type))
        } else {
            let body = response.text().await.unwrap_or_default();
            Err(StorageError::Get {
                name: self.name,
                key: key.to_string(),
                status: status.as_u16(),
                body: truncate_error_body(&body),
            })
        }
    }

    /// オブジェクトを DELETE する。
    ///
    /// v1 では UI から呼ばない (誤削除防止)。昇格後の RustFS 側も削除しない方針。
    #[allow(dead_code)]
    pub async fn delete(&self, key: &str) -> Result<(), StorageError> {
        let action = DeleteObject::new(&self.bucket, Some(&self.credentials), key);
        let url = action.sign(SIGN_DURATION);

        let response = self.client.delete(url).send().await?;

        let status = response.status();
        if status.is_success() {
            Ok(())
        } else {
            let body = response.text().await.unwrap_or_default();
            Err(StorageError::Delete {
                name: self.name,
                key: key.to_string(),
                status: status.as_u16(),
                body: truncate_error_body(&body),
            })
        }
    }
}

const SIGN_DURATION: Duration = Duration::from_secs(60 * 10);

fn truncate_error_body(body: &str) -> String {
    const MAX: usize = 1000;
    if body.len() <= MAX {
        body.to_string()
    } else {
        format!("{}…", &body[..MAX])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config() -> BackendConfig {
        BackendConfig {
            name: "test",
            endpoint: "https://example.test".to_string(),
            bucket: "bucket".to_string(),
            access_key_id: "AKID".to_string(),
            secret_access_key: "SECRET".to_string(),
            region: Some("auto".to_string()),
            public_base: "https://cdn.example.test/bucket".to_string(),
        }
    }

    #[test]
    fn public_url_joins_base_and_key() {
        let backend = StorageBackend::from_config(&config()).unwrap();
        assert_eq!(
            backend.public_url("blog/slug/img.jpg"),
            "https://cdn.example.test/bucket/blog/slug/img.jpg"
        );
    }

    #[test]
    fn public_url_trims_trailing_slash_in_base() {
        let mut cfg = config();
        cfg.public_base = "https://cdn.example.test/bucket/".to_string();
        let backend = StorageBackend::from_config(&cfg).unwrap();
        assert_eq!(
            backend.public_url("k.jpg"),
            "https://cdn.example.test/bucket/k.jpg"
        );
    }
}
