module Post exposing (Post, Tag, blogPosts, getAllPosts, newsPosts, postFromSlug)

import BackendTask exposing (BackendTask)
import BackendTask.Env
import Date exposing (Date)
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as JD
import Json.Decode.Extra as JD exposing (collection)
import Strapi
import Ticket exposing (Category)
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


getAllPosts : Maybe Int -> BackendTask FatalError (List Post)
getAllPosts maybeCategoryId =
    getPosts { skip = 0, limit = 100, categoryId = maybeCategoryId }


getPosts : Query -> BackendTask FatalError (List Post)
getPosts query =
    BackendTask.Env.expect "VITE_STRAPI_TOKEN"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\token ->
                getPostsInternal [] query token
            )


newsPosts : BackendTask FatalError (List Post)
newsPosts =
    getPosts { skip = 0, limit = 4, categoryId = Just 2 }


blogPosts : BackendTask FatalError (List Post)
blogPosts =
    getPosts { skip = 0, limit = 8, categoryId = Just 1 }


type alias Query =
    { skip : Int
    , limit : Int
    , categoryId : Maybe Int
    }


getPostsInternal : List Post -> Query -> String -> BackendTask FatalError (List Post)
getPostsInternal posts query token =
    let
        skipQuery =
            if query.skip == 0 then
                []

            else
                [ "pagination[start]=" ++ String.fromInt query.skip ]

        limitQuery =
            [ "pagination[limit]=" ++ String.fromInt query.limit ]

        tagQuery =
            case query.categoryId of
                Just categoryId ->
                    [ "filters[category][id][$eq]=" ++ String.fromInt categoryId ]

                Nothing ->
                    []

        params =
            String.join "&" (List.concat [ skipQuery, limitQuery, tagQuery ])
    in
    Strapi.load ("/posts?populate[0]=category&populate[1]=tags&populate[2]=coverImage&sort[0]=publishedOn:desc&" ++ params)
        (Strapi.collectionDecoder postDecoder)
        |> BackendTask.andThen
            (\collection ->
                let
                    current =
                        (collection.meta.pagination.start + 1) * collection.meta.pagination.limit
                in
                if collection.meta.pagination.total > current then
                    getPostsInternal (collection.data ++ posts) { query | skip = current } token

                else
                    BackendTask.succeed (collection.data ++ posts)
            )


type alias Post =
    { id : Int
    , title : String
    , slug : String
    , body : String
    , coverImage : Strapi.ImageSet
    , author : String
    , category : Category
    , tags : List Tag
    , publishedOn : Date
    }


type alias Tag =
    { id : Int
    , name : String
    , slug : String
    }


type alias Category =
    { id : Int
    , name : String
    , slug : String
    , type_ : CategoryType
    }


type CategoryType
    = News
    | Blog


postDecoder : JD.Decoder Post
postDecoder =
    JD.succeed Post
        |> JD.andMap (JD.field "id" JD.int)
        |> JD.andMap (JD.at [ "attributes", "title" ] JD.string)
        |> JD.andMap (JD.at [ "attributes", "slug" ] JD.string)
        |> JD.andMap (JD.at [ "attributes", "body" ] JD.string)
        |> JD.andMap (JD.at [ "attributes", "coverImage" ] Strapi.imageSetDecoder)
        |> JD.andMap (JD.succeed "小松原 康行")
        |> JD.andMap (JD.at [ "attributes", "category", "data" ] categoryDecoder)
        |> JD.andMap (JD.at [ "attributes", "tags", "data" ] (JD.list tagDecoder))
        -- |> JD.andMap (JD.at [ "_sys", "createdAt" ] Iso8601.decoder)
        -- |> JD.andMap (JD.at [ "_sys", "updatedAt" ] Iso8601.decoder)
        |> JD.andMap (JD.at [ "attributes", "publishedOn" ] Utils.dateDecoder)


categoryDecoder : JD.Decoder Category
categoryDecoder =
    JD.map4 Category
        (JD.field "id" JD.int)
        (JD.at [ "attributes", "name" ] JD.string)
        (JD.at [ "attributes", "slug" ] JD.string)
        (JD.at [ "attributes", "name" ]
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


tagDecoder : JD.Decoder Tag
tagDecoder =
    JD.map3 Tag
        (JD.field "id" JD.int)
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
