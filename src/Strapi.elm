module Strapi exposing (Collection, ImageSet, collectionDecoder, imageSetDecoder, load, renderImageSet)

-- import Url exposing (Url)

import BackendTask exposing (BackendTask)
import BackendTask.Env
import BackendTask.Http
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A
import Json.Decode as JD
import Json.Decode.Extra as JD
import MimeType exposing (MimeType)
import Pages.Url as Url exposing (Url)


load : String -> JD.Decoder a -> BackendTask FatalError a
load api decoder =
    BackendTask.map2 Tuple.pair
        (BackendTask.Env.expect "VITE_STRAPI_TOKEN")
        (BackendTask.Env.expect "VITE_STRAPI_URL")
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\( token, url ) ->
                BackendTask.Http.request
                    { url = url ++ api
                    , method = "GET"
                    , headers = [ ( "Authorization", "Bearer " ++ token ) ]
                    , body = BackendTask.Http.emptyBody
                    , retries = Nothing
                    , timeoutInMs = Nothing
                    }
                    (BackendTask.Http.expectJson decoder)
                    |> BackendTask.allowFatal
            )


type alias Collection a =
    { data : List a
    , meta : Meta
    }


type alias Meta =
    { pagination : Pagination
    }


type alias Pagination =
    { start : Int
    , limit : Int
    , total : Int
    }


collectionDecoder : JD.Decoder a -> JD.Decoder (Collection a)
collectionDecoder decoder =
    JD.map2 Collection
        (JD.field "data" (JD.list decoder))
        (JD.field "meta" metaDecoder)


metaDecoder : JD.Decoder Meta
metaDecoder =
    JD.map Meta
        (JD.field "pagination" paginationDecoder)


paginationDecoder : JD.Decoder Pagination
paginationDecoder =
    JD.map3 Pagination
        (JD.field "start" JD.int)
        (JD.field "limit" JD.int)
        (JD.field "total" JD.int)



--


type alias ImageSet =
    { name : String
    , alternativeText : Maybe String
    , caption : Maybe String
    , original : Image
    , large : Image
    , small : Image
    , medium : Image
    , thumbnail : Image
    }


type alias Image =
    { url : Url
    , mimeType : MimeType
    , width : Int
    , height : Int
    }


imageSetDecoder : JD.Decoder ImageSet
imageSetDecoder =
    JD.at [ "data", "attributes" ]
        (JD.succeed ImageSet
            |> JD.andMap (JD.field "name" JD.string)
            |> JD.andMap (JD.field "alternativeText" (JD.nullable JD.string))
            |> JD.andMap (JD.field "caption" (JD.nullable JD.string))
            |> JD.andMap imageDecoder
            |> JD.andMap (JD.at [ "formats", "large" ] imageDecoder)
            |> JD.andMap (JD.at [ "formats", "small" ] imageDecoder)
            |> JD.andMap (JD.at [ "formats", "medium" ] imageDecoder)
            |> JD.andMap (JD.at [ "formats", "thumbnail" ] imageDecoder)
        )


imageDecoder : JD.Decoder Image
imageDecoder =
    JD.succeed Image
        |> JD.andMap
            (JD.field "url"
                (JD.map Url.external JD.string)
            )
        |> JD.andMap
            (JD.field "mime"
                (JD.string
                    |> JD.andThen
                        (MimeType.parseMimeType
                            >> JD.fromMaybe "invalid mime string"
                        )
                )
            )
        |> JD.andMap (JD.field "width" JD.int)
        |> JD.andMap (JD.field "height" JD.int)


renderImageSet : ImageSet -> Html msg
renderImageSet imageSet =
    img
        [ A.attribute "srcset" <|
            (Url.toString imageSet.small.url
                ++ " 500w, "
                ++ Url.toString imageSet.medium.url
                ++ " 750w, "
                ++ Url.toString imageSet.large.url
                ++ " 1000w"
            )
        , A.attribute "sizes" "(max-width: 1280px) 100vw, 1280px"
        , A.src (Url.toString imageSet.original.url)
        , A.alt (Maybe.withDefault "" imageSet.alternativeText)
        , A.attribute "loading" "lazy"
        , A.width imageSet.original.width
        , A.height imageSet.original.height
        ]
        []
