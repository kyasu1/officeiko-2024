# 実装計画: Blogカテゴリ追加 + ローカル記事管理CRUDアプリ + GMB連携 (v8)

- 対象リポジトリ: `/Users/yako/Projects/officeiko-2024` (elm-pages 3.x / Netlify 静的サイト)
- 参考ライブラリ: `/Users/yako/Projects/gmb-event-poster` (Rust / Google My Business 投稿ライブラリ)
- バージョン: v8 — codex レビュー (v7 軽微な記載修正: 記事件数8件 / promoted 定義 /
  RustFS URL規約の誤読防止) を反映

## 0. 確定事項

| # | 項目 | 決定 |
|---|------|------|
| 1 | URL設計 | **案B**: `/blog`(一覧) + `/blog/:slug`(詳細) を新設。`/post/:slug` は News 限定に変更 |
| 2 | CRUDアプリ配置 | `officeiko-2024/tools/blog-manager/` (同一リポジトリ内) |
| 3 | GMB投稿タイプ | `topicType: STANDARD` (画像 + 文章 + サイトリンク) |
| 4 | 公開フロー | 下書き → 「公開」ボタン。git commit/push はチェックボックスで任意実行 |
| 5 | `/posts` 一覧 | 現状維持(全記事)。category バッジ表示を追加 |
| 6 | 既存slugの不整合 | **修正を許可** (ユーザー決定): ファイル名・slug を正しく直し、旧URLは 301 保護 |
| 7 | メディア管理 | **下書き/開発は RustFS (S3互換)、本番は Cloudflare R2**。下書きメディアは公開時に R2 へ昇格 |
| 8 | RustFS エンドポイント | `https://rustfs.mf.officeiko.co.jp` (S3互換 — x-amz-request-id 応答を確認済み) |
| 9 | 既存記事の取り込み | **既存8記事すべてを管理対象に含める** (ユーザー決定)。`category: "post"` の記事は存在しない (8件全て news/blog、実測確認済み) |

### 0.1 判明した重要事実
- **既存記事は全て News ではない**: `content/posts/fake-site-alert.md` は `category: "blog"`。
  `app/Route/Index.elm` の「詐欺販売サイトに関するご注意」バナーも `/post/fake-site-alert` を参照。
- **filename ≠ slug の実例**: `content/posts/summer-vactaion-2025.md` の slug は `winter-vacation-2025`。
  → **データの単純な間違いとして M1 で修正する** (§1.6)。アプリの原則「無断 rename しない」は維持しつつ、
  明示的なデータ修正はこの1回のみ。
- `image.officeiko.work` は Cloudflare 配信を確認 (server: cloudflare / cf-ray)。
  ローカル rclone には R2 remote 未設定 → R2 資格情報は `tools/blog-manager/.env` で与える。

## 1. サイト側: Blogカテゴリ対応 (elm-pages)

### 1.1 前提(現状)
- `src/Post.elm` は `Blog` カテゴリを実装済み: `categoryDecoder` が `"news"` / `"blog"` を受理、
  `blogPosts = getPosts { limit = 8, category = Just Blog }` も定義済み。
- `Post.elm:51` の Glob は `content/posts/` 固定 → `content/drafts/` は現状の対象外 (codex 確認済み)。
- `Category(..)` は現行 module で export されていない → 新ルートで `Just Blog` / `Just News` を
  使うため export が必要。
- `getAllPosts` は `limit = 100` → preRender の全件列挙には使えない (101件目以降が生成されない)。
  **全件列挙と一覧の件数制限は分離する**。
- ルートモジュール規約 (`.elm-pages/RouteBuilder.elm` 生成ドキュメント準拠):
  - 静的ルート: `RouteBuilder.single { head, data } |> RouteBuilder.buildNoState { view }`
  - 動的ルート: `RouteBuilder.preRender { head, pages, data } |> RouteBuilder.buildNoState { view }`
  - 既存 `script/src/AddRoute.elm` / `AddStaticRoute.elm` (elm-codegen スキャフォルダ) 利用可。

### 1.2 新規ファイル
| ファイル | 内容 |
|---|---|
| `app/Route/Blog.elm` | Blog一覧。`RouteBuilder.single`、`data = Post.getAllPosts (Just Blog)` |
| `src/Layout/Blog.elm` | 一覧レイアウト。`Layout.Posts` を流用し hero「ブログ」+ category バッジ + 画像カード |
| `app/Route/Blog/Slug_.elm` | Blog詳細。`RouteBuilder.preRender`。`pages` は **Blog カテゴリの全 slug** |
| `content/posts/<sample>.md` | 動作検証用サンプル blog 記事 1件 (`category: "blog"`) |

### 1.3 変更ファイル
| ファイル | 変更 |
|---|---|
| `src/Post.elm` | ① `Category(..)` を export。② `postFromCategorySlug : Category -> String -> ...` を追加(既存 `postFromSlug` 置換)。③ 全件列挙用に無制限取得関数を追加 (`getAllPostsUnlimited` 相当。一覧用の limit 付き取得と分離) |
| `app/Route/Post/Slug_.elm` | `pages` / `data` を **News のみ**に限定 |
| `app/Route/Index.elm` | ① ブログカードのリンクを `Route.Blog__Slug_` に。② 「詐欺販売サイト」バナー(fake-site-alert は blog)も `Route.Blog__Slug_` に。リンク先は記事の category で分岐する共通ヘルパー推奨 |
| `src/Layout/Posts.elm` | category バッジ (`News` / `Blog`) 追加。**全記事一覧のリンク先も category で分岐** (codex P1) |
| `src/Layout/Post.elm` | (任意) 詳細ページにも category バッジ表示 |
| `netlify.toml` | 旧URL保護の 301 リダイレクト (2件): `fake-site-alert` と `winter-vacation-2025` (§1.6) |

### 1.4 SEO / head
- 各新ルートに `Seo.summary` + `Seo.article` (既存 `Route/Post/Slug_.elm` と同型)。
- canonical: `https://www.officeiko.co.jp` (`src/Settings.elm`)。
- Blog詳細のOG image は frontmatter `coverImage` を使用。

