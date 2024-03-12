module Route.Privacy exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.Privacy exposing (Privacy)
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
    { privacy : Privacy }


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
    Layout.Privacy.file
        |> BackendTask.allowFatal
        |> BackendTask.map Data


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
        , title = Settings.withSubtitle "プライバシーポリシー"
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
        [ Layout.Privacy.view app.data.privacy ]
    }
