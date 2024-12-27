module Layout.Post exposing (view)

import Heroicons.Outline as Outline
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Layout
import Markdown
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer
import Pages.Url as Url
import Post exposing (Post)
import Svg.Attributes as SA
import Utils


view : Post -> Html msg
view post =
    div []
        [ Layout.hero [] [ text post.title ]
        , Layout.image [] (Image.render post.coverImage)
        , Layout.section []
            [ div [ class "flex  justify-between items-center text-sm space-x-2 " ]
                [ tagView post.tags
                , div [] [ text "更新日 ", text (Utils.kanjiDate post.publishedOn) ]
                ]
            ]
        , Layout.section [] (Markdown.toHtml renderer post.body)
        ]


tagView : List Post.Tag -> Html msg
tagView tags =
    div [ class "flex space-x-2" ]
        (List.map
            (\tag ->
                div [ class "rounded bg-gray-300 text-gray-900 px-2 py-1 font-semibold" ] [ text tag.name ]
            )
            tags
        )


renderer :
    { heading :
        { level : Block.HeadingLevel
        , rawText : String
        , children : List (Html msg)
        }
        -> Html msg
    , blockQuote : List (Html msg) -> Html msg
    , html : Markdown.Html.Renderer (List (Html msg) -> Html msg)
    , text : String -> Html msg
    , codeSpan : String -> Html msg
    , strong : List (Html msg) -> Html msg
    , emphasis : List (Html msg) -> Html msg
    , strikethrough : List (Html msg) -> Html msg
    , hardLineBreak : Html msg
    , image : { alt : String, src : String, title : Maybe String } -> Html msg
    , unorderedList : List (Block.ListItem (Html msg)) -> Html msg
    , orderedList : Int -> List (List (Html msg)) -> Html msg
    , codeBlock : { body : String, language : Maybe String } -> Html msg
    , thematicBreak : Html msg
    , table : List (Html msg) -> Html msg
    , tableHeader : List (Html msg) -> Html msg
    , tableBody : List (Html msg) -> Html msg
    , tableRow : List (Html msg) -> Html msg
    , tableCell : Maybe Block.Alignment -> List (Html msg) -> Html msg
    , tableHeaderCell : Maybe Block.Alignment -> List (Html msg) -> Html msg
    , paragraph : List (Html msg) -> Html msg
    , link : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg
    }
renderer =
    Markdown.Renderer.defaultHtmlRenderer
        |> (\r ->
                { r
                    | heading =
                        \{ level, children } ->
                            case level of
                                Block.H1 ->
                                    h1 [] children

                                Block.H2 ->
                                    h2 [ class "my-14 max-md:my-10 text-2xl md:text-3xl tracking-normal font-bold" ] children

                                Block.H3 ->
                                    h3 [ class "my-5 text-lg md:text-xl tracking-normal font-bold" ] children

                                Block.H4 ->
                                    h4 [ class "my-4 underline underline-offset-4" ] children

                                Block.H5 ->
                                    h5 [] children

                                Block.H6 ->
                                    h6 [] children
                    , paragraph = p [ class "text-base leading-loose tracking-normal max-md:text-lg max-md:tracking-tight max-md:leading-relaxed text-gray-600 my-4" ]
                    , link =
                        \link content ->
                            a
                                (List.concat
                                    [ case link.title of
                                        Just title ->
                                            [ A.title title ]

                                        Nothing ->
                                            []
                                    , [ A.href link.destination ]
                                    , [ class "inline-flex items-baseline mx-1 font-bold text-green-700 hover:underline " ]
                                    ]
                                )
                                (span [ class "mr-1" ] [ Outline.link [ SA.class "w-4 h-4" ] ] :: content)
                    , image =
                        \imageInfo ->
                            div [ class "flex items-center justify-center py-8" ]
                                [ case imageInfo.title of
                                    Just title ->
                                        Html.img
                                            [ A.src imageInfo.src
                                            , A.alt imageInfo.alt
                                            , A.title title
                                            , class "w-full max-w-[640px] h-auto"
                                            ]
                                            []

                                    Nothing ->
                                        Html.img
                                            [ A.src imageInfo.src
                                            , A.alt imageInfo.alt
                                            , class "w-full max-w-[640px] h-auto"
                                            ]
                                            []
                                ]
                    , unorderedList =
                        \items ->
                            Html.ul [ class "list-disc leading-loose border rounded-sm px-8 py-4" ]
                                (items
                                    |> List.map
                                        (\item ->
                                            case item of
                                                Block.ListItem task children ->
                                                    let
                                                        checkbox =
                                                            case task of
                                                                Block.NoTask ->
                                                                    Html.text ""

                                                                Block.IncompleteTask ->
                                                                    Html.input
                                                                        [ A.disabled True
                                                                        , A.checked False
                                                                        , A.type_ "checkbox"
                                                                        ]
                                                                        []

                                                                Block.CompletedTask ->
                                                                    Html.input
                                                                        [ A.disabled True
                                                                        , A.checked True
                                                                        , A.type_ "checkbox"
                                                                        ]
                                                                        []
                                                    in
                                                    Html.li [] (checkbox :: children)
                                        )
                                )
                    , orderedList =
                        \startingIndex items ->
                            ol
                                (case startingIndex of
                                    1 ->
                                        [ class "list-decimal text-gray-600 ml-6 leading-loose tracking-normal" ]

                                    _ ->
                                        [ A.start startingIndex, class "list-decimal text-gray-600 ml-6 leading-loose tracking-normal" ]
                                )
                                (items
                                    |> List.map
                                        (\itemBlocks ->
                                            Html.li []
                                                itemBlocks
                                        )
                                )
                }
           )
