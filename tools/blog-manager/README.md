# blog-manager

`content/posts/` の記事をローカルで管理するための小さな CRUD アプリ (Rust + axum)。

設計・計画はリポジトリ直下の `docs/blog-manager-plan.md` を参照。

## 起動

```bash
cd tools/blog-manager
cp .env.example .env   # 必要に応じて編集 (M2 では不要)
cargo run              # http://127.0.0.1:3001
```

ブラウザで <http://127.0.0.1:3001/> を開く。

## 設定

`.env` もしくは環境変数で指定する。

| 変数 | 既定値 | 説明 |
|---|---|---|
| `CONTENT_DIR` | `<repo>/content` | 記事ディレクトリ (`posts/`, `drafts/`) の親 |
| `PORT` | `3001` | 待ち受けポート |
| `TRASH_DIR` | `tools/blog-manager/.trash` | 削除した記事の退避先 |
| `MEDIA_DIR` | `tools/blog-manager/state/media` | メディア manifest の保存先 |

### オブジェクトストレージ

| 変数 | 例 | 説明 |
|---|---|---|
| `RUSTFS_ENDPOINT` | `https://rustfs.mf.officeiko.co.jp` | 下書きメディアの S3 互換エンドポイント |
| `RUSTFS_BUCKET` | `blog` | 下書きメディアのバケット (非公開) |
| `RUSTFS_ACCESS_KEY_ID` / `RUSTFS_SECRET_ACCESS_KEY` | — | 認証情報 |
| `RUSTFS_PUBLIC_BASE` | `https://rustfs.mf.officeiko.co.jp/blog` | 記事に書き込む下書きURL のベース |
| `R2_ENDPOINT` | `https://<account>.r2.cloudflarestorage.com` | 公開メディアのエンドポイント |
| `R2_BUCKET` | `officeiko` | 公開メディアのバケット |
| `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` | — | 認証情報 |
| `R2_PUBLIC_BASE` | `https://image.officeiko.work` | 公開URL のベース |

起動時に `RUSTFS_*` / `R2_*` が揃っていないとサーバは起動しない。

**必ず `127.0.0.1` にのみバインドする** (認証を持たないため)。将来必要になったら basic auth を追加する。

## データモデル

- データソースはファイルのみ (DB なし)
  - `content/posts/*.md` — 公開済み
  - `content/drafts/*.md` — 下書き (elm-pages の Glob 対象外なので誤公開されない)
- frontmatter は `src/Post.elm` の decoder と同一スキーマ
  - `title` / `slug` / `author` / `publishedOn` / `category` (`news` \| `blog`) / `tags` / `coverImage`
  - `tags` は Elm 側が `{ attributes: { name, slug } }` を要求する
  - `coverImage.alternativeText` と `tags` は**未設定でも必ず出力**する (Elm の `JD.field` が必須のため)
- 未知のキーは `#[serde(flatten)]` で保持する (トップレベル・`coverImage` のネスト両方)

## 実装上の約束

- **slug からファイル名を組み立てない**。`PostFile` がパスを保持し、slug → ファイルの解決は一覧から索引を作って行う
- 書き込みは一時ファイル + rename の atomic write
- slug は `^[a-z0-9][a-z0-9-]*$`。公開済み・下書きを横断して一意
- 本文は frontmatter 境界より後ろをバイト単位でそのまま保持する
- 解析できない記事は壊さずに一覧へ出し、「要修正」としてエラー理由を表示する
- 解析はできても **frontmatter の値が不正な記事も「要修正」** として表示する
  (例: `coverImage.url` が絶対 URL でないと Elm の `Url.fromString` が失敗しサイトのビルドが壊れるため、
  保存時に `http(s)://` の絶対 URL を要求する)
- `tags` / `tags[].attributes` の内部にある未知キーも保持する
- タグはフォームで `表示名,slug` の 1 行 1 件として編集する（Elm が `{attributes:{name,slug}}` を要求するため）

