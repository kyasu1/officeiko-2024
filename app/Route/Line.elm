module Route.Line exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

-- import Path

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Effect
import ErrorPage
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Json.Decode as Decode
import Layout.Selling
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Server.Request
import Server.Response
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


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    -- Layout.About.seoHeaders app.data.author
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = Settings.image
        , description = Settings.subtitle
        , title = "取扱商品" ++ "|" ++ Settings.title
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
    { title = "About"
    , body =
        [ Layout.Selling.view ]
    }
