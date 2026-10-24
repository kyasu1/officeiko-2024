module Post exposing
    ( Category(..)
    , Post
    , Tag
    , blogPosts
    , categoryToLabel
    , categoryToSlug
    , getAllPosts
    , getAllPostsUnlimited
    , newsPosts
    , postFromCategorySlug
    )

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


postFromCategorySlug : Category -> String -> BackendTask FatalError Post
postFromCategorySlug category slug =
    allPostsDict (Just category)
        |> BackendTask.andThen
            (\dict ->
                Dict.get slug dict
                    |> Maybe.map BackendTask.succeed
                    |> Maybe.withDefault
                        (BackendTask.fail <|
                            FatalError.fromString <|
                                "Unable to find "
                                    ++ categoryToSlug category
                                    ++ " post with slug "
                                    ++ slug
                        )
            )


getAllPosts : Maybe Category -> BackendTask FatalError (List Post)
getAllPosts maybeCategory =
    getPosts { skip = 0, limit = 100, category = maybeCategory }


{-| 全件を列挙する (preRender の pages 用)。一覧表示の件数制限とは分離する。
-}
getAllPostsUnlimited : Maybe Category -> BackendTask FatalError (List Post)
getAllPostsUnlimited maybeCategory =
    postsByCategory maybeCategory



--getPosts : Query -> BackendTask FatalError (List Post)
--getPosts query =
--    BackendTask.Env.expect "VITE_STRAPI_TOKEN"
--        |> BackendTask.allowFatal
--        |> BackendTask.andThen
--            (\token ->
--                getPostsInternal [] query token
--            )


postsTask : BackendTask error (List { filePath : String, slug : String })
postsTask =
    Glob.succeed (\filePath slug -> { filePath = filePath, slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/posts/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


getPosts : Query -> BackendTask FatalError (List Post)
getPosts query =
    postsByCategory query.category
        |> BackendTask.map
            (\posts ->
                posts
                    |> List.drop (query.skip * query.limit)
                    |> List.take query.limit
            )


{-| カテゴリで絞り込んだ全記事 (新しい順)。件数制限はここでは行わない。
-}
postsByCategory : Maybe Category -> BackendTask FatalError (List Post)
postsByCategory maybeCategory =
    postsTask
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
                            case maybeCategory of
                                Nothing ->
                                    True

                                Just category ->
                                    post.category == category
                        )
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


categoryToLabel : Category -> String
categoryToLabel v =
    case v of
        News ->
            "お知らせ"

        Blog ->
            "ブログ"


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


allPostsDict : Maybe Category -> BackendTask FatalError (Dict String Post)
allPostsDict maybeCategory =
    postsByCategory maybeCategory
        |> BackendTask.map
            (\posts ->
                List.map (\item -> ( item.slug, item )) posts
                    |> Dict.fromList
            )
