//! Durable publication progress. Reading a state file never silently resets it.
use serde::{Deserialize, Serialize};
use std::{fs, path::Path};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum GmbStatus {
    Pending,
    InFlight,
    Done,
    Unknown,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublishRecord {
    pub slug: String,
    pub file_name: String,
    pub operation_id: String,
    pub input_revision: String,
    pub promoted_revision: String,
    pub media_promoted: bool,
    pub file_moved: bool,
    pub commit_id: Option<String>,
    pub pushed: bool,
    #[serde(default)]
    pub deleted: bool,
    #[serde(default)]
    pub draft_source: bool,
    #[serde(default)]
    pub content_applied: bool,
    #[serde(default)]
    pub pending_contents: Option<String>,
    pub gmb: GmbStatus,
    pub search_url: Option<String>,
    pub post_name: Option<String>,
    pub error: Option<String>,
    pub updated_at: String,
}
impl PublishRecord {
    pub fn new(slug: &str, file_name: &str, revision: &str) -> Self {
        Self {
            slug: slug.into(),
            file_name: file_name.into(),
            operation_id: uuid::Uuid::new_v4().to_string(),
            input_revision: revision.into(),
            promoted_revision: revision.into(),
            media_promoted: false,
            file_moved: false,
            commit_id: None,
            pushed: false,
            deleted: false,
            draft_source: false,
            content_applied: false,
            pending_contents: None,
            gmb: GmbStatus::Pending,
            search_url: None,
            post_name: None,
            error: None,
            updated_at: chrono::Utc::now().to_rfc3339(),
        }
    }
    pub fn load(dir: &Path, slug: &str) -> Result<Option<Self>, String> {
        if !crate::model::is_valid_slug(slug) {
            return Err("無効な slug".into());
        }
        let path = dir.join(format!("{slug}.json"));
        let raw = match fs::read_to_string(&path) {
            Ok(raw) => raw,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(None),
            Err(e) => return Err(e.to_string()),
        };
        let record: Self =
            serde_json::from_str(&raw).map_err(|e| format!("公開状態を読み込めません: {e}"))?;
        if record.slug != slug {
            return Err("公開状態のslugが一致しません".into());
        }
        Ok(Some(record))
    }
    /// Recovery is a mutation and must only run while holding the publication write lock.
    pub fn recover(dir: &Path, slug: &str) -> Result<Option<Self>, String> {
        let mut record = Self::load(dir, slug)?;
        if let Some(r) = record.as_mut() {
            if r.gmb == GmbStatus::InFlight {
                r.gmb = GmbStatus::Unknown;
                r.save(dir)?;
            }
        }
        Ok(record)
    }
    pub fn save(&self, dir: &Path) -> Result<(), String> {
        use std::io::Write;
        fs::create_dir_all(dir).map_err(|e| e.to_string())?;
        let path = dir.join(format!("{}.json", self.slug));
        let temp = dir.join(format!(".{}.tmp", uuid::Uuid::new_v4()));
        let result = (|| -> std::io::Result<()> {
            let mut file = fs::OpenOptions::new()
                .write(true)
                .create_new(true)
                .open(&temp)?;
            file.write_all(&serde_json::to_vec_pretty(self)?)?;
            file.sync_all()?;
            fs::rename(&temp, &path)?;
            fs::File::open(dir)?.sync_all()
        })();
        if result.is_err() {
            let _ = fs::remove_file(temp);
        }
        result.map_err(|e| e.to_string())
    }
}

use crate::{
    handlers::AppState,
    media::{promote_urls, MediaManifest},
    repository::{hash_revision, render, Status},
};
use std::path::{Component, PathBuf};
#[derive(Default, Debug, Clone)]
pub struct PublishOptions {
    pub git: bool,
    pub gmb: bool,
    pub retry_unknown: bool,
    pub deployed: bool,
}
pub fn state_dir(state: &AppState) -> PathBuf {
    state.media_dir.join("../publish")
}

/// One lock covers media, content, git index, and external submission.
pub async fn run(
    state: &AppState,
    slug: &str,
    expected: &str,
    options: PublishOptions,
) -> Result<PublishRecord, String> {
    let _guard = state.write_lock.lock().await;
    let dir = state_dir(state);
    let mut post = state.repo.find(slug).ok_or("記事が見つかりません")?;
    if expected.is_empty() || expected != post.revision {
        return Err("編集開始時の revision が一致しません。再読み込みしてください".into());
    }
    if post.has_errors() {
        return Err(post.error_summary());
    }
    // 公開時のみ要求する項目 (カバー画像)。下書きはカバーなしで保存できるため
    // 索引側の validate() では検出されない。仮の URL で回避しない。
    if let Some(front_matter) = post.front_matter.as_ref() {
        let publish_errors = front_matter.validate_for_publish();
        if !publish_errors.is_empty() {
            return Err(publish_errors.join(" / "));
        }
    }
    let prior = PublishRecord::recover(&dir, slug)?;
    let mut record = match prior {
        Some(r)
            if (r.input_revision == post.revision || r.promoted_revision == post.revision)
                && !(r.file_moved && post.status == Status::Draft) =>
        {
            r
        }
        Some(r)
            if r.gmb == GmbStatus::Unknown
                || r.gmb == GmbStatus::InFlight
                || (r.commit_id.is_some() && !r.pushed) =>
        {
            return Err("前回の公開操作が未解決です。結果を確認してから再開してください".into())
        }
        _ => PublishRecord::new(slug, &post.file_name, &post.revision),
    };
    // A completed publication followed by a new draft is a new article lifecycle,
    // even when its bytes happen to match the deleted article.
    if post.status == Status::Draft {
        record.draft_source = true;
    }
    record.error = None;
    record.updated_at = chrono::Utc::now().to_rfc3339();
    // Persist before any side effects. Predict our URL transform so a crash after save is identifiable.
    let fm = post
        .front_matter
        .as_ref()
        .ok_or("frontmatterがありません")?;
    let manifest = MediaManifest::try_load(&state.media_dir, slug)?;
    let referenced = manifest.referenced_keys_at(
        fm,
        &post.body,
        &[&state.rustfs.public_url(""), &state.r2.public_url("")],
    );
    let mut promoted = fm.clone();
    let body = promote_urls(
        &mut promoted,
        &post.body,
        state.rustfs.public_url("").trim_end_matches('/'),
        state.r2.public_url("").trim_end_matches('/'),
        &referenced,
    );
    if !referenced.is_empty() {
        record.promoted_revision =
            hash_revision(&render(&promoted, &body).map_err(|e| e.to_string())?);
    }
    record.save(&dir)?;
    let result:Result<(),String>=async {
  if options.gmb && !options.deployed {return Err("本番への反映を確認してから GMB 投稿を実行してください".into());}
  if options.git { git_preflight(state,&record).await?; }
  reconcile_move(state,&mut record)?;
  match crate::handlers_media::promote_pending_media_locked(state,slug).await? {Ok(_)=>{},Err(e)=>return Err(e)}
  post=state.repo.find(slug).ok_or("昇格後の記事が見つかりません")?;
  record.promoted_revision=post.revision.clone();record.media_promoted=true;record.save(&dir)?;
  if post.status==Status::Draft {
   let name=Path::new(&post.file_name);
   if name.components().count()!=1 || !matches!(name.components().next(),Some(Component::Normal(_))) {return Err("無効な記事ファイル名".into());}
   let dest=state.repo.posts_dir().join(name);fs::create_dir_all(state.repo.posts_dir()).map_err(|e|e.to_string())?;
   if dest.exists() {
    // Only resume our own interrupted link+unlink operation.
    if !record.file_moved && fs::read(&dest).ok()==fs::read(&post.path).ok() && record.file_name==post.file_name {
     // Both links must refer to the same inode, not a coincidentally equal pre-existing article.
     #[cfg(unix)] { use std::os::unix::fs::MetadataExt; let a=fs::metadata(&dest).map_err(|e|e.to_string())?;let b=fs::metadata(&post.path).map_err(|e|e.to_string())?;if a.ino()!=b.ino() || a.dev()!=b.dev(){return Err("公開先に別の記事ファイルが存在します".into());} }
    } else {return Err("公開先に記事ファイルが存在します".into());}
   } else {fs::hard_link(&post.path,&dest).map_err(|e|format!("記事の公開に失敗しました: {e}"))?;}
   fs::remove_file(&post.path).map_err(|e|e.to_string())?;
  }
  record.file_moved=true;record.save(&dir)?;
  if options.git { git_publish(state,&mut record,&dir).await?;record.save(&dir)?; }
  if options.gmb && record.gmb!=GmbStatus::Done {
   if record.gmb==GmbStatus::Unknown && !options.retry_unknown {return Err("GMB の前回結果が不明です。管理画面で未投稿を確認し、明示的な再試行を選択してください".into());}
   let current=state.repo.find(slug).ok_or("公開済み記事が見つかりません")?;
   let fm=current.front_matter.as_ref().ok_or("frontmatterがありません")?;
   let cover_promoted=fm.cover_image.as_ref().map(|cover| !cover.url.starts_with(&state.rustfs.public_url(""))).unwrap_or(false);
   if !cover_promoted {return Err("カバー画像が未公開です".into());}
   let payload=crate::gmb::build_post(fm,&current.body)?;
   record.gmb=GmbStatus::InFlight;record.save(&dir)?;
   // Cancellation or process termination leaves durable in_flight; load() recovers as unknown.
   match state.gmb.send(payload).await {
    Ok(response)=>{record.gmb=GmbStatus::Done;record.search_url=response.search_url;record.post_name=response.name;record.save(&dir)?;},
    Err(e)=>{record.gmb=GmbStatus::Unknown;return Err(e);}
   }
  }
  Ok(())
 }.await;
    if let Err(error) = result {
        record.error = Some(error);
    }
    record.save(&dir)?;
    Ok(record)
}

async fn git(root: &Path, args: &[&str]) -> Result<String, String> {
    let output = tokio::process::Command::new("git")
        .current_dir(root)
        .args(args)
        .env("GIT_TERMINAL_PROMPT", "0")
        .output()
        .await
        .map_err(|e| e.to_string())?;
    if !output.status.success() {
        return Err(format!(
            "git {}: {}",
            args.first().unwrap_or(&""),
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}
async fn repo_root(state: &AppState) -> Result<PathBuf, String> {
    let root = git(state.repo.content_dir(), &["rev-parse", "--show-toplevel"]).await?;
    let root = PathBuf::from(root);
    let content = fs::canonicalize(state.repo.content_dir()).map_err(|e| e.to_string())?;
    if content != root.join("content") {
        return Err("git操作はリポジトリのcontentディレクトリだけで利用できます".into());
    }
    Ok(root)
}
pub(crate) async fn git_preflight(state: &AppState, record: &PublishRecord) -> Result<(), String> {
    let root = repo_root(state).await?;
    if git(&root, &["symbolic-ref", "--short", "HEAD"]).await? != "main" {
        return Err("git操作にはmainブランチが必要です".into());
    }
    let staged = git(&root, &["diff", "--cached", "--name-only"]).await?;
    let allowed = [
        format!("content/posts/{}", record.file_name),
        format!("content/drafts/{}", record.file_name),
    ];
    if staged
        .lines()
        .any(|p| p != allowed[0] && !(record.draft_source && p == allowed[1]))
    {
        return Err("他のファイルがstageされています。公開を中止しました".into());
    }
    Ok(())
}
async fn git_publish(
    state: &AppState,
    record: &mut PublishRecord,
    dir: &Path,
) -> Result<(), String> {
    let root = repo_root(state).await?;
    let dest = format!("content/posts/{}", record.file_name);
    let source = format!("content/drafts/{}", record.file_name);
    let marker = format!("Blog-Manager-Operation: {}", record.operation_id);
    if record.commit_id.is_none() {
        // Recover a successful commit whose progress write was interrupted.
        let previous = git(
            &root,
            &[
                "log",
                "-1",
                "--format=%H",
                "--fixed-strings",
                "--grep",
                &marker,
            ],
        )
        .await?;
        if !previous.is_empty() {
            record.commit_id = Some(previous);
        } else {
            git(&root, &["add", "--", &dest]).await?;
            if record.draft_source
                && git(&root, &["ls-files", "--error-unmatch", "--", &source])
                    .await
                    .is_ok()
            {
                git(&root, &["add", "--", &source]).await?;
            }
            git(
                &root,
                &[
                    "commit",
                    "-m",
                    &format!("Publish article: {}\n\n{marker}", record.slug),
                ],
            )
            .await?;
            record.commit_id = Some(git(&root, &["rev-parse", "HEAD"]).await?);
        }
        record.save(dir)?;
    }
    let id = record.commit_id.as_ref().unwrap();
    let committed = tokio::process::Command::new("git")
        .current_dir(&root)
        .args(["show", &format!("{id}:{dest}")])
        .output()
        .await
        .map_err(|e| e.to_string())?;
    if if record.deleted {
        committed.status.success()
    } else {
        !committed.status.success()
            || hash_revision(&String::from_utf8_lossy(&committed.stdout))
                != record.promoted_revision
    } {
        return Err("公開commitの内容が記事と一致しません".into());
    }
    // Do not push unrelated local commits that arrived after the recorded publication commit.
    if git(&root, &["rev-parse", "HEAD"]).await? != *id {
        return Err("HEADが公開commitから変わっています。手動でgit状態を確認してください".into());
    }
    git(&root, &["push", "origin", "main"]).await?;
    record.pushed = true;
    Ok(())
}

/// Called under the same write lock as edit/delete. Persist progress before invoking git.
pub(crate) async fn sync_change(
    state: &AppState,
    mut record: PublishRecord,
) -> Result<PublishRecord, String> {
    let dir = state_dir(state).join("changes").join(&record.operation_id);
    record.content_applied = true;
    record.pending_contents = None;
    record.save(&dir)?;
    if let Err(error) = git_publish(state, &mut record, &dir).await {
        record.error = Some(error);
    }
    record.save(&dir)?;
    Ok(record)
}
pub(crate) async fn retry_change(
    state: &AppState,
    slug: &str,
    id: &str,
) -> Result<PublishRecord, String> {
    uuid::Uuid::parse_str(id).map_err(|_| "無効な操作ID")?;
    let dir = state_dir(state).join("changes").join(id);
    let mut record = PublishRecord::load(&dir, slug)?.ok_or("操作が見つかりません")?;
    if record.operation_id != id {
        return Err("操作IDが一致しません".into());
    }
    let path = state.repo.posts_dir().join(&record.file_name);
    git_preflight(state, &record).await?;
    let current = fs::read_to_string(&path).ok();
    if record.deleted {
        if let Some(raw) = current.as_ref() {
            if record.content_applied || hash_revision(raw) != record.input_revision {
                return Err("同名記事が変更・再作成されています".into());
            }
            let post = state.repo.load(&path, Status::Published);
            state
                .repo
                .delete(&post, &record.input_revision)
                .map_err(|e| e.to_string())?;
        }
    } else if current.as_ref().map(|raw| hash_revision(raw)).as_deref()
        != Some(&record.promoted_revision)
    {
        if record.content_applied
            || current.as_ref().map(|raw| hash_revision(raw)).as_deref()
                != Some(&record.input_revision)
        {
            return Err("記事が変更されています。git状態を手動で確認してください".into());
        }
        let parsed = crate::repository::parse(
            record
                .pending_contents
                .as_deref()
                .ok_or("保存内容がありません")?,
        )
        .map_err(|e| e.to_string())?;
        let mut post = state.repo.load(&path, Status::Published);
        post.front_matter = Some(parsed.front_matter);
        post.body = parsed.body;
        state
            .repo
            .save(&post, &record.input_revision)
            .map_err(|e| e.to_string())?;
    }
    record.content_applied = true;
    record.pending_contents = None;
    git_preflight(state, &record).await?;
    record.error = None;
    if let Err(error) = git_publish(state, &mut record, &dir).await {
        record.error = Some(error);
    }
    record.save(&dir)?;
    Ok(record)
}

fn reconcile_move(state: &AppState, record: &mut PublishRecord) -> Result<(), String> {
    if record.file_moved {
        return Ok(());
    }
    let name = Path::new(&record.file_name);
    if name.components().count() != 1
        || !matches!(name.components().next(), Some(Component::Normal(_)))
    {
        return Err("無効なファイル名".into());
    }
    let source = state.repo.drafts_dir().join(name);
    let dest = state.repo.posts_dir().join(name);
    if source.exists() && dest.exists() {
        #[cfg(unix)]
        {
            use std::os::unix::fs::MetadataExt;
            let a = fs::metadata(&source).map_err(|e| e.to_string())?;
            let b = fs::metadata(&dest).map_err(|e| e.to_string())?;
            if a.ino() == b.ino() && a.dev() == b.dev() {
                let revision = fs::read_to_string(&dest)
                    .map(|s| hash_revision(&s))
                    .map_err(|e| e.to_string())?;
                if revision != record.promoted_revision {
                    return Err("移動途中の記事が変更されています".into());
                }
                fs::remove_file(source).map_err(|e| e.to_string())?;
                record.draft_source = true;
                record.file_moved = true;
                record.save(&state_dir(state))?;
            }
        }
    }
    Ok(())
}
/// Write intent before edit/delete; without this record the disk must remain untouched.
pub(crate) fn prepare_change(
    state: &AppState,
    post: &crate::repository::PostFile,
    updated: Option<&crate::repository::PostFile>,
) -> Result<PublishRecord, String> {
    let mut record = PublishRecord::new(
        post.slug().ok_or("slugがありません")?,
        &post.file_name,
        &post.revision,
    );
    record.deleted = updated.is_none();
    if let Some(updated) = updated {
        let contents = render(
            updated
                .front_matter
                .as_ref()
                .ok_or("frontmatterがありません")?,
            &updated.body,
        )
        .map_err(|e| e.to_string())?;
        record.promoted_revision = hash_revision(&contents);
        record.pending_contents = Some(contents);
    }
    record.save(&state_dir(state).join("changes").join(&record.operation_id))?;
    Ok(record)
}
pub fn pending_changes(state: &AppState) -> Vec<PublishRecord> {
    let Ok(entries) = fs::read_dir(state_dir(state).join("changes")) else {
        return Vec::new();
    };
    let mut records = Vec::new();
    for entry in entries.flatten() {
        if uuid::Uuid::parse_str(&entry.file_name().to_string_lossy()).is_err() {
            continue;
        }
        let Ok(files) = fs::read_dir(entry.path()) else {
            continue;
        };
        for file in files.flatten() {
            if let Ok(raw) = fs::read_to_string(file.path()) {
                if let Ok(record) = serde_json::from_str::<PublishRecord>(&raw) {
                    if !record.pushed {
                        records.push(record);
                    }
                }
            }
        }
    }
    records
}
pub(crate) fn inspect_change(
    state: &AppState,
    slug: &str,
    id: &str,
) -> Result<PublishRecord, String> {
    uuid::Uuid::parse_str(id).map_err(|_| "無効な操作ID")?;
    let record = PublishRecord::load(&state_dir(state).join("changes").join(id), slug)?
        .ok_or("操作が見つかりません")?;
    if record.operation_id != id {
        return Err("操作IDが一致しません".into());
    }
    Ok(record)
}
