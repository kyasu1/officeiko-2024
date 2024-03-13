module Gen.Layout.Pawn exposing (call_, moduleName_, values_, view)

{-| 
@docs moduleName_, view, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Pawn" ]


{-| view: Layout.Pawn.Html Pawn.Msg -> Layout.Pawn.Html Pawn.Msg -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Pawn" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith
                            [ "Layout", "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        ]
                        (Type.namedWith
                            [ "Layout", "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        )
                    )
            }
        )
        [ viewArg ]


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Pawn" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith
                                    [ "Layout", "Pawn" ]
                                    "Html"
                                    [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                                ]
                                (Type.namedWith
                                    [ "Layout", "Pawn" ]
                                    "Html"
                                    [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                                )
                            )
                    }
                )
                [ viewArg ]
    }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "Pawn" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith
                            [ "Layout", "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        ]
                        (Type.namedWith
                            [ "Layout", "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        )
                    )
            }
    }