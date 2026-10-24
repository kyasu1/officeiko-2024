//! カバー画像アップロード (2026-10-24 設計) の回帰テスト。
//!
//! - 下書きはカバーなしで作成・保存・再編集できる
//! - 公開にはカバー画像が必要
//! - multipart で送った画像は RustFS に置かれ、寸法を自動で読み取る
//! - アップロード失敗時は既存カバーと本文を維持する
//! - axum 既定の 2MB 上限でカバー画像が切り捨てられない
//!
//! ストレージは 127.0.0.1 の偽 S3 (メモリ保存) で検証する (ネットワーク不要)。

use axum::body::Body;
use axum::extract::{Path, State};
use axum::http::{Request, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::any;
use blog_manager::app::router;
use blog_manager::handlers::AppState;
use blog_manager::repository::Repository;
use blog_manager::storage::{BackendConfig, StorageBackend};
use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tower::ServiceExt;

type Store = Arc<Mutex<BTreeMap<String, (Vec<u8>, String)>>>;

async fn fake_handler(
    Path((_bucket, key)): Path<(String, String)>,
    State(store): State<Store>,
    req: Request<Body>,
) -> Response {
    if req.method() == axum::http::Method::PUT {
        let content_type = req
            .headers()
            .get(axum::http::header::CONTENT_TYPE)
            .and_then(|v| v.to_str().ok())
            .unwrap_or("application/octet-stream")
            .to_string();
        let bytes = axum::body::to_bytes(req.into_body(), 64 * 1024 * 1024)
            .await
            .unwrap();
        store
            .lock()
            .unwrap()
            .insert(key, (bytes.to_vec(), content_type));
        return StatusCode::OK.into_response();
    }
    match store.lock().unwrap().get(&key) {
        Some((bytes, content_type)) => Response::builder()
            .status(StatusCode::OK)
            .header(axum::http::header::CONTENT_TYPE, content_type.clone())
            .body(Body::from(bytes.clone()))
            .unwrap(),
        None => StatusCode::NOT_FOUND.into_response(),
    }
}

/// メモリで PUT/GET する偽 S3 を起動し、base URL を返す。
async fn fake_storage(name: &'static str) -> (StorageBackend, Store) {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let store: Store = Arc::new(Mutex::new(BTreeMap::new()));

    let app = axum::Router::new()
        .route("/{bucket}/{*key}", any(fake_handler))
        .with_state(store.clone());

    tokio::spawn(async move {
        let _ = axum::serve(listener, app).await;
    });

    let config = BackendConfig {
        name,
        endpoint: format!("http://{addr}"),
        bucket: name.to_string(),
        access_key_id: "AKID".to_string(),
        secret_access_key: "SECRET".to_string(),
        region: None,
        public_base: format!("http://{addr}/{name}"),
    };
    (
        StorageBackend::from_config(&config).expect("fake backend"),
        store,
    )
}

struct Fixture {
    _tmp: tempfile::TempDir,
    content: PathBuf,
    trash: PathBuf,
    media: PathBuf,
}

impl Fixture {
    fn new() -> Self {
        let tmp = tempfile::tempdir().unwrap();
        let content = tmp.path().join("content");
        let trash = tmp.path().join(".trash");
        let media = tmp.path().join("media");
        fs::create_dir_all(content.join("posts")).unwrap();
        fs::create_dir_all(content.join("drafts")).unwrap();
        Self {
            _tmp: tmp,
            content,
            trash,
            media,
        }
    }

    fn write_post(&self, slug: &str, cover_url: &str) -> PathBuf {
        let path = self.content.join("posts").join(format!("{slug}.md"));
        fs::write(
            &path,
            format!(
                "---\ntitle: タイトル {slug}\nslug: {slug}\npublishedOn: 2026-01-01\ncategory: blog\ncoverImage:\n  url: {cover_url}\n  width: 10\n  height: 10\n  alternativeText: 旧カバー\n---\n本文です\n"
            ),
        )
        .unwrap();
        path
    }

    fn draft_path(&self, slug: &str) -> PathBuf {
        self.content.join("drafts").join(format!("{slug}.md"))
    }

    async fn state(&self) -> AppState {
        self.state_parts().await.0
    }
    /// 偽ストレージの中身も返す (アップロード・昇格が実際に届いたか検証するため)。
    async fn state_parts(&self) -> (AppState, Store, Store) {
        let (rustfs, rustfs_store) = fake_storage("rustfs").await;
        let (r2, r2_store) = fake_storage("r2").await;
        (
            AppState {
                repo: Arc::new(Repository::new(&self.content, &self.trash)),
                write_lock: Arc::new(tokio::sync::Mutex::new(())),
                media_dir: self.media.clone(),
                rustfs,
                r2,
                gmb: Arc::new(blog_manager::gmb::EnvironmentGmb::default()),
            },
            rustfs_store,
            r2_store,
        )
    }

    /// ストレージへ届かない (DNS が引けない) バックエンド。
    fn unreachable_state(&self) -> AppState {
        let backend = |name: &'static str| {
            let config = BackendConfig {
                name,
                endpoint: format!("https://{name}.does-not-exist.invalid"),
                bucket: name.to_string(),
                access_key_id: "AKID".to_string(),
                secret_access_key: "SECRET".to_string(),
                region: None,
                public_base: format!("https://{name}.does-not-exist.invalid/{name}"),
            };
            StorageBackend::from_config(&config).expect("backend")
        };
        AppState {
            repo: Arc::new(Repository::new(&self.content, &self.trash)),
            write_lock: Arc::new(tokio::sync::Mutex::new(())),
            media_dir: self.media.clone(),
            rustfs: backend("rustfs"),
            r2: backend("r2"),
            gmb: Arc::new(blog_manager::gmb::EnvironmentGmb::default()),
        }
    }

    fn app_with(&self, state: AppState) -> axum::Router {
        router(
            state,
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static"),
        )
    }
}

