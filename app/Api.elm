module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import Date
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Pages.Manifest as Manifest
import Post exposing (Post)
import PostRoute
import Route exposing (Route)
import Settings


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes _ =
    [ sitemap getStaticRoutes ]


{-| `/sitemap.xml` をビルド時に生成する。

`getStaticRoutes` は preRender された記事ページを含む全ページを列挙するため、
記事の `publishedOn` を `lastmod` として対応付ける。

-}
sitemap : BackendTask FatalError (List Route) -> ApiRoute ApiRoute.Response
sitemap getStaticRoutes =
    ApiRoute.succeed
        (BackendTask.map2 sitemapXml
            getStaticRoutes
            (Post.getAllPostsUnlimited Nothing)
        )
        |> ApiRoute.literal "sitemap.xml"
        |> ApiRoute.single


sitemapXml : List Route -> List Post -> String
sitemapXml staticRoutes posts =
    let
        lastmodByLoc : Dict String String
        lastmodByLoc =
            posts
                |> List.map
                    (\post ->
                        ( Route.toString (PostRoute.route post.category post.slug)
                        , Date.toIsoString post.publishedOn
                        )
                    )
                |> Dict.fromList

        urls : List SitemapUrl
        urls =
            staticRoutes
                |> List.map
                    (\route ->
                        let
                            loc : String
                            loc =
                                Route.toString route
                        in
                        { loc = loc, lastmod = Dict.get loc lastmodByLoc }
                    )
                |> List.sortBy .loc
    in
    String.concat
        [ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        , "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
        , String.concat (List.map urlEntry urls)
        , "</urlset>\n"
        ]


type alias SitemapUrl =
    { loc : String
    , lastmod : Maybe String
    }


urlEntry : SitemapUrl -> String
urlEntry url =
    String.concat
        [ "  <url><loc>"
        , escapeXml (Settings.canonicalUrl ++ url.loc)
        , "</loc>"
        , case url.lastmod of
            Just lastmod ->
                "<lastmod>" ++ lastmod ++ "</lastmod>"

            Nothing ->
                ""
        , "</url>\n"
        ]


escapeXml : String -> String
escapeXml string =
    string
        |> String.replace "&" "&amp;"
        |> String.replace "<" "&lt;"
        |> String.replace ">" "&gt;"
        |> String.replace "\"" "&quot;"
        |> String.replace "'" "&apos;"


manifest : Manifest.Config
manifest =
    Manifest.init
        { name = "Site Name"
        , description = "Description"
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }
