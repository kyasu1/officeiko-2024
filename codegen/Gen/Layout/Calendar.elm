module Gen.Layout.Calendar exposing (moduleName_, values_, view)

{-| 
@docs moduleName_, view, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Calendar" ]


{-| view: List (Layout.Calendar.Html msg) -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "Calendar" ]
        , name = "view"
        , annotation =
            Just
                (Type.list
                    (Type.namedWith
                        [ "Layout", "Calendar" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
                )
        }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "Calendar" ]
            , name = "view"
            , annotation =
                Just
                    (Type.list
                        (Type.namedWith
                            [ "Layout", "Calendar" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }