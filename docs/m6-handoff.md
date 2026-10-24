# M6 引き継ぎ・検証記録 (仕上げ)

2026-10-24、agmsg経由でcodexからM5 (`4db4f12`) の引き継ぎを受け、piがM6を実施。
作業場所はM5と同じ。元作業ツリーとユーザーの未コミット変更は保持した。

- アプリ: `/private/tmp/officeiko-m5`、ブランチ `codex/blog-manager-m5`
- 共有ライブラリ: `/private/tmp/gmb-event-poster`、ブランチ `codex/blog-manager-standard`
- 隣接 path 依存 `../../../gmb-event-poster` は変更していない

## 検証ゲート (計画 §2.2 / §4 M6)

すべて実行し、結果は以下のとおり。

| ゲート | コマンド | 結果 |
|---|---|---|
| TLS監査 (アプリ) | `cargo tree --locked --offline --manifest-path tools/blog-manager/Cargo.toml -e features` | 解決成功 (1647行)。`native-tls` / `openssl` のヒット **0件** |
| TLS監査 (ライブラリ) | `cargo tree --locked --offline -e features` | 解決成功 (832行)。ヒット **0件** |
| ゲートが有効である確認 | 同上のツリーに `rustls 0.23.46` / `hyper-rustls 0.27.10` が存在 | 0件が「空振り」ではないことを確認 |
| アプリ test | `CARGO_INCREMENTAL=0 cargo test --locked --offline --manifest-path tools/blog-manager/Cargo.toml --target-dir /private/tmp/officeiko-m5-target` | **70 passed / 0 failed / 2 ignored** |
| ライブラリ test | `cargo test --locked --offline` | **5 passed / 0 failed** |
| アプリ fmt | `cargo fmt -- --check` | 通過 |
| アプリ clippy | `cargo clippy --all-targets -- -D warnings` | exit 0 (残 warning はライブラリ由来の3件のみ) |
| ライブラリ fmt | `cargo fmt -- --check` | 修正後 通過 |
| ライブラリ clippy | `cargo clippy --all-targets` | exit 0。既存の未使用フィールド3件のみ |
| サイト build | `npm ci && npm run build` | 成功。`/blog` と `/blog/:slug` 生成を確認 |
| git diff --check | 両リポジトリ | 通過 |

**TLS監査で注意した点**: `cargo tree` に `--target-dir` は渡せない (ビルド系フラグ)。
最初にこれを渡して解決失敗し、`grep` のヒット0件が**偽陰性**になった。計画 §2.2 の
「依存解決失敗と"存在しないこと"を区別」がまさにこのことで、`cargo tree` の exit code と
ツリー行数、そして `rustls` が実際に流入していることを併せて確認し直した。

## 修正した不具合 (2件)

1. **ライブラリの fmt 未準拠** (`gmb-event-poster/src/main.rs:62`)。
   `git blame` では `bff731cb` (2025-10-07) 由来で、M5の変更ではなく**既存の不具合**。
   `cargo fmt` で1箇所のみ整形した。
2. **clippy `items_after_test_module`** (`gmb-event-poster/src/auth.rs`)。
   M5で追加した `mod refresh_tests` が `fn refresh_delay` より前にあったため、関数を前に移動した。

## 文書の照合

- `tools/blog-manager/README.md`: 起動条件 (隣接ライブラリ必須 / `RUSTFS_*`・`R2_*` は起動に必須、
  `GMB_*` は投稿時のみ) を明記。「(M2 では不要)」「画面 (M2 時点)」の古い表記を除去。テスト実行の
  実際のコマンドと件数、M5の公開ステートマシン/実ストレージテストの説明、**残件**セクションを追加。
- `tools/blog-manager/.env.example`: 必須/任意の区別、`RUSTFS_PUBLIC_BASE` の例、既定値で空でよい項目をコメント化。
- `.gitignore` (ルート): `.superpowers/` を追加 (既存の `.opencode/` と同じ扱い)。
- `docs/blog-manager-plan.md` §3.2: `mediaFormat` の `IMAGE` を **`PHOTO`** に訂正。
  実装 (`builder.rs` の EVENT/STANDARD 両方) と実API疎通テストで `PHOTO` を確認済み。

### `content/drafts/` を gitignore しなかった理由

`git status` に下書きが出るが、意図した動作なので無視していない。公開時の git 反映は
`git_preflight` が stage 済みファイルを検査し、`content/posts/<file>` と
(draft 由来の公開なら) `content/drafts/<file>` 以外が stage されていれば中止する
(M5のレビュー指摘「無関係draftのgit混入」への対処)。`git add -A` は使わない。
したがって下書きは gitignore ではなく、公開時に明示的に stage される対象である。

## 保持した warning (3件)

`gmb-event-poster` の内部エラー応答型 (`pub(crate)` の `ErrorDetails` /
`ValidationErrorWrapper` / `ValidationErrorDetail`) に `code` / `error_type` /
`sub_error_code` の未使用フィールドwarningが残る。公開APIではない。
M6では既存の応答型を変更せず保持した (M5からの継続)。

## 実施しなかった残件

- **記事全体のプレビュー未実装**。編集は実装済みだが、本番表示と同じレンダリングのプレビュー画面はない
  (画像中継 `GET /media-preview/{*key}` のみ)。
- **`coverImage` 入力のUX改善** 未着手。
  どちらも既存M6の範囲外のため、今回黙って追加はしていない。
- **外部副作用を伴う受入が未実施**: 実RustFS/R2への昇格 (`tests/live_storage.rs` の ignored 2件)、
  管理UI→公開→git→Netlify→GMB の全経路E2E、実メディア昇格。
- 実GMBでは 2026-10-24 にユーザー許可のもと STANDARD 投稿1件で API 疎通と表示を確認済み
  (post ID `3996231750910215825`、下書き・scratch runner からの送信で、後に削除済み)。
  記録は `tools/blog-manager/state/live-tests/jewelry-ring-k18-132000001660-20261024.json` (ignored)。
  **再投稿しないこと。**

## 統合について

今回は commit まで。**push / merge / デプロイは実行していない**。
統合順は M4 (`e1b26b2`) → M5 → M6 と、共有ライブラリ `codex/blog-manager-standard` を
セットで選ぶ必要がある (アプリの path 依存がライブラリの STANDARD 対応を要求するため、
アプリのみを main に積んでもビルドできない)。

## Codexによる確認 (2026-10-24)

アプリ `f4bf28d` / ライブラリ `b892605` の差分を確認。Rustテストはアプリ70件成功・
実storage2件ignored、ライブラリ5件成功を再確認。両crateのfmt/clippyとTLS依存監査も通過。
サイトの `npm run build` (elm-reviewを含む) も再実行成功。既存ツール由来の非推奨warningは残る。
READMEのテストコマンドをリポジトリ直下から実行できる形に修正し、warningの型の説明を訂正した。

カバー画像について、ユーザーが「新規作成・編集時のアップロード、寸法自動取得、画像確認・
差し替え、カバーなし下書き保存可・公開時必須」の方針に合意。
設計は `docs/superpowers/specs/2026-10-24-cover-image-design.md`。実装は未着手でM6に含めない。