fn png_bytes(width: u32, height: u32) -> Vec<u8> {
    let img = image::ImageBuffer::from_fn(width, height, |x, y| {
        image::Rgba([(x * 10) as u8, (y * 10) as u8, 128, 255])
    });
    let mut out = Vec::new();
    img.write_to(&mut std::io::Cursor::new(&mut out), image::ImageFormat::Png)
        .unwrap();
    out
}

fn multipart_body(fields: &[(&str, &str)], file: Option<(&str, &str, &[u8])>) -> Vec<u8> {
    const BOUNDARY: &str = "----officeikoTestBoundary";
    let mut body = Vec::new();
    for (key, value) in fields {
        body.extend_from_slice(
            format!(
                "--{BOUNDARY}\r\nContent-Disposition: form-data; name=\"{key}\"\r\n\r\n{value}\r\n"
            )
            .as_bytes(),
        );
    }
    if let Some((name, file_name, bytes)) = file {
        body.extend_from_slice(
            format!("--{BOUNDARY}\r\nContent-Disposition: form-data; name=\"{name}\"; filename=\"{file_name}\"\r\nContent-Type: image/png\r\n\r\n")
                .as_bytes(),
        );
        body.extend_from_slice(bytes);
        body.extend_from_slice(b"\r\n");
    }
    body.extend_from_slice(format!("--{BOUNDARY}--\r\n").as_bytes());
    body
}

