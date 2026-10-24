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
            gmb: Arc::new(blog_manager::gmb::EnvironmentGmb::default()),
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

#[tokio::test]
async fn publish_moves_draft_once_and_persists_progress() {
    let fixture = Fixture::new();
    fs::create_dir_all(fixture.content.join("drafts")).unwrap();
    let source = fixture.content.join("drafts/original-name.md");
    fs::write(&source, sample_article("note", "\n本文\n")).unwrap();
    let revision = blog_manager::repository::hash_revision(&fs::read_to_string(&source).unwrap());
    let app = fixture.app();
    let (status, html) = post_form(
        &app,
        "/posts/note/publish",
        &[("expected_revision", &revision)],
    )
    .await;
    assert_eq!(status, StatusCode::OK, "{html}");
    assert!(!source.exists());
    assert!(fixture.content.join("posts/original-name.md").exists());
    let record =
        blog_manager::publish::PublishRecord::load(&fixture.media.join("../publish"), "note")
            .unwrap()
            .unwrap();
    assert!(record.file_moved);
    assert!(record.media_promoted);
    let (status, _) = post_form(
        &app,
        "/posts/note/publish",
        &[("expected_revision", &revision)],
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    let second =
        blog_manager::publish::PublishRecord::load(&fixture.media.join("../publish"), "note")
            .unwrap()
            .unwrap();
    assert_eq!(record.operation_id, second.operation_id);
}
#[tokio::test]
async fn publish_requires_revision_and_does_not_move_invalid_input() {
    let fixture = Fixture::new();
    fs::create_dir_all(fixture.content.join("drafts")).unwrap();
    let path = fixture.content.join("drafts/note.md");
    fs::write(&path, sample_article("note", "body")).unwrap();
    let app = fixture.app();
    let (_, html) = post_form(&app, "/posts/note/publish", &[]).await;
    assert!(path.exists());
    assert!(html.contains("revision"), "{html}");
}

#[tokio::test]
async fn publish_rejects_corrupt_manifest_and_leaves_draft() {
    let fixture = Fixture::new();
    fs::create_dir_all(fixture.content.join("drafts")).unwrap();
    fs::create_dir_all(&fixture.media).unwrap();
    let source = fixture.content.join("drafts/note.md");
    let raw = sample_article("note", "body");
    fs::write(&source, &raw).unwrap();
    fs::write(fixture.media.join("note.json"), "broken").unwrap();
    let rev = blog_manager::repository::hash_revision(&raw);
    let (_, html) = post_form(
        &fixture.app(),
        "/posts/note/publish",
        &[("expected_revision", &rev)],
    )
    .await;
    assert!(
        source.exists(),
        "corrupt manifest must stop publication: {html}"
    );
}

struct TestGmb {
    calls: std::sync::atomic::AtomicUsize,
    fail: bool,
}
impl blog_manager::gmb::GmbPublisher for TestGmb {
    fn send(&self, post: gmb_event_poster::StandardPost) -> blog_manager::gmb::SendFuture<'_> {
        self.calls.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        assert_eq!(post.topic_type, "STANDARD");
        Box::pin(async move {
            if self.fail {
                Err("response lost".into())
            } else {
                Ok(serde_json::from_str(r#"{"name":"accounts/a/locations/b/localPosts/p","searchUrl":"https://example.com/post"}"#).unwrap())
            }
        })
    }
}
#[tokio::test]
async fn unknown_gmb_never_resends_without_explicit_confirmation() {
    let fixture = Fixture::new();
    let path = fixture.write_post("note", "本文");
    let mut state = fixture.state();
    let sender = Arc::new(TestGmb {
        calls: 0.into(),
        fail: true,
    });
    state.gmb = sender.clone();
    let rev = blog_manager::repository::hash_revision(&fs::read_to_string(path).unwrap());
    let options = blog_manager::publish::PublishOptions {
        gmb: true,
        deployed: true,
        ..Default::default()
    };
    let first = blog_manager::publish::run(&state, "note", &rev, options.clone())
        .await
        .unwrap();
    assert_eq!(first.gmb, blog_manager::publish::GmbStatus::Unknown);
    let second = blog_manager::publish::run(&state, "note", &rev, options.clone())
        .await
        .unwrap();
    assert!(second.error.is_some());
    assert_eq!(sender.calls.load(std::sync::atomic::Ordering::SeqCst), 1);
    let options = blog_manager::publish::PublishOptions {
        retry_unknown: true,
        ..options
    };
    blog_manager::publish::run(&state, "note", &rev, options)
        .await
        .unwrap();
    assert_eq!(sender.calls.load(std::sync::atomic::Ordering::SeqCst), 2);
}
#[tokio::test]
async fn concurrent_publish_submits_gmb_once() {
    let fixture = Fixture::new();
    let path = fixture.write_post("note", "本文");
    let mut state = fixture.state();
    let sender = Arc::new(TestGmb {
        calls: 0.into(),
        fail: false,
    });
    state.gmb = sender.clone();
    let rev = blog_manager::repository::hash_revision(&fs::read_to_string(path).unwrap());
    let options = blog_manager::publish::PublishOptions {
        gmb: true,
        deployed: true,
        ..Default::default()
    };
    let (a, b) = tokio::join!(
        blog_manager::publish::run(&state, "note", &rev, options.clone()),
        blog_manager::publish::run(&state, "note", &rev, options)
    );
    assert_eq!(a.unwrap().gmb, blog_manager::publish::GmbStatus::Done);
    assert_eq!(b.unwrap().gmb, blog_manager::publish::GmbStatus::Done);
    assert_eq!(sender.calls.load(std::sync::atomic::Ordering::SeqCst), 1);
}

fn local_git(root: &Path, args: &[&str]) -> String {
    let out = std::process::Command::new("git")
        .current_dir(root)
        .args(args)
        .output()
        .unwrap();
    assert!(
        out.status.success(),
        "git {args:?}: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    String::from_utf8_lossy(&out.stdout).trim().into()
}
fn init_git(f: &Fixture) {
    let root = f.content.parent().unwrap();
    local_git(root, &["init", "-b", "main"]);
    local_git(root, &["config", "user.email", "tests@example.invalid"]);
    local_git(root, &["config", "user.name", "Tests"]);
    local_git(root, &["add", "content"]);
    local_git(root, &["commit", "-m", "initial"]);
}
#[tokio::test]
async fn git_failure_retries_push_without_duplicate_commit() {
    let f = Fixture::new();
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    let path = f.content.join("drafts/note.md");
    let raw = sample_article("note", "本文");
    fs::write(&path, &raw).unwrap();
    init_git(&f);
    let root = f.content.parent().unwrap();
    let remote = root.join("remote.git");
    local_git(root, &["remote", "add", "origin", remote.to_str().unwrap()]);
    let state = f.state();
    let rev = blog_manager::repository::hash_revision(&raw);
    let options = blog_manager::publish::PublishOptions {
        git: true,
        ..Default::default()
    };
    let first = blog_manager::publish::run(&state, "note", &rev, options.clone())
        .await
        .unwrap();
    assert!(first.error.is_some());
    assert!(first.commit_id.is_some());
    assert!(!first.pushed);
    let commit = first.commit_id.clone().unwrap();
    assert_eq!(local_git(root, &["rev-parse", "HEAD"]), commit);
    let removed = std::process::Command::new("git")
        .current_dir(root)
        .args([
            "cat-file",
            "-e",
            &format!("{commit}:content/drafts/note.md"),
        ])
        .output()
        .unwrap();
    assert!(!removed.status.success());
    // Simulate a crash after git commit but before commit_id was persisted.
    let mut interrupted = first.clone();
    interrupted.commit_id = None;
    interrupted
        .save(&blog_manager::publish::state_dir(&state))
        .unwrap();
    local_git(root, &["init", "--bare", remote.to_str().unwrap()]);
    let second = blog_manager::publish::run(&state, "note", &rev, options)
        .await
        .unwrap();
    assert!(second.error.is_none(), "{:?}", second.error);
    assert!(second.pushed);
    assert_eq!(second.commit_id, first.commit_id);
    assert_eq!(local_git(root, &["rev-list", "--count", "HEAD"]), "2");
}
#[tokio::test]
async fn git_rejects_unrelated_staged_files_before_moving_draft() {
    let f = Fixture::new();
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    let path = f.content.join("drafts/note.md");
    let raw = sample_article("note", "本文");
    fs::write(&path, &raw).unwrap();
    init_git(&f);
    let root = f.content.parent().unwrap();
    fs::write(root.join("other.txt"), "unrelated").unwrap();
    local_git(root, &["add", "other.txt"]);
    let r = blog_manager::publish::run(
        &f.state(),
        "note",
        &blog_manager::repository::hash_revision(&raw),
        blog_manager::publish::PublishOptions {
            git: true,
            ..Default::default()
        },
    )
    .await
    .unwrap();
    assert!(r.error.is_some());
    assert!(path.exists());
    assert_eq!(
        local_git(root, &["diff", "--cached", "--name-only"]),
        "other.txt"
    );
}
#[tokio::test]
async fn publish_recovers_media_uploaded_before_article_rewrite() {
    let f = Fixture::new();
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    let source = f.content.join("drafts/note.md");
    let url = "https://rustfs.cdn.example.test/rustfs/blog/note/a.jpg";
    let raw = sample_article("note", &format!("![image]({url})"))
        .replace("https://example.com/a.jpg", url);
    fs::write(&source, &raw).unwrap();
    blog_manager::media::MediaManifest {
        slug: "note".into(),
        items: vec![blog_manager::media::MediaItem {
            key: "blog/note/a.jpg".into(),
            content_type: "image/jpeg".into(),
            width: 1,
            height: 1,
            alt: "".into(),
            created_at: "now".into(),
            promoted: true,
            promoted_at: Some("now".into()),
        }],
    }
    .save(&f.media)
    .unwrap();
    let record = blog_manager::publish::run(
        &f.state(),
        "note",
        &blog_manager::repository::hash_revision(&raw),
        Default::default(),
    )
    .await
    .unwrap();
    assert!(record.error.is_none(), "{:?}", record.error);
    let saved = fs::read_to_string(f.content.join("posts/note.md")).unwrap();
    assert!(!saved.contains("rustfs.cdn"));
    assert!(saved.contains("https://r2.cdn.example.test/r2/blog/note/a.jpg"));
}
#[tokio::test]
async fn published_edit_with_git_rejects_wrong_branch_without_saving() {
    let f = Fixture::new();
    let path = f.write_post("note", "original body");
    init_git(&f);
    let root = f.content.parent().unwrap();
    local_git(root, &["switch", "-c", "feature"]);
    let app = f.app();
    let (_, html) = get(&app, "/posts/note/edit").await;
    let rev = extract_hidden(&html, "expected_revision");
    let mut fields = update_fields("note", &rev, "changed body");
    fields.push(("git", "on".into()));
    let (_, html) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert!(html.contains("main"), "{html}");
    assert!(fs::read_to_string(path).unwrap().contains("original body"));
}
#[tokio::test]
async fn published_edit_and_delete_sync_only_the_article() {
    let f = Fixture::new();
    let path = f.write_post("note", "old body");
    init_git(&f);
    let root = f.content.parent().unwrap();
    let remote = root.join("remote.git");
    local_git(root, &["init", "--bare", remote.to_str().unwrap()]);
    local_git(root, &["remote", "add", "origin", remote.to_str().unwrap()]);
    local_git(root, &["push", "origin", "main"]);
    fs::write(root.join("unrelated.txt"), "leave me untracked").unwrap();
    let app = f.app();
    let (_, html) = get(&app, "/posts/note/edit").await;
    let rev = extract_hidden(&html, "expected_revision");
    let mut fields = update_fields("note", &rev, "new body");
    fields.push(("git", "on".into()));
    let (_, html) = post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert!(html.contains("git反映が完了"), "{html}");
    assert!(local_git(root, &["show", "HEAD:content/posts/note.md"]).contains("new body"));
    assert_eq!(
        local_git(root, &["show", "--format=", "--name-only", "HEAD"]),
        "content/posts/note.md"
    );
    let (_, html) = get(&app, "/posts/note/delete").await;
    let rev = extract_hidden(&html, "expected_revision");
    let (_, html) = post_form(
        &app,
        "/posts/note/delete",
        &[("expected_revision", &rev), ("git", "on")],
    )
    .await;
    assert!(html.contains("git反映が完了"), "{html}");
    assert!(!path.exists());
    assert!(local_git(root, &["ls-tree", "-r", "--name-only", "HEAD"]).is_empty());
    assert!(root.join("unrelated.txt").exists());
}

#[tokio::test]
async fn review_interrupted_hardlink_leaves_draft() {
    let f = Fixture::new();
    let state = f.state();
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    let raw = sample_article("note", "body");
    let source = f.content.join("drafts/note.md");
    fs::write(&source, &raw).unwrap();
    let rev = blog_manager::repository::hash_revision(&raw);
    let mut rec = blog_manager::publish::PublishRecord::new("note", "note.md", &rev);
    rec.media_promoted = true;
    rec.save(&blog_manager::publish::state_dir(&state)).unwrap();
    fs::hard_link(&source, f.content.join("posts/note.md")).unwrap();
    let result = blog_manager::publish::run(&state, "note", &rev, Default::default())
        .await
        .unwrap();
    assert!(result.error.is_none(), "{:?}", result.error);
    assert!(
        !source.exists(),
        "interrupted move reports success but leaves duplicate draft"
    );
}
#[tokio::test]
async fn review_edit_stages_same_basename_unrelated_draft() {
    let f = Fixture::new();
    f.write_post("note", "original");
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    let draft = f.content.join("drafts/note.md");
    fs::write(&draft, sample_article("other", "old draft")).unwrap();
    init_git(&f);
    let root = f.content.parent().unwrap();
    fs::write(&draft, sample_article("other", "new unrelated draft")).unwrap();
    let app = f.app();
    let (_, html) = get(&app, "/posts/note/edit").await;
    let rev = extract_hidden(&html, "expected_revision");
    let mut fields = update_fields("note", &rev, "changed");
    fields.push(("git", "on".into()));
    post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert_eq!(
        local_git(root, &["show", "--format=", "--name-only", "HEAD"]),
        "content/posts/note.md"
    );
}
#[tokio::test]
async fn review_same_content_recreated_article_gets_new_operation() {
    let f = Fixture::new();
    f.write_post("note", "original");
    let state = f.state();
    let post = state.repo.find("note").unwrap();
    let mut rec = blog_manager::publish::PublishRecord::new("note", "note.md", &post.revision);
    rec.file_moved = true;
    rec.gmb = blog_manager::publish::GmbStatus::Done;
    rec.save(&blog_manager::publish::state_dir(&state)).unwrap();
    state.repo.delete(&post, &post.revision).unwrap();
    fs::create_dir_all(f.content.join("drafts")).unwrap();
    fs::write(
        f.content.join("drafts/note.md"),
        sample_article("note", "original"),
    )
    .unwrap();
    let result = blog_manager::publish::run(&state, "note", &post.revision, Default::default())
        .await
        .unwrap();
    assert_ne!(
        result.operation_id, rec.operation_id,
        "recreated article reuses completed operation"
    );
}
#[tokio::test]
async fn review_get_must_not_mutate_active_gmb() {
    let f = Fixture::new();
    f.write_post("note", "body");
    let state = f.state();
    let post = state.repo.find("note").unwrap();
    let mut rec = blog_manager::publish::PublishRecord::new("note", "note.md", &post.revision);
    rec.gmb = blog_manager::publish::GmbStatus::InFlight;
    let dir = blog_manager::publish::state_dir(&state);
    rec.save(&dir).unwrap();
    let _guard = state.write_lock.lock().await;
    let app = router(state.clone(), PathBuf::from("static"));
    get(&app, "/posts/note/publish").await;
    let raw = fs::read_to_string(dir.join("note.json")).unwrap();
    let read: blog_manager::publish::PublishRecord = serde_json::from_str(&raw).unwrap();
    assert_eq!(
        read.gmb,
        blog_manager::publish::GmbStatus::InFlight,
        "GET modifies record while write lock is held"
    );
}

#[tokio::test]
async fn review_mutation_state_failure_prevents_article_change() {
    let f = Fixture::new();
    let path = f.write_post("note", "unchanged");
    init_git(&f);
    let state = f.state();
    let dir = blog_manager::publish::state_dir(&state);
    fs::create_dir_all(&dir).unwrap();
    fs::write(dir.join("changes"), "not a directory").unwrap();
    let app = router(
        state,
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static"),
    );
    let (_, html) = get(&app, "/posts/note/edit").await;
    let revision = extract_hidden(&html, "expected_revision");
    let mut fields = update_fields("note", &revision, "mutated");
    fields.push(("git", "on".into()));
    post_form(&app, "/posts/note", &as_refs(&fields)).await;
    assert!(fs::read_to_string(path).unwrap().contains("unchanged"));
}

#[tokio::test]
async fn pending_delete_intent_is_discoverable_and_resumes_after_restart() {
    let f = Fixture::new();
    let path = f.write_post("note", "original");
    init_git(&f);
    let state = f.state();
    let post = state.repo.find("note").unwrap();
    let mut record = blog_manager::publish::PublishRecord::new("note", "note.md", &post.revision);
    record.deleted = true;
    record
        .save(
            &blog_manager::publish::state_dir(&state)
                .join("changes")
                .join(&record.operation_id),
        )
        .unwrap();
    let app = router(
        state,
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static"),
    );
    let (_, html) = get(&app, "/").await;
    assert!(html.contains(&record.operation_id));
    let (_, html) = post_form(&app, &format!("/git/{}/note", record.operation_id), &[]).await;
    assert!(!path.exists(), "{html}");
    assert_eq!(fs::read_dir(&f.trash).unwrap().count(), 1);
    let before = local_git(f.content.parent().unwrap(), &["rev-parse", "HEAD"]);
    post_form(&app, &format!("/git/{}/note", record.operation_id), &[]).await;
    assert_eq!(
        local_git(f.content.parent().unwrap(), &["rev-parse", "HEAD"]),
        before
    );
    assert_eq!(fs::read_dir(&f.trash).unwrap().count(), 1);
}
#[tokio::test]
async fn pending_edit_intent_replays_only_when_input_revision_matches() {
    let f = Fixture::new();
    let path = f.write_post("note", "original");
    init_git(&f);
    let state = f.state();
    let post = state.repo.find("note").unwrap();
    let desired = sample_article("note", "recovered edit");
    let parsed = blog_manager::repository::parse(&desired).unwrap();
    let desired = blog_manager::repository::render(&parsed.front_matter, &parsed.body).unwrap();
    let mut record = blog_manager::publish::PublishRecord::new("note", "note.md", &post.revision);
    record.promoted_revision = blog_manager::repository::hash_revision(&desired);
    record.pending_contents = Some(desired);
    record
        .save(
            &blog_manager::publish::state_dir(&state)
                .join("changes")
                .join(&record.operation_id),
        )
        .unwrap();
    let app = router(
        state,
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("static"),
    );
    post_form(&app, &format!("/git/{}/note", record.operation_id), &[]).await;
    assert!(fs::read_to_string(path).unwrap().contains("recovered edit"));
}
