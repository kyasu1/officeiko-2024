module Gen.Route.Contact exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Contact" ]


{-| route: RouteBuilder.StatelessRoute Route.Contact.RouteParams Route.Contact.Data Route.Contact.ActionData -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Contact" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatelessRoute"
                    [ Type.namedWith [ "Route", "Contact" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Contact" ] "Data" []
                    , Type.namedWith [ "Route", "Contact" ] "ActionData" []
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
    , data = Type.alias moduleName_ "Data" [] (Type.record [])
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , msg = Type.alias moduleName_ "Msg" [] Type.unit
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
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
                    [ "Route", "Contact" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias [ "Route", "Contact" ] "Data" [] (Type.record []))
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Contact" ]
                    "RouteParams"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Contact" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Contact" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatelessRoute"
                        [ Type.namedWith [ "Route", "Contact" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Contact" ] "Data" []
                        , Type.namedWith [ "Route", "Contact" ] "ActionData" []
                        ]
                    )
            }
    }