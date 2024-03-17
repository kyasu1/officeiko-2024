# README

https://realfavicongenerator.net/favicon_result?file_id=p1hoei0g2k77n1e6ed7o1uf2jdr6

https://github.com/elmcraft/elmcraft.org
https://github.com/kraklin/elm-pages-blog-starter

# 参考サイト

https://right-tax.jp/
https://corp.infomart.co.jp/

# モバイルメニュー

https://dev.to/seppegadeyne/crafting-a-mobile-menu-with-tailwind-css-without-javascript-1814

## 開発環境から正式環境へ反映する手順

1. Strapi の管理画面で、config をエクスポートする
2. 開発環境から Strapi のレポジトリを Push し、本番環境の Strapi で Pull して`docker compose build`で環境を作り直す
3. 更新されたデータを転送する

```shell
# docker compose exec strapi npm run push
```

4. elm-pages のレポジトリを Push する
