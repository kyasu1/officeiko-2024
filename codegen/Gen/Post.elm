module Gen.Post exposing (annotation_, blogPosts, call_, getAllPosts, make_, moduleName_, newsPosts, postFromSlug, tagToString, values_)

{-| 
@docs moduleName_, tagToString, blogPosts, newsPosts, getAllPosts, postFromSlug, annotation_, make_, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Post" ]


{-| tagToString: Post.Tag -> String -}
tagToString : Elm.Expression -> Elm.Expression
tagToString tagToStringArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Post" ]
            , name = "tagToString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Post" ] "Tag" [] ]
                        Type.string
                    )
            }
        )
        [ tagToStringArg ]


{-| blogPosts: BackendTask.BackendTask FatalError.FatalError (List Post.Post) -}
blogPosts : Elm.Expression
blogPosts =
    Elm.value
        { importFrom = [ "Post" ]
        , name = "blogPosts"
        , annotation =
            Just
                (Type.namedWith
                    [ "BackendTask" ]
                    "BackendTask"
                    [ Type.namedWith [ "FatalError" ] "FatalError" []
                    , Type.list (Type.namedWith [ "Post" ] "Post" [])
                    ]
                )
        }


{-| newsPosts: BackendTask.BackendTask FatalError.FatalError (List Post.Post) -}
newsPosts : Elm.Expression
newsPosts =
    Elm.value
        { importFrom = [ "Post" ]
        , name = "newsPosts"
        , annotation =
            Just
                (Type.namedWith
                    [ "BackendTask" ]
                    "BackendTask"
                    [ Type.namedWith [ "FatalError" ] "FatalError" []
                    , Type.list (Type.namedWith [ "Post" ] "Post" [])
                    ]
                )
        }


{-| getAllPosts: Maybe Post.Tag -> BackendTask.BackendTask FatalError.FatalError (List Post.Post) -}
getAllPosts : Elm.Expression -> Elm.Expression
getAllPosts getAllPostsArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Post" ]
            , name = "getAllPosts"
            , annotation =
                Just
                    (Type.function
                        [ Type.maybe (Type.namedWith [ "Post" ] "Tag" []) ]
                        (Type.namedWith
                            [ "BackendTask" ]
                            "BackendTask"
                            [ Type.namedWith [ "FatalError" ] "FatalError" []
                            , Type.list (Type.namedWith [ "Post" ] "Post" [])
                            ]
                        )
                    )
            }
        )
        [ getAllPostsArg ]


{-| postFromSlug: String -> BackendTask.BackendTask FatalError.FatalError Post.Post -}
postFromSlug : String -> Elm.Expression
postFromSlug postFromSlugArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Post" ]
            , name = "postFromSlug"
            , annotation =
                Just
                    (Type.function
                        [ Type.string ]
                        (Type.namedWith
                            [ "BackendTask" ]
                            "BackendTask"
                            [ Type.namedWith [ "FatalError" ] "FatalError" []
                            , Type.namedWith [ "Post" ] "Post" []
                            ]
                        )
                    )
            }
        )
        [ Elm.string postFromSlugArg ]


annotation_ :
    { tag : Type.Annotation
    , post : Type.Annotation
    , collection : Type.Annotation
    }
annotation_ =
    { tag =
        Type.alias
            moduleName_
            "Tag"
            []
            (Type.record
                [ ( "id", Type.string )
                , ( "tagType", Type.namedWith [ "Post" ] "TagType" [] )
                ]
            )
    , post =
        Type.alias
            moduleName_
            "Post"
            []
            (Type.record
                [ ( "title", Type.string )
                , ( "slug", Type.string )
                , ( "body", Type.string )
                , ( "coverImage", Type.namedWith [ "Post" ] "Image" [] )
                , ( "author", Type.string )
                , ( "tags", Type.list (Type.namedWith [ "Post" ] "Tag" []) )
                , ( "publishedOn", Type.namedWith [ "Date" ] "Date" [] )
                ]
            )
    , collection =
        Type.alias
            moduleName_
            "Collection"
            []
            (Type.record
                [ ( "skip", Type.int )
                , ( "limit", Type.int )
                , ( "total", Type.int )
                , ( "items", Type.list (Type.namedWith [ "Post" ] "Post" []) )
                ]
            )
    }


make_ :
    { tag : { id : Elm.Expression, tagType : Elm.Expression } -> Elm.Expression
    , post :
        { title : Elm.Expression
        , slug : Elm.Expression
        , body : Elm.Expression
        , coverImage : Elm.Expression
        , author : Elm.Expression
        , tags : Elm.Expression
        , publishedOn : Elm.Expression
        }
        -> Elm.Expression
    , collection :
        { skip : Elm.Expression
        , limit : Elm.Expression
        , total : Elm.Expression
        , items : Elm.Expression
        }
        -> Elm.Expression
    }
