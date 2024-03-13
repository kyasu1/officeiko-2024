module Gen.Route exposing (annotation_, baseUrl, baseUrlAsPath, call_, caseOf_, link, make_, moduleName_, redirectTo, routeToPath, segmentsToRoute, toLink, toPath, toString, urlToRoute, values_, withoutBaseUrl)

{-| 
@docs moduleName_, withoutBaseUrl, link, toLink, redirectTo, toString, toPath, baseUrlAsPath, routeToPath, baseUrl, urlToRoute, segmentsToRoute, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route" ]


{-| {-| . -}

withoutBaseUrl: String -> String
-}
withoutBaseUrl : String -> Elm.Expression
withoutBaseUrl withoutBaseUrlArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "withoutBaseUrl"
            , annotation = Just (Type.function [ Type.string ] Type.string)
            }
        )
        [ Elm.string withoutBaseUrlArg ]


{-| {-| . -}

link: 
    List (Html.Attribute msg)
    -> List (Html.Html msg)
    -> Route.Route
    -> Html.Html msg
-}
link :
    List Elm.Expression
    -> List Elm.Expression
    -> Elm.Expression
    -> Elm.Expression
link linkArg linkArg0 linkArg1 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "link"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Html" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ]
                            )
                        , Type.namedWith [ "Route" ] "Route" []
                        ]
                        (Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.list linkArg, Elm.list linkArg0, linkArg1 ]


{-| {-| . -}

toLink: (List (Html.Attribute msg) -> abc) -> Route.Route -> abc
-}
toLink : (Elm.Expression -> Elm.Expression) -> Elm.Expression -> Elm.Expression
toLink toLinkArg toLinkArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "toLink"
            , annotation =
                Just
                    (Type.function
                        [ Type.function
                            [ Type.list
                                (Type.namedWith
                                    [ "Html" ]
                                    "Attribute"
                                    [ Type.var "msg" ]
                                )
                            ]
                            (Type.var "abc")
                        , Type.namedWith [ "Route" ] "Route" []
                        ]
                        (Type.var "abc")
                    )
            }
        )
        [ Elm.functionReduced "toLinkUnpack" toLinkArg, toLinkArg0 ]


{-| {-| . -}

redirectTo: Route.Route -> Server.Response.Response data error
-}
redirectTo : Elm.Expression -> Elm.Expression
redirectTo redirectToArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "redirectTo"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith
                            [ "Server", "Response" ]
                            "Response"
                            [ Type.var "data", Type.var "error" ]
                        )
                    )
            }
        )
        [ redirectToArg ]


{-| {-| . -}

toString: Route.Route -> String
-}
toString : Elm.Expression -> Elm.Expression
toString toStringArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "toString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        Type.string
                    )
            }
        )
        [ toStringArg ]


{-| {-| . -}

toPath: Route.Route -> UrlPath.UrlPath
-}
toPath : Elm.Expression -> Elm.Expression
toPath toPathArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "toPath"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith [ "UrlPath" ] "UrlPath" [])
                    )
            }
        )
        [ toPathArg ]


{-| {-| . -}

baseUrlAsPath: List String
-}
baseUrlAsPath : Elm.Expression
baseUrlAsPath =
    Elm.value
        { importFrom = [ "Route" ]
        , name = "baseUrlAsPath"
        , annotation = Just (Type.list Type.string)
        }


{-| {-| . -}

routeToPath: Route.Route -> List String
-}
routeToPath : Elm.Expression -> Elm.Expression
routeToPath routeToPathArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "routeToPath"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.list Type.string)
                    )
            }
        )
        [ routeToPathArg ]


{-| {-| . -}

baseUrl: String
-}
baseUrl : Elm.Expression
baseUrl =
    Elm.value
        { importFrom = [ "Route" ]
        , name = "baseUrl"
        , annotation = Just Type.string
        }


{-| {-| . -}

urlToRoute: { url | path : String } -> Maybe Route.Route
-}
urlToRoute : { url | path : String } -> Elm.Expression
urlToRoute urlToRouteArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "urlToRoute"
            , annotation =
                Just
                    (Type.function
                        [ Type.extensible "url" [ ( "path", Type.string ) ] ]
                        (Type.maybe (Type.namedWith [ "Route" ] "Route" []))
                    )
            }
        )
        [ Elm.record [ Tuple.pair "path" (Elm.string urlToRouteArg.path) ] ]


{-| {-| . -}

segmentsToRoute: List String -> Maybe Route.Route
-}
segmentsToRoute : List String -> Elm.Expression
segmentsToRoute segmentsToRouteArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Route" ]
            , name = "segmentsToRoute"
            , annotation =
                Just
                    (Type.function
                        [ Type.list Type.string ]
                        (Type.maybe (Type.namedWith [ "Route" ] "Route" []))
                    )
            }
        )
        [ Elm.list (List.map Elm.string segmentsToRouteArg) ]


