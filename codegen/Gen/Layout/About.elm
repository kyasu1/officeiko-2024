module Gen.Layout.About exposing (moduleName_, values_, view)

{-| 
@docs moduleName_, view, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "About" ]


{-| view: List (Layout.About.Html msg) -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "About" ]
        , name = "view"
        , annotation =
            Just
                (Type.list
                    (Type.namedWith
                        [ "Layout", "About" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
                )
        }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "About" ]
            , name = "view"
            , annotation =
                Just
                    (Type.list
                        (Type.namedWith
                            [ "Layout", "About" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }