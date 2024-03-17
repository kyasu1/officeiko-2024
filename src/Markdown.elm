module Markdown exposing (toHtml)

import Html exposing (Html)
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer


toHtml :
    { heading :
        { level : Markdown.Block.HeadingLevel
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
    , unorderedList : List (Markdown.Block.ListItem (Html msg)) -> Html msg
    , orderedList : Int -> List (List (Html msg)) -> Html msg
    , codeBlock : { body : String, language : Maybe String } -> Html msg
    , thematicBreak : Html msg
    , table : List (Html msg) -> Html msg
    , tableHeader : List (Html msg) -> Html msg
    , tableBody : List (Html msg) -> Html msg
    , tableRow : List (Html msg) -> Html msg
    , tableCell : Maybe Markdown.Block.Alignment -> List (Html msg) -> Html msg
    , tableHeaderCell : Maybe Markdown.Block.Alignment -> List (Html msg) -> Html msg
    , paragraph : List (Html msg) -> Html msg
    , link : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg
    }
    -> String
    -> List (Html msg)
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
