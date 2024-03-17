module Layout.Access exposing (Access, load, view)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Json.Decode as JD
import Layout
import Markdown
import Markdown.Block
import Markdown.Html
import Markdown.Renderer
import Pages.Url
import Strapi
import Url


load : BackendTask FatalError Access
load =
    Strapi.load "/page-access?populate[0]=gamo.image&populate[1]=shinKoshigaya.image&populate[2]=accessMap" decoder


type alias Access =
    { accessMap : Strapi.ImageSet
    , description : String
    , gamoTitle : String
    , gamo : List Strapi.Field
    , shinKoshigayaTitle : String
    , shinKoshigaya : List Strapi.Field
    }


decoder : JD.Decoder Access
decoder =
    JD.at [ "data", "attributes" ]
        (JD.map6 Access
            (JD.field "accessMap" Strapi.imageSetDecoder)
            (JD.field "description" JD.string)
            (JD.field "gamoTitle" JD.string)
            (JD.field "gamo" (JD.list Strapi.fieldDecoder))
            (JD.field "shinKoshigayaTitle" JD.string)
            (JD.field "shinKoshigaya" (JD.list Strapi.fieldDecoder))
        )


view : Access -> List (Html msg)
view access =
    [ Layout.hero [] [ text "Access" ]
    , Layout.image [] (img [ A.src (Pages.Url.toString access.accessMap.original.url) ] [])
    , Layout.section []
        [ div [ class "space-y-4" ] (Markdown.toHtml descriptionRender access.description)
        ]
    , Layout.subHeader [ text access.gamoTitle ]
    , Layout.section [] [ div [ class "space-y-4" ] (List.map row access.gamo) ]
    , Layout.subHeader [ text access.shinKoshigayaTitle ]
    , Layout.section [] [ div [ class "space-y-4" ] (List.map row access.shinKoshigaya) ]
    ]


row : Strapi.Field -> Html msg
row field =
    div [ class "flex flex-col-reverse md:flex-row" ]
        [ div [ class "w-full md:w-1/2 p-4" ]
            (Markdown.toHtml stepRender field.description)

        -- , div [ class "w-full md:w-1/2 p-4" ] [ img [ A.src (Url.toString field.image.original.url) ] [] ]
        , div [ class "w-full md:w-1/2 p-4" ] [ Strapi.renderImageSet field.image ]
        ]


descriptionRender :
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
descriptionRender =
    Markdown.Renderer.defaultHtmlRenderer
        |> (\r ->
                { r
                    | paragraph = p [ class "leading-relaxed" ]
                    , link =
                        \link content ->
                            a
                                [ A.href link.destination
                                , case Url.fromString link.destination of
                                    Just url ->
                                        if url.host == "maps.app.goo.gl" then
                                            A.target "_blank"

                                        else
                                            A.target "_self"

                                    Nothing ->
                                        A.target "_self"
                                ]
                                content
                }
           )


stepRender :
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
stepRender =
    Markdown.Renderer.defaultHtmlRenderer
        |> (\r ->
                { r
                    | image =
                        \imageInfo ->
                            img [ A.src imageInfo.src, class "mx-auto w-1/2 my-4" ] []
                    , link =
                        \link content ->
                            a
                                [ A.href link.destination
                                , A.target "_blank"
                                ]
                                content
                }
           )
