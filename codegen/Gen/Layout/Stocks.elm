module Gen.Layout.Stocks exposing (call_, moduleName_, values_, view)

{-| 
@docs moduleName_, view, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Stocks" ]


{-| view: Market.Market -> List (Layout.Stocks.Html msg) -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Stocks" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "Stocks" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
        )
        [ viewArg ]


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Stocks" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                (Type.list
                                    (Type.namedWith
                                        [ "Layout", "Stocks" ]
                                        "Html"
                                        [ Type.var "msg" ]
                                    )
                                )
                            )
                    }
                )
                [ viewArg ]
    }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "Stocks" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list
                            (Type.namedWith
                                [ "Layout", "Stocks" ]
                                "Html"
                                [ Type.var "msg" ]
                            )
                        )
                    )
            }
    }