async fn send(
    app: &axum::Router,
    uri: &str,
    content_type: &str,
    body: Vec<u8>,
) -> (StatusCode, String) {
    let response = app
        .clone()
        .oneshot(
            Request::post(uri)
                .header("content-type", content_type)
                .body(Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();
    let status = response.status();
    let body = axum::body::to_bytes(response.into_body(), 64 * 1024 * 1024)
        .await
        .unwrap();
    (status, String::from_utf8_lossy(&body).to_string())
}

async fn post_multipart(app: &axum::Router, uri: &str, body: Vec<u8>) -> (StatusCode, String) {
    send(
        app,
        uri,
        "multipart/form-data; boundary=----officeikoTestBoundary",
        body,
    )
    .await
}

async fn post_form(app: &axum::Router, uri: &str, fields: &[(&str, &str)]) -> (StatusCode, String) {
    let body = fields
        .iter()
        .map(|(k, v)| format!("{k}={}", percent_encode(v)))
        .collect::<Vec<_>>()
        .join("&");
    send(
        app,
        uri,
        "application/x-www-form-urlencoded",
        body.into_bytes(),
    )
    .await
}

async fn get(app: &axum::Router, uri: &str) -> (StatusCode, String) {
    let response = app
        .clone()
        .oneshot(Request::get(uri).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let body = axum::body::to_bytes(response.into_body(), 64 * 1024 * 1024)
        .await
        .unwrap();
    (status, String::from_utf8_lossy(&body).to_string())
}

fn percent_encode(value: &str) -> String {
    let mut out = String::new();
    for byte in value.as_bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(*byte as char)
            }
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

fn form_fields(
    slug: &str,
    revision: &str,
    cover: (&str, &str, &str, &str),
) -> Vec<(&'static str, String)> {
    vec![
        ("expected_revision", revision.to_string()),
        ("title", "カバーなし記事".to_string()),
        ("slug", slug.to_string()),
        ("category", "blog".to_string()),
        ("published_on", "2026-01-01".to_string()),
        ("cover_url", cover.0.to_string()),
        ("cover_width", cover.1.to_string()),
        ("cover_height", cover.2.to_string()),
        ("cover_alt", cover.3.to_string()),
        ("tags", String::new()),
        ("body", "本文です".to_string()),
    ]
}

fn extract_hidden(html: &str, name: &str) -> String {
    let needle = format!("name=\"{name}\" value=\"");
    let start = html
        .find(&needle)
        .unwrap_or_else(|| panic!("{name} not found in {html}"));
    let rest = &html[start + needle.len()..];
    rest[..rest.find('"').unwrap()].to_string()
}

/// カバーなしで下書きを作成 → 索引・編集フォーム・保存とも通る。
#[tokio::test]
async fn draft_can_be_created_without_a_cover() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields("no-cover", "", ("", "", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let (status, _) = post_form(&app, "/posts", &refs).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    let raw = fs::read_to_string(fixture.draft_path("no-cover")).unwrap();
    assert!(!raw.contains("coverImage"), "仮の値で埋めない: {raw}");
    assert!(raw.contains("title: カバーなし記事"));

    // 編集フォームは「カバーなし」を表示 (壊れてはいない)
    let (status, html) = get(&app, "/posts/no-cover/edit").await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("カバー画像は設定されていません"), "{html}");
    assert!(html.contains("name=\"cover_file\""), "画像入力がある");

    // 索引上もエラー扱い (要修正) ではない
    let (status, html) = get(&app, "/").await;
    assert_eq!(status, StatusCode::OK);
    assert!(
        !html.contains("要修正"),
        "カバーなしを下書きでエラーにしない: {html}"
    );
}

/// 再編集 (カバー欄を空のまま保存) でもカバーなしが維持される。
#[tokio::test]
async fn draft_without_cover_survives_a_re_edit() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields("re-edit", "", ("", "", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    post_form(&app, "/posts", &refs).await;

    let (_status, html) = get(&app, "/posts/re-edit/edit").await;
    let revision = extract_hidden(&html, "expected_revision");
    let fields = form_fields("re-edit", &revision, ("", "", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let (status, _) = post_form(&app, "/posts/re-edit", &refs).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    let raw = fs::read_to_string(fixture.draft_path("re-edit")).unwrap();
    assert!(!raw.contains("coverImage"), "{raw}");
}

/// 公開はカバー画像を要求し、下書きはそのまま残る。
#[tokio::test]
async fn publish_requires_a_cover_image() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields("needs-cover", "", ("", "", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    post_form(&app, "/posts", &refs).await;

    let (_status, html) = get(&app, "/posts/needs-cover/edit").await;
    let revision = extract_hidden(&html, "expected_revision");

    let (status, html) = post_form(
        &app,
        "/posts/needs-cover/publish",
        &[("expected_revision", revision.as_str())],
    )
    .await;
    assert_eq!(status, StatusCode::OK, "公開エラー画面: {html}");
    assert!(html.contains("カバー画像"), "公開時にカバーを要求: {html}");

    assert!(
        fixture.draft_path("needs-cover").exists(),
        "下書きはそのまま"
    );
    assert!(
        !fixture
            .content
            .join("posts")
            .join("needs-cover.md")
            .exists(),
        "公開されない"
    );
}

/// multipart で送ったカバーは RustFS に置かれ、寸法を自動で読み取る。
#[tokio::test]
async fn multipart_create_uploads_cover_and_reads_dimensions() {
    let fixture = Fixture::new();
    let (state, rustfs_store, _r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state);

    let image = png_bytes(4, 3);
    let fields = form_fields("with-cover", "", ("", "", "", "指輪の写真"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();

    let body = multipart_body(&parts, Some(("cover_file", "指輪 写真.png", &image)));
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "作成できる: {html}");

    let raw = fs::read_to_string(fixture.draft_path("with-cover")).unwrap();
    assert!(raw.contains("coverImage"), "カバーが入る: {raw}");
    assert!(raw.contains("width: 4"), "寸法は画像から: {raw}");
    assert!(raw.contains("height: 3"), "寸法は画像から: {raw}");
    assert!(raw.contains("alternativeText: 指輪の写真"), "{raw}");
    // 下書きは RustFS URL (ダミーの絶対 URL を書かない)
    let url = raw
        .lines()
        .find(|line| line.trim().starts_with("url:"))
        .unwrap()
        .trim()
        .to_string();
    assert!(url.contains("http://127.0.0.1"), "RustFS URL: {url}");

    // manifest に登録され、公開時の昇格対象になる
    let manifest = fs::read_to_string(fixture.media.join("with-cover.json")).unwrap();
    assert!(manifest.contains("\"promoted\": false"), "{manifest}");

    // 偽 RustFS に実体が届いている
    let stored = rustfs_store.lock().unwrap();
    let keys: Vec<&String> = stored.keys().collect();
    assert_eq!(keys.len(), 1, "RustFS に 1 オブジェクト: {keys:?}");
    assert!(keys[0].starts_with("blog/with-cover/"), "{keys:?}");
    assert_eq!(stored[keys[0]].0.len(), image.len(), "バイト数が一致");
}

/// 公開済み記事のカバー差し替えは R2 まで昇格し、RustFS URL を書かない。
#[tokio::test]
async fn published_cover_replacement_promotes_to_r2() {
    let fixture = Fixture::new();
    fixture.write_post("published-one", "https://image.officeiko.work/old.jpg");
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let (_status, html) = get(&app, "/posts/published-one/edit").await;
    let revision = extract_hidden(&html, "expected_revision");

    let image = png_bytes(8, 5);
    let fields = form_fields("published-one", &revision, ("", "", "", "新しいカバー"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "new.png", &image)));
    let (status, html) = post_multipart(&app, "/posts/published-one", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "保存できる: {html}");

    let raw = fs::read_to_string(fixture.content.join("posts").join("published-one.md")).unwrap();
    assert!(raw.contains("width: 8"), "{raw}");
    assert!(
        !raw.contains("rustfs"),
        "公開済み記事に RustFS URL を書かない: {raw}"
    );
}

/// アップロード失敗時は既存カバーと本文をそのまま維持する。
#[tokio::test]
async fn cover_upload_failure_keeps_existing_cover_and_body() {
    let fixture = Fixture::new();
    let path = fixture.write_post("keep-cover", "https://image.officeiko.work/old.jpg");
    let before = fs::read_to_string(&path).unwrap();

    let state = fixture.unreachable_state();
    let app = fixture.app_with(state);

    let (_status, html) = get(&app, "/posts/keep-cover/edit").await;
    let revision = extract_hidden(&html, "expected_revision");

    let image = png_bytes(6, 6);
    let fields = form_fields("keep-cover", &revision, ("", "", "", "差し替えたい"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "broken.png", &image)));
    let (status, html) = post_multipart(&app, "/posts/keep-cover", body).await;

    assert_eq!(status, StatusCode::OK, "エラーをフォームで返す");
    assert!(html.contains("カバー画像の保存に失敗しました"), "{html}");

    let after = fs::read_to_string(&path).unwrap();
    assert_eq!(before, after, "既存カバーと本文はそのまま");
}

/// 不正な画像は保存されず、frontmatter も変わらない。
#[tokio::test]
async fn invalid_cover_image_is_rejected_without_touching_the_article() {
    let fixture = Fixture::new();
    let path = fixture.write_post("bad-image", "https://image.officeiko.work/old.jpg");
    let before = fs::read_to_string(&path).unwrap();

    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let (_status, html) = get(&app, "/posts/bad-image/edit").await;
    let revision = extract_hidden(&html, "expected_revision");

    let fields = form_fields("bad-image", &revision, ("", "", "", ""));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(
        &parts,
        Some(("cover_file", "not-an-image.png", b"plain text")),
    );
    let (status, html) = post_multipart(&app, "/posts/bad-image", body).await;

    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("カバー画像が不正です"), "{html}");
    assert_eq!(fs::read_to_string(&path).unwrap(), before);
}

/// 公開時に下書きカバー (RustFS) が R2 へ昇格し、記事には R2 URL だけが残る。
#[tokio::test]
async fn publish_promotes_a_draft_cover_to_r2() {
    let fixture = Fixture::new();
    let (state, _rustfs_store, r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state.clone());

    let image = png_bytes(6, 4);
    let fields = form_fields("promote-me", "", ("", "", "", "カバー"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "cover.png", &image)));
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let draft = fs::read_to_string(fixture.draft_path("promote-me")).unwrap();
    assert!(
        draft.contains("http://127.0.0.1"),
        "下書きは RustFS URL: {draft}"
    );

    let revision = state.repo.find("promote-me").unwrap().revision.clone();
    let record = blog_manager::publish::run(
        &state,
        "promote-me",
        &revision,
        blog_manager::publish::PublishOptions {
            git: false,
            gmb: false,
            retry_unknown: false,
            deployed: false,
        },
    )
    .await
    .expect("公開できる");
    assert!(record.file_moved, "posts へ移動");

    let published =
        fs::read_to_string(fixture.content.join("posts").join("promote-me.md")).unwrap();
    assert!(published.contains("width: 6"), "{published}");
    let cover_line = published
        .lines()
        .find(|line| line.trim().starts_with("url:"))
        .unwrap()
        .trim()
        .to_string();
    assert!(
        cover_line.contains("/r2/blog/promote-me/"),
        "R2 URL へ差し替え: {cover_line}"
    );

    let r2_keys: Vec<String> = r2_store.lock().unwrap().keys().cloned().collect();
    assert_eq!(r2_keys.len(), 1, "R2 へ 1 オブジェクト昇格: {r2_keys:?}");
    assert!(
        r2_keys[0].starts_with("blog/promote-me/"),
        "R2 の key は記事スラッグ下: {r2_keys:?}"
    );
    assert!(r2_keys[0].ends_with(".png"), "{r2_keys:?}");
}

/// axum 既定の 2MB 上限で切り捨てられていない (3MB は「不正な画像」で止まる)。
#[tokio::test]
async fn body_limit_allows_covers_larger_than_two_megabytes() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields("big-cover", "", ("", "", "", ""));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let big = vec![0u8; 3 * 1024 * 1024];
    let body = multipart_body(&parts, Some(("cover_file", "big.png", &big)));
    let (_status, html) = post_multipart(&app, "/posts", body).await;

    assert!(
        html.contains("カバー画像が不正です"),
        "ボディ上限ではなく画像検証で止まる: {html}"
    );
    assert!(
        !fixture.draft_path("big-cover").exists(),
        "不正な画像で作成しない"
    );
}

/// URL だけを入力した既存の動き (手動設定) は multipart でも壊れない。
#[tokio::test]
async fn manual_cover_url_still_works_through_multipart() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields(
        "manual-url",
        "",
        ("https://example.com/manual.jpg", "1200", "630", "手動"),
    );
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, None);
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let raw = fs::read_to_string(fixture.draft_path("manual-url")).unwrap();
    assert!(raw.contains("url: https://example.com/manual.jpg"), "{raw}");
    assert!(raw.contains("width: 1200"), "{raw}");
}

/// URL がないのに幅だけ入力した場合は取り消し忘れを指摘する (入力を黙って捨てない)。
#[tokio::test]
async fn cover_dimensions_without_url_are_rejected() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields("half-cover", "", ("", "1200", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let (status, html) = post_form(&app, "/posts", &refs).await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("URL を入力してください"), "{html}");
    assert!(!fixture.draft_path("half-cover").exists());
}

// ---------------------------------------------------------------------------
// codex 指摘 (b86ccd7 レビュー) の境界テスト
// ---------------------------------------------------------------------------

/// ノイズ画像の PNG。圧縮されないためサイズを予測できる (上限テスト用)。
fn noisy_png(side: u32) -> Vec<u8> {
    let mut seed: u64 = 0x2545_F491_4F6C_DD1D;
    let mut next = move || {
        seed = seed
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        (seed >> 33) as u8
    };
    let raw: Vec<u8> = (0..side * side * 3).map(|_| next()).collect();
    let img = image::RgbImage::from_raw(side, side, raw).expect("noise buffer");
    let mut out = Vec::new();
    img.write_to(&mut std::io::Cursor::new(&mut out), image::ImageFormat::Png)
        .unwrap();
    out
}

/// 10MB ちょうどの PNG (ファイル単体の上限を超える)。
fn oversized_png() -> Vec<u8> {
    let bytes = noisy_png(2000);
    assert!(
        bytes.len() > 10 * 1024 * 1024,
        "テスト画像が上限を超えていない: {}",
        bytes.len()
    );
    bytes
}

/// 上限すれすれ (< 10MB) の PNG。他のフォーム項目と合わせてもリクエストを通す必要がある。
fn near_limit_png() -> Vec<u8> {
    let limit = 10 * 1024 * 1024usize;
    let mut side = 1700u32;
    loop {
        let bytes = noisy_png(side);
        if bytes.len() >= limit {
            assert!(side > 200, "画像が大きすぎます: {}", bytes.len());
            side -= 50;
            continue;
        }
        if bytes.len() + 512 * 1024 < limit {
            side += 50;
            continue;
        }
        assert!(
            bytes.len() > 2 * 1024 * 1024,
            "テスト画像が小さすぎます (2MB 上限の検証にならない): {}",
            bytes.len()
        );
        return bytes;
    }
}

/// 上限すれすれのカバーは、他のフォーム項目と同時に送っても切り捨てられない。
/// (リクエスト全体の上限 = ファイル単体の上限 + 余裕)
#[tokio::test]
async fn near_limit_cover_survives_the_whole_multipart_request() {
    let fixture = Fixture::new();
    let (state, rustfs_store, _r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state);

    let image = near_limit_png();
    // 記事本文もフォーム項目なので、リクエスト全体はファイル単体の上限を超える。
    let mut fields = form_fields("near-limit", "", ("", "", "", "上限すれすれ"));
    let long_body = "あ".repeat(300_000); // UTF-8 で約 900KB
    for field in fields.iter_mut() {
        if field.0 == "body" {
            field.1 = long_body.clone();
        }
    }
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "near-limit.png", &image)));
    assert!(
        image.len() > 9 * 1024 * 1024,
        "上限すれすれでない: {}",
        image.len()
    );
    assert!(
        body.len() > 10 * 1024 * 1024,
        "リクエスト全体がファイル上限を超えていない (file {} / body {})",
        image.len(),
        body.len()
    );

    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let stored = rustfs_store.lock().unwrap();
    assert_eq!(
        stored.len(),
        1,
        "RustFS へ 1 オブジェクト: {:?}",
        stored.keys()
    );
    let (bytes, _) = stored.values().next().unwrap();
    assert_eq!(bytes.len(), image.len(), "ボディ上限で切り捨てられていない");

    let draft = fs::read_to_string(fixture.draft_path("near-limit")).unwrap();
    assert!(draft.contains("alternativeText: 上限すれすれ"), "{draft}");
    assert!(draft.ends_with(&long_body), "本文も切り捨てられていない");
}

