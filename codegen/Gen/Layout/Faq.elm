module Gen.Layout.Faq exposing (call_, moduleName_, qAndA, values_, view)

{-| 
@docs moduleName_, qAndA, view, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Faq" ]


{-| qAndA: ( String, List (Layout.Faq.Html msg) ) -> Layout.Faq.Html msg -}
qAndA : Elm.Expression -> Elm.Expression
qAndA qAndAArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Faq" ]
            , name = "qAndA"
            , annotation =
                Just
                    (Type.function
                        [ Type.tuple
                            Type.string
                            (Type.list
                                (Type.namedWith
                                    [ "Layout", "Faq" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                        ]
                        (Type.namedWith
                            [ "Layout", "Faq" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
        )
        [ qAndAArg ]


{-| view: List (Layout.Faq.Html msg) -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "Faq" ]
        , name = "view"
        , annotation =
            Just
                (Type.list
                    (Type.namedWith
                        [ "Layout", "Faq" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
                )
        }


call_ : { qAndA : Elm.Expression -> Elm.Expression }
call_ =
    { qAndA =
        \qAndAArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Faq" ]
                    , name = "qAndA"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.tuple
                                    Type.string
                                    (Type.list
                                        (Type.namedWith
                                            [ "Layout", "Faq" ]
                                            "Html"
                                            [ Type.var "msg" ]
                                        )
                                    )
                                ]
                                (Type.namedWith
                                    [ "Layout", "Faq" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ qAndAArg ]
    }


values_ : { qAndA : Elm.Expression, view : Elm.Expression }
values_ =
    { qAndA =
        Elm.value
            { importFrom = [ "Layout", "Faq" ]
            , name = "qAndA"
            , annotation =
                Just
                    (Type.function
                        [ Type.tuple
                            Type.string
                            (Type.list
                                (Type.namedWith
                                    [ "Layout", "Faq" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                        ]
                        (Type.namedWith
                            [ "Layout", "Faq" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    , view =
        Elm.value
            { importFrom = [ "Layout", "Faq" ]
            , name = "view"
            , annotation =
                Just
                    (Type.list
                        (Type.namedWith
                            [ "Layout", "Faq" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }