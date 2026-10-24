module PostRoute exposing (route)

{-| 記事のカテゴリに応じた詳細ページのルートを返す。

`/post/:slug` は News、`/blog/:slug` は Blog に対応する。

-}

import Post exposing (Category(..))
import Route


route : Category -> String -> Route.Route
route category slug =
    case category of
        News ->
            Route.Post__Slug_ { slug = slug }

        Blog ->
            Route.Blog__Slug_ { slug = slug }
