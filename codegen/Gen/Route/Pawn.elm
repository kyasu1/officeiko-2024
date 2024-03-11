module Gen.Route.Pawn exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Pawn" ]


{-| route: RouteBuilder.StatefulRoute Route.Pawn.RouteParams Route.Pawn.Data Route.Pawn.ActionData Route.Pawn.Model Route.Pawn.Msg -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Pawn" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatefulRoute"
                    [ Type.namedWith [ "Route", "Pawn" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Pawn" ] "Data" []
                    , Type.namedWith [ "Route", "Pawn" ] "ActionData" []
                    , Type.namedWith [ "Route", "Pawn" ] "Model" []
                    , Type.namedWith [ "Route", "Pawn" ] "Msg" []
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
    , msg = Type.namedWith [ "Route", "Pawn" ] "Msg" []
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
                (Type.alias [ "Route", "Pawn" ] "ActionData" [] (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias [ "Route", "Pawn" ] "Data" [] (Type.record []))
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Pawn" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Pawn" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Pawn" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatefulRoute"
                        [ Type.namedWith [ "Route", "Pawn" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Pawn" ] "Data" []
                        , Type.namedWith [ "Route", "Pawn" ] "ActionData" []
                        , Type.namedWith [ "Route", "Pawn" ] "Model" []
                        , Type.namedWith [ "Route", "Pawn" ] "Msg" []
                        ]
                    )
            }
    }