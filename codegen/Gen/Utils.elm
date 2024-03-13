module Gen.Utils exposing (call_, dateDecoder, kanjiDate, moduleName_, posixToDate, posixToKanji, toDiff, toPrice, values_, zone)

{-| 
@docs moduleName_, toDiff, toPrice, dateDecoder, posixToKanji, kanjiDate, posixToDate, zone, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Utils" ]


{-| toDiff: Decimal.Decimal -> String -}
toDiff : Elm.Expression -> Elm.Expression
toDiff toDiffArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Utils" ]
            , name = "toDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                        Type.string
                    )
            }
        )
        [ toDiffArg ]


{-| toPrice: Decimal.Decimal -> String -}
toPrice : Elm.Expression -> Elm.Expression
toPrice toPriceArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Utils" ]
            , name = "toPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                        Type.string
                    )
            }
        )
        [ toPriceArg ]


{-| dateDecoder: Json.Decode.Decoder Date.Date -}
dateDecoder : Elm.Expression
dateDecoder =
    Elm.value
        { importFrom = [ "Utils" ]
        , name = "dateDecoder"
        , annotation =
            Just
                (Type.namedWith
                    [ "Json", "Decode" ]
                    "Decoder"
                    [ Type.namedWith [ "Date" ] "Date" [] ]
                )
        }


{-| posixToKanji: Time.Posix -> String -}
posixToKanji : Elm.Expression -> Elm.Expression
posixToKanji posixToKanjiArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Utils" ]
            , name = "posixToKanji"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Time" ] "Posix" [] ]
                        Type.string
                    )
            }
        )
        [ posixToKanjiArg ]


{-| kanjiDate: Date.Date -> String -}
kanjiDate : Elm.Expression -> Elm.Expression
kanjiDate kanjiDateArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Utils" ]
            , name = "kanjiDate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Date" ] "Date" [] ]
                        Type.string
                    )
            }
        )
        [ kanjiDateArg ]


{-| posixToDate: Time.Posix -> Date.Date -}
posixToDate : Elm.Expression -> Elm.Expression
posixToDate posixToDateArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Utils" ]
            , name = "posixToDate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Time" ] "Posix" [] ]
                        (Type.namedWith [ "Date" ] "Date" [])
                    )
            }
        )
        [ posixToDateArg ]


{-| zone: Time.Extra.Zone -}
zone : Elm.Expression
zone =
    Elm.value
        { importFrom = [ "Utils" ]
        , name = "zone"
        , annotation = Just (Type.namedWith [ "Time", "Extra" ] "Zone" [])
        }


call_ :
    { toDiff : Elm.Expression -> Elm.Expression
    , toPrice : Elm.Expression -> Elm.Expression
    , posixToKanji : Elm.Expression -> Elm.Expression
    , kanjiDate : Elm.Expression -> Elm.Expression
    , posixToDate : Elm.Expression -> Elm.Expression
    }
call_ =
    { toDiff =
        \toDiffArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Utils" ]
                    , name = "toDiff"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                                Type.string
                            )
                    }
                )
                [ toDiffArg ]
    , toPrice =
        \toPriceArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Utils" ]
                    , name = "toPrice"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                                Type.string
                            )
                    }
                )
                [ toPriceArg ]
    , posixToKanji =
        \posixToKanjiArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Utils" ]
                    , name = "posixToKanji"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Time" ] "Posix" [] ]
                                Type.string
                            )
                    }
                )
                [ posixToKanjiArg ]
    , kanjiDate =
        \kanjiDateArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Utils" ]
                    , name = "kanjiDate"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Date" ] "Date" [] ]
                                Type.string
                            )
                    }
                )
                [ kanjiDateArg ]
    , posixToDate =
        \posixToDateArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Utils" ]
                    , name = "posixToDate"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith [ "Time" ] "Posix" [] ]
                                (Type.namedWith [ "Date" ] "Date" [])
                            )
                    }
                )
                [ posixToDateArg ]
    }


values_ :
    { toDiff : Elm.Expression
    , toPrice : Elm.Expression
    , dateDecoder : Elm.Expression
    , posixToKanji : Elm.Expression
    , kanjiDate : Elm.Expression
    , posixToDate : Elm.Expression
    , zone : Elm.Expression
    }
values_ =
    { toDiff =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "toDiff"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                        Type.string
                    )
            }
    , toPrice =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "toPrice"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Decimal" ] "Decimal" [] ]
                        Type.string
                    )
            }
    , dateDecoder =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "dateDecoder"
            , annotation =
                Just
                    (Type.namedWith
                        [ "Json", "Decode" ]
                        "Decoder"
                        [ Type.namedWith [ "Date" ] "Date" [] ]
                    )
            }
    , posixToKanji =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "posixToKanji"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Time" ] "Posix" [] ]
                        Type.string
                    )
            }
    , kanjiDate =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "kanjiDate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Date" ] "Date" [] ]
                        Type.string
                    )
            }
    , posixToDate =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "posixToDate"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Time" ] "Posix" [] ]
                        (Type.namedWith [ "Date" ] "Date" [])
                    )
            }
    , zone =
        Elm.value
            { importFrom = [ "Utils" ]
            , name = "zone"
            , annotation = Just (Type.namedWith [ "Time", "Extra" ] "Zone" [])
            }
    }