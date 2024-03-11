module Gen.Market exposing (annotation_, call_, caseOf_, coinRates, decoder, gdDiff, gdPrice, gdRate, gdRates, make_, moduleName_, ptDiff, ptPrice, ptRate, ptRates, svRates, updated, values_)

{-| 
@docs moduleName_, coinRates, svRates, ptRate, ptRates, gdRate, gdRates, ptDiff, ptPrice, gdDiff, gdPrice, updated, decoder, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Market" ]


{-| coinRates: Market.Market -> List Market.Coin -}
coinRates : Elm.Expression -> Elm.Expression
coinRates coinRatesArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "coinRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Coin" []))
                    )
            }
        )
        [ coinRatesArg ]


{-| svRates: Market.Market -> List Market.Rate -}
svRates : Elm.Expression -> Elm.Expression
svRates svRatesArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "svRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
        )
        [ svRatesArg ]


{-| ptRate: 
    Market.Market
    -> Market.Pt
    -> { label : String, note : String, buyout : String, pawn : String }
-}
ptRate : Elm.Expression -> Elm.Expression -> Elm.Expression
ptRate ptRateArg ptRateArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "ptRate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" []
                        , Type.namedWith [ "Market" ] "Pt" []
                        ]
                        (Type.record
                            [ ( "label", Type.string )
                            , ( "note", Type.string )
                            , ( "buyout", Type.string )
                            , ( "pawn", Type.string )
                            ]
                        )
                    )
            }
        )
        [ ptRateArg, ptRateArg0 ]


{-| ptRates: Market.Market -> List Market.Rate -}
ptRates : Elm.Expression -> Elm.Expression
ptRates ptRatesArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "ptRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
        )
        [ ptRatesArg ]


{-| gdRate: 
    Market.Market
    -> Market.Gd
    -> { label : String, note : String, buyout : String, pawn : String }
-}
gdRate : Elm.Expression -> Elm.Expression -> Elm.Expression
gdRate gdRateArg gdRateArg0 =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "gdRate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" []
                        , Type.namedWith [ "Market" ] "Gd" []
                        ]
                        (Type.record
                            [ ( "label", Type.string )
                            , ( "note", Type.string )
                            , ( "buyout", Type.string )
                            , ( "pawn", Type.string )
                            ]
                        )
                    )
            }
        )
        [ gdRateArg, gdRateArg0 ]


{-| gdRates: Market.Market -> List Market.Rate -}
gdRates : Elm.Expression -> Elm.Expression
gdRates gdRatesArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "gdRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
        )
        [ gdRatesArg ]


{-| ptDiff: Market.Market -> String -}
ptDiff : Elm.Expression -> Elm.Expression
ptDiff ptDiffArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "ptDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
        )
        [ ptDiffArg ]


{-| ptPrice: Market.Market -> String -}
ptPrice : Elm.Expression -> Elm.Expression
ptPrice ptPriceArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "ptPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
        )
        [ ptPriceArg ]


{-| gdDiff: Market.Market -> String -}
gdDiff : Elm.Expression -> Elm.Expression
gdDiff gdDiffArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "gdDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
        )
        [ gdDiffArg ]


{-| gdPrice: Market.Market -> String -}
gdPrice : Elm.Expression -> Elm.Expression
gdPrice gdPriceArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "gdPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
        )
        [ gdPriceArg ]


{-| updated: Market.Market -> String -}
updated : Elm.Expression -> Elm.Expression
updated updatedArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Market" ]
            , name = "updated"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
        )
        [ updatedArg ]


{-| decoder: Json.Decode.Decoder Market.Market -}
decoder : Elm.Expression
decoder =
    Elm.value
        { importFrom = [ "Market" ]
        , name = "decoder"
        , annotation =
            Just
                (Type.namedWith
                    [ "Json", "Decode" ]
                    "Decoder"
                    [ Type.namedWith [ "Market" ] "Market" [] ]
                )
        }


annotation_ :
    { coin : Type.Annotation
    , rate : Type.Annotation
    , pt : Type.Annotation
    , gd : Type.Annotation
    , market : Type.Annotation
    }
annotation_ =
    { coin =
        Type.alias
            moduleName_
            "Coin"
            []
            (Type.record
                [ ( "label", Type.string )
                , ( "buyout", Type.string )
                , ( "pawn", Type.string )
                ]
            )
    , rate =
        Type.alias
            moduleName_
            "Rate"
            []
            (Type.record
                [ ( "label", Type.string )
                , ( "note", Type.string )
                , ( "buyout", Type.string )
                , ( "pawn", Type.string )
                ]
            )
    , pt = Type.namedWith [ "Market" ] "Pt" []
    , gd = Type.namedWith [ "Market" ] "Gd" []
    , market = Type.namedWith [ "Market" ] "Market" []
    }


