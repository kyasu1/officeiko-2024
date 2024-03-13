module Gen.Pawn exposing (annotation_, call_, init, make_, moduleName_, update, values_, view)

{-| 
@docs moduleName_, view, update, init, annotation_, make_, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Pawn" ]


{-| view: Pawn.Model -> Pawn.Html Pawn.Msg -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Pawn" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Pawn" ] "Model" [] ]
                        (Type.namedWith
                            [ "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        )
                    )
            }
        )
        [ viewArg ]


{-| update: Shared.Model -> Pawn.Msg -> Pawn.Model -> ( Pawn.Model, Effect.Effect Pawn.Msg ) -}
update : Elm.Expression -> Elm.Expression -> Elm.Expression -> Elm.Expression
update updateArg updateArg0 updateArg1 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Pawn" ]
            , name = "update"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Shared" ] "Model" []
                        , Type.namedWith [ "Pawn" ] "Msg" []
                        , Type.namedWith [ "Pawn" ] "Model" []
                        ]
                        (Type.tuple
                            (Type.namedWith [ "Pawn" ] "Model" [])
                            (Type.namedWith
                                [ "Effect" ]
                                "Effect"
                                [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                            )
                        )
                    )
            }
        )
        [ updateArg, updateArg0, updateArg1 ]


{-| init: Date.Date -> Pawn.Model -}
init : Elm.Expression -> Elm.Expression
init initArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Pawn" ]
            , name = "init"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Date" ] "Date" [] ]
                        (Type.namedWith [ "Pawn" ] "Model" [])
                    )
            }
        )
        [ initArg ]


annotation_ : { model : Type.Annotation, msg : Type.Annotation }
annotation_ =
    { model =
        Type.alias
            moduleName_
            "Model"
            []
            (Type.record
                [ ( "form", Type.namedWith [ "Pawn" ] "Form" [] )
                , ( "contract"
                  , Type.maybe (Type.namedWith [ "Pawn" ] "Contract" [])
                  )
                ]
            )
    , msg = Type.namedWith [ "Pawn" ] "Msg" []
    }


make_ :
    { model :
        { form : Elm.Expression, contract : Elm.Expression } -> Elm.Expression
    }
make_ =
    { model =
        \model_args ->
            Elm.withType
                (Type.alias
                    [ "Pawn" ]
                    "Model"
                    []
                    (Type.record
                        [ ( "form", Type.namedWith [ "Pawn" ] "Form" [] )
                        , ( "contract"
                          , Type.maybe (Type.namedWith [ "Pawn" ] "Contract" [])
                          )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "form" model_args.form
                    , Tuple.pair "contract" model_args.contract
                    ]
                )
    }


call_ :
    { view : Elm.Expression -> Elm.Expression
    , update :
        Elm.Expression -> Elm.Expression -> Elm.Expression -> Elm.Expression
    , init : Elm.Expression -> Elm.Expression
    }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Pawn" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Pawn" ] "Model" [] ]
                                (Type.namedWith
                                    [ "Pawn" ]
                                    "Html"
                                    [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                                )
                            )
                    }
                )
                [ viewArg ]
    , update =
        \updateArg updateArg0 updateArg1 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Pawn" ]
                    , name = "update"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Shared" ] "Model" []
                                , Type.namedWith [ "Pawn" ] "Msg" []
                                , Type.namedWith [ "Pawn" ] "Model" []
                                ]
                                (Type.tuple
                                    (Type.namedWith [ "Pawn" ] "Model" [])
                                    (Type.namedWith
                                        [ "Effect" ]
                                        "Effect"
                                        [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                                    )
                                )
                            )
                    }
                )
                [ updateArg, updateArg0, updateArg1 ]
    , init =
        \initArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Pawn" ]
                    , name = "init"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Date" ] "Date" [] ]
                                (Type.namedWith [ "Pawn" ] "Model" [])
                            )
                    }
                )
                [ initArg ]
    }


values_ :
    { view : Elm.Expression, update : Elm.Expression, init : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Pawn" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Pawn" ] "Model" [] ]
                        (Type.namedWith
                            [ "Pawn" ]
                            "Html"
                            [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                        )
                    )
            }
    , update =
        Elm.value
            { importFrom = [ "Pawn" ]
            , name = "update"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Shared" ] "Model" []
                        , Type.namedWith [ "Pawn" ] "Msg" []
                        , Type.namedWith [ "Pawn" ] "Model" []
                        ]
                        (Type.tuple
                            (Type.namedWith [ "Pawn" ] "Model" [])
                            (Type.namedWith
                                [ "Effect" ]
                                "Effect"
                                [ Type.namedWith [ "Pawn" ] "Msg" [] ]
                            )
                        )
                    )
            }
    , init =
        Elm.value
            { importFrom = [ "Pawn" ]
            , name = "init"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Date" ] "Date" [] ]
                        (Type.namedWith [ "Pawn" ] "Model" [])
                    )
            }
    }