module Gen.Layout.WesternUnion exposing (moduleName_, values_, view)

{-| 
@docs moduleName_, view, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Layout", "WesternUnion" ]


{-| view: Layout.WesternUnion.Html msg -}
view : Elm.Expression
view =
    Elm.value
        { importFrom = [ "Layout", "WesternUnion" ]
        , name = "view"
        , annotation =
            Just
                (Type.namedWith
                    [ "Layout", "WesternUnion" ]
                    "Html"
                    [ Type.var "msg" ]
                )
        }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "Layout", "WesternUnion" ]
            , name = "view"
            , annotation =
                Just
                    (Type.namedWith
                        [ "Layout", "WesternUnion" ]
                        "Html"
                        [ Type.var "msg" ]
                    )
            }
    }