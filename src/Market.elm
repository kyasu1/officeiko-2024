module Market exposing
    ( Coin
    , Gd(..)
    , Market
    , Pt(..)
    , Rate
    , coinRates
    , decoder
    , gdDiff
    , gdPrice
    , gdRate
    , gdRates
    , ptDiff
    , ptPrice
    , ptRate
    , ptRates
    , svRates
    , updated
    )

import Decimal exposing (Decimal)
import Iso8601
import Json.Decode as JD
import Json.Decode.Extra as JD
import Time
import Time.Extra
import Utils


type Market
    = Market Internal


type alias Internal =
    { timestamp : Time.Posix
    , gd : Decimal
    , gdDiff : Decimal
    , pt : Decimal
    , ptDiff : Decimal
    , sv : Decimal
    , prices : Prices
    }


type alias Prices =
    { generation : Int
    , golds : Golds
    , platinums : Platinums
    , silvers : Silvers
    }



-- price を文字列から Decimal にデコードするヘルパー


decimalFromStringDecoder : JD.Decoder Decimal
decimalFromStringDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case Decimal.fromString s of
                    Just d ->
                        JD.succeed d

                    Nothing ->
                        JD.fail ("Could not convert string '" ++ s ++ "' to Decimal.")
            )


pricesDecoder : JD.Decoder Prices
pricesDecoder =
    JD.field "generation" JD.int
        |> JD.andThen
            (\gen ->
                JD.field "metals"
                    (JD.map3 (Prices gen)
                        goldsDecoder
                        platinumsDecoder
                        silversDecoder
                    )
            )


type alias Golds =
    List { gd : Gd, price : Decimal, note : String }


type alias Platinums =
    List { pt : Pt, price : Decimal, note : String }


type alias Silvers =
    List { sv : Sv, price : Decimal, note : String }


gdFieldName : Gd -> String
gdFieldName gd =
    case gd of
        K21_6 ->
            "K21_6"

        K18S ->
            "K18"

        _ ->
            (gdToString gd).label


decodeGdItem : Gd -> JD.Decoder { gd : Gd, price : Decimal, note : String }
decodeGdItem gd =
    JD.field (gdFieldName gd)
        (JD.field "price" decimalFromStringDecoder
            |> JD.map (\price -> { gd = gd, price = price, note = (gdToString gd).note })
        )


goldsDecoder : JD.Decoder Golds
goldsDecoder =
    JD.succeed (\a b c d e f g h i j -> [ a, b, c, d, e, f, g, h, i, j ])
        |> JD.andMap (decodeGdItem AuIG)
        |> JD.andMap (decodeGdItem K24)
        |> JD.andMap (decodeGdItem K23)
        |> JD.andMap (decodeGdItem K22)
        |> JD.andMap (decodeGdItem K21_6)
        |> JD.andMap (decodeGdItem K20)
        |> JD.andMap (decodeGdItem K18S)
        |> JD.andMap (decodeGdItem K14)
        |> JD.andMap (decodeGdItem K10)
        |> JD.andMap (decodeGdItem K9)


decodePtItem : Pt -> JD.Decoder { pt : Pt, price : Decimal, note : String }
decodePtItem pt =
    JD.field (ptToString pt |> .label)
        (JD.field "price" decimalFromStringDecoder
            |> JD.map (\price -> { pt = pt, price = price, note = (ptToString pt).note })
        )


platinumsDecoder : JD.Decoder Platinums
platinumsDecoder =
    JD.map5
        (\a b c d e -> [ a, b, c, d, e ])
        (decodePtItem PtIG)
        (decodePtItem Pt1000)
        (decodePtItem Pt950)
        (decodePtItem Pt900)
        (decodePtItem Pt850)


decodeSvItem : Sv -> JD.Decoder { sv : Sv, price : Decimal, note : String }
decodeSvItem sv =
    JD.field (svToString sv |> .label)
        (JD.field "price" decimalFromStringDecoder
            |> JD.map (\price -> { sv = sv, price = price, note = (svToString sv).note })
        )