annotation_ : { route : Type.Annotation }
annotation_ =
    { route = Type.namedWith [ "Route" ] "Route" [] }


make_ :
    { post__Slug_ : Elm.Expression -> Elm.Expression
    , about : Elm.Expression
    , calendar : Elm.Expression
    , contact : Elm.Expression
    , faq : Elm.Expression
    , kaitoriTicket : Elm.Expression
    , line : Elm.Expression
    , pawn : Elm.Expression
    , posts : Elm.Expression
    , privacy : Elm.Expression
    , selling : Elm.Expression
    , stocks : Elm.Expression
    , tokutei : Elm.Expression
    , westernUnion : Elm.Expression
    , index : Elm.Expression
    }
make_ =
    { post__Slug_ =
        \ar0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "Post__Slug_"
                    , annotation = Just (Type.namedWith [] "Route" [])
                    }
                )
                [ ar0 ]
    , about =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "About"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , calendar =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Calendar"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , contact =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Contact"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , faq =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Faq"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , kaitoriTicket =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "KaitoriTicket"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , line =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Line"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , pawn =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Pawn"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , posts =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Posts"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , privacy =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Privacy"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , selling =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Selling"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , stocks =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Stocks"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , tokutei =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Tokutei"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , westernUnion =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "WesternUnion"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    , index =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "Index"
            , annotation = Just (Type.namedWith [] "Route" [])
            }
    }


caseOf_ :
    { route :
        Elm.Expression
        -> { routeTags_0_0
            | post__Slug_ : Elm.Expression -> Elm.Expression
            , about : Elm.Expression
            , calendar : Elm.Expression
            , contact : Elm.Expression
            , faq : Elm.Expression
            , kaitoriTicket : Elm.Expression
            , line : Elm.Expression
            , pawn : Elm.Expression
            , posts : Elm.Expression
            , privacy : Elm.Expression
            , selling : Elm.Expression
            , stocks : Elm.Expression
            , tokutei : Elm.Expression
            , westernUnion : Elm.Expression
            , index : Elm.Expression
        }
        -> Elm.Expression
    }
caseOf_ =
    { route =
        \routeExpression routeTags ->
            Elm.Case.custom
                routeExpression
                (Type.namedWith [ "Route" ] "Route" [])
                [ Elm.Case.branch1
                    "Post__Slug_"
                    ( "one", Type.record [ ( "slug", Type.string ) ] )
                    routeTags.post__Slug_
                , Elm.Case.branch0 "About" routeTags.about
                , Elm.Case.branch0 "Calendar" routeTags.calendar
                , Elm.Case.branch0 "Contact" routeTags.contact
                , Elm.Case.branch0 "Faq" routeTags.faq
                , Elm.Case.branch0 "KaitoriTicket" routeTags.kaitoriTicket
                , Elm.Case.branch0 "Line" routeTags.line
                , Elm.Case.branch0 "Pawn" routeTags.pawn
                , Elm.Case.branch0 "Posts" routeTags.posts
                , Elm.Case.branch0 "Privacy" routeTags.privacy
                , Elm.Case.branch0 "Selling" routeTags.selling
                , Elm.Case.branch0 "Stocks" routeTags.stocks
                , Elm.Case.branch0 "Tokutei" routeTags.tokutei
                , Elm.Case.branch0 "WesternUnion" routeTags.westernUnion
                , Elm.Case.branch0 "Index" routeTags.index
                ]
    }


call_ :
    { withoutBaseUrl : Elm.Expression -> Elm.Expression
    , link :
        Elm.Expression -> Elm.Expression -> Elm.Expression -> Elm.Expression
    , toLink : Elm.Expression -> Elm.Expression -> Elm.Expression
    , redirectTo : Elm.Expression -> Elm.Expression
    , toString : Elm.Expression -> Elm.Expression
    , toPath : Elm.Expression -> Elm.Expression
    , routeToPath : Elm.Expression -> Elm.Expression
    , urlToRoute : Elm.Expression -> Elm.Expression
    , segmentsToRoute : Elm.Expression -> Elm.Expression
    }
