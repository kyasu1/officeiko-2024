# M5 引き継ぎ・実装記録

2026-10-24、opencodeのrate limit後にCodexがM4 e1b26b2を基点に継続。

## 作業場所

- アプリ: `/private/tmp/officeiko-m5`、ブランチ `codex/blog-manager-m5`。M4の`feat/blog-manager-m4`に積んだ変更。
- 共有ライブラリ: `/private/tmp/gmb-event-poster`、ブランチ `codex/blog-manager-standard`。
- 両リポジトリの変更が必要。path依存は計画どおり隣接配置の `../../../gmb-event-poster`。
- 元のメイン作業ツリーの未コミット `.env.example`、gmbリポジトリの設定変更は保持。

## 実装

公開/再開の状態記録、メディア昇格、記事移動、任意git commit/push、STANDARD投稿、GMB単独操作。
送信前in_flight永続化、結果不明unknown、自動再送防止、操作ID付きcommitからの復旧。
公開済み編集/削除の任意git反映は変更前に意図を記録し、一覧から中断操作を再開可能。
ライブラリにSTANDARD型/ビルダーを追加、EVENT APIを維持、reqwest 0.12 rustls化、expires_inからtoken再取得時刻を計算。

## 検証

- アプリ: `CARGO_INCREMENTAL=0 cargo test --locked --offline --manifest-path tools/blog-manager/Cargo.toml --target-dir /private/tmp/officeiko-m5-target`。
- ライブラリ: `cargo test --locked --offline --manifest-path /private/tmp/gmb-event-poster/Cargo.toml`。
- アプリのfmt/clippy、git diff --check、cargo tree featuresでopenssl/native-tls不在を確認。
- 別レビュー担当の5件を全て再現テストRED→GREENで修正。GETの状態変更、移動途中の重複、無関係draftのgit混入、削除再作成の状態継承、編集/削除の意図保存の順序。
- 実RustFS/R2の2テストは未実行(ignored)。実GMB送信・実デプロイも未実施。
- ライブラリには従来のエラー型の未使用フィールドwarningが3件残る。

## 判断と限界

1. Google APIの画像形式はPHOTOを使用(計画のIMAGEを訂正)。canonicalは現サイトのapex officeiko.co.jpに合わせた。
2. planどおりgit push origin mainを使用。公開commit後のHEAD変更は拒否するが、そのcommit以前にmainに積まれたローカルcommitもpush対象になる。
3. write lockは同一プロセス内の直列化。他のエディタ/gitからの同時書込みは運用上避ける。外部の同時変更はこのロックでは防げない。
4. 実Google/ストレージ/Netlifyの確認には資格情報と対象記事・実行許可が必要。ローカル試験だけではプロバイダー挙動は保証できない。
5. プロセス中断の復旧を対象とし、全ファイル操作について電源断耐性までは保証しない。

## 残る受入確認

計画M5の実STANDARD投稿成功条件は未確認。対象記事・送信内容・実行許可を確認してから実行する。
M4も現時点でmain未統合のため、M4→M5と共有ライブラリの統合順序を選ぶ。M6の仕上げは別途。
