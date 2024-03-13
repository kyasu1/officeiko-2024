module Gen.Layout.Selling exposing (annotation_, call_, caseOf_, items, make_, moduleName_, row, rows, splitByTwo, values_, view)

{-| 
@docs moduleName_, splitByTwo, items, row, rows, view, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Selling" ]


{-| splitByTwo: List a -> List ( a, Maybe a ) -}
splitByTwo : List Elm.Expression -> Elm.Expression
splitByTwo splitByTwoArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "splitByTwo"
            , annotation =
                Just
                    (Type.function
                        [ Type.list (Type.var "a") ]
                        (Type.list
                            (Type.tuple
                                (Type.var "a")
                                (Type.maybe (Type.var "a"))
                            )
                        )
                    )
            }
        )
        [ Elm.list splitByTwoArg ]


{-| items: List (Layout.Selling.Item msg) -}
items : Elm.Expression
items =
    Elm.value
        { importFrom = [ "Layout", "Selling" ]
        , name = "items"
        , annotation =
            Just
                (Type.list
                    (Type.namedWith
                        [ "Layout", "Selling" ]
                        "Item"
                        [ Type.var "msg" ]
                    )
                )
        }


{-| row: Layout.Selling.Alignment -> Layout.Selling.Item msg -> Layout.Selling.Html msg -}
row : Elm.Expression -> Elm.Expression -> Elm.Expression
row rowArg rowArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "row"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Layout", "Selling" ] "Alignment" []
                        , Type.namedWith
                            [ "Layout", "Selling" ]
                            "Item"
                            [ Type.var "msg" ]
                        ]
                        (Type.namedWith
                            [ "Layout", "Selling" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
        )
        [ rowArg, rowArg0 ]


{-| rows: 
    ( Layout.Selling.Item msg, Maybe (Layout.Selling.Item msg) )
    -> List (Layout.Selling.Html msg)
-}
rows : Elm.Expression -> Elm.Expression
rows rowsArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "rows"
            , annotation =
                Just
                    (Type.function
                        [ Type.tuple
                            (Type.namedWith
                                [ "Layout", "Selling" ]
                                "Item"
                                [ Type.var "msg" ]
                            )
                            (Type.maybe
                                (Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Item"
                                    [ Type.var "msg" ]
                                )
                            )
                        ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "Selling" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
        )
        [ rowsArg ]


{-| view: Layout.Selling.Html msg -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "Selling" ]
        , name = "view"
        , annotation =
            Just
                (Type.namedWith
                    [ "Layout", "Selling" ]
                    "Html"
                    [ Type.var "msg" ]
                )
        }


annotation_ :
    { item : Type.Annotation -> Type.Annotation, alignment : Type.Annotation }
annotation_ =
    { item =
        \itemArg0 ->
            Type.alias
                moduleName_
                "Item"
                [ itemArg0 ]
                (Type.record
                    [ ( "header", Type.string )
                    , ( "body"
                      , Type.list
                            (Type.namedWith
                                [ "Layout", "Selling" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                      )
                    , ( "image", Type.string )
                    ]
                )
    , alignment = Type.namedWith [ "Layout", "Selling" ] "Alignment" []
    }


make_ :
    { item :
        { header : Elm.Expression
        , body : Elm.Expression
        , image : Elm.Expression
        }
        -> Elm.Expression
    , left : Elm.Expression
    , right : Elm.Expression
    }
make_ =
    { item =
        \item_args ->
            Elm.withType
                (Type.alias
                    [ "Layout", "Selling" ]
                    "Item"
                    [ Type.var "msg" ]
                    (Type.record
                        [ ( "header", Type.string )
                        , ( "body"
                          , Type.list
                                (Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                          )
                        , ( "image", Type.string )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "header" item_args.header
                    , Tuple.pair "body" item_args.body
                    , Tuple.pair "image" item_args.image
                    ]
                )
    , left =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "Left"
            , annotation = Just (Type.namedWith [] "Alignment" [])
            }
    , right =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "Right"
            , annotation = Just (Type.namedWith [] "Alignment" [])
            }
    }


caseOf_ :
    { alignment :
        Elm.Expression
        -> { alignmentTags_0_0 | left : Elm.Expression, right : Elm.Expression }
        -> Elm.Expression
    }
caseOf_ =
    { alignment =
        \alignmentExpression alignmentTags ->
            Elm.Case.custom
                alignmentExpression
                (Type.namedWith [ "Layout", "Selling" ] "Alignment" [])
                [ Elm.Case.branch0 "Left" alignmentTags.left
                , Elm.Case.branch0 "Right" alignmentTags.right
                ]
    }


call_ :
    { splitByTwo : Elm.Expression -> Elm.Expression
    , row : Elm.Expression -> Elm.Expression -> Elm.Expression
    , rows : Elm.Expression -> Elm.Expression
    }
call_ =
    { splitByTwo =
        \splitByTwoArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Selling" ]
                    , name = "splitByTwo"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list (Type.var "a") ]
                                (Type.list
                                    (Type.tuple
                                        (Type.var "a")
                                        (Type.maybe (Type.var "a"))
                                    )
                                )
                            )
                    }
                )
                [ splitByTwoArg ]
    , row =
        \rowArg rowArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Selling" ]
                    , name = "row"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Alignment"
                                    []
                                , Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Item"
                                    [ Type.var "msg" ]
                                ]
                                (Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ rowArg, rowArg0 ]
    , rows =
        \rowsArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Selling" ]
                    , name = "rows"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.tuple
                                    (Type.namedWith
                                        [ "Layout", "Selling" ]
                                        "Item"
                                        [ Type.var "msg" ]
                                    )
                                    (Type.maybe
                                        (Type.namedWith
                                            [ "Layout", "Selling" ]
                                            "Item"
                                            [ Type.var "msg" ]
                                        )
                                    )
                                ]
                                (Type.list
                                    (Type.namedWith
                                        [ "Layout", "Selling" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                )
                            )
                    }
                )
                [ rowsArg ]
    }


values_ :
    { splitByTwo : Elm.Expression
    , items : Elm.Expression
    , row : Elm.Expression
    , rows : Elm.Expression
    , view : Elm.Expression
    }
values_ =
    { splitByTwo =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "splitByTwo"
            , annotation =
                Just
                    (Type.function
                        [ Type.list (Type.var "a") ]
                        (Type.list
                            (Type.tuple
                                (Type.var "a")
                                (Type.maybe (Type.var "a"))
                            )
                        )
                    )
            }
    , items =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "items"
            , annotation =
                Just
                    (Type.list
                        (Type.namedWith
                            [ "Layout", "Selling" ]
                            "Item"
                            [ Type.var "msg" ]
                        )
                    )
            }
    , row =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "row"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Layout", "Selling" ] "Alignment" []
                        , Type.namedWith
                            [ "Layout", "Selling" ]
                            "Item"
                            [ Type.var "msg" ]
                        ]
                        (Type.namedWith
                            [ "Layout", "Selling" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    , rows =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "rows"
            , annotation =
                Just
                    (Type.function
                        [ Type.tuple
                            (Type.namedWith
                                [ "Layout", "Selling" ]
                                "Item"
                                [ Type.var "msg" ]
                            )
                            (Type.maybe
                                (Type.namedWith
                                    [ "Layout", "Selling" ]
                                    "Item"
                                    [ Type.var "msg" ]
                                )
                            )
                        ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "Selling" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
    , view =
        Elm.value
            { importFrom = [ "Layout", "Selling" ]
            , name = "view"
            , annotation =
                Just
                    (Type.namedWith
                        [ "Layout", "Selling" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
            }
    }