call_ =
    { withoutBaseUrl =
        \withoutBaseUrlArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "withoutBaseUrl"
                    , annotation =
                        Just (Type.function [ Type.string ] Type.string)
                    }
                )
                [ withoutBaseUrlArg ]
    , link =
        \linkArg linkArg0 linkArg1 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "link"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list
                                    (Type.namedWith
                                        [ "Html" ]
                                        "Attribute"
                                        [ Type.var "msg" ]
                                    )
                                , Type.list
                                    (Type.namedWith
                                        [ "Html" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                , Type.namedWith [ "Route" ] "Route" []
                                ]
                                (Type.namedWith
                                    [ "Html" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ linkArg, linkArg0, linkArg1 ]
    , toLink =
        \toLinkArg toLinkArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "toLink"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.function
                                    [ Type.list
                                        (Type.namedWith
                                            [ "Html" ]
                                            "Attribute"
                                            [ Type.var "msg" ]
                                        )
                                    ]
                                    (Type.var "abc")
                                , Type.namedWith [ "Route" ] "Route" []
                                ]
                                (Type.var "abc")
                            )
                    }
                )
                [ toLinkArg, toLinkArg0 ]
    , redirectTo =
        \redirectToArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "redirectTo"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Route" ] "Route" [] ]
                                (Type.namedWith
                                    [ "Server", "Response" ]
                                    "Response"
                                    [ Type.var "data", Type.var "error" ]
                                )
                            )
                    }
                )
                [ redirectToArg ]
    , toString =
        \toStringArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "toString"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Route" ] "Route" [] ]
                                Type.string
                            )
                    }
                )
                [ toStringArg ]
    , toPath =
        \toPathArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "toPath"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Route" ] "Route" [] ]
                                (Type.namedWith [ "UrlPath" ] "UrlPath" [])
                            )
                    }
                )
                [ toPathArg ]
    , routeToPath =
        \routeToPathArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "routeToPath"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Route" ] "Route" [] ]
                                (Type.list Type.string)
                            )
                    }
                )
                [ routeToPathArg ]
    , urlToRoute =
        \urlToRouteArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "urlToRoute"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.extensible
                                    "url"
                                    [ ( "path", Type.string ) ]
                                ]
                                (Type.maybe
                                    (Type.namedWith [ "Route" ] "Route" [])
                                )
                            )
                    }
                )
                [ urlToRouteArg ]
    , segmentsToRoute =
        \segmentsToRouteArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "segmentsToRoute"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list Type.string ]
                                (Type.maybe
                                    (Type.namedWith [ "Route" ] "Route" [])
                                )
                            )
                    }
                )
                [ segmentsToRouteArg ]
    }


values_ :
    { withoutBaseUrl : Elm.Expression
    , link : Elm.Expression
    , toLink : Elm.Expression
    , redirectTo : Elm.Expression
    , toString : Elm.Expression
    , toPath : Elm.Expression
    , baseUrlAsPath : Elm.Expression
    , routeToPath : Elm.Expression
    , baseUrl : Elm.Expression
    , urlToRoute : Elm.Expression
    , segmentsToRoute : Elm.Expression
    }
values_ =
    { withoutBaseUrl =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "withoutBaseUrl"
            , annotation = Just (Type.function [ Type.string ] Type.string)
            }
    , link =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "link"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Html" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ]
                            )
                        , Type.namedWith [ "Route" ] "Route" []
                        ]
                        (Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ])
                    )
            }
    , toLink =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "toLink"
            , annotation =
                Just
                    (Type.function
                        [ Type.function
                            [ Type.list
                                (Type.namedWith
                                    [ "Html" ]
                                    "Attribute"
                                    [ Type.var "msg" ]
                                )
                            ]
                            (Type.var "abc")
                        , Type.namedWith [ "Route" ] "Route" []
                        ]
                        (Type.var "abc")
                    )
            }
    , redirectTo =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "redirectTo"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith
                            [ "Server", "Response" ]
                            "Response"
                            [ Type.var "data", Type.var "error" ]
                        )
                    )
            }
    , toString =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "toString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        Type.string
                    )
            }
    , toPath =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "toPath"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith [ "UrlPath" ] "UrlPath" [])
                    )
            }
    , baseUrlAsPath =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "baseUrlAsPath"
            , annotation = Just (Type.list Type.string)
            }
    , routeToPath =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "routeToPath"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.list Type.string)
                    )
            }
    , baseUrl =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "baseUrl"
            , annotation = Just Type.string
            }
    , urlToRoute =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "urlToRoute"
            , annotation =
                Just
                    (Type.function
                        [ Type.extensible "url" [ ( "path", Type.string ) ] ]
                        (Type.maybe (Type.namedWith [ "Route" ] "Route" []))
                    )
            }
    , segmentsToRoute =
        Elm.value
            { importFrom = [ "Route" ]
            , name = "segmentsToRoute"
            , annotation =
                Just
                    (Type.function
                        [ Type.list Type.string ]
                        (Type.maybe (Type.namedWith [ "Route" ] "Route" []))
                    )
            }
    }