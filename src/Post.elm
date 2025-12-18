module Post exposing (Post, Tag, blogPosts, getAllPosts, newsPosts, postFromSlug)

import BackendTask exposing (BackendTask)
import BackendTask.File
import BackendTask.Glob as Glob
import Date exposing (Date)
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Image exposing (Image)
import Json.Decode as JD
import Json.Decode.Extra as JD exposing (collection)
import Utils


postFromSlug : String -> BackendTask FatalError Post
postFromSlug slug =
    allPostsDict
        |> BackendTask.andThen
            (\postsDict ->
                Dict.get slug postsDict
                    |> Maybe.map BackendTask.succeed
                    |> Maybe.withDefault
                        (BackendTask.fail <|
                            FatalError.fromString <|
                                "Unable to find post with slug "
                                    ++ slug
                        )
            )


getAllPosts : Maybe Category -> BackendTask FatalError (List Post)
getAllPosts maybeCategory =
    getPosts { skip = 0, limit = 100, category = maybeCategory }



--getPosts : Query -> BackendTask FatalError (List Post)
--getPosts query =
--    BackendTask.Env.expect "VITE_STRAPI_TOKEN"
--        |> BackendTask.allowFatal
--        |> BackendTask.andThen
--            (\token ->
--                getPostsInternal [] query token
--            )


postsTask : Query -> BackendTask error (List { filePath : String, slug : String })
postsTask query =
    Glob.succeed (\filePath slug -> { filePath = filePath, slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/posts/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


getPosts : Query -> BackendTask FatalError (List Post)
getPosts query =
    postsTask query
        |> BackendTask.map
            (\files ->
                List.map (\post -> BackendTask.File.bodyWithFrontmatter postDecoder post.filePath) files
            )
        |> BackendTask.resolve
        |> BackendTask.map
            (\posts ->
                posts
                    |> List.sortBy (\post -> post.publishedOn |> Date.toRataDie)
                    |> List.reverse
                    |> List.filter
                        (\post ->
                            case query.category of
                                Nothing ->
                                    True

                                Just category ->
                                    post.category == category
                        )
                    |> List.drop (query.skip * query.limit)
                    |> List.take query.limit
            )
        |> BackendTask.allowFatal


newsPosts : BackendTask FatalError (List Post)
newsPosts =
    getPosts { skip = 0, limit = 4, category = Just News }


blogPosts : BackendTask FatalError (List Post)
blogPosts =
    getPosts { skip = 0, limit = 8, category = Just Blog }


type alias Query =
    { skip : Int
    , limit : Int
    , category : Maybe Category
    }


type alias Post =
    { title : String
    , slug : String
    , body : String
    , coverImage : Image
    , author : String
    , category : Category
    , tags : List Tag
    , publishedOn : Date
    }


type alias Tag =
    { name : String
    , slug : String
    }


categoryDecoder : JD.Decoder Category
categoryDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case String.toLower s of
                    "news" ->
                        JD.succeed News

                    "blog" ->
                        JD.succeed Blog

                    _ ->
                        JD.fail ("Category must be `news` or `blog`, **" ++ s ++ "** is invalid")
            )


type Category
    = News
    | Blog


categoryToSlug : Category -> String
categoryToSlug v =
    case v of
        News ->
            "news"

        Blog ->
            "blog"


postDecoder : String -> JD.Decoder Post
postDecoder body =
    JD.succeed Post
        |> JD.andMap (JD.field "title" JD.string)
        |> JD.andMap (JD.field "slug" JD.string)
        |> JD.andMap (JD.succeed body)
        |> JD.andMap (JD.field "coverImage" Image.decoder)
        |> JD.andMap (JD.succeed "小松原 康行")
        |> JD.andMap (JD.field "category" categoryDecoder)
        |> JD.andMap (JD.field "tags" (JD.list tagDecoder))
        |> JD.andMap (JD.field "publishedOn" Utils.dateDecoder)


tagDecoder : JD.Decoder Tag
tagDecoder =
    JD.map2 Tag
        (JD.at [ "attributes", "name" ] JD.string)
        (JD.at [ "attributes", "slug" ] JD.string)


allPostsDict : BackendTask FatalError (Dict String Post)
allPostsDict =
    getAllPosts Nothing
        |> BackendTask.map
            (\posts ->
                List.map (\item -> ( item.slug, item )) posts
                    |> Dict.fromList
            )
