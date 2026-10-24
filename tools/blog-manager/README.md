# blog-manager

`content/posts/` の記事をローカルで管理するための小さな CRUD アプリ (Rust + axum)。

設計・計画はリポジトリ直下の `docs/blog-manager-plan.md` を参照。

## 起動

**前提: 隣接リポジトリの共有ライブラリが必要** (`Cargo.toml` の path 依存
`gmb-event-poster = { path = "../../../gmb-event-poster" }`)。このリポジトリの親ディレクトリに
`gmb-event-poster/` がある配置で、STANDARD対応済みの `main` を使う。無いとビルドできない。
共有ライブラリ: <https://gitea.tera.officeiko.co.jp/kyasu1/gmb-event-poster>。
未取得の場合は、このリポジトリの親ディレクトリで次を実行する。

```bash
git clone --branch main \
  ssh://git@gitea.tera.officeiko.co.jp:4224/kyasu1/gmb-event-poster.git
```

```bash
cd tools/blog-manager
cp .env.example .env   # RUSTFS_* と R2_* は起動に必須。GMB_* は投稿する時だけ
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

## 画面

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/` | 記事一覧 (公開済み + 下書き、状態・カテゴリ・公開日・slug・ファイル名) |
| GET | `/posts/{slug}` | 記事詳細 (frontmatter / coverImage / 本文 / raw YAML) |
| GET | `/files/{status}/{file_name}` | **解析できなかった記事**の詳細 (status は `published` \| `draft`) |
| GET | `/posts/new` | 新規記事フォーム（作成先は下書き） |
| POST | `/posts` | 記事作成（`content/drafts/` に作成）。`cover_file` によるカバー画像アップロード対応 |
| GET | `/posts/{slug}/edit` | 編集フォーム（公開済みは slug / カテゴリ変更不可） |
| POST | `/posts/{slug}` | 記事更新 (`multipart/form-data` / urlencoded 両対応) |
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

### カバー画像 (2026-10-24 設計)

- 新規作成・編集フォームから `cover_file` で画像を選べる。**寸法 (width/height) は画像から自動取得**
  し、URL 手入力は既存画像を利用する場合の補助として残す
- **下書きはカバーなしで作成・保存・再編集できる**。未設定なら frontmatter に `coverImage` キー自体を
  書かない (仮の URL を埋めない)。索引はカバーなし下書きを「要修正」にしない
- **公開にはカバーが必要**。検証は下書き用 `FrontMatter::validate()` と公開用
  `FrontMatter::validate_for_publish()` に分離し、後者は `publish::run` がファイル移動前に適用する
- 下書きのカバーは RustFS URL、公開済み記事は保存時に R2 へ昇格して R2 URL を書く
  (公開済み記事に RustFS URL を書かない規則はメディアと同じ)。下書きカバーは公開時の
  メディア昇格 (§2.5 step 0) で R2 URL へ差し替わる
- 画像不正・ストレージ障害・昇格失敗のいずれも**保存そのものを中止**し、既存カバーと本文を
  そのまま残す。旧カバーのオブジェクトは削除しない (孤児オブジェクトは許容)
- **表示用 URL は保存用 URL と別**。管理下の RustFS カバーは非公開バケットなのでブラウザから
  直接読めず、詳細・編集画面は `GET /media-preview/{*key}` のローカル中継で表示する。
  記事へ書き込む URL (URL 欄) はそのまま。R2 など公開済み URL は直接表示する
- URL がないのに width/height/alt だけが入力された場合は「取り消し忘れ」としてエラーにし、
  入力を黙って捨てない。カバーを取り消すには 4 項目をすべて空にする
- ボディ上限は**ファイル単体とリクエスト全体で分ける**。`validate_upload` は画像 10MB
  (`MAX_UPLOAD_BYTES`) を検証し、multipart ルートの `DefaultBodyLimit` は
  `MAX_REQUEST_BYTES` (10MB + 2MB 余裕)。multipart のボディには境界マーカーと
  他のフォーム項目 (title / body / revision) も入るため、同一値だと 10MB ちょうどの
  画像が他の項目と同時に通らない。axum 既定の 2MB のままでも読み取れていなかった

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

作成・編集・削除・公開と任意のGMB連携を利用できます。

## テスト

```bash
# アプリ (リポジトリ直下から)。rustc の incremental ICE を避けるため CARGO_INCREMENTAL=0 と
# 専用 target-dir を使う (M5 で判明した環境上の回避策)
CARGO_INCREMENTAL=0 cargo test --locked --offline \
  --manifest-path tools/blog-manager/Cargo.toml \
  --target-dir /private/tmp/officeiko-m5-target
# → 92 passed / 0 failed / 2 ignored

# 実ストレージへの疎通 (ignored の 2 件。RUSTFS_*/R2_* の実設定が必要)
cargo test --manifest-path tools/blog-manager/Cargo.toml --test live_storage -- --ignored

# 共有ライブラリ (リポジトリ直下から、隣接リポジトリの manifest を指定)
cargo test --locked --offline --manifest-path ../gmb-event-poster/Cargo.toml   # → 5 passed
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
- カバー画像 (`tests/cover_upload.rs`、偽 S3 を 127.0.0.1 に起動して実 PUT/GET を検証)
  - カバーなし下書きの作成・保存・再編集と、索引で「要修正」にしないこと
  - 公開時にカバーを要求し、下書きは移動されないこと
  - multipart でのカバーアップロード (寸法自動取得・RustFS へ実 PUT・manifest 登録)
  - 公開済み記事のカバー差し替えは即 R2 昇格し、RustFS URL を書かないこと
  - 下書きカバーは公開時の昇格で R2 URL へ差し替わること
  - アップロード失敗・画像不正時に既存カバーと本文を維持すること
  - 新規作成のアップロード失敗時に下書きを残さず、同一 slug で再試行できること
  - 公開時のカバー検証がメディア昇格・記事移動・state 記録より前であること
  - 上限すれすれ (約 9.7MB) のカバーを 900KB の本文と同時に送っても通ること
    (リクエスト全体は 10MB を超える)、10MB 超過はファイル単体で拒否すること
  - 下書きカバーは /media-preview 中継で表示し、非公開 URL を `src` に使わないこと
  - 公開済み URL はそのまま表示し、URL だけの設定はファイルなしの編集でも残ること
- 公開ステートマシン (`tests/publish.rs`): 昇格→移動→git→GMB の遷移、中断からの再開、
  `in_flight` 永続化と unknown 化 (自動再送しない)、git preflight の stage 検査
- 実ストレージ (`tests/live_storage.rs`): `#[ignore]` の 2 件。実 RustFS/R2 の設定がある環境でのみ実行