### 1.5 検証
- `npm run build` → `dist/blog/index.html`、`dist/blog/<slug>/index.html` 生成を確認。
- `/post/:slug` の preRender ページ一覧から blog slug が除外されていることを確認。
- リンク分岐の確認: Index バナー・Layout.Posts の fake-site-alert が `/blog/fake-site-alert` を指すこと。
- slug 修正後、slug `summer-vacation-2025` のページが `/post/summer-vacation-2025` に生成されること。
- `npx elm-review` 通過。
- 301 リダイレクトは Netlify デプロイ後に実URLで確認 (`curl -I`)。

### 1.6 既存データの修正 (ユーザー許可済み / M1 で実施)
- `content/posts/summer-vactaion-2025.md` → **`content/posts/summer-vacation-2025.md`** に rename
- frontmatter slug: `"winter-vacation-2025"` → **`"summer-vacation-2025"`** (title「夏季休業」に一致)
- 301: `netlify.toml` に `from = "/post/winter-vacation-2025"` → `to = "/post/summer-vacation-2025"`
  (旧 slug は GMB 等の外部から参照されている可能性があるため保護。リポジトリ内参照は無し — 確認済み)
- slug 変更対象の `publishedOn: "2025-07-01"` 等その他の frontmatter は変更しない

## 2. 記事管理CRUDアプリ (Rust + axum, rustlsのみ)

### 2.1 配置と構成
```
officeiko-2024/tools/blog-manager/
├── Cargo.toml
├── .env                  # gitignore 対象 (GMB_* / R2_* 等)
├── .gitignore            # target/, .env, .trash/, state/
├── templates/            # askama テンプレート (base / list / form / detail / publish-result)
├── static/               # DaisyUI ビルド済みCSSをベンダー (CDN非依存)
└── src/
    ├── main.rs           # ルータ構築・起動 (bind 127.0.0.1, PORT env, default 3001)
    ├── state.rs          # AppState { content_dir, repo_root, gmb, r2, publish_locks }
    ├── model.rs          # FrontMatter / PostFile / Category / PublishState / Validation
    ├── repository.rs     # md読み書き・一覧・移動・slugユーティリティ (slug→実ファイル解決)
    ├── media.rs          # R2アップロード (multipart受付・検証・寸法検出・SigV4 PUT)
    ├── publish.rs        # 公開ステートマシン (ファイル移動→git→GMB) + state/<slug>.json 管理
    ├── handlers.rs       # CRUD + publish/retry + media ハンドラ
    ├── gmb.rs            # gmb_event_poster へのアダプタ (STANDARD投稿)
    └── error.rs
```

### 2.2 依存 (rustls-only ポリシー)
| クレート | 指定 |
|---|---|
| `axum` 0.8 + `tokio` | HTTPサーバ (localhostのみ、TLS不要)。`multipart` feature (media 用) |
| `reqwest` 0.12 | `default-features = false, features = ["json", "rustls-tls"]` |
| `jsonwebtoken` 9.3 | ring バックエンド (openssl不要) — gmb-event-poster と共通 |
| `rusty-s3` | S3互換 (R2) SigV4 署名の最小実装。HTTPは reqwest (rustls) と組合せ。aws-sdk 非使用 |
| `image` 0.25 | アップロード画像の寸法検出 (pure Rust, openssl不要) |
| `mime_guess` | アップロード時の Content-Type 判定 |
| `askama` | サーバレンダテンプレート |
| `serde` / `serde_json` / `serde_yaml` 0.9 | frontmatter シリアライズ (未知キーは `serde_yaml::Value`) |
| `chrono`, `dotenvy`, `thiserror`, `regex` | ユーティリティ |
| `gmb-event-poster` | `path = "../../../gmb-event-poster"` (path dependency) |

**検証ゲート (M6)**:
- `cargo tree -e features` で `native-tls` / `openssl-sys` の流入が 0件であること。
  (`cargo tree -i openssl-sys` は「存在しない」場合も非zero終了するため、
  **依存解決失敗と"存在しないこと"を区別して**解釈する — codex P2)
- reqwest 0.12 + jsonwebtoken(ring) の併用で両 crate を `cargo check` / `cargo test`。
- 注記: default-features=false により HTTP/2 もデフォルトから外れる。rustls-tls は webpki roots
  (OS 追加CAを参照しない) — 企業プロキシ等の環境差がある場合は注意 (codex P2)。

### 2.3 データモデル
- データソースはファイルのみ (DBなし):
  - 下書き: `content/drafts/*.md` (サイトの Glob 対象外)
  - 公開済み: `content/posts/*.md`
  - ソフト削除: `tools/blog-manager/.trash/*.md`
- **`PostFile` は元ファイルの path を必ず保持**。slug→実ファイルの解決はインデックス (Dict path)
  経由で行い、**slug から filename を組み立てない**。既存記事の filename を無断 rename しない
  (例外: §1.6 の明示的な1回限りのデータ修正)。
- 新規作成ファイル名は slug から生成してよい (新規のみ)。
- `FrontMatter` 構造体: 既存スキーマと同一 + **ネスト型 (coverImage) にも `#[serde(flatten)] extra: serde_yaml::Value`
  相当の保護**を適用 (トップレベルのみの flatten では内部の未知キーが落ちる — codex P2)。
- シリアライズ注意 (Elm デコーダとの整合):
  - `alternativeText` は **常に出力** (None 時は `null`)。`skip` すると Elm の `JD.field` が欠落で失敗。
  - `tags` も常に出力。空 `[]` は既存どおり。**非空 tags は Elm 側が `{attributes: {name, slug}}` 形式を
    要求する** (`tagDecoder` は `JD.at ["attributes","name"]`) — v1 ではタグ編集UIを限定的にし、
    出力形式はこの legacy 形式に合わせる。
- YAML 正規化の限界を明記: コメント / キー順 / クォートは元通りにならない。**本文は frontmatter 境界だけを
  処理し、バイト単位でそのまま保持**。
