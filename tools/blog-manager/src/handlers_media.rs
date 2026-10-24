//! メディアのアップロードとプレビュー中継 (M4)。

use crate::handlers::{self, AppState, PostForm};
use crate::media::{
    promote_urls, render_post_image, validate_upload, MediaError, MediaItem, MediaManifest,
};
use crate::repository::{PostFile, Repository, Status};
use askama::Template;
use axum::extract::{Multipart, Path, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};

// ---------------------------------------------------------------------------
// 「保存してメディアを追加」(編集フォームから formaction で来る)
// ---------------------------------------------------------------------------

/// 編集フォームと同じ内容を受け取り、保存してからアップロード画面へ遷移する。
///
/// フォームの入れ子ができないため、メディア追加は編集フォームの
/// 「保存してメディアを追加」ボタン (formaction) から始める。ここで記事を保存することで、
/// アップロード後に編集フォームへ戻ったときに入力内容が失われない。
pub async fn save_and_open_upload(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    form: axum::Form<PostForm>,
) -> Response {
    handlers::save_article(&state, &slug, form.0, |slug| {
        Redirect::to(&format!("/posts/{slug}/media/new")).into_response()
    })
    .await
}

#[derive(Template)]
#[template(path = "media_upload.html")]
pub struct UploadTemplate {
    pub slug: String,
    pub title: String,
    pub status_label: &'static str,
    pub status_class: &'static str,
    /// 公開済み記事はアップロード時に即 R2 へ昇格する (§2.6.1)
    pub published: bool,
    /// 既存の管理下メディア
    pub items: Vec<UploadItemView>,
    pub error: String,
}

pub struct UploadItemView {
    pub key: String,
    pub url: String,
    pub preview_url: String,
    pub width: u32,
    pub height: u32,
    pub alt: String,
    pub promoted: bool,
}

pub async fn upload_form(State(state): State<AppState>, Path(slug): Path<String>) -> Response {
    let Some(post) = state.repo.find(&slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let Some(front_matter) = post.front_matter.clone() else {
        return not_found(&format!(
            "frontmatter を解析できないためメディアを追加できません: {}",
            post.file_name
        ));
    };

    let manifest = MediaManifest::load(&state.media_dir, &slug);
    let items = manifest
        .items
        .iter()
        .map(|item| UploadItemView {
            key: item.key.clone(),
            url: if item.promoted {
                state.r2.public_url(&item.key)
            } else {
                state.rustfs.public_url(&item.key)
            },
            preview_url: format!("/media-preview/{}", item.key),
            width: item.width,
            height: item.height,
            alt: item.alt.clone(),
            promoted: item.promoted,
        })
        .collect();

    render_template(UploadTemplate {
        slug,
        title: front_matter.title,
        status_label: post.status.label(),
        status_class: match post.status {
            Status::Published => "badge-success",
            Status::Draft => "badge-warning",
        },
        published: post.status == Status::Published,
        items,
        error: String::new(),
    })
}

fn not_found(detail: &str) -> Response {
    (
        StatusCode::NOT_FOUND,
        Html(format!(
            "<h1>記事が見つかりません</h1><p><code>{}</code></p><p><a href=\"/\">一覧へ戻る</a></p>",
            html_escape(detail)
        )),
    )
        .into_response()
}

fn html_escape(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

fn render_template<T: Template>(template: T) -> Response {
    match template.render() {
        Ok(html) => Html(html).into_response(),
        Err(err) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("テンプレートの描画に失敗しました: {err}"),
        )
            .into_response(),
    }
}

// ---------------------------------------------------------------------------
// アップロード (multipart)
// ---------------------------------------------------------------------------

const TARGET_BODY: &str = "body";
const TARGET_COVER: &str = "cover";

/// multipart フォームから file / alt / target を受け取る。
struct UploadForm {
    file_name: String,
    content_type: String,
    bytes: Vec<u8>,
    alt: String,
    target: String,
}

async fn read_multipart(mut multipart: Multipart) -> Result<UploadForm, String> {
    let mut file_name = None;
    let mut content_type = None;
    let mut bytes = None;
    let mut alt = String::new();
    let mut target = TARGET_BODY.to_string();

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|err| format!("フォームの読み込みに失敗しました: {err}"))?
    {
        let name = field.name().unwrap_or_default().to_string();
        match name.as_str() {
            "file" => {
                file_name = Some(field.file_name().unwrap_or_default().to_string());
                content_type = Some(
                    field
                        .content_type()
                        .unwrap_or("application/octet-stream")
                        .to_string(),
                );
                bytes = Some(
                    field
                        .bytes()
                        .await
                        .map_err(|err| format!("ファイルの読み込みに失敗しました: {err}"))?
                        .to_vec(),
                );
            }
            "alt" => {
                alt = field
                    .text()
                    .await
                    .map_err(|err| format!("alt の読み込みに失敗しました: {err}"))?;
            }
            "target" => {
                target = field
                    .text()
                    .await
                    .map_err(|err| format!("挿入先の読み込みに失敗しました: {err}"))?;
            }
            _ => {}
        }
    }

    let file_name = file_name.unwrap_or_default();
    let content_type = content_type.unwrap_or_default();
    let bytes = bytes.ok_or("ファイルが選択されていません")?;

    Ok(UploadForm {
        file_name,
        content_type,
        bytes,
        alt,
        target,
    })
}

