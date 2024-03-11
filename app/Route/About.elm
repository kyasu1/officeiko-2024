module Route.About exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.About
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask.BackendTask FatalError Data
data =
    BackendTask.succeed {}


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = Settings.image
        , description = Settings.subtitle
        , title = Settings.withSubtitle "会社概要"
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
    -> View (PagesMsg Msg)
view _ _ =
    { title = Settings.withSubtitle "会社概要"
    , body = Layout.About.view
    }
