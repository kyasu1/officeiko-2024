module Gen.Layout.KaitoriTicket exposing (annotation_, call_, data, make_, moduleName_, values_, view)

{-| 
@docs moduleName_, data, view, annotation_, make_, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "KaitoriTicket" ]


{-| data: BackendTask.BackendTask FatalError.FatalError Layout.KaitoriTicket.TicketFile -}
data : Elm.Expression
data =
    Elm.value
        { importFrom = [ "Layout", "KaitoriTicket" ]
        , name = "data"
        , annotation =
            Just
                (Type.namedWith
                    [ "BackendTask" ]
                    "BackendTask"
                    [ Type.namedWith [ "FatalError" ] "FatalError" []
                    , Type.namedWith
                        [ "Layout", "KaitoriTicket" ]
                        "TicketFile"
                        []
                    ]
                )
        }


{-| view: Layout.KaitoriTicket.TicketFile -> List (Layout.KaitoriTicket.Html msg) -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "KaitoriTicket" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith
                            [ "Layout", "KaitoriTicket" ]
                            "TicketFile"
                            []
                        ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "KaitoriTicket" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
        )
        [ viewArg ]


annotation_ : { ticketFile : Type.Annotation }
annotation_ =
    { ticketFile =
        Type.alias
            moduleName_
            "TicketFile"
            []
            (Type.record
                [ ( "date", Type.namedWith [ "Date" ] "Date" [] )
                , ( "items"
                  , Type.list
                        (Type.namedWith
                            [ "Layout", "KaitoriTicket" ]
                            "Ticket"
                            []
                        )
                  )
                ]
            )
    }


make_ :
    { ticketFile :
        { date : Elm.Expression, items : Elm.Expression } -> Elm.Expression
    }
make_ =
    { ticketFile =
        \ticketFile_args ->
            Elm.withType
                (Type.alias
                    [ "Layout", "KaitoriTicket" ]
                    "TicketFile"
                    []
                    (Type.record
                        [ ( "date", Type.namedWith [ "Date" ] "Date" [] )
                        , ( "items"
                          , Type.list
                                (Type.namedWith
                                    [ "Layout", "KaitoriTicket" ]
                                    "Ticket"
                                    []
                                )
                          )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "date" ticketFile_args.date
                    , Tuple.pair "items" ticketFile_args.items
                    ]
                )
    }


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "KaitoriTicket" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith
                                    [ "Layout", "KaitoriTicket" ]
                                    "TicketFile"
                                    []
                                ]
                                (Type.list
                                    (Type.namedWith
                                        [ "Layout", "KaitoriTicket" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                )
                            )
                    }
                )
                [ viewArg ]
    }


values_ : { data : Elm.Expression, view : Elm.Expression }
values_ =
    { data =
        Elm.value
            { importFrom = [ "Layout", "KaitoriTicket" ]
            , name = "data"
            , annotation =
                Just
                    (Type.namedWith
                        [ "BackendTask" ]
                        "BackendTask"
                        [ Type.namedWith [ "FatalError" ] "FatalError" []
                        , Type.namedWith
                            [ "Layout", "KaitoriTicket" ]
                            "TicketFile"
                            []
                        ]
                    )
            }
    , view =
        Elm.value
            { importFrom = [ "Layout", "KaitoriTicket" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith
                            [ "Layout", "KaitoriTicket" ]
                            "TicketFile"
                            []
                        ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "KaitoriTicket" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
    }