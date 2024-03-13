module Gen.Layout.Posts exposing (call_, moduleName_, values_, view)

{-| 
@docs moduleName_, view, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Posts" ]


{-| view: List Post.Post -> Layout.Posts.Html msg -}
view : List Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Layout", "Posts" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.list (Type.namedWith [ "Post" ] "Post" []) ]
                        (Type.namedWith
                            [ "Layout", "Posts" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
        )
        [ Elm.list viewArg ]


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Layout", "Posts" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.list
                                    (Type.namedWith [ "Post" ] "Post" [])
                                ]
                                (Type.namedWith
                                    [ "Layout", "Posts" ]
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
            { importFrom = [ "Layout", "Posts" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.list (Type.namedWith [ "Post" ] "Post" []) ]
                        (Type.namedWith
                            [ "Layout", "Posts" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }