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

## 画面 (M2 時点)

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/` | 記事一覧 (公開済み + 下書き、状態・カテゴリ・公開日・slug・ファイル名) |
| GET | `/posts/{slug}` | 記事詳細 (frontmatter / coverImage / 本文 / raw YAML) |
| GET | `/static/*` | 静的ファイル |

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

## 静的アセット

`static/daisyui.css` は [daisyUI 4.12.24](https://www.npmjs.com/package/daisyui/v/4.12.24) の
`dist/full.min.css` をそのまま同梱したもの (CDN 非依存・ビルド不要)。
更新する場合:

```bash
curl -sL -o static/daisyui.css https://cdn.jsdelivr.net/npm/daisyui@4.12.24/dist/full.min.css
```
