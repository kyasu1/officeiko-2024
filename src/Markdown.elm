module Markdown exposing (toHtml)

import Html exposing (Html)
import Markdown.Block as Block exposing (Block)
import Markdown.Parser
import Markdown.Renderer exposing (Renderer)



-- toHtml : { blockQuote : List (Html msg) -> Html msg, html : Renderer (List (Html msg) -> Html msg), text : String -> Html msg, codeSpan : String -> Html msg, strong : List (Html msg) -> Html msg, emphasis : List (Html msg) -> Html msg, strikethrough : List (Html msg) -> Html msg, hardLineBreak : Html msg, link : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg, image : { alt : String, src : String, title : Maybe String } -> Html msg, unorderedList : List (Block.ListItem (Html msg)) -> Html msg, codeBlock : { body : String, language : Maybe String } -> Html msg, thematicBreak : Html msg, table : List (Html msg) -> Html msg, tableHeader : List (Html msg) -> Html msg, tableBody : List (Html msg) -> Html msg, tableRow : List (Html msg) -> Html msg, tableCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, tableHeaderCell : Maybe Block.Alignment -> List (Html msg) -> Html msg, heading : { rawText : String, level : Block.HeadingLevel, children : List (Html msg) } -> Html msg, paragraph : List (Html msg) -> Html msg, orderedList : Int -> List (List (Html msg)) -> Html msg } ->String -> List (Html msg)


toHtml renderer markdownString =
    markdownString
        |> Markdown.Parser.parse
        |> Result.mapError (\_ -> "Markdown error.")
        |> Result.andThen
            (\blocks ->
                Markdown.Renderer.render
                    renderer
                    blocks
            )
        |> Result.withDefault [ Html.text "failed to render markdown" ]
