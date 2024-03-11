module Gen.Utils exposing (call_, kanjiDate, moduleName_, posixToKanji, toDiff, toPrice, values_)

{-| 
@docs moduleName_, toDiff, toPrice, posixToKanji, kanjiDate, call_, values_
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


call_ :
    { toDiff : Elm.Expression -> Elm.Expression
    , toPrice : Elm.Expression -> Elm.Expression
    , posixToKanji : Elm.Expression -> Elm.Expression
    , kanjiDate : Elm.Expression -> Elm.Expression
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
    }


values_ :
    { toDiff : Elm.Expression
    , toPrice : Elm.Expression
    , posixToKanji : Elm.Expression
    , kanjiDate : Elm.Expression
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
    }