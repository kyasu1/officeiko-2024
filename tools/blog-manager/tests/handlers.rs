//! ハンドラ経由の回帰テスト (codex M3 レビュー指摘)。
//!
//! - 楽観ロック衝突のあと、再送信しても上書きできないこと
//! - タグの未知キーがハンドラ経由の保存でも保持されること
//! - 予約 slug が作成できないこと

use axum::body::Body;
use axum::http::{Request, StatusCode};
use blog_manager::app::router;
use blog_manager::handlers::AppState;
use blog_manager::repository::Repository;
use blog_manager::storage::{BackendConfig, StorageBackend};
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tower::ServiceExt;

fn sample_article(slug: &str, body: &str) -> String {
    format!(
        "---\ntitle: タイトル {slug}\nslug: {slug}\npublishedOn: 2026-01-01\ncategory: blog\ntags:\n  - id: 42\n    attributes:\n      name: 買取\n      slug: trade-in\n      customNested: keep-me\ncoverImage:\n  url: https://example.com/a.jpg\n  width: 10\n  height: 10\n  alternativeText: null\n---\n{body}"
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
        Self {
            content,
            trash,
            media,
            _tmp: tmp,
        }
    }

    fn write_post(&self, slug: &str, body: &str) -> PathBuf {
        let path = self.content.join("posts").join(format!("{slug}.md"));
        fs::write(&path, sample_article(slug, body)).unwrap();
        path
    }

    fn state(&self) -> AppState {
        AppState {
            repo: Arc::new(Repository::new(&self.content, &self.trash)),
            write_lock: Arc::new(tokio::sync::Mutex::new(())),
            media_dir: self.media.clone(),
            rustfs: test_backend("rustfs"),
            r2: test_backend("r2"),
        }
    }

    fn app(&self) -> axum::Router {
        router(
            self.state(),
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static"),
        )
    }
}

