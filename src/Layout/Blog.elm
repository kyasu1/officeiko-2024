module Layout.Blog exposing (view)

{-| ブログ記事の一覧レイアウト。カード表示は `Layout.Posts` を流用する。
-}

import Html exposing (Html)
import Layout.Posts
import Post exposing (Post)


view : List Post -> Html msg
view posts =
    Layout.Posts.viewWithTitle { title = "ブログ", posts = posts }
