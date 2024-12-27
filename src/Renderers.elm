module Renderers exposing (postImage, render)

import Html
import Image exposing (Image)
import Markdown.Html as MH
import Url


render : MH.Renderer (List (Html.Html msg) -> Html.Html msg)
render =
    MH.oneOf [ postImage ]


postImage : MH.Renderer (List (Html.Html msg) -> Html.Html msg)
postImage =
    MH.tag "post-image"
        (\stringUrl stringWidth stringHeight maybeAlt _ ->
            case ( Url.fromString stringUrl, String.toInt stringWidth, String.toInt stringHeight ) of
                ( Just url, Just width, Just height ) ->
                    let
                        imageBase =
                            Image.new { url = url, width = width, height = height }

                        image =
                            case maybeAlt of
                                Just alt ->
                                    Image.withAlternativeText alt imageBase

                                Nothing ->
                                    imageBase
                    in
                    Html.div [] [ Image.render image ]

                _ ->
                    Html.div [] [ Html.img [] [] ]
        )
        |> MH.withAttribute "url"
        |> MH.withAttribute "width"
        |> MH.withAttribute "height"
        |> MH.withOptionalAttribute "alt"