- フォーム編集は「ディスクから読んだ値」にフォーム項目のみを適用して書き戻す (新規 FrontMatter をゼロから
  組み立てない — codex P2)。
- slug: `^[a-z0-9][a-z0-9-]*$`。posts + drafts 全体で一意。**公開済み記事の slug は編集不可**
  (例外は §1.6 のみ、手作業)。日本語タイトルからの自動生成不可 → slug は手動入力必須、空欄補完 `post-YYYYMMDDhhmm`。
- 書き込みは**一時ファイル + rename の atomic write**。公開処理の重複チェックと移動は **slug 単位の排他ロック**
  (`publish_locks`) で直列化し、同時 publish / 二重送信で既存記事を上書きしない (codex P2 受入条件)。

### 2.4 画面 / エンドポイント (DaisyUI 最小構成)
| Method | Path (HTTP上のURL) | axum 0.8 実装構文 |
|---|---|---|
| GET | `/` | `/` |
| GET | `/posts/new` | `/posts/new` |
| POST | `/posts` | `/posts` |
| GET | `/posts/:slug` | `/posts/{slug}` |
| GET | `/posts/:slug/edit` | `/posts/{slug}/edit` |
| POST | `/posts/:slug` | `/posts/{slug}` |
| POST | `/posts/:slug/delete` | `/posts/{slug}/delete` |
| POST | `/posts/:slug/publish` | `/posts/{slug}/publish` |
| POST | `/posts/:slug/gmb` | `/posts/{slug}/gmb` (GMB単独操作) |
| POST | `/media/:slug` | `/media/{slug}` (multipart, メディアアップロード) |
| GET | `/static/*` | `/static/{*path}` |

