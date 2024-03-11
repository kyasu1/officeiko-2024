module Route.Pawn exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Layout.Pawn
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Pawn
import RouteBuilder exposing (App, StatefulRoute)
import Settings
import Shared
import UrlPath exposing (UrlPath)
import View exposing (View)


type alias Model =
    { pawn : Pawn.Model
    }


type Msg
    = PawnMsg Pawn.Msg


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        -- |> RouteBuilder.buildNoState { view = view }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , update = update
            , init = init
            , subscriptions = subscriptions
            }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init app shared =
    ( { pawn = Pawn.init shared.date }, Effect.none )


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update app shared msg model =
    case msg of
        PawnMsg subMsg ->
            let
                ( pawn, effect ) =
                    Pawn.update shared subMsg model.pawn
            in
            ( { model | pawn = pawn }, Effect.map PawnMsg effect )


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path sharedModel model =
    Sub.none


data : BackendTask.BackendTask FatalError Data
data =
    BackendTask.succeed {}


image : Seo.Image
image =
    { url = UrlPath.fromString "/images/pawn.png" |> Pages.Url.fromPath
    , alt = "質入れのイメージ"
    , dimensions = Nothing
    , mimeType = Nothing
    }


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    -- Layout.About.seoHeaders app.data.author
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = image
        , description = Settings.subtitle
        , title = Settings.withSubtitle "質入・融資"
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
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ model =
    { title = Settings.withSubtitle "質入・融資"
    , body = [ Layout.Pawn.view (Pawn.view model.pawn) |> Html.map (PagesMsg.fromMsg << PawnMsg) ]
    }
