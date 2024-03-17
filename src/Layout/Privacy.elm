module Layout.Privacy exposing (Privacy, file, view)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Json.Decode as JD
import Layout
import Markdown
import Markdown.Block as Block
import Markdown.Renderer


type alias Privacy =
    { body : String
    , title : String
    , date : String
    , slug : String
    }


metaDecoder : String -> String -> JD.Decoder Privacy
metaDecoder slug body =
    JD.map3 (Privacy body)
        (JD.field "title" JD.string)
        (JD.field "date" JD.string)
        (JD.succeed slug)


file : BackendTask { fatal : FatalError, recoverable : File.FileReadError JD.Error } Privacy
file =
    File.bodyWithFrontmatter (metaDecoder "privacy") "content/privacy.md"



-- renderer : { blockQuote : List (Html msg) -> Html msg, html : Renderer (List (Html msg) -> Html msg), text : String -> Html msg, codeSpan : String -> Html msg, strong : List (Html msg) -> Html msg, emphasis : List (Html msg) -> Html msg, strikethrough : List (Html msg) -> Html msg, hardLineBreak : Html msg, link : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg, image : { alt : String, src : String, title : Maybe String } -> Html msg, unorderedList : List (Block.ListItem (Html msg)) -> Html msg, codeBlock : { body : String, language : Maybe String } -> Html msg, thematicBreak : Html msg, table : List (Html msg) -> Html msg, tableHeader : List (Html msg) -> Html msg, tableBody : List (Html msg) -> Html msg, tableRow : List (Html msg) -> Html msg, tableCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, tableHeaderCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, heading : { rawText : String, level : Block.HeadingLevel, children : List (Html msg) } -> Html msg, paragraph : List (Html msg) -> Html msg, orderedList : Int -> List (List (Html msg)) -> Html msg }
-- renderer : { blockQuote : List (Html msg) -> Html msg, html : Renderer (List (Html msg) -> Html msg), text : String -> Html msg, codeSpan : String -> Html msg, strong : List (Html msg) -> Html msg, emphasis : List (Html msg) -> Html msg, strikethrough : List (Html msg) -> Html msg, hardLineBreak : Html msg, link : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg, image : { alt : String, src : String, title : Maybe String } -> Html msg, unorderedList : List (Block.ListItem (Html msg)) -> Html msg, codeBlock : { body : String, language : Maybe String } -> Html msg, thematicBreak : Html msg, table : List (Html msg) -> Html msg, tableHeader : List (Html msg) -> Html msg, tableBody : List (Html msg) -> Html msg, tableRow : List (Html msg) -> Html msg, tableCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, tableHeaderCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, heading : { rawText : String, level : Block.HeadingLevel, children : List (Html msg) } -> Html msg, paragraph : List (Html msg) -> Html msg, orderedList : Int -> List (List (Html msg)) -> Html msg } -> Renderer (Html msg )


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
                                    h4 [] children

                                Block.H5 ->
                                    h5 [] children

                                Block.H6 ->
                                    h6 [] children
                    , paragraph = p [ class "text-base leading-loose tracking-normal max-md:text-lg max-md:tracking-tight max-md:leading-relaxed text-gray-600" ]
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


view : Privacy -> Html msg
view privacy =
    div []
        [ Layout.hero [] [ text privacy.title ]
        , Layout.section []
            [ article [ class "py-2 md:py-0 px-2 md:px-6" ]
                (Markdown.toHtml renderer privacy.body
                    ++ [ div [ class "text-right my-4 leading-loose tracking-normal text-gray-600" ]
                            [ p [] [ text "最終改訂日：2018年5月1日" ]
                            , p [] [ text "個人情報取扱事業者" ]
                            , p [] [ text "株式会社オフイスイコー" ]
                            , p [] [ text "埼玉県越谷市七左町1-299-1" ]
                            , p [] [ text "代表取締役社長 小松原 康行" ]
                            ]
                       ]
                )
            ]
        ]