make_ :
    { coin :
        { label : Elm.Expression
        , buyout : Elm.Expression
        , pawn : Elm.Expression
        }
        -> Elm.Expression
    , rate :
        { label : Elm.Expression
        , note : Elm.Expression
        , buyout : Elm.Expression
        , pawn : Elm.Expression
        }
        -> Elm.Expression
    , ptIG : Elm.Expression
    , pt1000 : Elm.Expression
    , pt950 : Elm.Expression
    , pt900 : Elm.Expression
    , pt850 : Elm.Expression
    , auIG : Elm.Expression
    , k24 : Elm.Expression
    , k23 : Elm.Expression
    , k22 : Elm.Expression
    , k21_6 : Elm.Expression
    , k20 : Elm.Expression
    , k18 : Elm.Expression
    , k18S : Elm.Expression
    , k14 : Elm.Expression
    , k10 : Elm.Expression
    , k9 : Elm.Expression
    }
make_ =
    { coin =
        \coin_args ->
            Elm.withType
                (Type.alias
                    [ "Market" ]
                    "Coin"
                    []
                    (Type.record
                        [ ( "label", Type.string )
                        , ( "buyout", Type.string )
                        , ( "pawn", Type.string )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "label" coin_args.label
                    , Tuple.pair "buyout" coin_args.buyout
                    , Tuple.pair "pawn" coin_args.pawn
                    ]
                )
    , rate =
        \rate_args ->
            Elm.withType
                (Type.alias
                    [ "Market" ]
                    "Rate"
                    []
                    (Type.record
                        [ ( "label", Type.string )
                        , ( "note", Type.string )
                        , ( "buyout", Type.string )
                        , ( "pawn", Type.string )
                        ]
                    )
                )
                (Elm.record
                    [ Tuple.pair "label" rate_args.label
                    , Tuple.pair "note" rate_args.note
                    , Tuple.pair "buyout" rate_args.buyout
                    , Tuple.pair "pawn" rate_args.pawn
                    ]
                )
    , ptIG =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "PtIG"
            , annotation = Just (Type.namedWith [] "Pt" [])
            }
    , pt1000 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "Pt1000"
            , annotation = Just (Type.namedWith [] "Pt" [])
            }
    , pt950 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "Pt950"
            , annotation = Just (Type.namedWith [] "Pt" [])
            }
    , pt900 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "Pt900"
            , annotation = Just (Type.namedWith [] "Pt" [])
            }
    , pt850 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "Pt850"
            , annotation = Just (Type.namedWith [] "Pt" [])
            }
    , auIG =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "AuIG"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k24 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K24"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k23 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K23"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k22 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K22"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k21_6 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K21_6"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k20 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K20"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k18 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K18"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k18S =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K18S"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k14 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K14"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k10 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K10"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    , k9 =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "K9"
            , annotation = Just (Type.namedWith [] "Gd" [])
            }
    }


caseOf_ :
    { pt :
        Elm.Expression
        -> { ptTags_0_0
            | ptIG : Elm.Expression
            , pt1000 : Elm.Expression
            , pt950 : Elm.Expression
            , pt900 : Elm.Expression
            , pt850 : Elm.Expression
        }
        -> Elm.Expression
    , gd :
        Elm.Expression
        -> { gdTags_1_0
            | auIG : Elm.Expression
            , k24 : Elm.Expression
            , k23 : Elm.Expression
            , k22 : Elm.Expression
            , k21_6 : Elm.Expression
            , k20 : Elm.Expression
            , k18 : Elm.Expression
            , k18S : Elm.Expression
            , k14 : Elm.Expression
            , k10 : Elm.Expression
            , k9 : Elm.Expression
        }
        -> Elm.Expression
    }
caseOf_ =
    { pt =
        \ptExpression ptTags ->
            Elm.Case.custom
                ptExpression
                (Type.namedWith [ "Market" ] "Pt" [])
                [ Elm.Case.branch0 "PtIG" ptTags.ptIG
                , Elm.Case.branch0 "Pt1000" ptTags.pt1000
                , Elm.Case.branch0 "Pt950" ptTags.pt950
                , Elm.Case.branch0 "Pt900" ptTags.pt900
                , Elm.Case.branch0 "Pt850" ptTags.pt850
                ]
    , gd =
        \gdExpression gdTags ->
            Elm.Case.custom
                gdExpression
                (Type.namedWith [ "Market" ] "Gd" [])
                [ Elm.Case.branch0 "AuIG" gdTags.auIG
                , Elm.Case.branch0 "K24" gdTags.k24
                , Elm.Case.branch0 "K23" gdTags.k23
                , Elm.Case.branch0 "K22" gdTags.k22
                , Elm.Case.branch0 "K21_6" gdTags.k21_6
                , Elm.Case.branch0 "K20" gdTags.k20
                , Elm.Case.branch0 "K18" gdTags.k18
                , Elm.Case.branch0 "K18S" gdTags.k18S
                , Elm.Case.branch0 "K14" gdTags.k14
                , Elm.Case.branch0 "K10" gdTags.k10
                , Elm.Case.branch0 "K9" gdTags.k9
                ]
    }