/// ファイル単体の 10MB 検証は維持される (リクエスト上限を引き上げても緩めない)。
#[tokio::test]
async fn cover_over_the_file_limit_is_rejected_as_too_large() {
    let fixture = Fixture::new();
    let (state, rustfs_store, _r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state);

    let image = oversized_png();
    let fields = form_fields("over-limit", "", ("", "", "", ""));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "over.png", &image)));

    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::OK, "エラー画面を再表示: {html}");
    assert!(html.contains("ファイルサイズが上限"), "{html}");
    assert!(
        !fixture.draft_path("over-limit").exists(),
        "上限超過で作成しない"
    );
    assert!(
        rustfs_store.lock().unwrap().is_empty(),
        "上限超過の画像はストレージへ置かない"
    );
}

/// 下書きカバー (非公開 RustFS) は /media-preview 中継で表示し、
/// 記事へ書き込む URL そのものは <img src> にしない。
#[tokio::test]
async fn draft_cover_preview_goes_through_the_media_relay() {
    let fixture = Fixture::new();
    let (state, _rustfs_store, _r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state);

    let image = png_bytes(8, 5);
    let fields = form_fields("preview-me", "", ("", "", "", "プレビュー"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "cover.png", &image)));
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let draft = fs::read_to_string(fixture.draft_path("preview-me")).unwrap();
    let stored_url = draft
        .lines()
        .find(|line| line.trim().starts_with("url:"))
        .unwrap()
        .trim()
        .trim_start_matches("url:")
        .trim()
        .to_string();
    assert!(
        stored_url.contains("/rustfs/blog/preview-me/"),
        "下書きは RustFS URL: {stored_url}"
    );

    for uri in ["/posts/preview-me", "/posts/preview-me/edit"] {
        let (status, html) = get(&app, uri).await;
        assert_eq!(status, StatusCode::OK, "{uri}");
        assert!(
            html.contains("src=\"/media-preview/blog/preview-me/"),
            "{uri} は中継 URL で表示: {html}"
        );
        assert!(
            !html.contains(&format!("src=\"{stored_url}\"")),
            "{uri} は非公開 URL を直接表示しない: {html}"
        );
    }

    // URL 欄には記事へ書き込む URL がそのまま残る (表示用と保存用を分ける)
    let (_status, html) = get(&app, "/posts/preview-me/edit").await;
    assert!(
        html.contains(&format!("value=\"{stored_url}\"")),
        "URL 欄は保存される URL: {html}"
    );

    // 中継は実際に画像を返す (カバーの key で 404 にならない)
    let key = stored_url
        .split("/rustfs/")
        .nth(1)
        .unwrap_or_else(|| panic!("key を抽出できない: {stored_url}"));
    let (status, served) = get(&app, &format!("/media-preview/{key}")).await;
    assert_eq!(status, StatusCode::OK, "中継がカバーを返す");
    assert!(!served.is_empty(), "中継が画像を返す");
}

