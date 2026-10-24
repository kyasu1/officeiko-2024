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
