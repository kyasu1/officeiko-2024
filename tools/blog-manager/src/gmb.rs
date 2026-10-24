//! GBP adapter. No network activity until the user requests a post.
use crate::model::FrontMatter;
use gmb_event_poster::{GmbClient, ServiceAccountConfig, StandardPost, StandardPostBuilder};
use std::{future::Future, pin::Pin};
pub type SendFuture<'a> =
    Pin<Box<dyn Future<Output = Result<gmb_event_poster::ApiResponse, String>> + Send + 'a>>;
pub trait GmbPublisher: Send + Sync {
    fn send(&self, post: StandardPost) -> SendFuture<'_>;
}
#[derive(Default)]
pub struct EnvironmentGmb {
    client: tokio::sync::Mutex<Option<GmbClient>>,
}
impl GmbPublisher for EnvironmentGmb {
    fn send(&self, post: StandardPost) -> SendFuture<'_> {
        Box::pin(async move {
            let mut client = self.client.lock().await;
            if client.is_none() {
                let config = ServiceAccountConfig::from_env()
                    .map_err(|_| "GMB の設定を確認してください".to_string())?;
                *client = Some(
                    GmbClient::new(config)
                        .await
                        .map_err(|_| "GMB 認証に失敗しました".to_string())?,
                );
            }
            // Do not reflect token request bodies, JWTs or private keys into HTML.
            client
                .as_ref()
                .unwrap()
                .create_standard_post(post)
                .await
                .map_err(|e| {
                    format!(
                        "GMB送信に失敗しました (HTTP {:?})。結果を確認してください",
                        e.status_code
                    )
                })
        })
    }
}
pub fn build_post(fm: &FrontMatter, body: &str) -> Result<StandardPost, String> {
    let mut plain = String::new();
    for event in pulldown_cmark::Parser::new(body) {
        match event {
            pulldown_cmark::Event::Text(text) | pulldown_cmark::Event::Code(text) => {
                plain.push_str(&text);
                plain.push(' ');
            }
            pulldown_cmark::Event::SoftBreak | pulldown_cmark::Event::HardBreak => plain.push(' '),
            _ => {}
        }
    }
    let summary = plain
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
        .chars()
        .take(1500)
        .collect::<String>();
    StandardPostBuilder::new()
        .summary(summary)
        .url(format!("https://officeiko.co.jp{}", fm.url_path()))
        .image_url(&fm.cover_image.url)
        .build()
        .map_err(|e| e.to_string())
}