/// 公開済み (R2 など外部公開済み) のカバーは従来どおり URL を直接表示する。
#[tokio::test]
async fn published_cover_preview_is_used_directly() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let public_url = "https://image.officeiko.work/blog/old-cover.jpg";
    fixture.write_post("old-cover", public_url);

    let (status, html) = get(&app, "/posts/old-cover/edit").await;
    assert_eq!(status, StatusCode::OK);
    assert!(
        html.contains(&format!("src=\"{public_url}\"")),
        "公開済み URL はそのまま表示: {html}"
    );
    assert!(!html.contains("/media-preview/"), "{html}");
}

/// カバーなしの公開は、メディア昇格・記事移動・state 記録より前に止まる。
#[tokio::test]
async fn publish_without_cover_stops_before_any_side_effect() {
    let fixture = Fixture::new();
    let (state, rustfs_store, r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state.clone());

    let fields = form_fields("no-side-effect", "", ("", "", "", ""));
    let refs: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let (status, _) = post_form(&app, "/posts", &refs).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    let revision = state.repo.find("no-side-effect").unwrap().revision.clone();
    let result = blog_manager::publish::run(
        &state,
        "no-side-effect",
        &revision,
        blog_manager::publish::PublishOptions {
            git: false,
            gmb: false,
            retry_unknown: false,
            deployed: false,
        },
    )
    .await;
    assert!(result.is_err(), "カバーなしは公開できない");
    let message = result.err().unwrap();
    assert!(message.contains("カバー画像"), "{message}");

    assert!(rustfs_store.lock().unwrap().is_empty(), "昇格なし");
    assert!(r2_store.lock().unwrap().is_empty(), "R2 への PUT なし");
    let publish_dir = fixture.media.join("../publish");
    if publish_dir.exists() {
        assert!(
            fs::read_dir(&publish_dir).unwrap().next().is_none(),
            "公開 state を残さない"
        );
    }
    assert!(
        fixture.draft_path("no-side-effect").exists(),
        "下書きはそのまま"
    );
}

