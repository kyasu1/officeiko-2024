module Gen.Route.Tokutei exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Tokutei" ]


{-| route: RouteBuilder.StatelessRoute Route.Tokutei.RouteParams Route.Tokutei.Data Route.Tokutei.ActionData -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Tokutei" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatelessRoute"
                    [ Type.namedWith [ "Route", "Tokutei" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Tokutei" ] "Data" []
                    , Type.namedWith [ "Route", "Tokutei" ] "ActionData" []
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
                [ ( "privacy"
                  , Type.namedWith [ "Layout", "Privacy" ] "Privacy" []
                  )
                ]
            )
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , msg = Type.alias moduleName_ "Msg" [] Type.unit
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : { privacy : Elm.Expression } -> Elm.Expression
    , routeParams : routeParams -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Tokutei" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Tokutei" ]
                    "Data"
                    []
                    (Type.record
                        [ ( "privacy"
                          , Type.namedWith [ "Layout", "Privacy" ] "Privacy" []
                          )
                        ]
                    )
                )
                (Elm.record [ Tuple.pair "privacy" data_args.privacy ])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Tokutei" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Tokutei" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Tokutei" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatelessRoute"
                        [ Type.namedWith [ "Route", "Tokutei" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Tokutei" ] "Data" []
                        , Type.namedWith [ "Route", "Tokutei" ] "ActionData" []
                        ]
                    )
            }
    }