silversDecoder : JD.Decoder Silvers
silversDecoder =
    JD.map3
        (\a b c -> [ a, b, c ])
        (decodeSvItem SV1000)
        (decodeSvItem SV950)
        (decodeSvItem SV925)


timestampDecoder : JD.Decoder Time.Posix
timestampDecoder =
    JD.map3
        (\date hour minute ->
            date
                |> Time.Extra.add Time.Extra.Hour (hour - 9) Time.utc
                |> Time.Extra.add Time.Extra.Minute minute Time.utc
        )
        (JD.field "date" Iso8601.decoder)
        (JD.field "hour" JD.int)
        (JD.field "minute" JD.int)


decoder : JD.Decoder Market
decoder =
    JD.map7 Internal
        timestampDecoder
        (JD.field "gd" JD.int |> JD.map Decimal.fromInt)
        (JD.field "gd_ratio" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt_ratio" JD.int |> JD.map Decimal.fromInt)
        (JD.field "sv" JD.int |> JD.map Decimal.fromInt)
        (JD.field "prices" pricesDecoder)
        |> JD.map Market


updated : Market -> String
updated (Market market) =
    (market.timestamp |> Utils.posixToKanji)
        ++ "（"
        ++ String.fromInt market.prices.generation
        ++ "）"


gdPrice : Market -> String
gdPrice (Market market) =
    market.gd |> Utils.toPrice


gdDiff : Market -> String
gdDiff (Market market) =
    market.gdDiff |> Utils.toDiff


ptPrice : Market -> String
ptPrice (Market market) =
    market.pt |> Utils.toPrice


ptDiff : Market -> String
ptDiff (Market market) =
    market.ptDiff |> Utils.toDiff


type alias Rate =
    { label : String
    , note : String
    , buyout : String
    , pawn : String
    }


calcPawn : Decimal -> Int -> String
calcPawn buyout pawnRate =
    Decimal.mul buyout (Decimal.fromIntWithExponent pawnRate -1)
        |> Decimal.round 2
        |> Utils.toPrice



-- Gold


type Gd
    = AuIG
    | K24
    | K23
    | K22
    | K21_6
    | K20
    | K18S
    | K14
    | K10
    | K9


gdToString : Gd -> { label : String, note : String }
gdToString gd =
    case gd of
        AuIG ->
            { label = "AuIG"
            , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はK24S扱いとなります"
            }

        K24 ->
            { label = "K24"
            , note = "純金のコイン、K24刻印のある指輪やネックレスなど"
            }

        K23 ->
            { label = "K23"
            , note = "イーグル金貨、クルーガーランド金貨、ブリタニア金貨、中華系のアクセサリーなど（支那金）"
            }

        K22 ->
            { label = "K22"
            , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
            }

        K21_6 ->
            { label = "K21.6"
            , note = "インディアンコインやイーグルコインなど米国や中南米のコインに多いです"
            }

        K20 ->
            { label = "K20"
            , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
            }

        K18S ->
            { label = "K18"
            , note = "国内では最も一般的です。検定刻印の有無に関わらず同じ金額でお買取りします"
            }

        K14 ->
            { label = "K14"
            , note = "ハワイアンや米国のアクセサリーに多いです。日本でも最近ではよく見かけます"
            }

        K10 ->
            { label = "K10"
            , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
            }

        K9 ->
            { label = "K9"
            , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
            }


gdRates : Market -> List Rate
gdRates (Market market) =
    market.prices.golds
        |> List.map (gdItemToRate 8)


gdItemToRate : Int -> { gd : Gd, price : Decimal, note : String } -> Rate
gdItemToRate pawnRate item =
    let
        info =
            gdToString item.gd
    in
    { label = info.label
    , note = item.note
    , buyout = item.price |> Utils.toPrice
    , pawn = calcPawn item.price pawnRate
    }


gdRate : Market -> Gd -> Rate
gdRate (Market market) gd =
    market.prices.golds
        |> List.filter (\item -> item.gd == gd)
        |> List.head
        |> Maybe.map (gdItemToRate 8)
        |> Maybe.withDefault { label = "", note = "", buyout = "", pawn = "" }



-- Platinum


type Pt
    = PtIG
    | Pt1000
    | Pt950
    | Pt900
    | Pt850


ptToString : Pt -> { label : String, note : String }
ptToString pt =
    case pt of
        PtIG ->
            { label = "PtIG"
            , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はPt1000扱いとなります"
            }

        Pt1000 ->
            { label = "Pt1000"
            , note = "コイン・ネックレス・指輪等"
            }

        Pt950 ->
            { label = "Pt950"
            , note = "ブランド品や結婚指輪などに多いです"
            }

        Pt900 ->
            { label = "Pt900"
            , note = "指輪に使用される場合が多いです"
            }

        Pt850 ->
            { label = "Pt850"
            , note = "ネックレスやブレスレットに使用される場合が多いです"
            }


ptRates : Market -> List Rate
ptRates (Market market) =
    market.prices.platinums
        |> List.map (ptItemToRate 8)


ptItemToRate : Int -> { pt : Pt, price : Decimal, note : String } -> Rate
ptItemToRate pawnRate item =
    let
        info =
            ptToString item.pt
    in
    { label = info.label
    , note = item.note
    , buyout = item.price |> Utils.toPrice
    , pawn = calcPawn item.price pawnRate
    }


ptRate : Market -> Pt -> Rate
ptRate (Market market) pt =
    market.prices.platinums
        |> List.filter (\item -> item.pt == pt)
        |> List.head
        |> Maybe.map (ptItemToRate 8)
        |> Maybe.withDefault { label = "", note = "", buyout = "", pawn = "" }



-- Silver


type Sv
    = SV1000
    | SV950
    | SV925


svToString : Sv -> { label : String, note : String }
svToString sv =
    case sv of
        SV1000 ->
            { label = "Sv1000"
            , note = "インゴットや銀杯など"
            }

        SV950 ->
            { label = "Sv950"
            , note = "トロフィーなどに多いです"
            }

        SV925 ->
            { label = "Sv925"
            , note = "指輪に使用される場合が多いです"
            }


svRates : Market -> List Rate
svRates (Market market) =
    market.prices.silvers
        |> List.map
            (\item ->
                let
                    info =
                        svToString item.sv
                in
                { label = info.label
                , note = item.note
                , buyout = item.price |> Utils.toPrice
                , pawn = calcPawn item.price 7
                }
            )



-- Coin


type alias Coin =
    { label : String
    , buyout : String
    , pawn : String
    }


calcCoin : String -> Decimal -> Decimal -> Coin
calcCoin label gd weight =
    Decimal.mul gd weight
        |> Decimal.mul (Decimal.fromIntWithExponent 9 -1)
        |> Decimal.round 2
        |> (\buyout ->
                { label = label ++ "（" ++ Decimal.toString weight ++ "g)"
                , buyout = buyout |> Utils.toPrice
                , pawn =
                    Decimal.mul buyout (Decimal.fromIntWithExponent 9 -1)
                        |> Decimal.truncate 4
                        |> Utils.toPrice
                }
           )


coinRates : Market -> List Coin
coinRates (Market market) =
    [ calcCoin "天皇陛下御即位記念 10万円金貨" market.gd (Decimal.fromInt 30)
    , calcCoin "天皇陛下御在位60年記念 10万円金貨" market.gd (Decimal.fromInt 20)
    , calcCoin "皇太子殿下ご成婚記念 5万円金貨" market.gd (Decimal.fromInt 18)
    , calcCoin "天皇陛下御在位10年記念 1万円金貨" market.gd (Decimal.fromInt 20)
    , calcCoin "天皇陛下御在位30年記念 1万円金貨" market.gd (Decimal.fromInt 20)
    , calcCoin "天皇陛下御在位20年記念 1万円金貨" market.gd (Decimal.fromInt 20)
    , calcCoin "オリンピック等各種 1万円金貨" market.gd (Decimal.fromIntWithExponent 156 -1)
    ]