## 残件 (M6 で実施しなかったもの)

- **本文のフルプレビュー未実装**。記事編集は実装済みだが、記事全体を本番表示と同じように
  レンダリングするプレビュー画面はない。現状のプレビューは `GET /media-preview/{*key}` の
  画像中継のみ (計画 §2.6 の非公開中継)。
- **記事ごとのカバー画像アップロード改善** は方針合意済み・未実装。
  新規作成・編集から画像選択、寸法自動取得、画像確認・差し替えを行えるようにする。
  カバー未設定でも下書き保存でき、公開時には必須とする。
  [合意した設計](../../docs/superpowers/specs/2026-10-24-cover-image-design.md) を参照。
  現状は保存済み記事の「保存してメディアを追加」で挿入先「カバー画像」を選ぶ機能があり、
  新規作成時にはまだ URL・幅・高さが必須。本文のフルプレビューと併せ、M6の範囲外。
- **外部を伴う受入が未実施**: 実 RustFS/R2 への昇格 (ignored テスト)、管理UI→公開→git→Netlify→GMB
  の全経路 E2E、実 R2 へのメディア昇格。実 GMB では 2026-10-24 に STANDARD 投稿 1 件で
  API 疎通と表示のみ確認済み (scratch runner からの送信で、下書き)。実行には対象記事と
  実行許可のユーザー確認が必要。
- 共有ライブラリの内部エラー応答型 (`pub(crate)`) に未使用フィールド warning が 3 件残る
  (`code` / `error_type` / `sub_error_code`)。M6では既存の応答型を変更せず保持した。

## 静的アセット

`static/daisyui.css` は [daisyUI 4.12.24](https://www.npmjs.com/package/daisyui/v/4.12.24) の
`dist/full.min.css` をそのまま同梱したもの (CDN 非依存・ビルド不要)。
更新する場合:

```bash
curl -sL -o static/daisyui.css https://cdn.jsdelivr.net/npm/daisyui@4.12.24/dist/full.min.css
```

## 公開と再開 (M5)

詳細ページの「公開・GMB」から操作します。公開すると参照中の管理メディアをR2に昇格し、記事をdraftsからpostsに移します。git commit/pushとGMB投稿はそれぞれ任意です。

- git反映はmainブランチだけで実行し、他のstage済みファイルがあれば停止します。記事と追跡済みの移動元削除だけをcommitし、pushに失敗した場合も同じcommitから再開します。
- `state/publish/<slug>.json` に操作ID、入力/変換後の内容hash、commit、送信状況を保存します。破損state/manifestは空扱いせず停止します。操作中のstateは削除しないでください。
- GMBは本番反映の確認チェックが必要です。通常は記事公開→Netlify反映確認→「GMBだけ投稿する」の順で操作します。canonicalは現在のサイトと同じ `https://officeiko.co.jp` です。
- GMBは送信前にin_flightをディスクへ同期します。中断・タイムアウトはunknownとなり自動再送しません。Google管理画面を確認し、未投稿の場合だけ明示的に再試行します。doneの操作は再送しません。
- 公開済み記事の編集・削除も任意のgit反映を選べます。git失敗時は結果画面の再試行ボタンで再開できます。記事変更自体は保存済みです。
- メディアの一部が昇格済みでも、再開時は残りだけ転送し、すべて完了してから画像参照URLを変換します。管理外URL、本文の単なるURL表記、似たprefixの画像URLは書き換えません。
- プロセス内の操作は1つのwrite lockで直列化します。他のプロセス/エディタ/gitコマンドから同時に同じ記事やindexを変更しない運用を前提とします。

GMBライブラリは隣接リポジトリ `../../../gmb-event-poster` をpath依存します。STANDARD投稿・期限更新・reqwest rustls移行を含む同時変更が必要です。実投稿テストは自動テストに含みません。対象記事と実行許可を確認してから実施してください。

追加ルート: `GET/POST /posts/{slug}/publish`、`POST /posts/{slug}/gmb`、編集/削除のgit再試行 `POST /git/{id}/{slug}`。

公開状態の表示は読み取り専用です。in_flightからunknownへの復旧は書き込みロック下でのみ行います。編集/削除のgit反映は記事を変更する前に意図と期待内容を保存し、中断後は一覧の「未完了のgit反映」から再開できます。同じslug・同じ内容でも、削除後に新しい下書きとして作り直した記事には新しい操作IDを使います。
