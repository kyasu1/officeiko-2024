module Post exposing (Collection, Post, Tag, blogPosts, getAllPosts, newsPosts, postFromSlug, tagToString)

import BackendTask exposing (BackendTask)
import BackendTask.Env
import BackendTask.Http
import Date exposing (Date)
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Iso8601
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


getAllPosts : Maybe Tag -> BackendTask FatalError (List Post)
getAllPosts maybeTag =
    getPosts { skip = 0, limit = 100, tag = maybeTag }


getPosts : Query -> BackendTask FatalError (List Post)
getPosts query =
    BackendTask.Env.expect "VITE_NEWT_TOKEN"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\token ->
                getPostsInternal [] query token
            )


newsPosts : BackendTask FatalError (List Post)
newsPosts =
    getPosts { skip = 0, limit = 4, tag = Just { id = "65eb9f683156f73a4095ae0d", tagType = News } }


blogPosts : BackendTask FatalError (List Post)
blogPosts =
    getPosts { skip = 0, limit = 8, tag = Just { id = "65ed74544fe9c152044f034d", tagType = Blog } }


type alias Query =
    { skip : Int
    , limit : Int
    , tag : Maybe Tag
    }


getPostsInternal : List Post -> Query -> String -> BackendTask FatalError (List Post)
getPostsInternal posts query token =
    let
        skipQuery =
            if query.skip == 0 then
                []

            else
                [ "skip=" ++ String.fromInt query.skip ]

        limitQuery =
            [ "limit=" ++ String.fromInt query.limit ]

        tagQuery =
            case query.tag of
                Just tag ->
                    [ "tags=" ++ tag.id ]

                Nothing ->
                    []

        params =
            String.join "&" (List.concat [ skipQuery, limitQuery, tagQuery ])
    in
    BackendTask.Http.request
        { url = "http://officeiko.cdn.newt.so/v1/post/article?body[fmt]=text&order=-publishedOn&" ++ params
        , method = "GET"
        , headers = [ ( "Authorization", "Bearer " ++ token ) ]
        , body = BackendTask.Http.emptyBody
        , retries = Nothing
        , timeoutInMs = Nothing
        }
        (BackendTask.Http.expectJson decoder)
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\collection ->
                let
                    current =
                        (collection.skip + 1) * collection.limit
                in
                if collection.total > current then
                    getPostsInternal (collection.items ++ posts) { query | skip = current } token

                else
                    BackendTask.succeed (collection.items ++ posts)
            )


type alias Collection =
    { skip : Int
    , limit : Int
    , total : Int
    , items : List Post
    }


type alias Post =
    { title : String
    , slug : String
    , body : String
    , coverImage : Image
    , author : String
    , tags : List Tag

    -- , createdAt : Time.Posix
    -- , updatedAt : Time.Posix
    , publishedOn : Date
    }


type alias Image =
    { height : Int
    , width : Int
    , src : String
    , title : Maybe String
    , fileName : String
    , fileType : String
    }


type alias Tag =
    { id : String
    , tagType : TagType
    }


type TagType
    = News
    | Blog


tagToString : Tag -> String
tagToString tag =
    case tag.tagType of
        News ->
            "News"

        Blog ->
            "Blog"


decoder : JD.Decoder Collection
decoder =
    JD.map4 Collection
        (JD.field "skip" JD.int)
        (JD.field "limit" JD.int)
        (JD.field "total" JD.int)
        (JD.field "items" (JD.list postDecoder))


postDecoder : JD.Decoder Post
postDecoder =
    JD.succeed Post
        |> JD.andMap (JD.field "title" JD.string)
        |> JD.andMap (JD.field "slug" JD.string)
        |> JD.andMap (JD.field "body" JD.string)
        |> JD.andMap (JD.field "coverImage" imageDecoder)
        |> JD.andMap (JD.at [ "author", "fullName" ] JD.string)
        |> JD.andMap (JD.field "tags" (JD.list tagDecoder))
        -- |> JD.andMap (JD.at [ "_sys", "createdAt" ] Iso8601.decoder)
        -- |> JD.andMap (JD.at [ "_sys", "updatedAt" ] Iso8601.decoder)
        |> JD.andMap (JD.field "publishedOn" (Iso8601.decoder |> JD.map Utils.posixToDate))


imageDecoder : JD.Decoder Image
imageDecoder =
    JD.succeed Image
        |> JD.andMap (JD.field "height" JD.int)
        |> JD.andMap (JD.field "width" JD.int)
        |> JD.andMap (JD.field "src" JD.string)
        |> JD.andMap (JD.optionalNullableField "title" JD.string)
        |> JD.andMap (JD.field "fileName" JD.string)
        |> JD.andMap (JD.field "fileType" JD.string)


tagDecoder : JD.Decoder Tag
tagDecoder =
    JD.map2 Tag
        (JD.field "_id" JD.string)
        (JD.field "name"
            JD.string
            |> JD.andThen
                (\s ->
                    case s of
                        "News" ->
                            JD.succeed News

                        "Blog" ->
                            JD.succeed Blog

                        _ ->
                            JD.fail ("Invalid tag string " ++ s)
                )
        )
        |> JD.andThen
            (\tag ->
                -- let
                --     _ =
                --         Debug.log "tag " tag
                -- in
                JD.succeed tag
            )


allPostsDict : BackendTask FatalError (Dict String Post)
allPostsDict =
    getAllPosts Nothing
        |> BackendTask.map
            (\posts ->
                List.map (\item -> ( item.slug, item )) posts
                    |> Dict.fromList
            )
