module Gen.Layout.Contact exposing (moduleName_, values_, view)

{-| 
@docs moduleName_, view, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "Contact" ]


{-| view: List (Layout.Contact.Html msg) -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "Contact" ]
        , name = "view"
        , annotation =
            Just
                (Type.list
                    (Type.namedWith
                        [ "Layout", "Contact" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
                )
        }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "Contact" ]
            , name = "view"
            , annotation =
                Just
                    (Type.list
                        (Type.namedWith
                            [ "Layout", "Contact" ]
                            "Html"
                            [ Type.var "msg" ]
                        )
                    )
            }
    }