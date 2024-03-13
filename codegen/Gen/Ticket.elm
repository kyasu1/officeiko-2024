module Gen.Ticket exposing (annotation_, call_, caseOf_, categoryToString, make_, moduleName_, values_)

{-| 
@docs moduleName_, categoryToString, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Ticket" ]


{-| categoryToString: Ticket.Category -> String -}
categoryToString : Elm.Expression -> Elm.Expression
categoryToString categoryToStringArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Ticket" ]
            , name = "categoryToString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Ticket" ] "Category" [] ]
                        Type.string
                    )
            }
        )
        [ categoryToStringArg ]


annotation_ :
    { ticket : Type.Annotation
    , price : Type.Annotation
    , category : Type.Annotation
    }
annotation_ =
    { ticket =
        Type.alias
            moduleName_
            "Ticket"
            []
            (Type.record
                [ ( "category", Type.namedWith [ "Ticket" ] "Category" [] )
                , ( "name", Type.string )
                , ( "note", Type.maybe Type.string )
                , ( "price", Type.namedWith [ "Ticket" ] "Price" [] )
                ]
            )
    , price = Type.namedWith [ "Ticket" ] "Price" []
    , category = Type.namedWith [ "Ticket" ] "Category" []
    }


make_ :
    { ticket :
        { category : Elm.Expression
        , name : Elm.Expression
        , note : Elm.Expression
        , price : Elm.Expression
        }
        -> Elm.Expression
    , priced : Elm.Expression -> Elm.Expression
    , percent : Elm.Expression -> Elm.Expression
    , shopping : Elm.Expression
    , gift : Elm.Expression
    , travel : Elm.Expression
    , beer : Elm.Expression
    , stamp : Elm.Expression
    , ohter : Elm.Expression
    }
make_ =
    { ticket =
        \ticket_args ->
            Elm.withType
                (Type.alias
                    [ "Ticket" ]
                    "Ticket"
                    []
                    (Type.record
                        [ ( "category"
                          , Type.namedWith [ "Ticket" ] "Category" []
                          )
                        , ( "name", Type.string )
                        , ( "note", Type.maybe Type.string )
                        , ( "price", Type.namedWith [ "Ticket" ] "Price" [] )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "category" ticket_args.category
                    , Tuple.pair "name" ticket_args.name
                    , Tuple.pair "note" ticket_args.note
                    , Tuple.pair "price" ticket_args.price
                    ]
                )
    , priced =
        \ar0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Ticket" ]
                    , name = "Priced"
                    , annotation = Just (Type.namedWith [] "Price" [])
                    }
                )
                [ ar0 ]
    , percent =
        \ar0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Ticket" ]
                    , name = "Percent"
                    , annotation = Just (Type.namedWith [] "Price" [])
                    }
                )
                [ ar0 ]
    , shopping =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Shopping"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    , gift =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Gift"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    , travel =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Travel"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    , beer =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Beer"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    , stamp =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Stamp"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    , ohter =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "Ohter"
            , annotation = Just (Type.namedWith [] "Category" [])
            }
    }


caseOf_ :
    { price :
        Elm.Expression
        -> { priceTags_0_0
            | priced : Elm.Expression -> Elm.Expression
            , percent : Elm.Expression -> Elm.Expression
        }
        -> Elm.Expression
    , category :
        Elm.Expression
        -> { categoryTags_1_0
            | shopping : Elm.Expression
            , gift : Elm.Expression
            , travel : Elm.Expression
            , beer : Elm.Expression
            , stamp : Elm.Expression
            , ohter : Elm.Expression
        }
        -> Elm.Expression
    }
caseOf_ =
    { price =
        \priceExpression priceTags ->
            Elm.Case.custom
                priceExpression
                (Type.namedWith [ "Ticket" ] "Price" [])
                [ Elm.Case.branch1
                    "Priced"
                    ( "basicsInt", Type.int )
                    priceTags.priced
                , Elm.Case.branch1
                    "Percent"
                    ( "decimalDecimal"
                    , Type.namedWith [ "Decimal" ] "Decimal" []
                    )
                    priceTags.percent
                ]
    , category =
        \categoryExpression categoryTags ->
            Elm.Case.custom
                categoryExpression
                (Type.namedWith [ "Ticket" ] "Category" [])
                [ Elm.Case.branch0 "Shopping" categoryTags.shopping
                , Elm.Case.branch0 "Gift" categoryTags.gift
                , Elm.Case.branch0 "Travel" categoryTags.travel
                , Elm.Case.branch0 "Beer" categoryTags.beer
                , Elm.Case.branch0 "Stamp" categoryTags.stamp
                , Elm.Case.branch0 "Ohter" categoryTags.ohter
                ]
    }


call_ : { categoryToString : Elm.Expression -> Elm.Expression }
call_ =
    { categoryToString =
        \categoryToStringArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Ticket" ]
                    , name = "categoryToString"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Ticket" ] "Category" [] ]
                                Type.string
                            )
                    }
                )
                [ categoryToStringArg ]
    }


values_ : { categoryToString : Elm.Expression }
values_ =
    { categoryToString =
        Elm.value
            { importFrom = [ "Ticket" ]
            , name = "categoryToString"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Ticket" ] "Category" [] ]
                        Type.string
                    )
            }
    }