module Gen.Route.Stocks exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Stocks" ]


{-| route: RouteBuilder.StatefulRoute Route.Stocks.RouteParams Route.Stocks.Data Route.Stocks.ActionData Route.Stocks.Model Route.Stocks.Msg -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Stocks" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatefulRoute"
                    [ Type.namedWith [ "Route", "Stocks" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Stocks" ] "Data" []
                    , Type.namedWith [ "Route", "Stocks" ] "ActionData" []
                    , Type.namedWith [ "Route", "Stocks" ] "Model" []
                    , Type.namedWith [ "Route", "Stocks" ] "Msg" []
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
    , data = Type.alias moduleName_ "Data" [] Type.unit
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    , msg = Type.namedWith [ "Route", "Stocks" ] "Msg" []
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , routeParams : routeParams -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Stocks" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Stocks" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Stocks" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Stocks" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatefulRoute"
                        [ Type.namedWith [ "Route", "Stocks" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Stocks" ] "Data" []
                        , Type.namedWith [ "Route", "Stocks" ] "ActionData" []
                        , Type.namedWith [ "Route", "Stocks" ] "Model" []
                        , Type.namedWith [ "Route", "Stocks" ] "Msg" []
                        ]
                    )
            }
    }