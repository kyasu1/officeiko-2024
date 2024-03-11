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
import Time
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
    }


decoder : JD.Decoder Market
decoder =
    JD.map6 Internal
        (JD.field "timestamp" Iso8601.decoder)
        (JD.field "gd" JD.int |> JD.map Decimal.fromInt)
        (JD.field "gd_diff" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt_diff" JD.int |> JD.map Decimal.fromInt)
        (JD.succeed (Decimal.fromInt 120))
        |> JD.map Market


updated : Market -> String
updated (Market market) =
    market.timestamp |> Utils.posixToKanji


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


type Gd
    = AuIG
    | K24
    | K23
    | K22
    | K21_6
    | K20
    | K18
    | K18S
    | K14
    | K10
    | K9


gdRates : Market -> List Rate
gdRates market =
    [ AuIG, K24, K23, K22, K21_6, K20, K18, K18S, K14, K10, K9 ] |> List.map (gdRate market)


gdRate : Market -> Gd -> { label : String, note : String, buyout : String, pawn : String }
gdRate (Market market) gd =
    case gd of
        AuIG ->
            calcGd market.gd 1000 100
                |> (\price ->
                        { label = "AuIG"
                        , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はK24S扱いとなります"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K24 ->
            calcGd market.gd 1000 200
                |> (\price ->
                        { label = "K24"
                        , note = "純金のコイン、K24刻印のある指輪やネックレスなど"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K23 ->
            calcGd market.gd 958 400
                |> (\price ->
                        { label = "K23"
                        , note = "イーグル金貨、クルーガーランド金貨、ブリタニア金貨、中華系のアクセサリーなど（支那金）"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K22 ->
            calcGd market.gd 916 400
                |> (\price ->
                        { label = "K22"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K21_6 ->
            calcGd market.gd 900 400
                |> (\price ->
                        { label = "K21.6"
                        , note = "インディアンコインやイーグルコインなど米国や中南米のコインに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K20 ->
            calcGd market.gd 833 400
                |> (\price ->
                        { label = "K20"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K18 ->
            calcGd market.gd 750 100
                |> (\price ->
                        { label = "K18特定品"
                        , note = "程度の良い喜平製品や小売可能なジュエリーなどはプラス査定"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K18S ->
            calcGd market.gd 750 150
                |> (\price ->
                        { label = "K18"
                        , note = "国内では最も一般的です。検定刻印の有無に関わらず同じ金額でお買取りします"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K14 ->
            calcGd market.gd 583 450
                |> (\price ->
                        { label = "K14"
                        , note = "ハワイアンや米国のアクセサリーに多いです。日本でも最近ではよく見かけます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K10 ->
            calcGd market.gd 416 500
                |> (\price ->
                        { label = "K10"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K9 ->
            calcGd market.gd 375 500
                |> (\price ->
                        { label = "K9"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )


calcGd : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcGd price purity margin =
    let
        purified =
            Decimal.mul price (Decimal.fromIntWithExponent purity -3)

        buyout =
            Decimal.sub purified (Decimal.fromIntWithExponent margin 0) |> Decimal.truncate 1
    in
    { buyout = buyout |> Utils.toPrice
    , pawn =
        Decimal.mul buyout (Decimal.fromIntWithExponent 9 -1) |> Decimal.round 2 |> Utils.toPrice
    }


type Pt
    = PtIG
    | Pt1000
    | Pt950
    | Pt900
    | Pt850


ptRates : Market -> List Rate
ptRates market =
    [ PtIG, Pt1000, Pt950, Pt900, Pt850 ] |> List.map (ptRate market)


ptRate : Market -> Pt -> { label : String, note : String, buyout : String, pawn : String }
ptRate (Market market) pt =
    case pt of
        PtIG ->
            calcPt market.pt 1000 150
                |> (\price ->
                        { label = "PtIG"
                        , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はPt1000扱いとなります"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt1000 ->
            calcPt market.pt 1000 200
                |> (\price ->
                        { label = "Pt1000"
                        , note = "コイン・ネックレス・指輪等"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt950 ->
            calcPt market.pt 950 100
                |> (\price ->
                        { label = "Pt950"
                        , note = "ブランド品や結婚指輪などに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt900 ->
            calcPt market.pt 900 0
                |> (\price ->
                        { label = "Pt900"
                        , note = "指輪に使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt850 ->
            calcPt market.pt 850 0
                |> (\price ->
                        { label = "Pt850"
                        , note = "ネックレスやブレスレットに使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )


calcPt : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcPt price purity margin =
    let
        purified =
            Decimal.mul price (Decimal.fromIntWithExponent purity -3)

        buyout =
            Decimal.sub purified (Decimal.fromIntWithExponent margin 0) |> Decimal.truncate 1
    in
    { buyout = buyout |> Utils.toPrice
    , pawn =
        Decimal.mul buyout (Decimal.fromIntWithExponent 9 -1) |> Decimal.round 2 |> Utils.toPrice
    }



--


type Sv
    = SV1000
    | SV950
    | SV925


svRates : Market -> List Rate
svRates market =
    [ SV1000, SV950, SV925 ] |> List.map (svRate market)


svRate : Market -> Sv -> { label : String, note : String, buyout : String, pawn : String }
svRate (Market market) v =
    case v of
        SV1000 ->
            calcSv market.sv 1000 50
                |> (\price ->
                        { label = "SV1000"
                        , note = "インゴットや銀杯など"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        SV950 ->
            calcSv market.sv 950 50
                |> (\price ->
                        { label = "SV950"
                        , note = "トロフィーなどに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        SV925 ->
            calcSv market.sv 925 50
                |> (\price ->
                        { label = "SV925"
                        , note = "指輪に使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )


calcSv : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcSv price purity margin =
    let
        purified =
            Decimal.mul price (Decimal.fromIntWithExponent purity -3)

        buyout =
            Decimal.sub purified (Decimal.fromIntWithExponent margin 0) |> Decimal.truncate 1
    in
    { buyout = buyout |> Utils.toPrice
    , pawn =
        Decimal.mul buyout (Decimal.fromIntWithExponent 9 -1) |> Decimal.round 1 |> Utils.toPrice
    }


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
