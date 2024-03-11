module Route.Selling exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.Selling
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import UrlPath
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


image : Seo.Image
image =
    { url = UrlPath.fromString "/logo.png" |> Pages.Url.fromPath
    , alt = "株式会社オフイスイコーのロゴ"
    , dimensions = Nothing
    , mimeType = Nothing
    }


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = Settings.image
        , description = Settings.subtitle
        , title = Settings.withSubtitle "取扱商品"
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
view app _ =
    { title = Settings.withSubtitle "取扱商品"
    , body =
        [ Layout.Selling.view ]
    }
