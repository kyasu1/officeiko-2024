module Layout.Selling exposing (..)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Json.Decode as JD
import JsonFile
import Layout
import Markdown
import Markdown.Block
import Markdown.Html
import Markdown.Renderer


load : BackendTask FatalError Selling
load =
    File.jsonFile decoder "./content/selling.json"
        |> BackendTask.allowFatal


type alias Selling =
    { title : String
    , description : String
    , items : List JsonFile.Field
    }


decoder : JD.Decoder Selling
decoder =
    JD.map3 Selling
        (JD.field "title" JD.string)
        (JD.field "description" JD.string)
        (JD.field "items" (JD.list JsonFile.decoder))


view : Selling -> Html msg
view data =
    div []
        [ Layout.hero [] [ text data.title ]
        , Layout.section []
            (Markdown.toHtml itemRender data.description)
        , Layout.section []
            [ div [ class "space-y-8" ]
                (splitByTwo data.items |> List.map rows |> List.concat)
            ]
        ]


rows : ( JsonFile.Field, Maybe JsonFile.Field ) -> List (Html msg)
rows ( left, maybeRight ) =
    List.concat
        [ [ row Left left
          ]
        , case maybeRight of
            Just right ->
                [ row Right right
                ]

            Nothing ->
                []
        ]


row : Alignment -> JsonFile.Field -> Html msg
row alignment item =
    div [ class "grid grid-cols-1 md:grid-cols-3 items-center" ]
        [ div
            [ class "flex items-center justify-center"
            , case alignment of
                Left ->
                    class ""

                Right ->
                    class "md:order-last"
            ]
            [ div [ class "w-full max-w-[240px] border border-black" ]
                [ Image.render item.image
                ]
            ]
        , div [ class "md:col-span-2 bg-white w-full h-full p-4 shadow-sm" ]
            (Markdown.toHtml itemRender item.description)
        ]


type Alignment
    = Left
    | Right


splitByTwo : List a -> List ( a, Maybe a )
splitByTwo list =
    case list of
        a :: b :: rest ->
            ( a, Just b ) :: splitByTwo rest

        [ a ] ->
            [ ( a, Nothing ) ]

        [] ->
            []


itemRender :
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
itemRender =
    Markdown.Renderer.defaultHtmlRenderer
        |> (\r ->
                { r
                    | heading =
                        \{ level, children } ->
                            case level of
                                Markdown.Block.H1 ->
                                    Html.h1 [] children

                                Markdown.Block.H2 ->
                                    Html.h2 [] children

                                Markdown.Block.H3 ->
                                    Html.h3 [ class "font-bold" ] children

                                Markdown.Block.H4 ->
                                    Html.h4 [] children

                                Markdown.Block.H5 ->
                                    Html.h5 [] children

                                Markdown.Block.H6 ->
                                    Html.h6 [] children
                    , paragraph = Html.p [ class "leading-loose" ]
                    , image =
                        \imageInfo ->
                            img [ A.src imageInfo.src, class "mx-auto w-1/2 my-4" ] []
                    , link =
                        \link content ->
                            Layout.link link.destination content
                    , html =
                        Markdown.Html.oneOf
                            [ Markdown.Html.tag "span"
                                (\className renderedChildren ->
                                    Html.span [ class className ] renderedChildren
                                )
                                |> Markdown.Html.withAttribute "class"
                            ]
                }
           )
