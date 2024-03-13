module Gen.Layout.Post exposing (call_, moduleName_, values_, view)

{-| 
@docs moduleName_, view, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Post" ]


{-| view: Post.Post -> Layout.Post.Html msg -}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Post" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Post" ] "Post" [] ]
                        (Type.namedWith
                            [ "Layout", "Post" ]
                            "Html"
                            [ Type.var "msg" ]
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
                    { importFrom = [ "Layout", "Post" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Post" ] "Post" [] ]
                                (Type.namedWith
                                    [ "Layout", "Post" ]
                                    "Html"
                                    [ Type.var "msg" ]
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
            { importFrom = [ "Layout", "Post" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Post" ] "Post" [] ]
                        (Type.namedWith
                            [ "Layout", "Post" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }