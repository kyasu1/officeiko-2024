module Gen.Route.WesternUnion exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "WesternUnion" ]


{-| route: RouteBuilder.StatefulRoute Route.WesternUnion.RouteParams Route.WesternUnion.Data Route.WesternUnion.ActionData Route.WesternUnion.Model Route.WesternUnion.Msg -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "WesternUnion" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatefulRoute"
                    [ Type.namedWith
                        [ "Route", "WesternUnion" ]
                        "RouteParams"
                        []
                    , Type.namedWith [ "Route", "WesternUnion" ] "Data" []
                    , Type.namedWith [ "Route", "WesternUnion" ] "ActionData" []
                    , Type.namedWith [ "Route", "WesternUnion" ] "Model" []
                    , Type.namedWith [ "Route", "WesternUnion" ] "Msg" []
                    ]
                )
        }


annotation_ :
    { actionData : Type.Annotation
    , data : Type.Annotation
    , routeParams : Type.Annotation
    , model : Type.Annotation
    , msg : Type.Annotation
    }
annotation_ =
    { actionData = Type.alias moduleName_ "ActionData" [] (Type.record [])
    , data = Type.alias moduleName_ "Data" [] (Type.record [])
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    , msg = Type.namedWith [ "Route", "WesternUnion" ] "Msg" []
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : data -> Elm.Expression
    , routeParams : routeParams -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "WesternUnion" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "WesternUnion" ]
                    "Data"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "WesternUnion" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "WesternUnion" ]
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
            { importFrom = [ "Route", "WesternUnion" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatefulRoute"
                        [ Type.namedWith
                            [ "Route", "WesternUnion" ]
                            "RouteParams"
                            []
                        , Type.namedWith [ "Route", "WesternUnion" ] "Data" []
                        , Type.namedWith
                            [ "Route", "WesternUnion" ]
                            "ActionData"
                            []
                        , Type.namedWith [ "Route", "WesternUnion" ] "Model" []
                        , Type.namedWith [ "Route", "WesternUnion" ] "Msg" []
                        ]
                    )
            }
    }