- **axum 0.8 の実装パターンは `/{param}` / `/{*path}`**。旧 `:slug` / `*path` 表記を Router に渡すと panic
  する (codex P2 / 公式: https://docs.rs/axum/latest/axum/struct.Router.html)。
- 認証: 無し (127.0.0.1 bind のみ)。将来必要になれば basic auth。
- **HTML フォームの入れ子は不可** のため、記事編集フォームとメディア upload フォームは**別 `<form>`**
  とする (§2.4.1 の未保存編集保護を参照)。
- UI: DaisyUI (`card`, `table`, `badge`, `btn`, `navbar`, `alert`)。JS不使用、form POST + リダイレクト。


### 2.4.1 未保存編集の保護 (upload と本文の分離問題)

別 `<form>` でメディアを upload すると、記事編集フォームの本文・タイトル・alt・挿入先選択値は
**送信されず失われる** (HTML の制約)。この対策:

- upload フォームの submit 前に、記事編集フォームの入力値を **サーバ側の編集セッションに保存**
  (v1 は JS なし: 「メディアを追加」ボタンを押すと、**まず現在の記事フォームの値を POST して
  編集セッションを保存し、続けて upload フォームを表示** する2段階遷移にする)。
- upload 完了/失敗時は、編集セッションの値を復元した状態で記事編集フォームを再描画する。
- エラー時も同様にセッション値を保持した再描画を行う (テスト必須: §5)。

編集セッションの保存先: `state/edit-session/<slug>.json` (操作単位、明示的に「保存」または
「破棄」で削除)。**同一記事の同時編集 (複数タブ) は衝突の原因となるため、フォームに
`edit_session_id` (uuid) を持たせて分離し、id 不一致時は「他のセッションが編集中」として
明示的に拒否する** (codex 第2回残り 反映)。

### 2.5 公開フロー (`POST /posts/:slug/publish`) — ステートマシン化
**state モデル (codex 第2回 P1 反映)** — `tools/blog-manager/state/` 配下:

- `state/<slug>.json`: **operation 単位**の記録
  `{ slug, operation_id (uuid), revision (content sha256), file_moved, committed, pushed,
  gmb: pending|in_flight|done|unknown, media_promoted, updated_at }`
- `state/media/<slug>.json`: メディア manifest (§2.6)。`promoted` は key 単位で管理し、
  **記事が実際に参照する key 集合が全て promoted なら**集約値 `media_promoted=true`。
- **operation_id / revision**: 同一 slug でも再編集・削除→再作成を区別できるよう必須。
  古い完了状態の誤適用を防ぐため、操作の開始時に発行し、revision hash で無効化判定を行う。
- **revision の定義 (codex 第2回残り 反映)**: `revision` は「入力時の記事ファイルの sha256」。
  メディア昇格で記事 URL が置換されると内容が変わるため、state に **`input_revision`** と
  **`promoted_revision`** (昇格後 = 昇格で置換した記事ファイルの sha256) を保持する。
  外部編集との区別: 現在のファイル hash が `promoted_revision` と一致すれば「自分の変換」とみなし、
  state を無効化しない。`promoted_revision` が無い/不一致かつ input_revision とも不一致の場合のみ
  外部編集として manifest を再評価する。
- **参照メディア集合と upload 済み manifest の区別**: manifest は「その記事で upload された全 key」の
  履歴。公開時の昇格対象は**記事ファイルが実際に参照している key 集合**のみとし、
  挿入を取り消した未使用画像 (manifest に残るが記事が参照しない key) の昇格失敗で公開を
  妨げない (昇格対象から除外)。
- **media_promoted の無効化**: 参照メディア集合に `promoted=false` の key が1つでもあれば false。

ステップと堅牢化 (codex P1 反映):

0. **メディア昇格** (§2.6): 記事が実際に参照している key 集合のうち `promoted=false` のものを
   RustFS → R2 に昇格し、記事内の RustFS URL を R2 URL に置換 (frontmatter + body、atomic write)。
   完了後 `media_promoted=true`。失敗はここで停止 (draft も URL 置換前のまま残存)。
1. **ファイル移動** — `content/drafts/<file>` → `content/posts/<file>` (実ファイル path 経由、atomic)。
   完了後 `file_moved=true`。失敗はここで停止 (draft は残存)。
2. **git commit** (チェックボックス ON の場合のみ):
   - cwd を **repo root に固定** (content_dir から導出)。
   - **現ブランチが `main` かつ非 detached HEAD** であることを確認 (そうでなければ中断して結果画面に表示)。
   - **target 以外の staged 変更が既にある場合は拒否** (`git status --porcelain` を確認、
     他の意図しないファイルを commit に混入させない)。
   - 対象記事のみ commit: `git add content/posts/<file>` + **draft が git 追跡済みなら移動元の削除も
     同時に stage** (`git add content/drafts/<file>`) — 追跡済み draft の削除を commit しないと下書きが復活する。
   - 完了後 `committed=true`。
3. **git push** (checkbox ON): `git push origin main` (HEAD を push)。完了後 `pushed=true`。
   **push 成功 ≠ deploy 完了** である旨を UI に明記。
   **git 操作は共有 index 全体の排他** (tokio のグローバル Mutex) の下で実行し、
   slug 別ロック (§2.3) と併用する。
4. **GMB投稿** (チェックボックス ON の場合のみ):
   - **送信直前に `gmb=in_flight` を atomic に永続化** (副作用の発生前に意図を記録)。
   - §3 を実行し、応答を受け取ったら `searchUrl` を state に記録 (`gmb=done`)。
   - タイムアウト・レスポンス喪失・プロセス終了で `in_flight` のまま残ったものは、再起動後に
     **`gmb=unknown` として扱い、自動再送しない** (create API に requestId は無く、
     重複投稿を防ぐため手動確認後に明示再試行)。
5. **完了画面**: 各ステップの成功/失敗/unknown と GMB searchUrl、次の推奨アクションを表示。

- **失敗からの再開**: ファイル移動済み・commit済み・push済みを state に持つため、**公開済み記事一覧から
  失敗ステップのみ再試行できる** (publish エンドポイントの step1 が draft 必須でも再開可能にする — codex P1)。
- **クラッシュ境界の照合**: 「副作用の成功 → state 保存」の間にクラッシュした場合を想定し、
  再開時は **state と実態 (対象ファイルの存在・対象 commit・メディア manifest) を照合** して
  整合性を確認する。不整合 (副作用成功 / state 未記録) はクラッシュとみなして安全側
  (unknown / 未完了) に倒し、明示再試行とする。
- **git OFF / GMB ON の組合せ**: サイト未反映のまま外部投稿になる点を UI で警告。
- **GMB単独操作** (`POST /posts/:slug/gmb`): 本番反映を確認した後に投稿できるよう、公開済み記事一覧にも
  常設ボタンを用意 (推奨運用: 公開 → デプロイ確認 → GMB投稿)。
- **CTA URL は category 依存**: news → `https://www.officeiko.co.jp/post/<slug>`、
  blog → `https://www.officeiko.co.jp/blog/<slug>` (News も管理対象のため — codex P1)。
- **公開済み記事の編集/削除**: 保存・削除も次の build/push で本番反映されるため、
  編集/削除フォームにも git commit/push チェックボックス (デフォルトOFF) を設け、
  その場合の commit 対象は変更/削除された記事ファイルのみに限定。
- **公開済み記事へのメディア追加**: §2.6.1 を参照 (RustFS に置いた新規メディアを
  保存時に昇格してから保存する一体操作)。

### 2.6 メディア管理 — v6 で単一仕様に統一

**目的**: ブログ本文中の画像 (既存慣習の `<post-image>`) と frontmatter `coverImage` の管理。

**2バックエンド構成** (ユーザー決定):

| バックエンド | 用途 | 特徴 |
|---|---|---|
| **RustFS** (`https://rustfs.mf.officeiko.co.jp`) | **下書き / 開発** | S3互換、非公開を前提。サイクル回し放題、公開影響ゼロ |
| **Cloudflare R2** (`https://<ACCOUNT_ID>.r2.cloudflarestorage.com`, 公開 base `https://image.officeiko.work`) | **本番 (公開)** | 既存 `coverImage` / `<post-image>` が参照。サイト・GMB からアクセス |

**配置キーの対応** (同一 key で両バックエンドに置く):
- key: `blog/<slug>/<sanitized-filename>-<timestamp>.<ext>`
- RustFS: `https://rustfs.mf.officeiko.co.jp/<bucket>/blog/<slug>/...`
- R2: `https://image.officeiko.work/blog/<slug>/...`

**ライフサイクル**:
1. **下書き中**: メディアは RustFS にアップロード。記事 frontmatter/body の URL は **RustFS 公開URL**
   (※ Elm の Image デコーダは `Url.fromString` で absolute URL を受理。RustFS URL はバケットへのアクセス制御
   に依存 — 非公開の場合はアップロード時に仮URLとして扱い、公開時に R2 URL へ置換する運用を推奨。
   より確実なのは **「URL は常に R2 形式で記事に記載し、物理配置だけを管理」する方式**: 下書き中は
   R2 URL を書き込むが実体は RustFS にあり、表示はローカルで動作確認できない。ここでは前者
   (RustFS URL を記事に入れ、公開時に置換) を採用 — §6 リスク参照)。
2. **公開時 (§2.5 publish)**: **step 0 としてメディア昇格**を追加:
   - 記事が参照するメディアキーを走査 (RustFS URL の抽出)
   - RustFS から GET → R2 に PUT (同一 key、同一 Content-Type)
   - 記事内の RustFS URL を R2 URL に置換 (frontmatter coverImage.url と body の `<post-image>` 両方)
   - 昇格完了後 `media_promoted=true` を state に記録 (再試行対象)
   - RustFS のオブジェクトは残す (手動削除は許容、誤削除防止)
3. **公開後**: 記事のメディアは全て R2 (公開URL)。RustFS 側の削除は v1 では自動化しない。

**実装詳細**:

**記事内のメディア表現 (規約 / codex 第2回残り 反映)**
- 適用範囲を限定: **「draft の新規管理メディアは RustFS、公開済みの既存参照は R2 を維持」**。
  既存記事 (公開済み) が参照する R2 URL は変更せず、**R2 → RustFS への逆変換はしない**。
- 新規管理下メディアは「**key**」で同一視。記事ファイルには **`RUSTFS_PUBLIC_BASE/<key>`** 形式のURLを
  書き込む (公開時に `RUSTFS_PUBLIC_BASE` → `R2_PUBLIC_BASE` へ **R2 へ昇格変換** できるよう、
  形式を固定)。
- **本文バイト保持の原則の例外**: 明示的なメディア URL 変更 (昇格置換・手動編集) は対象外。
- 置換・解決は、設定の (origin, bucket, prefix) との**厳密一致**で行い、単純な文字列置換に依存しない。
- 本文の対応形式: **`<post-image url width height alt>` と Markdown画像 `![alt](url)`** 両方を走査対象とする
  (既存記事は `<post-image>` が主だが、Markdown画像も許容して吸収する)。
- frontmatter `coverImage.url` も置換対象。
- 管理下メディアの一覧 (manifest) を **`tools/blog-manager/state/media/<slug>.json`** に保持:
  `{ key, content_type, width, height, alt, created_at, promoted: bool, promoted_at }`。
  各レコードの `promoted` フラグで昇格済みを管理し、**key 単位で昇格・再昇格**できる。
  `media_promoted` (state/<slug>.json) は集約値 (**記事が実際に参照する key 集合が全て promoted** なら true) で、
  revision hash と併せて無効化判定に使う (後述 §2.5.1)。

**アップロード経路** (JSなし form POST で完結)
1. 編集フォーム内に「メディアアップロード」フォーム (file + alt + 挿入先: 本文/カバー) を併設。
   **HTML フォームの入れ子は禁止**のため、**記事編集フォームと upload フォームは別 `<form>`** とする。
   別フォームは編集中の本文を送信しない → **未保存の本文が消える問題**への対策として、
   upload フォームの submit 直前に **本文・タイトル・alt・選択値をサーバの編集セッションに保存**
   する処理を挟む (§2.4.1 参照)。
2. `POST /media/{slug}` (multipart) で受付。
   検証: mime (`image/jpeg|png|webp|gif` via mime_guess) + サイズ上限 10MB (`DefaultBodyLimit`)。
3. `image` crate で寸法検出 (width/height)。Elm デコーダが int を要求するため必須。
4. **rusty-s3 で SigV4 署名 → reqwest (rustls) で RustFS へ PUT**。
   endpoint: `RUSTFS_ENDPOINT`、region `auto` (RustFS の path-style/virtual-host は設定に依存、
   実資格情報で確認)。
5. key は `blog/<slug>/<sanitized-filename>-<timestamp>.<ext>` (既存の flat key には触れない)。
6. 記事への挿入URL = `RUSTFS_PUBLIC_BASE/<key>` (例: `https://rustfs.mf.officeiko.co.jp/<bucket>/blog/<slug>/img.jpg`)。
   **記事には R2 URL を書き込まない** (下書き段階では RustFS URL のみ)。
7. 編集セッションを復元した状態でフォームを再描画し、挿入先に応じて:
   - 本文 → `<post-image url width height alt>` を body に追記した状態で再描画
   - カバー → `coverImage {url,width,height,alternativeText}` を設定した状態で再描画
   失敗時もセッションの値を保持したままエラーメッセージ付きで再描画する (テスト必須)。

**昇格 (publish step 0)** — publish 実行時のみ (§2.5 ステップ0 と対応):
- manifest を走査して `promoted=false` の key を抽出。
- 各 key について: GET(RustFS) → PUT(R2, 同一 key, 同一 Content-Type)。**GET/PUT が全 key で
  完了するまで本文の書換えは行わない**。途中失敗の場合は**draft を維持**し、完了済みの key だけ
  manifest を `promoted=true` に更新して中断 (再開は失敗キーのみ)。
- 全 key 昇格後に記事ファイルの URL を一括置換 (atomic write)。置換は frontmatter coverImage.url と
  body の両方。`media_promoted=true` を state に記録。
- RustFS のオブジェクトは残す (手動削除は許容、誤削除防止)。

**公開済み記事へのメディア追加** (§2.6.1 に詳細):
- 追加したメディアはまず RustFS に置き (manifest `promoted=false`)、**「公開済み記事の保存 = 昇格 + 保存 +
  git」** の一体操作で R2 へ昇格させる。

**非公開 RustFS のプレビュー**:
- RustFS を非公開に保つ場合、ブラウザは RustFS URL を直接表示できない → **管理アプリ側で
  認証付き GET 中継** (`GET /media-preview/{*key}`、key は `blog/<slug>/...` とスラッシュを含むため
  axum 0.8 のキャッチオール構文、127.0.0.1 bind 前提) を提供し、
  編集フォームのプレビューはこの中継URLを使う。記事ファイルには資格情報や presigned URL を
  **埋め込まない**。

- 既存メディア (R2 既存キー) は触らない (読み取り URL 手入力欄は維持)。
- v1 では RustFS / R2 双方に削除機能を設けない (誤削除防止、孤児は許容)。
- `.env` 追加キー (gitignore 必須):
  - `RUSTFS_ENDPOINT / RUSTFS_BUCKET / RUSTFS_ACCESS_KEY_ID / RUSTFS_SECRET_ACCESS_KEY /
    RUSTFS_PUBLIC_BASE` (下書き・開発)
  - `R2_ACCOUNT_ID / R2_BUCKET / R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY / R2_PUBLIC_BASE`
    (本番; `R2_PUBLIC_BASE=https://image.officeiko.work`)
- **前提確認 (M4 冒頭)**: 各バックエンドの資格情報で PUT/GET **および公開URLの readback** 動作テスト
  (テンポラリキー)。x-amz-request-id / server:cloudflare の応答は疎通の証拠であって資格情報・
  SigV4・公開URLの対応の証明ではないため、実キーで検証する。失敗時は rclone シェルアウトを代替案。
- **作成前 (slug 未定) の upload**: upload には slug が必要 (key 生成のため) → **記事作成画面
  (slug 未確定) では upload 不可** とする。先に記事を作成して slug を確定してから upload
  (作成後は編集画面で upload 可)。slug 未確定のままの画像添付が必要になれば、一時 key 領域
  (`blog/_tmp/<uuid>/...`) も検討可能だが v1 では対象外。

### 2.6.1 公開済み記事へのメディア追加

- 追加したメディアは manifest に `promoted=false` で登録 (RustFS に PUT)。
- **保存ボタンは「昇格 + 保存 + (任意)git」の一体操作**:
  1. まず未昇格の key を R2 へ昇格 (§2.6 の昇格と同じ手順)
  2. 記事ファイルを atomic に保存 (この時点で記事は R2 URL を参照)
  3. (checkbox ON の場合) 変更記事ファイルのみ git commit (§2.5 の hardened git と同じ手順)
- 昇格が失敗した場合は保存を中止 (公開済み記事に RustFS URL を残さない)。
- 既に `media_promoted=true` の記事に画像を追加すると、`media_promoted` は新規 key が未昇格のため
  保存時に再評価され、追加した key のみ昇格対象となる (manifest で管理)。


### 2.7 既存記事の取り込み (v7 追加)

**目的**: 現在 `content/posts/` にある全記事を、新ツールの管理対象として扱う (ユーザー決定)。

**前提 (実測確認)**: 既存8記事 — `fake-site-alert`(blog) / `summer-vacation-2026`(news) /
`summer-vactaion-2025`(news, slug不整合→§1.6で修正) / `temporary-closed-2025-02` /
`temporary-closed-2026-03` / `winter-vacation-2024-2025` / `winter-vacation-2025-2026` /
`winter-vacation-2026-2027` (後4件は news)。`category: "post"` の記事は存在しない
(decoder が受理しないため elm ビルドも破綻する)。

**方針**:
- **初回起動時に `content/posts/*.md` を走査し、管理インデックス (in-memory) を構築**。
  既存記事は「公開済み・R2参照」としてそのまま扱い、**強制的なメディア昇格や URL 変換は行わない**
  (§2.6 の適用範囲)。
- 管理対象にした後の編集/削除は、新規記事と同じルール (§2.4/§2.5/§2.6.1) に従う。
- frontmatter パース失敗の記事は一覧に「要修正」バッジで表示し、壊さず残す (§6 リスク)。
- state/media manifest は初回起動時には存在しない → 既存記事が参照する R2 URL は
  「外部メディア (管理外)」として扱い、昇格対象外。既存記事に**新規メディアを追加した場合のみ**
  manifest を生成して昇格ルールを適用する (§2.6.1)。

## 3. GMB連携 (Google Business Profile)

### 3.1 再利用方式 (codex P1 反映)
- `gmb-event-poster` を **path dependency** として利用 (auth / client / types / error)。
- **gmb-event-poster 側の改修**:
  1. `reqwest = { version = "0.12", default-features = false, features = ["json", "rustls-tls"] }`
     (0.11 → 0.12: `.form` / `.json` / `.text` / `status.as_u16` は同 API で動作、追加 form feature 不要)
  2. **`StandardPost` 型を新設** (`languageCode`, `summary`, `callToAction`, `media`, `topicType: "STANDARD"`)。
     既存 `LocalPost` は `event: Event` 必須かつ `callToAction` フィールド無しのため、
     **EVENT 互換を維持したまま別型**とし、`create_standard_post` メソッドを `GmbClient` に追加。
     (`LocalPost` の optional 化は既存 CLI への影響が大きいので採らない)
  3. **トークン寿命の管理**: `TokenResponse.expires_in` を捨てずに返す (auth.rs は現在 discard)。
     `GmbClient` は (access_token, expires_at) を保持し、期限 - 5分で再取得。
     **JWT の exp (1時間) とアクセストークン寿命 (expires_in) は別物** — expires_in を正とする
     (既存 client は token 文字列のみ保持のため、キャッシュ機能は新規実装)。
- `EventPostBuilder` (EVENT) はそのまま。`StandardPostBuilder` を新規追加 (builder の流儀に沿う)。

### 3.2 STANDARD 投稿ペイロード (想定)
```json
{
  "languageCode": "ja-JP",
  "summary": "<本文冒頭からの抜粋 (<= 1500字, markdown記法は除去したプレーンテキスト)>",
  "topicType": "STANDARD",
  "callToAction": {
    "actionType": "LEARN_MORE",
    "url": "<category に応じた公開URL>"
  },
  "media": [{ "mediaFormat": "PHOTO", "sourceUrl": "<coverImage.url>" }]
}
```
- **訂正 (M6 確認)**: `mediaFormat` は `IMAGE` ではなく **`PHOTO`**。実装 (`gmb-event-poster/src/builder.rs`
  の EVENT/STANDARD 両ビルダー) と 2026-10-24 の実 API 疎通テストで `PHOTO` を確認済み。
- 画像: frontmatter `coverImage.url` (新規記事は R2 公開URL) を使用 — 全て公開ホスト済み。
- 認証: 既存 Domain-Wide Delegation (service account JWT, scope `business.manage`) をそのまま利用。
- `.env`: `tools/blog-manager/.env` に `GMB_SERVICE_ACCOUNT_EMAIL / GMB_PRIVATE_KEY / GMB_USER_EMAIL /
  GMB_ACCOUNT_ID / GMB_LOCATION_ID` (+ `PORT`, `CONTENT_DIR`, `R2_*`) を配置。
- 参考: https://developers.google.com/my-business/reference/rest/v4/accounts.locations.localPosts/create

## 4. 実装順序 (Milestones)

| Phase | 作業 | 完了条件 |
|---|---|---|
| M1 | サイト側Blog対応 (§1.2, §1.3, 301) + **既存データ修正 (§1.6)** + サンプル記事 | `npm run build` 成功、`/blog` と `/blog/:slug` が生成、リンク分岐確認、slug修正+301反映、elm-review 通過 |
| M2 | CRUDスケルトン (axum起動・一覧・詳細・frontmatter読み書き/atomic write) | 一覧が posts + drafts を表示、**既存8記事を管理対象として取り込み**、正しく表示される (§2.7) |
| M3 | CRUDフォーム完成 (作成/編集/削除/検証/排他) | draft 保存→編集→trash移動が動く、単体テスト緑、同時 publish の上書き防止テスト緑 |
| M4 | メディア管理 (§2.6: 両バックエンド接続確認 → multipart → 寸法検出 → SigV4 PUT → **RustFSへ**アップロード → 記事へRustFS URL挿入 → 編集セッション復元 → 公開時昇格 → R2 URL置換 → 非公開中継プレビュー) | ローカルファイル→RustFS→記事挿入→(下書きは中継でプレビュー)→公開時にR2昇格→URL置換が動く |
| M5 | GMB連携 (gmb-event-poster改修 + StandardPostBuilder + publish ステートマシン + git hardening) | 実GMBへSTANDARD投稿成功、失敗ステップの再試行が動く (外部公開を伴うため**受入テスト用記事と実行許可のユーザー確認**後に実施) |
| M6 | 仕上げ (README, .gitignore, TLS監査 §2.2ゲート, cargo test) | 監査・テスト全緑 |

## 5. テスト計画
- Rust 単体:
  - frontmatter シリアライズ/パースのラウンドトリップ — **実在記事を fixture に使用**
    (未知キー・ネスト未知キーの保護、alternativeText/tags の常時出力、body のバイト保持)
  - slug バリデーション・重複検出、slug→実ファイル解決、trash 移動
  - atomic write (一時ファイル + rename)
  - 同時 publish の排他 (2スレッド同時実行で上書きされないこと)
  - メディア: mime/サイズ検証、寸法検出、SigV4 署名と PUT リクエスト構築 (両バックエンドはモック)、
    key のサニタイズ
  - **メディア昇格**: 記事内の RustFS URL 抽出 → GET/PUT (モック) → URL 置換のラウンドトリップ。
    失敗時に state が `media_promoted=false` のまま残り再試行できること
  - **昇格の部分失敗**: 複数 key の途中で失敗し、完了済み key は `promoted=true`、失敗 key のみ
    再試行できること (draft を維持、URL置換は全 key 完了後のみ)
  - **クラッシュ境界の照合**: 「副作用成功 → state 保存前」の終了をシミュレートし、再開時に
    実ファイル/対象 commit/manifest との照合で安全側 (unknown/未完了) に倒すこと
  - **GMB in_flight**: 送信直前の `in_flight` 永続化、再起動後の unknown 化、自動再送しないこと
  - **公開済み記事へのメディア追加**: 昇格+保存+git の一体操作、昇格失敗時は保存中止
  - **未保存編集の保護**: upload 前の編集セッション保存、完了/失敗時の再描画で
    本文・タイトル・alt・選択値が保持されること
  - **非公開中継プレビュー**: 記事ファイルに資格情報/presigned URL が書き込まれないこと、
    中継 URL が動作すること
  - GMB ペイロード組み立て (summary 切り詰め、CTA URL の category 分岐) — 通信はモック
  - publish ステートマシンの遷移と失敗再開 (unknown の扱い含む)
- 統合: `npm run build` (Elm) + `cargo test` (Rust)。
- E2E 手順書: sample記事 → draft作成 → 画像アップロード → 公開 (git checkbox ON) → Netlify反映確認 →
  301確認 → GMB投稿確認。

## 6. リスクと対処
| リスク | 対処 |
|---|---|
| 公開済み記事の slug 変更 → URL / GMBリンク破壊 | 公開済みは slug 編集不可 (例外: §1.6 の明示修正のみ、301で保護) |
| git 操作の混入・誤 push (staged 変更, 非mainブランチ) | repo root 固定、main/非detached 確認、staged 変更の検出・拒否、対象限定 commit |
| 追跡済み draft の削除忘れ → 下書き復活 | 移動元削除も同時に stage/commit |
| 移動後に git/GMB 失敗 → 再開不能 | state/<slug>.json のステップ記録 + 失敗ステップのみ再試行 |
| GMB 重複投稿 (レスポンス喪失後の再送) | unknown 状態の扱いを定義、自動再送しない、手動確認後に明示再試行 |
| git push 成功 ≠ deploy 完了 | UI 注意書き、GMB単独操作で本番反映確認後に投稿可能 |
| R2 資格情報の漏洩 | `.env` gitignore、bind 127.0.0.1 のみ |
| **RustFS メディアが非公開で下書き確認不可** | 管理アプリの認証付き GET 中継でプレビューを提供。記事には資格情報/presigned URL を埋め込まない (§2.6) |
| **メディア昇格失敗 (R2 障害等)** | step 0 で停止。state に `media_promoted=false` のまま残り、再試行可能。公開後の R2 必須条件が保たれる |
| アップロード失敗 / R2 障害 | フォームの内容は失われない (アップロードは独立フォーム、§2.4.1 編集セッションで保護)、再試行可能。接続確認を M4 冒頭で実施 |
| R2 孤児メディア (記事から参照されないオブジェクト) | v1 では許容、削除機能は設けない |
| GMB API 制限 (summary 1500字、投稿頻度) | ペイロード検証と明確なエラー表示 |
| reqwest 0.12 移行の挙動差 (HTTP/2, webpki roots) | §2.2 のゲートで両 crate を check/test、features 監査 |
| YAML 正規化 (コメント・キー順の喪失) | 限界を明記、本文は frontmatter 境界のみ処理して保持 |
| frontmatter 壊れ (YAML 手書き既存ファイル) | パース失敗時は一覧に「要修正」バッジで表示し、壊さず残す |

## 7. codex レビュー反映記録

### v3 (codexレビュー 2026-10-24)

| 指摘 | レベル | 対応 |
|---|---|---|
| fake-site-alert は blog。バナー/一覧リンクの分岐 + 旧URL 301 が必要 | P1 | §1.3 (Index・Layout.Posts の分岐、netlify.toml 301)、§1.5 検証に追加 |
| git 操作の堅牢化 (混入・非main・staged・draft復活) | P1 | §2.5 ステップ2/3 に堅牢化条件を明記 |
| 公開ステップの永続記録・失敗ステップ再試行・GMB unknown 扱い・GMB単独操作・CTAのcategory分岐 | P1 | §2.5 ステートマシン化 + GMB単独エンドポイント + §3.2 |
| LocalPost は event 必須/CTA無し → StandardPost 別型 + client メソッド、token 寿命管理の新規実装 | P1 | §3.1 改修内容を3点に具体化 |
| slug から filename を組み立てない (実例: summer-vactaion-2025.md)、排他・atomic write | P2 | §2.3 受入条件に追加 |
| flatten はネストを保護しない、フォーム編集はディスク値起点、alternativeText/tags 常時出力、実記事roundtrip | P2 | §2.3 / §5 |
| axum 0.8 は `/{slug}` / `/{*path}` 構文 (`:slug` は panic) | P2 | §2.4 表に実装構文列を追加 |
| Category 未 export、getAllPosts limit=100 (preRender 件数問題) | 確認事項 | §1.1 / §1.3 ①③ に反映 |
| reqwest 0.12 で .form は追加 feature 不要、HTTP/2・webpki roots の差分、cargo tree -e features 監査、cargo tree -i の終了コード解釈 | 確認事項 | §2.2 検証ゲートに反映 |

### v4 (ユーザー決定 2026-10-24)

| 決定 | 対応 |
|---|---|
| slug/filename 不整合は「単なる間違い」→ 修正許可 | §0 確定事項6、§1.6 データ修正手順 + 301、§2.3 の原則に例外条項 |
| メディア (画像等) をブログに含めたい。置き場所は Cloudflare R2 (ローカルから API アクセス可能) | §0 確定事項7、§2.6 新設 (rusty-s3 + reqwest rustls、multipart、JSなしフォームフロー) |

### v5 (ユーザー決定 2026-10-24)

| 決定 | 対応 |
|---|---|
| 開発/下書き用ストレージとして RustFS (https://rustfs.mf.officeiko.co.jp) を使用可能 | §0 確定事項7/8、§2.6 を2バックエンド構成に再設計、§2.5 に publish step 0 (メディア昇格) を追加、§2.2/§6 更新、§5 に昇格テスト追加 |

### v6 (codexレビュー第2回 2026-10-24)

| 指摘 | 対応 |
|---|---|
| §2.6 に旧 R2直送仕様が残り矛盾 (upload先・戻すURL・昇格・state・完了条件が2系統) | §2.6 を単一仕様に書き直し (upload→RustFS→publish時に昇格)、§2.5 に step 0 明記、ヘッダ更新 |
| 公開済み記事への画像追加時の昇格経路が未定義 | §2.6.1 新設 (保存=昇格+保存+git の一体操作、失敗時は保存中止)、manifest (state/media/<slug>.json) で key 単位管理 |
| state のクラッシュ境界が未明確 (副作用成功→state保存前の終了) | §2.5 state モデルに operation_id / revision、in_flight 永続化、再起動後 unknown、実態照合を追加 |
| JSなしメディアフォームで未保存編集が失われる (フォーム入れ子不可) | §2.4 注記 + §2.4.1 新設 (別フォーム + サーバ側編集セッション保存)、失敗時再描画テスト |
| 非公開RustFSのプレビュー不能 | §2.6 に認証付き GET 中継を追加、記事に資格情報/presigned URL を埋めない |
| 画像参照を文字列置換に依存 | key 単位 manifest + (origin,bucket,prefix) 厳密一致、対応形式を post-image + Markdown画像に明記 |
| x-amz-request-id / server:cloudflare は疎通の証拠にすぎない | §2.6 前提確認を「PUT/GET + 公開URL readback」までに拡張 |
| 実GMB投稿は外部公開を伴う | §4 M5 に「受入テスト用記事 + 実行許可のユーザー確認」を追加 |

### v7 (codex第2回残り + ユーザー決定 2026-10-24)

| 内容 | 対応 |
|---|---|
| §2.5 番号付きフローに step 0 が無い / 先頭は (v4) のまま | §2.5 に step 0 (メディア昇格) 明記、タイトル/バージョン行を v7 に更新 |
| 「記事は常に RUSTFS URL」↔「公開後は全て R2」の矛盾 | §2.6 適用範囲を「draft 新規=RustFS / 公開済み既存=R2維持」に限定、R2→RustFS 逆変換なし、本文バイト保持の例外を明記 |
| revision=content sha256 は昇格置換で変わる | input_revision / promoted_revision 分離、外部編集誤認防止、参照メディア集合と upload 済み manifest の区別 |
| プレビュールートが `{key}` (スラッシュ混入で不一致) | `/{*key}` (axum 0.8 キャッチオール) に修正 |
| 同一記事の同時編集 (複数タブ) でセッション衝突 | `edit_session_id` をフォームに持たせて分離、不一致時は明示拒否 |
| **ユーザー決定: 既存記事も管理対象に含める** | §0 確定事項9 追加、§2.7 (既存記事の取り込み方針) 新設。既存記事は公開済み・R2参照のまま扱い、強制変換しない |

### v8 (codex v7 軽微な記載修正 2026-10-24)

| 内容 | 対応 |
|---|---|
| §2.7 の列挙は8件 (既存7記事という表記と M2 完了条件を実走査件数に合わせる) | §2.7 前提を「既存8記事」に、M2 完了条件を「既存8記事」に修正 (列挙も news 4件に修正) |
| state 概要の「全key promoted」は後段定義に合わせる | 「記事が実際に参照する key 集合が全て promoted」に揃え |
| RustFS URL 規約の括弧内「逆変換できるよう」は誤読 | 「R2 へ昇格変換できるよう」に修正 |