async fn get(app: &axum::Router, uri: &str) -> (StatusCode, String) {
    let response = app
        .clone()
        .oneshot(Request::get(uri).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let body = axum::body::to_bytes(response.into_body(), 1024 * 1024)
        .await
        .unwrap();
    (status, String::from_utf8_lossy(&body).to_string())
}

async fn post_form(app: &axum::Router, uri: &str, fields: &[(&str, &str)]) -> (StatusCode, String) {
    let body = fields
        .iter()
        .map(|(key, value)| format!("{}={}", key, urlencoding(value)))
        .collect::<Vec<_>>()
        .join("&");

    let response = app
        .clone()
        .oneshot(
            Request::post(uri)
                .header("content-type", "application/x-www-form-urlencoded")
                .body(Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();
    let status = response.status();
    let body = axum::body::to_bytes(response.into_body(), 1024 * 1024)
        .await
        .unwrap();
    (status, String::from_utf8_lossy(&body).to_string())
}

fn test_backend(name: &'static str) -> StorageBackend {
    let config = BackendConfig {
        name,
        endpoint: format!("https://{name}.example.test"),
        bucket: name.to_string(),
        access_key_id: "AKID".to_string(),
        secret_access_key: "SECRET".to_string(),
        region: None,
        public_base: format!("https://{name}.cdn.example.test/{name}"),
    };
    StorageBackend::from_config(&config).expect("test backend")
}

fn urlencoding(value: &str) -> String {
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

fn extract_hidden(html: &str, name: &str) -> String {
    let needle = format!("name=\"{name}\" value=\"");
    let start = html
        .find(&needle)
        .unwrap_or_else(|| panic!("{name} not found"));
    let rest = &html[start + needle.len()..];
    rest[..rest.find('"').unwrap()].to_string()
}

fn update_fields(slug: &str, revision: &str, body: &str) -> Vec<(&'static str, String)> {
    vec![
        ("title", format!("タイトル {slug}")),
        ("slug", slug.to_string()),
        ("category", "blog".to_string()),
        ("published_on", "2026-01-01".to_string()),
        ("author", "小松原 康行".to_string()),
        ("cover_url", "https://example.com/a.jpg".to_string()),
        ("cover_width", "10".to_string()),
        ("cover_height", "10".to_string()),
        ("cover_alt", String::new()),
        ("tags", "買取,trade-in".to_string()),
        ("body", body.to_string()),
        ("expected_revision", revision.to_string()),
    ]
}

fn as_refs<'a>(fields: &'a [(&'static str, String)]) -> Vec<(&'a str, &'a str)> {
    fields
        .iter()
        .map(|(key, value)| (*key, value.as_str()))
        .collect()
}

/// 衝突を返したフォームで再送信しても、他人の保存内容を上書きできないこと。
#[tokio::test]
async fn conflict_resubmit_is_rejected() {
    let fixture = Fixture::new();
    let path = fixture.write_post("note", "\n最初の本文\n");
    let app = fixture.app();

    // A さんが編集フォームを開く
    let (status, html) = get(&app, "/posts/note/edit").await;
    assert_eq!(status, StatusCode::OK);
    let stale_revision = extract_hidden(&html, "expected_revision");

    // B さんが先に保存する (ファイルを直接更新)
    fs::write(&path, sample_article("note", "\nBさんの本文\n")).unwrap();

    // A さんの保存は衝突になる
    let fields = update_fields("note", &stale_revision, "\nAさんの本文\n");
    let (status, html) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("他の編集が先に保存されました"), "{html}");

    // 再描画された hidden は空 (最新 revision を配らない)
    let retry_revision = extract_hidden(&html, "expected_revision");
    assert!(
        retry_revision.is_empty(),
        "revision should be blank: {retry_revision:?}"
    );

    // そのまま再送信しても保存されない
    let fields = update_fields("note", &retry_revision, "\nAさんの本文\n");
    let (status, html) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("revision"), "{html}");

    let saved = fs::read_to_string(&path).unwrap();
    assert!(saved.contains("Bさんの本文"), "B さんの内容が残る: {saved}");
    assert!(
        !saved.contains("Aさんの本文"),
        "A さんの内容で上書きされない"
    );
}

/// hidden を消しただけの POST では保存できないこと。
#[tokio::test]
async fn update_requires_revision() {
    let fixture = Fixture::new();
    let path = fixture.write_post("note", "\n元の本文\n");
    let app = fixture.app();

    let fields = update_fields("note", "", "\n書き換え\n");
    let (status, html) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("revision"), "{html}");
    assert!(fs::read_to_string(&path).unwrap().contains("元の本文"));
}

/// タグの未知キーがハンドラ経由の保存でも失われないこと。
#[tokio::test]
async fn update_preserves_unknown_tag_keys() {
    let fixture = Fixture::new();
    let path = fixture.write_post("note", "\n元の本文\n");
    let app = fixture.app();

    let (_, html) = get(&app, "/posts/note/edit").await;
    let revision = extract_hidden(&html, "expected_revision");

    // 表示名だけ変更して保存
    let mut fields = update_fields("note", &revision, "\n本文だけ変更\n");
    fields[9] = ("tags", "買取館,trade-in".to_string());
    let (status, _) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    let saved = fs::read_to_string(&path).unwrap();
    assert!(saved.contains("id: 42"), "タグ直下の未知キー: {saved}");
    assert!(
        saved.contains("customNested: keep-me"),
        "attributes 内の未知キー: {saved}"
    );
    assert!(
        saved.contains("name: 買取館"),
        "表示名は更新される: {saved}"
    );
    assert!(saved.contains("本文だけ変更"));
}

/// 予約 slug (`new`) は作成できないこと。
#[tokio::test]
async fn reserved_slug_is_rejected() {
    let fixture = Fixture::new();
    let app = fixture.app();

    let fields = vec![
        ("title", "予約 slug".to_string()),
        ("slug", "new".to_string()),
        ("category", "blog".to_string()),
        ("published_on", "2026-01-01".to_string()),
        ("author", String::new()),
        ("cover_url", "https://example.com/a.jpg".to_string()),
        ("cover_width", "10".to_string()),
        ("cover_height", "10".to_string()),
        ("cover_alt", String::new()),
        ("tags", String::new()),
        ("body", "本文".to_string()),
        ("expected_revision", String::new()),
    ];
    let (status, html) = post_form(&app, "/posts", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("予約"), "{html}");
    assert!(!fixture.content.join("drafts/new.md").exists());
}

/// 削除は同一秒に同名ファイルを繰り返しても退避内容を失わないこと。
#[tokio::test]
async fn repeated_delete_keeps_every_trashed_file() {
    let fixture = Fixture::new();
    let app = fixture.app();

    let path = fixture.write_post("note", "\n1回目\n");
    let (_, html) = get(&app, "/posts/note/delete").await;
    let revision = extract_hidden(&html, "expected_revision");
    let fields = vec![("expected_revision", revision)];
    let (status, _) = post_form(&app, "/posts/note/delete", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    fs::write(&path, sample_article("note", "\n2回目\n")).unwrap();
    let (_, html) = get(&app, "/posts/note/delete").await;
    let revision = extract_hidden(&html, "expected_revision");
    let fields = vec![("expected_revision", revision)];
    let (status, _) = post_form(&app, "/posts/note/delete", &as_refs(&fields)).await;
    assert_eq!(status, StatusCode::SEE_OTHER);

    let trashed: Vec<PathBuf> = fs::read_dir(&fixture.trash)
        .unwrap()
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .collect();
    assert_eq!(trashed.len(), 2, "退避ファイルが2件: {trashed:?}");

    let contents: Vec<String> = trashed
        .iter()
        .map(|path| fs::read_to_string(path).unwrap())
        .collect();
    assert!(contents.iter().any(|c| c.contains("1回目")), "{contents:?}");
    assert!(contents.iter().any(|c| c.contains("2回目")), "{contents:?}");
}

#[allow(dead_code)]
fn assert_exists(path: &Path) {
    assert!(path.exists(), "{}", path.display());
}

// ---------------------------------------------------------------------------
// M4: メディア
// ---------------------------------------------------------------------------

/// `GET /media-preview/{*key}` は管理下 key の形式だけを受け付ける。
#[tokio::test]
async fn media_preview_rejects_unsafe_keys() {
    let fixture = Fixture::new();
    let app = fixture.app();

    for uri in [
        "/media-preview/etc/passwd",
        "/media-preview/blog/../secret",
        "/media-preview/blog/..%2F..%2Fetc",
        "/media-preview/blog//double",
    ] {
        let (status, _) = get(&app, uri).await;
        assert!(
            status == StatusCode::BAD_REQUEST || status == StatusCode::NOT_FOUND,
            "{uri}: 拒否されること (actual {status})"
        );
    }

    // 形式が正しくても実体が取れなければ 404 (テストバックエンドには無い)
    let (status, body) = get(&app, "/media-preview/blog/s/valid-key.jpg").await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert!(body.contains("メディアを取得できません"), "{body}");
}

/// アップロード画面・アップロード先は slug が存在しないと 404。
#[tokio::test]
async fn media_routes_404_for_unknown_slug() {
    let fixture = Fixture::new();
    let app = fixture.app();

    let (status, _) = get(&app, "/posts/unknown/media/new").await;
    assert_eq!(status, StatusCode::NOT_FOUND);

    let (status, _) = get(&app, "/posts/unknown/edit").await;
    assert_eq!(status, StatusCode::NOT_FOUND);
}

/// 編集フォームの formaction (`POST /posts/{slug}/media/new`) は保存して
/// アップロード画面への 303 を返すこと。
#[tokio::test]
async fn save_and_open_upload_redirects_after_save() {
    let fixture = Fixture::new();
    fixture.write_post("note", "\n本文\n");
    let app = fixture.app();

    let (_, html) = get(&app, "/posts/note/edit").await;
    let revision = extract_hidden(&html, "expected_revision");
    let fields = update_fields("note", &revision, "\n保存してからメディア追加\n");
    let (status, _) = post_form(&app, "/posts/note/media/new", &as_refs(&fields)).await;

    assert_eq!(status, StatusCode::SEE_OTHER);
    let saved = fs::read_to_string(fixture.content.join("posts/note.md")).unwrap();
    assert!(saved.contains("保存してからメディア追加"), "{saved}");
    assert!(
        saved.contains("id: 42"),
        "タグの未知キーも保存される: {saved}"
    );
}

/// アップロード画面は slug と manifest を表示する。
#[tokio::test]
async fn upload_form_lists_managed_media() {
    let fixture = Fixture::new();
    fixture.write_post("note", "\n本文\n");
    let app = fixture.app();

    let (status, html) = get(&app, "/posts/note/media/new").await;
    assert_eq!(status, StatusCode::OK);
    assert!(html.contains("メディアをアップロード"), "{html}");
    assert!(html.contains("enctype=\"multipart/form-data\""), "{html}");
    assert!(html.contains("まだありません"), "manifest が空のときの表示");
    // note は posts/ にある = 公開済みなので「保存時に R2 へ昇格」が表示される
    assert!(
        html.contains("保存時に R2 へ昇格"),
        "公開済み記事の文言: {html}"
    );
}
