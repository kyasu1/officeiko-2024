module Gen.Layout.Privacy exposing (annotation_, call_, file, make_, moduleName_, values_, view)

{-| 
@docs moduleName_, view, file, annotation_, make_, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Privacy" ]


{-| view: Layout.Privacy.Privacy -> Layout.Privacy.Html msg -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Privacy" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Layout", "Privacy" ] "Privacy" [] ]
                        (Type.namedWith
                            [ "Layout", "Privacy" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
        )
        [ viewArg ]


{-| file: 
    BackendTask.BackendTask { fatal : FatalError.FatalError
    , recoverable : BackendTask.File.FileReadError Json.Decode.Error
    } Layout.Privacy.Privacy
-}
file : Elm.Expression
file =
    Elm.value
        { importFrom = [ "Layout", "Privacy" ]
        , name = "file"
        , annotation =
            Just
                (Type.namedWith
                    [ "BackendTask" ]
                    "BackendTask"
                    [ Type.record
                        [ ( "fatal"
                          , Type.namedWith [ "FatalError" ] "FatalError" []
                          )
                        , ( "recoverable"
                          , Type.namedWith
                                [ "BackendTask", "File" ]
                                "FileReadError"
                                [ Type.namedWith [ "Json", "Decode" ] "Error" []
                                ]
                          )
                        ]
                    , Type.namedWith [ "Layout", "Privacy" ] "Privacy" []
                    ]
                )
        }


annotation_ : { privacy : Type.Annotation }
annotation_ =
    { privacy =
        Type.alias
            moduleName_
            "Privacy"
            []
            (Type.record
                [ ( "body", Type.string )
                , ( "title", Type.string )
                , ( "date", Type.string )
                , ( "slug", Type.string )
                ]
            )
    }


make_ :
    { privacy :
        { body : Elm.Expression
        , title : Elm.Expression
        , date : Elm.Expression
        , slug : Elm.Expression
        }
        -> Elm.Expression
    }
make_ =
    { privacy =
        \privacy_args ->
            Elm.withType
                (Type.alias
                    [ "Layout", "Privacy" ]
                    "Privacy"
                    []
                    (Type.record
                        [ ( "body", Type.string )
                        , ( "title", Type.string )
                        , ( "date", Type.string )
                        , ( "slug", Type.string )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "body" privacy_args.body
                    , Tuple.pair "title" privacy_args.title
                    , Tuple.pair "date" privacy_args.date
                    , Tuple.pair "slug" privacy_args.slug
                    ]
                )
    }


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Privacy" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith
                                    [ "Layout", "Privacy" ]
                                    "Privacy"
                                    []
                                ]
                                (Type.namedWith
                                    [ "Layout", "Privacy" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                )
                            )
                    }
                )
                [ viewArg ]
    }


values_ : { view : Elm.Expression, file : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "Privacy" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Layout", "Privacy" ] "Privacy" [] ]
                        (Type.namedWith
                            [ "Layout", "Privacy" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    , file =
        Elm.value
            { importFrom = [ "Layout", "Privacy" ]
            , name = "file"
            , annotation =
                Just
                    (Type.namedWith
                        [ "BackendTask" ]
                        "BackendTask"
                        [ Type.record
                            [ ( "fatal"
                              , Type.namedWith [ "FatalError" ] "FatalError" []
                              )
                            , ( "recoverable"
                              , Type.namedWith
                                    [ "BackendTask", "File" ]
                                    "FileReadError"
                                    [ Type.namedWith
                                        [ "Json", "Decode" ]
                                        "Error"
                                        []
                                    ]
                              )
                            ]
                        , Type.namedWith [ "Layout", "Privacy" ] "Privacy" []
                        ]
                    )
            }
    }