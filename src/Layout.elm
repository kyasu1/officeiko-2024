module Layout exposing (externalLink, hero, image, link, section)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Route


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
        (class "flex items-center justify-center bg-white"
            :: attrs
        )
        [ contents
        ]


linkCss =
    class "text-blue-600 visited:text-purple-600 underline underline-offset-1"


link : String -> Route.Route -> Html msg
link s route =
    Route.link [ linkCss ]
        [ text s
        ]
        route


externalLink : String -> List (Html msg) -> Html msg
externalLink url content =
    a [ linkCss, A.target "_blank", A.href url, A.rel "noopener noreferrer" ] content