## 画面 (M2 時点)

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/` | 記事一覧 (公開済み + 下書き、状態・カテゴリ・公開日・slug・ファイル名) |
| GET | `/posts/{slug}` | 記事詳細 (frontmatter / coverImage / 本文 / raw YAML) |
| GET | `/files/{status}/{file_name}` | **解析できなかった記事**の詳細 (status は `published` \| `draft`) |
| GET | `/posts/new` | 新規記事フォーム（作成先は下書き） |
| POST | `/posts` | 記事作成（`content/drafts/` に作成） |
| GET | `/posts/{slug}/edit` | 編集フォーム（公開済みは slug / カテゴリ変更不可） |
| POST | `/posts/{slug}` | 記事更新 |
| GET | `/posts/{slug}/delete` | 削除の確認 |
| POST | `/posts/{slug}/delete` | 削除（`.trash/` に退避） |
| GET | `/posts/{slug}/media/new` | メディア追加画面 (アップロードフォーム + 管理下メディア一覧) |
| POST | `/posts/{slug}/media/new` | 編集フォームの「保存してメディアを追加」(formaction)。保存してから追加画面へ遷移 |
| POST | `/media/{slug}` | multipart アップロード (file + alt + 挿入先 body/cover) |
| GET | `/media-preview/{*key}` | 非公開 RustFS のプレビュー中継 (127.0.0.1 のみ) |
| GET | `/static/*` | 静的ファイル |

解析できない記事・slug が不正な記事は `/posts/{slug}` に載らないため、状態 + ファイル名で開く。
slug 空間とファイル名空間を混ぜないことで、`slug=shadowed` の正常記事と `draft/shadowed.md` の
壊れた記事が併存しても互いを隠さない。

## メディア管理 (M4)

- **下書きメディアは RustFS** (`RUSTFS_BUCKET`、非公開)、**公開メディアは R2** (`R2_BUCKET`、
  `image.officeiko.work` で配信)
- アップロードは multipart で受け付け、mime (JPEG/PNG/GIF/WebP) と 10MB 上限を検証し、
  `image` crate で寸法を検出する (Elm デコーダが width/height を要求するため)
- key は `blog/<slug>/<sanitized-name>-<id>.<ext>`。記事には **RustFS の URL** を書き込む
- **下書き記事**: `<post-image>` (本文) または `coverImage` に RustFS URL を挿入し、manifest
  (`state/media/<slug>.json`) に `promoted=false` で記録
- **公開済み記事**: 保存時に **R2 へ昇格** (RustFS GET → R2 PUT、同一 key) してから、
  記事には R2 公開URL を書く。昇格が失敗したら保存を中止する (§2.6.1 — RustFS URL の混入防止)
- プレビューは `GET /media-preview/{*key}` のローカル中継のみ。記事ファイルに資格情報や
  presigned URL は書き込まない
- R2 の既存メディア (`officeiko` バケットの既存キー) は管理対象外。手入力の URL 欄は維持
- v1 ではメディアの削除機能を設けない (誤削除防止。孤児オブジェクトは許容)

### M5 publish への接続

`handlers_media::promote_pending_media` が、公開時に下書きメディアを一括昇格する
ステップ (計画 §2.5 step 0) を提供する:

- 記事が**実際に参照している**未昇格 key のみを昇格 (manifest にあっても未参照の
  メディアは対象外 — 未使用メディアの失敗で公開を妨げない)
- 全 key の PUT が終わるまで記事を書き換えない。途中失敗時は完了 key だけ
  `promoted=true` を記録して中断し、再試行は失敗 key のみになる
- 記事の URL 置換は管理下 key との全体一致で行う (`<post-image>` と Markdown 画像の両方)

## 同時編集・誤操作への対策

- **書き込みの直列化**: 作成・更新・削除はプロセス内のグローバルロックで直列化する
- **楽観ロック**: フォームは読み込み時の内容ハッシュ (`expected_revision`) を hidden で持ち、
  保存時にディスクの内容が変わっていれば「他の編集が先に保存されました」として拒否する
  （二重送信・別タブからの上書きを防ぐ）
  - **エラー再描画では revision を更新しない**。最新の revision を返すと、古い本文のまま
    再送信して他人の保存内容を上書きできてしまうため、衝突時は revision を空にして再送信も拒否する
  - revision が空の更新・削除はエラー（hidden を消すだけの上書きを防ぐ）
- **公開済み記事の不変条件**: slug とカテゴリは変更できない（URL と GMB のリンクを守るため）。
  フォーム側で readonly/disabled にし、リポジトリ層でも拒否する
- **上書きしない作成**: 新規作成は `create_new` で既存ファイルを上書きしない。slug は全記事で一意
- **削除はゴミ箱へ**: ファイルは `.trash/` に退避し、復元できる。
  宛先は `create_new` で確保してから書き込むため、同一秒に同名記事を削除しても既存の退避ファイルを
  上書きしない（タイムスタンプ + pid + 連番 + status + ファイル名）
- **予約 slug**: `new` は `/posts/new` と衝突するため slug に使えない

作成・編集・削除・公開は M3 以降で追加する。

## テスト

```bash
cargo test                        # ユニット + ハンドラ統合 (モック)
cargo test --test live_storage -- --ignored   # 実ストレージ疎通 (RUSTFS_*/R2_* が必要)
```

- 既存記事 8 件すべてのパース
- frontmatter の roundtrip (値が変わらないこと) と本文のバイト一致
- 未知キー (トップレベル / ネスト) の保持
- `alternativeText` / `tags` の常時出力
- ファイル名と slug が一致しない記事の解決
- 壊れた記事の一覧表示と到達性
- atomic write と一時ファイルの残留チェック
- slug 重複・不正 slug の拒否
- `coverImage.url` の絶対 URL 検証
- タグ内部の未知キー保持
- slug 空間とファイル名空間の衝突 (`slug=shadowed` + `draft/shadowed.md` など)
- 作成（下書き保存・既存ファイルの非上書き・slug 重複拒否）
- 楽観ロック（古い revision での保存・削除の拒否）
- 公開済み記事の slug / カテゴリ変更拒否
- 削除で `.trash/` へ退避されること
- タグ入力のパースとバリデーション
- ハンドラ経由の回帰テスト（`tests/handlers.rs`）
  - 衝突後に再送信しても他人の保存内容を上書きしない
  - revision なしの更新を拒否
  - タグの未知キーがハンドラ経由の保存でも残る
  - 予約 slug の作成拒否
  - 同一秒に同名記事を繰り返し削除しても退避内容が失われない
- メディア: key 生成 (日本語 stem のサニタイズ)、寸法検出、mime/サイズ上限の拒否
- manifest の roundtrip / 参照 key の抽出 (未使用メディアを含めない) / key 単位の昇格記録
- promote_urls: 管理下 key のみ URL を置換 (未管理の R2 URL を触らない)
- media-preview の key 検証 (パストラバーサル拒否) と存在しない key の 404
- 「保存してメディアを追加」(formaction) が通常の保存と同じ検査を通ること

## 静的アセット

`static/daisyui.css` は [daisyUI 4.12.24](https://www.npmjs.com/package/daisyui/v/4.12.24) の
`dist/full.min.css` をそのまま同梱したもの (CDN 非依存・ビルド不要)。
更新する場合:

```bash
curl -sL -o static/daisyui.css https://cdn.jsdelivr.net/npm/daisyui@4.12.24/dist/full.min.css
```
