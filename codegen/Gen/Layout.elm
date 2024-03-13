module Gen.Layout exposing (call_, externalLink, hero, image, link, moduleName_, section, values_)

{-| 
@docs moduleName_, externalLink, link, image, hero, section, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout" ]


{-| externalLink: String -> List (Layout.Html msg) -> Layout.Html msg -}
externalLink : String -> List Elm.Expression -> Elm.Expression
externalLink externalLinkArg externalLinkArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout" ]
            , name = "externalLink"
            , annotation =
                Just
                    (Type.function
                        [ Type.string
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.string externalLinkArg, Elm.list externalLinkArg0 ]


{-| link: String -> Route.Route -> Layout.Html msg -}
link : String -> Elm.Expression -> Elm.Expression
link linkArg linkArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout" ]
            , name = "link"
            , annotation =
                Just
                    (Type.function
                        [ Type.string, Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.string linkArg, linkArg0 ]


{-| image: List (Layout.Attribute msg) -> Layout.Html msg -> Layout.Html msg -}
image : List Elm.Expression -> Elm.Expression -> Elm.Expression
image imageArg imageArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout" ]
            , name = "image"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ]
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.list imageArg, imageArg0 ]


{-| hero: List (Layout.Attribute msg) -> List (Layout.Html msg) -> Layout.Html msg -}
hero : List Elm.Expression -> List Elm.Expression -> Elm.Expression
hero heroArg heroArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout" ]
            , name = "hero"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.list heroArg, Elm.list heroArg0 ]


{-| section: List (Layout.Attribute msg) -> List (Layout.Html msg) -> Layout.Html msg -}
section : List Elm.Expression -> List Elm.Expression -> Elm.Expression
section sectionArg sectionArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout" ]
            , name = "section"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.list sectionArg, Elm.list sectionArg0 ]


call_ :
    { externalLink : Elm.Expression -> Elm.Expression -> Elm.Expression
    , link : Elm.Expression -> Elm.Expression -> Elm.Expression
    , image : Elm.Expression -> Elm.Expression -> Elm.Expression
    , hero : Elm.Expression -> Elm.Expression -> Elm.Expression
    , section : Elm.Expression -> Elm.Expression -> Elm.Expression
    }
call_ =
    { externalLink =
        \externalLinkArg externalLinkArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout" ]
                    , name = "externalLink"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.string
                                , Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                ]
                                (Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ externalLinkArg, externalLinkArg0 ]
    , link =
        \linkArg linkArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout" ]
                    , name = "link"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.string
                                , Type.namedWith [ "Route" ] "Route" []
                                ]
                                (Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ linkArg, linkArg0 ]
    , image =
        \imageArg imageArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout" ]
                    , name = "image"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Attribute"
                                        [ Type.var "msg" ]
                                    )
                                , Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                ]
                                (Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ imageArg, imageArg0 ]
    , hero =
        \heroArg heroArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout" ]
                    , name = "hero"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Attribute"
                                        [ Type.var "msg" ]
                                    )
                                , Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                ]
                                (Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ heroArg, heroArg0 ]
    , section =
        \sectionArg sectionArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout" ]
                    , name = "section"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Attribute"
                                        [ Type.var "msg" ]
                                    )
                                , Type.list
                                    (Type.namedWith
                                        [ "Layout" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                ]
                                (Type.namedWith
                                    [ "Layout" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ sectionArg, sectionArg0 ]
    }


values_ :
    { externalLink : Elm.Expression
    , link : Elm.Expression
    , image : Elm.Expression
    , hero : Elm.Expression
    , section : Elm.Expression
    }
values_ =
    { externalLink =
        Elm.value
            { importFrom = [ "Layout" ]
            , name = "externalLink"
            , annotation =
                Just
                    (Type.function
                        [ Type.string
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
    , link =
        Elm.value
            { importFrom = [ "Layout" ]
            , name = "link"
            , annotation =
                Just
                    (Type.function
                        [ Type.string, Type.namedWith [ "Route" ] "Route" [] ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
    , image =
        Elm.value
            { importFrom = [ "Layout" ]
            , name = "image"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ]
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
    , hero =
        Elm.value
            { importFrom = [ "Layout" ]
            , name = "hero"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
    , section =
        Elm.value
            { importFrom = [ "Layout" ]
            , name = "section"
            , annotation =
                Just
                    (Type.function
                        [ Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Attribute"
                                [ Type.var "msg" ]
                            )
                        , Type.list
                            (Type.namedWith
                                [ "Layout" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        ]
                        (Type.namedWith [ "Layout" ] "Html" [ Type.var "msg" ])
                    )
            }
    }