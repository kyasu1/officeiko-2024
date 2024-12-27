module Layout.Posts exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Layout
import Pages.Url as Url
import Post exposing (Post, Tag)
import Route
import Utils


view : List Post -> Html msg
view posts =
    div []
        [ Layout.hero [] [ text "投稿一覧" ]
        , Layout.section [] [ div [ class "space-y-8" ] (List.map postView posts) ]
        ]


postView : Post -> Html msg
postView post =
    let
        link content =
            Route.link [] [ content ] (Route.Post__Slug_ { slug = post.slug })
    in
    div [ class "flex md:space-x flex-col md:flex-row items-center shadow-sm" ]
        [ div [ class "w-full md:w-1/2 md:shrink-0 md:border-r" ]
            [ link
                (Image.render post.coverImage)
            ]
        , div [ class "w-full md:w-1/2 bg-white h-48 overflow-hidden p-4 md:flex-1" ]
            [ div [ class "flex space-x-2 items-center" ] (listTags post.tags ++ [ div [] [ text (Utils.kanjiDate post.publishedOn) ] ])
            , div [ class "px-2 py-2 font-bold" ] [ link (text post.title) ]
            , div [ class "px-2 py-2 text-sm whitespace-pre truncate" ] [ text post.body ]
            ]
        ]


listTags : List Tag -> List (Html msg)
listTags tags =
    List.map
        (\tag ->
            div [ class "px-2 py-1 bg-gray-200 text-sm text-gray-800 rounded" ]
                [ text tag.name
                ]
        )
        tags