/// アップロード本体。
///
/// 1. 検証 (mime / サイズ / 寸法) と key 生成
/// 2. RustFS へ PUT
/// 3. **公開済み記事なら即昇格** (RustFS → R2、§2.6.1)。記事には R2 URL を書く
/// 4. target に応じて本文 or coverImage へ反映して保存
/// 5. manifest に登録
///
/// 昇格が失敗した場合 (公開済み記事) は保存を中止する — RustFS URL が公開記事に
/// 混入するのを防ぐため (§2.6.1)。
pub async fn upload(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    multipart: Multipart,
) -> Response {
    let _guard = state.write_lock.lock().await;

    let form = match read_multipart(multipart).await {
        Ok(form) => form,
        Err(error) => return upload_error_page(&state, &slug, error).await,
    };

    if form.target != TARGET_BODY && form.target != TARGET_COVER {
        return upload_error_page(&state, &slug, "挿入先が不正です".to_string()).await;
    }

    let Some(post) = state.repo.find(&slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let Some(mut front_matter) = post.front_matter.clone() else {
        return not_found(&format!(
            "frontmatter を解析できないためメディアを追加できません: {}",
            post.file_name
        ));
    };

    // 1) 検証と key 生成
    let media = match validate_upload(
        &slug,
        &form.file_name,
        form.bytes.clone(),
        &form.content_type,
    ) {
        Ok(media) => media,
        Err(MediaError::Io(err)) => return upload_error_page(&state, &slug, err.to_string()).await,
        Err(err) => return upload_error_page(&state, &slug, err.to_string()).await,
    };

    // 2) RustFS へ PUT
    if let Err(err) = state
        .rustfs
        .put(&media.key, form.bytes, &media.content_type)
        .await
    {
        return upload_error_page(&state, &slug, err.to_string()).await;
    }

    // 3) 公開済み記事は即昇格 (RustFS → R2)
    let published = post.status == Status::Published;
    let (article_url, promoted) = if published {
        match promote_object(&state, &media.key, &media.content_type).await {
            Ok(()) => (state.r2.public_url(&media.key), true),
            Err(err) => {
                // 保存を中止 (公開済み記事に RustFS URL を書かない)
                return upload_error_page(
                    &state,
                    &slug,
                    format!("R2 への昇格に失敗したため保存を中止しました: {err}"),
                )
                .await;
            }
        }
    } else {
        (state.rustfs.public_url(&media.key), false)
    };

    // 4) 記事へ反映
    let mut body = post.body.clone();
    if form.target == TARGET_COVER {
        front_matter.cover_image.url = article_url.clone();
        front_matter.cover_image.width = media.width;
        front_matter.cover_image.height = media.height;
        front_matter.cover_image.alternative_text = Some(form.alt.clone());
    } else {
        body.push_str(&render_post_image(
            &article_url,
            media.width,
            media.height,
            &form.alt,
        ));
    }

    let updated = PostFile {
        front_matter: Some(front_matter),
        body,
        ..post.clone()
    };
    let revision = latest_revision(&state.repo, &post);
    if let Err(err) = state.repo.save(&updated, &revision) {
        return upload_error_page(&state, &slug, err.display_message()).await;
    }

    // 5) manifest へ登録
    let now = chrono::Utc::now().to_rfc3339();
    let mut manifest = MediaManifest::load(&state.media_dir, &slug);
    manifest.items.push(MediaItem {
        key: media.key.clone(),
        content_type: media.content_type.clone(),
        width: media.width,
        height: media.height,
        alt: form.alt,
        created_at: now.clone(),
        promoted,
        promoted_at: promoted.then(|| now.clone()),
    });
    if let Err(err) = manifest.save(&state.media_dir) {
        return upload_error_page(
            &state,
            &slug,
            format!("manifest の保存に失敗しました: {err}"),
        )
        .await;
    }

    Redirect::to(&format!("/posts/{slug}/edit?flash=media-added")).into_response()
}

/// RustFS から取得して R2 へ同じ key で置く (昇格)。
async fn promote_object(state: &AppState, key: &str, content_type: &str) -> Result<(), String> {
    let (bytes, _) = state.rustfs.get(key).await.map_err(|err| err.to_string())?;
    state
        .r2
        .put(key, bytes, content_type)
        .await
        .map_err(|err| err.to_string())
}

/// 記事ファイルの現在の revision を取得する (アップロード中は write_lock を
/// 持っているため、これが最新)。
fn latest_revision(repo: &Repository, post: &PostFile) -> String {
    repo.load(&post.path, post.status).revision
}

async fn upload_error_page(state: &AppState, slug: &str, error: String) -> Response {
    // エラー画面は upload_form と同じく manifest の一覧を表示する
    let Some(post) = state.repo.find(slug) else {
        return not_found(&format!("slug: {slug}"));
    };
    let Some(front_matter) = post.front_matter.clone() else {
        return not_found(&format!("frontmatter を解析できません: {}", post.file_name));
    };

    let manifest = MediaManifest::load(&state.media_dir, slug);
    let items = manifest
        .items
        .iter()
        .map(|item| UploadItemView {
            key: item.key.clone(),
            url: if item.promoted {
                state.r2.public_url(&item.key)
            } else {
                state.rustfs.public_url(&item.key)
            },
            preview_url: format!("/media-preview/{}", item.key),
            width: item.width,
            height: item.height,
            alt: item.alt.clone(),
            promoted: item.promoted,
        })
        .collect();

    render_template(UploadTemplate {
        slug: slug.to_string(),
        title: front_matter.title,
        status_label: post.status.label(),
        status_class: match post.status {
            Status::Published => "badge-success",
            Status::Draft => "badge-warning",
        },
        published: post.status == Status::Published,
        items,
        error,
    })
}

// ---------------------------------------------------------------------------
// プレビュー中継 (非公開 RustFS を見るためのローカル専用ルート)
// ---------------------------------------------------------------------------

/// RustFS のオブジェクトを中継する。
///
/// RustFS の `blog` バケットは非公開のため、下書きメディアは直接ブラウザで
/// 見られない。記事ファイルには資格情報や presigned URL を埋め込まない (計画 §2.6)。
/// このルートは 127.0.0.1 bind のみで提供する。
pub async fn media_preview(State(state): State<AppState>, Path(key): Path<String>) -> Response {
    if !is_safe_key(&key) {
        return (StatusCode::BAD_REQUEST, "無効な key です").into_response();
    }

    match state.rustfs.get(&key).await {
        Ok((bytes, content_type)) => (
            StatusCode::OK,
            [
                (header::CONTENT_TYPE, content_type),
                (header::CACHE_CONTROL, "private, max-age=60".to_string()),
            ],
            bytes,
        )
            .into_response(),
        Err(err) => (
            StatusCode::NOT_FOUND,
            format!("メディアを取得できませんでした: {err}"),
        )
            .into_response(),
    }
}

/// key は `blog/` 始まりで、`..` / バックスラッシュ / 空セグメントを含まないこと。
fn is_safe_key(key: &str) -> bool {
    if !key.starts_with("blog/") || key.contains("..") || key.contains('\\') {
        return false;
    }
    key.split('/').all(|segment| !segment.is_empty())
}

// ---------------------------------------------------------------------------
// 昇格 (publish 時の一括昇格 — M5 の publish ステートマシンから呼ぶ)
// ---------------------------------------------------------------------------

/// 記事が実際に参照している未昇格メディアをすべて R2 へ昇格し、記事の URL を置き換える。
///
/// M4 では公開済み記事へのメディア追加 (§2.6.1) の保存時昇格に使う。
/// 全 key の PUT が終わるまで記事は書き換えない。途中で失敗した場合、
/// 完了した key だけ manifest を `promoted=true` にして中断する (再試行は失敗 key のみ)。
pub async fn promote_pending_media(
    state: &AppState,
    slug: &str,
) -> Result<Result<(String, String), String>, String> {
    let _guard = state.write_lock.lock().await;

    let Some(post) = state.repo.find(slug) else {
        return Err(format!("記事が見つかりません: {slug}"));
    };
    let Some(mut front_matter) = post.front_matter.clone() else {
        return Err(format!("frontmatter を解析できません: {slug}"));
    };

    let mut manifest = MediaManifest::load(&state.media_dir, slug);
    let referenced = manifest.referenced_keys(&front_matter, &post.body);
    let pending: Vec<String> = referenced
        .iter()
        .filter(|key| {
            manifest
                .item(key)
                .map(|item| !item.promoted)
                .unwrap_or(false)
        })
        .cloned()
        .collect();

    let mut promoted_keys = Vec::new();
    let mut failed: Option<String> = None;
    for key in &pending {
        let content_type = manifest
            .item(key)
            .map(|item| item.content_type.clone())
            .unwrap_or_else(|| "application/octet-stream".to_string());
        match promote_object(state, key, &content_type).await {
            Ok(()) => {
                promoted_keys.push(key.clone());
            }
            Err(err) => {
                failed = Some(format!("{key}: {err}"));
                break;
            }
        }
    }

    if !promoted_keys.is_empty() {
        let now = chrono::Utc::now().to_rfc3339();
        for key in &promoted_keys {
            manifest.update_item(key, true, Some(now.clone()));
        }
        if let Err(err) = manifest.save(&state.media_dir) {
            return Err(format!("manifest の保存に失敗しました: {err}"));
        }
    }

    if let Some(error) = failed {
        // 完了分は記録済み。呼び出し側は失敗として扱い、再試行時に残りを処理する。
        return Ok(Err(format!("昇格に失敗しました: {error}")));
    }

    if promoted_keys.is_empty() {
        // 昇格対象なし — そのまま完了
        return Ok(Ok((post.body.clone(), post.revision.clone())));
    }

    // 記事の URL を一括置換して保存
    let rustfs_base = rustfs_public_base(state);
    let r2_base = r2_public_base(state);
    let new_body = promote_urls(
        &mut front_matter,
        &post.body,
        &rustfs_base,
        &r2_base,
        &promoted_keys,
    );

    let updated = PostFile {
        front_matter: Some(front_matter),
        body: new_body,
        ..post.clone()
    };
    let revision = latest_revision(&state.repo, &post);
    if let Err(err) = state.repo.save(&updated, &revision) {
        return Err(format!(
            "記事の保存に失敗しました: {}",
            err.display_message()
        ));
    }

    let saved = state
        .repo
        .find(slug)
        .ok_or_else(|| format!("保存後の記事が見つかりません: {slug}"))?;
    Ok(Ok((saved.body.clone(), saved.revision.clone())))
}

fn rustfs_public_base(state: &AppState) -> String {
    state
        .rustfs
        .public_url("")
        .trim_end_matches('/')
        .to_string()
}

fn r2_public_base(state: &AppState) -> String {
    state.r2.public_url("").trim_end_matches('/').to_string()
}