/// 新規作成の途中でアップロードが失敗しても、同一 slug は残らない (再試行できる)。
#[tokio::test]
async fn failed_cover_upload_on_create_leaves_the_slug_free_for_retry() {
    let fixture = Fixture::new();
    let (state, rustfs_store, _r2_store) = fixture.state_parts().await;
    let app = fixture.app_with(state);

    let fields = form_fields("retry-me", "", ("", "", "", "指輪"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let broken = b"not-an-image".to_vec();
    let body = multipart_body(&parts, Some(("cover_file", "broken.png", &broken)));
    let (status, html) = post_multipart(&app, "/posts", body).await;

    assert_eq!(status, StatusCode::OK, "フォームを再表示: {html}");
    assert!(html.contains("カバー画像が不正です"), "{html}");
    assert!(
        html.contains("value=\"retry-me\""),
        "入力した slug を維持して再試行できる: {html}"
    );
    assert!(
        html.contains("value=\"指輪\""),
        "alt 入力も維持される: {html}"
    );
    assert!(
        !fixture.draft_path("retry-me").exists(),
        "失敗時に下書きを残さない"
    );
    assert!(
        rustfs_store.lock().unwrap().is_empty(),
        "不正画像を置かない"
    );

    // 同じ slug で再試行できる (取り残された下書きと衝突しない)
    let image = png_bytes(7, 2);
    let fields = form_fields("retry-me", "", ("", "", "", "指輪"));
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, Some(("cover_file", "cover.png", &image)));
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "再試行で作成できる: {html}");

    let draft = fs::read_to_string(fixture.draft_path("retry-me")).unwrap();
    assert!(draft.contains("width: 7"), "{draft}");
}

