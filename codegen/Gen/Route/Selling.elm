module Gen.Route.Selling exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Selling" ]


{-| route: RouteBuilder.StatefulRoute Route.Selling.RouteParams Route.Selling.Data Route.Selling.ActionData Route.Selling.Model Route.Selling.Msg -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Selling" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatefulRoute"
                    [ Type.namedWith [ "Route", "Selling" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Selling" ] "Data" []
                    , Type.namedWith [ "Route", "Selling" ] "ActionData" []
                    , Type.namedWith [ "Route", "Selling" ] "Model" []
                    , Type.namedWith [ "Route", "Selling" ] "Msg" []
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
    , msg = Type.namedWith [ "Route", "Selling" ] "Msg" []
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
                    [ "Route", "Selling" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias [ "Route", "Selling" ] "Data" [] (Type.record []))
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Selling" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Selling" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Selling" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatefulRoute"
                        [ Type.namedWith [ "Route", "Selling" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Selling" ] "Data" []
                        , Type.namedWith [ "Route", "Selling" ] "ActionData" []
                        , Type.namedWith [ "Route", "Selling" ] "Model" []
                        , Type.namedWith [ "Route", "Selling" ] "Msg" []
                        ]
                    )
            }
    }