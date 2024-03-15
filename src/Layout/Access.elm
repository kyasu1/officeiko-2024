module Layout.Access exposing (Access, load, view)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Json.Decode as JD
import Layout
import Markdown
import Markdown.Renderer
import Strapi
import Url


load : BackendTask FatalError Access
load =
    Strapi.load "/page-access?populate[0]=gamo.image&populate[1]=shinKoshigaya.image&populate[2]=accessMap" decoder


type alias Access =
    { accessMap : Strapi.ImageSet
    , description : String
    , gamoTitle : String
    , gamo : List Field
    , shinKoshigayaTitle : String
    , shinKoshigaya : List Field
    }


type alias Field =
    { description : String
    , image : Strapi.ImageSet
    }


decoder : JD.Decoder Access
decoder =
    JD.at [ "data", "attributes" ]
        (JD.map6 Access
            (JD.field "accessMap" Strapi.imageSetDecoder)
            (JD.field "description" JD.string)
            (JD.field "gamoTitle" JD.string)
            (JD.field "gamo" (JD.list fieldDecoder))
            (JD.field "shinKoshigayaTitle" JD.string)
            (JD.field "shinKoshigaya" (JD.list fieldDecoder))
        )


fieldDecoder : JD.Decoder Field
fieldDecoder =
    JD.map2 Field
        (JD.field "description" JD.string)
        (JD.field "image" Strapi.imageSetDecoder)


view : Access -> List (Html msg)
view access =
    [ Layout.hero [] [ text "Access" ]
    , Layout.image [] (img [ A.src (Url.toString access.accessMap.original.url) ] [])
    , Layout.section []
        [ div [ class "space-y-4" ] (Markdown.toHtml descriptionRender access.description)
        ]
    , Layout.subHeader [ text access.gamoTitle ]
    , div [ class "space-y-4" ] (List.map row access.gamo)
    , Layout.subHeader [ text access.shinKoshigayaTitle ]

    -- , div [ class "space-y-4" ] (List.map row access.shinKoshigaya)
    , div [ class "text-center py-16 font-bold" ] [ text "UNDER CONSTRUCTION" ]
    ]


row : Field -> Html msg
row field =
    div [ class "flex flex-col-reverse md:flex-row" ]
        [ div [ class "w-full md:w-1/2 p-4" ]
            (Markdown.toHtml stepRender field.description)
        , div [ class "w-full md:w-1/2 p-4" ] [ img [ A.src (Url.toString field.image.original.url) ] [] ]
        ]


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