/// 画像を選ばず URL だけでカバーを設定した記事を、編集 (multipart・ファイルなし)
/// しても URL と寸法がそのまま残る。
#[tokio::test]
async fn manual_cover_url_survives_an_edit_without_a_file() {
    let fixture = Fixture::new();
    let state = fixture.state().await;
    let app = fixture.app_with(state);

    let fields = form_fields(
        "manual-edit",
        "",
        (
            "https://image.officeiko.work/blog/existing.jpg",
            "1200",
            "630",
            "既存画像",
        ),
    );
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, None);
    let (status, html) = post_multipart(&app, "/posts", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let (_status, html) = get(&app, "/posts/manual-edit/edit").await;
    let revision = extract_hidden(&html, "expected_revision");
    assert!(
        html.contains("src=\"https://image.officeiko.work/blog/existing.jpg\""),
        "公開済み URL はそのまま表示: {html}"
    );

    let fields = form_fields(
        "manual-edit",
        &revision,
        (
            "https://image.officeiko.work/blog/existing.jpg",
            "1200",
            "630",
            "既存画像",
        ),
    );
    let parts: Vec<(&str, &str)> = fields.iter().map(|(k, v)| (*k, v.as_str())).collect();
    let body = multipart_body(&parts, None);
    let (status, html) = post_multipart(&app, "/posts/manual-edit", body).await;
    assert_eq!(status, StatusCode::SEE_OTHER, "{html}");

    let raw = fs::read_to_string(fixture.draft_path("manual-edit")).unwrap();
    assert!(
        raw.contains("url: https://image.officeiko.work/blog/existing.jpg"),
        "{raw}"
    );
    assert!(raw.contains("width: 1200"), "{raw}");
    assert!(raw.contains("height: 630"), "{raw}");
}
