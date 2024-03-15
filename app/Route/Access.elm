module Route.Access exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Effect
import FatalError
import Head
import Head.Seo as Seo
import Html exposing (..)
import Layout.Access exposing (Access)
import Pages.Url
import PagesMsg
import Route
import RouteBuilder exposing (App)
import Settings
import Shared
import UrlPath
import View


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    {}


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single { data = data, head = head }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( {}, Effect.none )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    { access : Access }


type alias ActionData =
    BackendTask.BackendTask FatalError.FatalError (List RouteParams)


data : BackendTask.BackendTask FatalError.FatalError Data
data =
    Layout.Access.load |> BackendTask.map Data


image : Seo.Image
image =
    { url =
        Pages.Url.external "https://newt-s3.s3.ap-northeast-1.amazonaws.com/access_map_d76b65c614.jpghttps://newt-s3.s3.ap-northeast-1.amazonaws.com/access_map_d76b65c614.jpg"
    , alt = "Access"
    , dimensions = Just { width = 1106, height = 579 }
    , mimeType = Nothing
    }


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = image
        , description = Settings.subtitle
        , title = Settings.withSubtitle "Access"
        , locale = Settings.locale
        }
        |> Seo.article
            { tags = []
            , section = Nothing
            , publishedTime = Nothing
            , modifiedTime = Nothing
            , expirationTime = Nothing
            }


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app _ _ =
    { title = "Access"
    , body = Layout.Access.view app.data.access
    }
