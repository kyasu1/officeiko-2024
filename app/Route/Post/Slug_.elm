module Route.Post.Slug_ exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Layout.Post
import PagesMsg exposing (PagesMsg)
import Post
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Post.getAllPosts Nothing
        |> BackendTask.map
            (\posts ->
                List.map (\post -> { slug = post.slug }) posts
            )


type alias Data =
    { post : Post.Post }


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.map Data (Post.postFromSlug routeParams.slug)


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    []


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.post.title
    , body = [ Layout.Post.view app.data.post ]
    }
