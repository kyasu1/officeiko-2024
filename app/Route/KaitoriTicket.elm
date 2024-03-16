module Route.KaitoriTicket exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.KaitoriTicket exposing (TicketFile)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import UrlPath exposing (UrlPath)
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    { file : TicketFile }


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
    Layout.KaitoriTicket.data |> BackendTask.map Data


image : Seo.Image
image =
    { url = UrlPath.fromString "/images/item-ticket.jpg" |> Pages.Url.fromPath
    , alt = "金券買取のイメージ"
    , dimensions = Nothing
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
        , title = Settings.withSubtitle "金券買取"
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
    { title = Settings.withSubtitle "金券買取"
    , body = Layout.KaitoriTicket.view app.data.file
    }
