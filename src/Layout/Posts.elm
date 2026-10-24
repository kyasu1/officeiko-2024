module Layout.Posts exposing (view, viewWithTitle)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Layout
import Pages.Url as Url
import Post exposing (Post, Tag)
import PostRoute
import Route
import Utils


view : List Post -> Html msg
view posts =
    viewWithTitle { title = "投稿一覧", posts = posts }


viewWithTitle : { title : String, posts : List Post } -> Html msg
viewWithTitle config =
    div []
        [ Layout.hero [] [ text config.title ]
        , Layout.section [] [ div [ class "space-y-8" ] (List.map postView config.posts) ]
        ]


postView : Post -> Html msg
postView post =
    let
        link content =
            Route.link [] [ content ] (PostRoute.route post.category post.slug)
    in
    div [ class "flex md:space-x flex-col md:flex-row items-center shadow-sm" ]
        [ div [ class "w-full md:w-1/2 md:shrink-0 md:border-r" ]
            [ link
                (Image.render post.coverImage)
            ]
        , div [ class "w-full md:w-1/2 bg-white h-48 overflow-hidden p-4 md:flex-1" ]
            [ div [ class "flex space-x-2 items-center" ]
                (categoryBadge post.category
                    :: listTags post.tags
                    ++ [ div [] [ text (Utils.kanjiDate post.publishedOn) ] ]
                )
            , div [ class "px-2 py-2 font-bold" ] [ link (text post.title) ]
            , div [ class "px-2 py-2 text-sm whitespace-pre truncate" ] [ text post.body ]
            ]
        ]


categoryBadge : Post.Category -> Html msg
categoryBadge category =
    div [ class "px-2 py-1 bg-iko-500 text-sm text-white rounded" ]
        [ text (Post.categoryToLabel category) ]


listTags : List Tag -> List (Html msg)
listTags tags =
    List.map
        (\tag ->
            div [ class "px-2 py-1 bg-gray-200 text-sm text-gray-800 rounded" ]
                [ text tag.name
                ]
        )
        tags