make_ =
    { tag =
        \tag_args ->
            Elm.withType
                (Type.alias
                    [ "Post" ]
                    "Tag"
                    []
                    (Type.record
                        [ ( "id", Type.string )
                        , ( "tagType", Type.namedWith [ "Post" ] "TagType" [] )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "id" tag_args.id
                    , Tuple.pair "tagType" tag_args.tagType
                    ]
                )
    , post =
        \post_args ->
            Elm.withType
                (Type.alias
                    [ "Post" ]
                    "Post"
                    []
                    (Type.record
                        [ ( "title", Type.string )
                        , ( "slug", Type.string )
                        , ( "body", Type.string )
                        , ( "coverImage", Type.namedWith [ "Post" ] "Image" [] )
                        , ( "author", Type.string )
                        , ( "tags"
                          , Type.list (Type.namedWith [ "Post" ] "Tag" [])
                          )
                        , ( "publishedOn", Type.namedWith [ "Date" ] "Date" [] )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "title" post_args.title
                    , Tuple.pair "slug" post_args.slug
                    , Tuple.pair "body" post_args.body
                    , Tuple.pair "coverImage" post_args.coverImage
                    , Tuple.pair "author" post_args.author
                    , Tuple.pair "tags" post_args.tags
                    , Tuple.pair "publishedOn" post_args.publishedOn
                    ]
                )
    , collection =
        \collection_args ->
            Elm.withType
                (Type.alias
                    [ "Post" ]
                    "Collection"
                    []
                    (Type.record
                        [ ( "skip", Type.int )
                        , ( "limit", Type.int )
                        , ( "total", Type.int )
                        , ( "items"
                          , Type.list (Type.namedWith [ "Post" ] "Post" [])
                          )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "skip" collection_args.skip
                    , Tuple.pair "limit" collection_args.limit
                    , Tuple.pair "total" collection_args.total
                    , Tuple.pair "items" collection_args.items
                    ]
                )
    }


call_ :
    { tagToString : Elm.Expression -> Elm.Expression
    , getAllPosts : Elm.Expression -> Elm.Expression
    , postFromSlug : Elm.Expression -> Elm.Expression
    }
call_ =
    { tagToString =
        \tagToStringArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Post" ]
                    , name = "tagToString"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Post" ] "Tag" [] ]
                                Type.string
                            )
                    }
                )
                [ tagToStringArg ]
    , getAllPosts =
        \getAllPostsArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Post" ]
                    , name = "getAllPosts"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.maybe
                                    (Type.namedWith [ "Post" ] "Tag" [])
                                ]
                                (Type.namedWith
                                    [ "BackendTask" ]
                                    "BackendTask"
                                    [ Type.namedWith
                                        [ "FatalError" ]
                                        "FatalError"
                                        []
                                    , Type.list
                                        (Type.namedWith [ "Post" ] "Post" [])
                                    ]
                                )
                            )
                    }
                )
                [ getAllPostsArg ]
    , postFromSlug =
        \postFromSlugArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Post" ]
                    , name = "postFromSlug"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.string ]
                                (Type.namedWith
                                    [ "BackendTask" ]
                                    "BackendTask"
                                    [ Type.namedWith
                                        [ "FatalError" ]
                                        "FatalError"
                                        []
                                    , Type.namedWith [ "Post" ] "Post" []
                                    ]
                                )
                            )
                    }
                )
                [ postFromSlugArg ]
    }


values_ :
    { tagToString : Elm.Expression
    , blogPosts : Elm.Expression
    , newsPosts : Elm.Expression
    , getAllPosts : Elm.Expression
    , postFromSlug : Elm.Expression
    }
values_ =
    { tagToString =
        Elm.value
            { importFrom = [ "Post" ]
            , name = "tagToString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Post" ] "Tag" [] ]
                        Type.string
                    )
            }
    , blogPosts =
        Elm.value
            { importFrom = [ "Post" ]
            , name = "blogPosts"
            , annotation =
                Just
                    (Type.namedWith
                        [ "BackendTask" ]
                        "BackendTask"
                        [ Type.namedWith [ "FatalError" ] "FatalError" []
                        , Type.list (Type.namedWith [ "Post" ] "Post" [])
                        ]
                    )
            }
    , newsPosts =
        Elm.value
            { importFrom = [ "Post" ]
            , name = "newsPosts"
            , annotation =
                Just
                    (Type.namedWith
                        [ "BackendTask" ]
                        "BackendTask"
                        [ Type.namedWith [ "FatalError" ] "FatalError" []
                        , Type.list (Type.namedWith [ "Post" ] "Post" [])
                        ]
                    )
            }
    , getAllPosts =
        Elm.value
            { importFrom = [ "Post" ]
            , name = "getAllPosts"
            , annotation =
                Just
                    (Type.function
                        [ Type.maybe (Type.namedWith [ "Post" ] "Tag" []) ]
                        (Type.namedWith
                            [ "BackendTask" ]
                            "BackendTask"
                            [ Type.namedWith [ "FatalError" ] "FatalError" []
                            , Type.list (Type.namedWith [ "Post" ] "Post" [])
                            ]
                        )
                    )
            }
    , postFromSlug =
        Elm.value
            { importFrom = [ "Post" ]
            , name = "postFromSlug"
            , annotation =
                Just
                    (Type.function
                        [ Type.string ]
                        (Type.namedWith
                            [ "BackendTask" ]
                            "BackendTask"
                            [ Type.namedWith [ "FatalError" ] "FatalError" []
                            , Type.namedWith [ "Post" ] "Post" []
                            ]
                        )
                    )
            }
    }