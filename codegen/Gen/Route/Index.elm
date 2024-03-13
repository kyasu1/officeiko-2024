module Gen.Route.Index exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Index" ]


{-| route: RouteBuilder.StatelessRoute Route.Index.RouteParams Route.Index.Data Route.Index.ActionData -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Index" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                    [ "RouteBuilder" ]
                    "StatelessRoute"
                    [ Type.namedWith [ "Route", "Index" ] "RouteParams" []
                    , Type.namedWith [ "Route", "Index" ] "Data" []
                    , Type.namedWith [ "Route", "Index" ] "ActionData" []
                    ]
                )
        }


annotation_ :
    { actionData : Type.Annotation
    , data : Type.Annotation
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
                [ ( "news", Type.list (Type.namedWith [ "Post" ] "Post" []) )
                , ( "blog", Type.list (Type.namedWith [ "Post" ] "Post" []) )
                ]
            )
    , msg = Type.alias moduleName_ "Msg" [] Type.unit
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : { news : Elm.Expression, blog : Elm.Expression } -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Index" ]
                    "ActionData"
                    []
                    (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                    [ "Route", "Index" ]
                    "Data"
                    []
                    (Type.record
                        [ ( "news"
                          , Type.list (Type.namedWith [ "Post" ] "Post" [])
                          )
                        , ( "blog"
                          , Type.list (Type.namedWith [ "Post" ] "Post" [])
                          )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "news" data_args.news
                    , Tuple.pair "blog" data_args.blog
                    ]
                )
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Index" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Index" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                        [ "RouteBuilder" ]
                        "StatelessRoute"
                        [ Type.namedWith [ "Route", "Index" ] "RouteParams" []
                        , Type.namedWith [ "Route", "Index" ] "Data" []
                        , Type.namedWith [ "Route", "Index" ] "ActionData" []
                        ]
                    )
            }
    }