call_ :
    { coinRates : Elm.Expression -> Elm.Expression
    , svRates : Elm.Expression -> Elm.Expression
    , ptRate : Elm.Expression -> Elm.Expression -> Elm.Expression
    , ptRates : Elm.Expression -> Elm.Expression
    , gdRate : Elm.Expression -> Elm.Expression -> Elm.Expression
    , gdRates : Elm.Expression -> Elm.Expression
    , ptDiff : Elm.Expression -> Elm.Expression
    , ptPrice : Elm.Expression -> Elm.Expression
    , gdDiff : Elm.Expression -> Elm.Expression
    , gdPrice : Elm.Expression -> Elm.Expression
    , updated : Elm.Expression -> Elm.Expression
    }
call_ =
    { coinRates =
        \coinRatesArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "coinRates"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                (Type.list
                                    (Type.namedWith [ "Market" ] "Coin" [])
                                )
                            )
                    }
                )
                [ coinRatesArg ]
    , svRates =
        \svRatesArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "svRates"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                (Type.list
                                    (Type.namedWith [ "Market" ] "Rate" [])
                                )
                            )
                    }
                )
                [ svRatesArg ]
    , ptRate =
        \ptRateArg ptRateArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "ptRate"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" []
                                , Type.namedWith [ "Market" ] "Pt" []
                                ]
                                (Type.record
                                    [ ( "label", Type.string )
                                    , ( "note", Type.string )
                                    , ( "buyout", Type.string )
                                    , ( "pawn", Type.string )
                                    ]
                                )
                            )
                    }
                )
                [ ptRateArg, ptRateArg0 ]
    , ptRates =
        \ptRatesArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "ptRates"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                (Type.list
                                    (Type.namedWith [ "Market" ] "Rate" [])
                                )
                            )
                    }
                )
                [ ptRatesArg ]
    , gdRate =
        \gdRateArg gdRateArg0 ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "gdRate"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" []
                                , Type.namedWith [ "Market" ] "Gd" []
                                ]
                                (Type.record
                                    [ ( "label", Type.string )
                                    , ( "note", Type.string )
                                    , ( "buyout", Type.string )
                                    , ( "pawn", Type.string )
                                    ]
                                )
                            )
                    }
                )
                [ gdRateArg, gdRateArg0 ]
    , gdRates =
        \gdRatesArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "gdRates"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                (Type.list
                                    (Type.namedWith [ "Market" ] "Rate" [])
                                )
                            )
                    }
                )
                [ gdRatesArg ]
    , ptDiff =
        \ptDiffArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "ptDiff"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                Type.string
                            )
                    }
                )
                [ ptDiffArg ]
    , ptPrice =
        \ptPriceArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "ptPrice"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                Type.string
                            )
                    }
                )
                [ ptPriceArg ]
    , gdDiff =
        \gdDiffArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "gdDiff"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                Type.string
                            )
                    }
                )
                [ gdDiffArg ]
    , gdPrice =
        \gdPriceArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "gdPrice"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                Type.string
                            )
                    }
                )
                [ gdPriceArg ]
    , updated =
        \updatedArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Market" ]
                    , name = "updated"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Market" ] "Market" [] ]
                                Type.string
                            )
                    }
                )
                [ updatedArg ]
    }


values_ :
    { coinRates : Elm.Expression
    , svRates : Elm.Expression
    , ptRate : Elm.Expression
    , ptRates : Elm.Expression
    , gdRate : Elm.Expression
    , gdRates : Elm.Expression
    , ptDiff : Elm.Expression
    , ptPrice : Elm.Expression
    , gdDiff : Elm.Expression
    , gdPrice : Elm.Expression
    , updated : Elm.Expression
    , decoder : Elm.Expression
    }
values_ =
    { coinRates =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "coinRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Coin" []))
                    )
            }
    , svRates =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "svRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
    , ptRate =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "ptRate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" []
                        , Type.namedWith [ "Market" ] "Pt" []
                        ]
                        (Type.record
                            [ ( "label", Type.string )
                            , ( "note", Type.string )
                            , ( "buyout", Type.string )
                            , ( "pawn", Type.string )
                            ]
                        )
                    )
            }
    , ptRates =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "ptRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
    , gdRate =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "gdRate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" []
                        , Type.namedWith [ "Market" ] "Gd" []
                        ]
                        (Type.record
                            [ ( "label", Type.string )
                            , ( "note", Type.string )
                            , ( "buyout", Type.string )
                            , ( "pawn", Type.string )
                            ]
                        )
                    )
            }
    , gdRates =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "gdRates"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        (Type.list (Type.namedWith [ "Market" ] "Rate" []))
                    )
            }
    , ptDiff =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "ptDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
    , ptPrice =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "ptPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
    , gdDiff =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "gdDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
    , gdPrice =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "gdPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
    , updated =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "updated"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                        Type.string
                    )
            }
    , decoder =
        Elm.value
            { importFrom = [ "Market" ]
            , name = "decoder"
            , annotation =
                Just
                    (Type.namedWith
                        [ "Json", "Decode" ]
                        "Decoder"
                        [ Type.namedWith [ "Market" ] "Market" [] ]
                    )
            }
    }