module Gen.Route.KaitoriTicket exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "KaitoriTicket" ]


{-| route: RouteBuilder.StatelessRoute Route.KaitoriTicket.RouteParams Route.KaitoriTicket.Data Route.KaitoriTicket.ActionData -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "KaitoriTicket" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatelessRoute"
                    [ Type.namedWith
                        [ "Route", "KaitoriTicket" ]
                        "RouteParams"
                        []
                    , Type.namedWith [ "Route", "KaitoriTicket" ] "Data" []
                    , Type.namedWith
                        [ "Route", "KaitoriTicket" ]
                        "ActionData"
                        []
                    ]
                )
        }


annotation_ :
    { actionData : Type.Annotation
    , data : Type.Annotation
    , routeParams : Type.Annotation
    , msg : Type.Annotation
    , model : Type.Annotation
    }
annotation_ =
    { actionData = Type.alias moduleName_ "ActionData" [] (Type.record [])
    , data =
        Type.alias
            moduleName_
            "Data"
            []
            (Type.record
                [ ( "file"
                  , Type.namedWith [ "Layout", "KaitoriTicket" ] "TicketFile" []
                  )
                ]
            )
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , msg = Type.alias moduleName_ "Msg" [] Type.unit
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : { file : Elm.Expression } -> Elm.Expression
    , routeParams : routeParams -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "KaitoriTicket" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "KaitoriTicket" ]
                    "Data"
                    []
                    (Type.record
                        [ ( "file"
                          , Type.namedWith
                                [ "Layout", "KaitoriTicket" ]
                                "TicketFile"
                                []
                          )
                        ]
                    )
                )
                (Elm.record [ Tuple.pair "file" data_args.file ])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "KaitoriTicket" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "KaitoriTicket" ]
                    "Model"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "KaitoriTicket" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatelessRoute"
                        [ Type.namedWith
                            [ "Route", "KaitoriTicket" ]
                            "RouteParams"
                            []
                        , Type.namedWith [ "Route", "KaitoriTicket" ] "Data" []
                        , Type.namedWith
                            [ "Route", "KaitoriTicket" ]
                            "ActionData"
                            []
                        ]
                    )
            }
    }