module Image exposing (Image, decoder, new, render, renderSeo, withAlternativeText)

--import Pages.Url as Url exposing (Url)

import Head.Seo as Seo
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Json.Decode as JD
import Json.Decode.Extra as JD
import MimeType exposing (MimeType)
import Pages.Url
import Url exposing (Url)
import Url.Builder


type Image
    = Image Internal


type alias Internal =
    { url : Url
    , width : Int
    , height : Int
    , alternativeText : Maybe String
    }


new : { url : Url, width : Int, height : Int } -> Image
new props =
    Image
        { url = props.url
        , width = props.width
        , height = props.height
        , alternativeText = Nothing
        }


withAlternativeText : String -> Image -> Image
withAlternativeText title (Image image) =
    Image { image | alternativeText = Just title }



--


decoder : JD.Decoder Image
decoder =
    JD.succeed Internal
        |> JD.andMap
            (JD.field "url" JD.string
                |> JD.andThen
                    (\s ->
                        case Url.fromString s of
                            Just url ->
                                JD.succeed url

                            Nothing ->
                                JD.fail "Invalid url "
                    )
             --(JD.map Url.external JD.string)
            )
        --|> JD.andMap
        --    (JD.field "mime"
        --        (JD.string
        --            |> JD.andThen
        --                (MimeType.parseMimeType
        --                    >> JD.fromMaybe "invalid mime string"
        --                )
        --        )
        --    )
        |> JD.andMap (JD.field "width" JD.int)
        |> JD.andMap (JD.field "height" JD.int)
        |> JD.andMap (JD.field "alternativeText" (JD.maybe JD.string))
        |> JD.map Image


srcset : List { url : Url, width : Int } -> Html.Attribute msg
srcset props =
    let
        field : { url : Url, width : Int } -> String
        field { url, width } =
            String.concat [ imageLoader { url = url, width = width }, " ", String.fromInt width, "w" ]
    in
    A.attribute "srcset" (String.join ", " (List.map field props))


imageLoader : { url : Url, width : Int } -> String
imageLoader props =
    let
        url =
            Url.toString props.url
    in
    Url.Builder.crossOrigin "https://image.officeiko.work"
        [ "cdn-cgi"
        , "image"
        , "width=" ++ String.fromInt props.width
        , Url.toString props.url
        ]
        []


render : Image -> Html msg
render (Image image) =
    figure [ class "flex flex-col items-center" ]
        [ img
            [ class "object-contain w-full"
            , srcset
                [ { url = image.url, width = 640 }
                , { url = image.url, width = 768 }
                , { url = image.url, width = 1024 }
                ]
            , A.attribute "sizes" "(max-width: 1280px) 100vw, 1280px"
            , A.src (Url.toString image.url)
            , A.alt (Maybe.withDefault "" image.alternativeText)
            , A.attribute "loading" "lazy"
            , A.width image.width
            , A.height image.height
            ]
            []
        ]


renderSeo : Image -> Seo.Image
renderSeo (Image image) =
    { url = Pages.Url.external (imageLoader { url = image.url, width = 1600 })
    , alt = image.alternativeText |> Maybe.withDefault ""
    , dimensions =
        Just
            { width = image.width
            , height = image.height
            }
    , mimeType = Nothing
    }
