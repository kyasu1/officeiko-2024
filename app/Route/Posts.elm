module Route.Posts exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.Posts
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Post exposing (Post)
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
    { posts : List Post }


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
    Post.getAllPosts Nothing
        |> BackendTask.map Data


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image = Settings.image
        , description = Settings.subtitle
        , title = Settings.withSubtitle "投稿記事一覧"
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
    { title = Settings.withSubtitle "投稿記事一覧"
    , body =
        [ Layout.Posts.view app.data.posts
        ]
    }
