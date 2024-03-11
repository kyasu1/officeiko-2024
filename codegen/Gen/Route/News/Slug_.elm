module Gen.Route.News.Slug_ exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "News", "Slug_" ]


{-| route: RouteBuilder.StatefulRoute Route.News.Slug_.RouteParams Route.News.Slug_.Data Route.News.Slug_.ActionData Route.News.Slug_.Model Route.News.Slug_.Msg -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "News", "Slug_" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatefulRoute"
                    [ Type.namedWith
                        [ "Route", "News", "Slug_" ]
                        "RouteParams"
                        []
                    , Type.namedWith [ "Route", "News", "Slug_" ] "Data" []
                    , Type.namedWith
                        [ "Route", "News", "Slug_" ]
                        "ActionData"
                        []
                    , Type.namedWith [ "Route", "News", "Slug_" ] "Model" []
                    , Type.namedWith [ "Route", "News", "Slug_" ] "Msg" []
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
    , routeParams =
        Type.alias
            moduleName_
            "RouteParams"
            []
            (Type.record [ ( "slug", Type.string ) ])
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    , msg = Type.namedWith [ "Route", "News", "Slug_" ] "Msg" []
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : data -> Elm.Expression
    , routeParams : { slug : Elm.Expression } -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "News", "Slug_" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "News", "Slug_" ]
                    "Data"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "News", "Slug_" ]
                    "RouteParams"
                    []
                    (Type.record [ ( "slug", Type.string ) ])
                )
                (Elm.record [ Tuple.pair "slug" routeParams_args.slug ])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "News", "Slug_" ]
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
            { importFrom = [ "Route", "News", "Slug_" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatefulRoute"
                        [ Type.namedWith
                            [ "Route", "News", "Slug_" ]
                            "RouteParams"
                            []
                        , Type.namedWith [ "Route", "News", "Slug_" ] "Data" []
                        , Type.namedWith
                            [ "Route", "News", "Slug_" ]
                            "ActionData"
                            []
                        , Type.namedWith [ "Route", "News", "Slug_" ] "Model" []
                        , Type.namedWith [ "Route", "News", "Slug_" ] "Msg" []
                        ]
                    )
            }
    }