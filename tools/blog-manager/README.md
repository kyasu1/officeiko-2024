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
| GET | `/static/*` | 静的ファイル |

解析できない記事・slug が不正な記事は `/posts/{slug}` に載らないため、状態 + ファイル名で開く。
slug 空間とファイル名空間を混ぜないことで、`slug=shadowed` の正常記事と `draft/shadowed.md` の
壊れた記事が併存しても互いを隠さない。

## 同時編集・誤操作への対策

- **書き込みの直列化**: 作成・更新・削除はプロセス内のグローバルロックで直列化する
- **楽観ロック**: フォームは読み込み時の内容ハッシュ (`expected_revision`) を hidden で持ち、
  保存時にディスクの内容が変わっていれば「他の編集が先に保存されました」として拒否する
  （二重送信・別タブからの上書きを防ぐ）
- **公開済み記事の不変条件**: slug とカテゴリは変更できない（URL と GMB のリンクを守るため）。
  フォーム側で readonly/disabled にし、リポジトリ層でも拒否する
- **上書きしない作成**: 新規作成は `create_new` で既存ファイルを上書きしない。slug は全記事で一意
- **削除はゴミ箱へ**: ファイルは `.trash/` に `YYYYMMDDHHMMSS-{status}-{filename}` で退避し、復元できる

作成・編集・削除・公開は M3 以降で追加する。

## テスト

```bash
cargo test
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

## 静的アセット

`static/daisyui.css` は [daisyUI 4.12.24](https://www.npmjs.com/package/daisyui/v/4.12.24) の
`dist/full.min.css` をそのまま同梱したもの (CDN 非依存・ビルド不要)。
更新する場合:

```bash
curl -sL -o static/daisyui.css https://cdn.jsdelivr.net/npm/daisyui@4.12.24/dist/full.min.css
```
