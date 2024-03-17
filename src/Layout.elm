module Layout exposing (hero, image, link, section, subHeader)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Route
import UrlPath


section : List (Attribute msg) -> List (Html msg) -> Html msg
section attrs =
    Html.section (class "max-w-5xl mx-auto px-2 md:px-4 py-4" :: attrs)


hero : List (Attribute msg) -> List (Html msg) -> Html msg
hero attrs contents =
    div
        (class "flex items-center justify-center pl-6 min-h-16 bg-gray-100 border-gray-300 border-solid border-b shadow-sm"
            :: attrs
        )
        [ h1 [ class "font-bold tracking-[0.3rem] text-xl md:text-2xl lg:text-3xl  max-md:tracking-tight" ]
            contents
        ]


image : List (Attribute msg) -> Html msg -> Html msg
image attrs contents =
    div
        ([ class "flex items-center justify-center bg-white", A.attribute "loading" "lazy" ]
            ++ attrs
        )
        [ contents
        ]


linkCss : Attribute msg
linkCss =
    class "text-blue-600 visited:text-purple-600 underline underline-offset-1"


link : String -> List (Html msg) -> Html msg
link url content =
    case UrlPath.fromString url |> Route.segmentsToRoute of
        Just route ->
            Route.link [ linkCss ] content route

        Nothing ->
            externalLink url content


externalLink : String -> List (Html msg) -> Html msg
externalLink url content =
    a [ linkCss, A.target "_blank", A.href url, A.rel "noopener noreferrer" ] content


subHeader : List (Html msg) -> Html msg
subHeader =
    h2 [ class "text-center text-xl p-2 mb-2 bg-gray-200 text-gray-900 font-semibold" ]
