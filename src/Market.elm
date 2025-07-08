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
      -- , gdRate
    , gdRatePercent
    , gdRates
    , ptDiff
    , ptPrice
      -- , ptRate
    , ptRatePercent
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
        (JD.field "date" Iso8601.decoder)
        (JD.field "gd" JD.int |> JD.map Decimal.fromInt)
        (JD.field "gd_ratio" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt" JD.int |> JD.map Decimal.fromInt)
        (JD.field "pt_ratio" JD.int |> JD.map Decimal.fromInt)
        (JD.field "sv" JD.int |> JD.map Decimal.fromInt)
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
      -- | K18
    | K18S
    | K14
    | K10
    | K9


gdRates : Market -> List Rate
gdRates market =
    [ AuIG, K24, K23, K22, K21_6, K20, K18S, K14, K10, K9 ] |> List.map (gdRatePercent market)


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
            calcGd market.gd 1000 300
                |> (\price ->
                        { label = "K24"
                        , note = "純金のコイン、K24刻印のある指輪やネックレスなど"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K23 ->
            calcGd market.gd 958 500
                |> (\price ->
                        { label = "K23"
                        , note = "イーグル金貨、クルーガーランド金貨、ブリタニア金貨、中華系のアクセサリーなど（支那金）"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K22 ->
            calcGd market.gd 916 500
                |> (\price ->
                        { label = "K22"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K21_6 ->
            calcGd market.gd 900 500
                |> (\price ->
                        { label = "K21.6"
                        , note = "インディアンコインやイーグルコインなど米国や中南米のコインに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K20 ->
            calcGd market.gd 833 500
                |> (\price ->
                        { label = "K20"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
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
            calcGd market.gd 585 450
                |> (\price ->
                        { label = "K14"
                        , note = "ハワイアンや米国のアクセサリーに多いです。日本でも最近ではよく見かけます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K10 ->
            calcGd market.gd 416 800
                |> (\price ->
                        { label = "K10"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K9 ->
            calcGd market.gd 375 800
                |> (\price ->
                        { label = "K9"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )


gdRatePercent : Market -> Gd -> { label : String, note : String, buyout : String, pawn : String }
gdRatePercent (Market market) gd =
    case gd of
        AuIG ->
            calcGdByPercent market.gd 1000 (Decimal.fromIntWithExponent 98 -2)
                |> (\price ->
                        { label = "AuIG"
                        , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はK24S扱いとなります"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K24 ->
            calcGdByPercent market.gd 1000 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "K24"
                        , note = "純金のコイン、K24刻印のある指輪やネックレスなど"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K23 ->
            calcGdByPercent market.gd 958 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "K23"
                        , note = "イーグル金貨、クルーガーランド金貨、ブリタニア金貨、中華系のアクセサリーなど（支那金）"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K22 ->
            calcGdByPercent market.gd 916 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "K22"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K21_6 ->
            calcGdByPercent market.gd 900 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "K21.6"
                        , note = "インディアンコインやイーグルコインなど米国や中南米のコインに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K20 ->
            calcGdByPercent market.gd 833 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "K20"
                        , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K18S ->
            calcGdByPercent market.gd 750 (Decimal.fromIntWithExponent 98 -2)
                |> (\price ->
                        { label = "K18"
                        , note = "国内では最も一般的です。検定刻印の有無に関わらず同じ金額でお買取りします"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K14 ->
            calcGdByPercent market.gd 585 (Decimal.fromIntWithExponent 95 -2)
                |> (\price ->
                        { label = "K14"
                        , note = "ハワイアンや米国のアクセサリーに多いです。日本でも最近ではよく見かけます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K10 ->
            calcGdByPercent market.gd 416 (Decimal.fromIntWithExponent 88 -2)
                |> (\price ->
                        { label = "K10"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        K9 ->
            calcGdByPercent market.gd 375 (Decimal.fromIntWithExponent 88 -2)
                |> (\price ->
                        { label = "K9"
                        , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )



-- Core calculation functions


calcByMargin : Decimal -> Int -> Int -> Int -> { buyout : String, pawn : String }
calcByMargin price purity margin pawnRate =
    let
        purified =
            Decimal.mul price (Decimal.fromIntWithExponent purity -3)

        buyout =
            Decimal.sub purified (Decimal.fromIntWithExponent margin 0)
                |> Decimal.truncate 1
    in
    { buyout = buyout |> Utils.toPrice
    , pawn =
        Decimal.mul buyout (Decimal.fromIntWithExponent pawnRate -1)
            |> Decimal.round 2
            |> Utils.toPrice
    }


calcByPercent : Decimal -> Int -> Decimal -> Int -> { buyout : String, pawn : String }
calcByPercent price purity percent pawnRate =
    let
        purified =
            Decimal.mul price (Decimal.fromIntWithExponent purity -3)

        buyout =
            Decimal.mul purified percent
                |> Decimal.truncate 1
    in
    { buyout = buyout |> Utils.toPrice
    , pawn =
        Decimal.mul buyout (Decimal.fromIntWithExponent pawnRate -1)
            |> Decimal.round 2
            |> Utils.toPrice
    }



-- Gold calculation functions


calcGd : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcGd price purity margin =
    calcByMargin price purity margin 8


calcGdByPercent : Decimal -> Int -> Decimal -> { buyout : String, pawn : String }
calcGdByPercent price purity percent =
    calcByPercent price purity percent 8


type Pt
    = PtIG
    | Pt1000
    | Pt950
    | Pt900
    | Pt850


ptRates : Market -> List Rate
ptRates market =
    [ PtIG, Pt1000, Pt950, Pt900, Pt850 ] |> List.map (ptRatePercent market)


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


ptRatePercent : Market -> Pt -> { label : String, note : String, buyout : String, pawn : String }
ptRatePercent (Market market) pt =
    case pt of
        PtIG ->
            calcPtByPercent market.pt 1000 (Decimal.fromIntWithExponent 97 -2)
                |> (\price ->
                        { label = "PtIG"
                        , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はPt1000扱いとなります"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt1000 ->
            calcPtByPercent market.pt 1000 (Decimal.fromIntWithExponent 94 -2)
                |> (\price ->
                        { label = "Pt1000"
                        , note = "コイン・ネックレス・指輪等"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt950 ->
            calcPtByPercent market.pt 950 (Decimal.fromIntWithExponent 94 -2)
                |> (\price ->
                        { label = "Pt950"
                        , note = "ブランド品や結婚指輪などに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt900 ->
            calcPtByPercent market.pt 900 (Decimal.fromIntWithExponent 100 -2)
                |> (\price ->
                        { label = "Pt900"
                        , note = "指輪に使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        Pt850 ->
            calcPtByPercent market.pt 850 (Decimal.fromIntWithExponent 100 -2)
                |> (\price ->
                        { label = "Pt850"
                        , note = "ネックレスやブレスレットに使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )



-- Platinum calculation functions


calcPt : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcPt price purity margin =
    calcByMargin price purity margin 9


calcPtByPercent : Decimal -> Int -> Decimal -> { buyout : String, pawn : String }
calcPtByPercent price purity percent =
    calcByPercent price purity percent 9



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


svRatePercent : Market -> Sv -> { label : String, note : String, buyout : String, pawn : String }
svRatePercent (Market market) v =
    case v of
        SV1000 ->
            calcSvByPercent market.sv 1000 (Decimal.fromIntWithExponent 70 -2)
                |> (\price ->
                        { label = "SV1000"
                        , note = "インゴットや銀杯など"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        SV950 ->
            calcSvByPercent market.sv 950 (Decimal.fromIntWithExponent 70 -2)
                |> (\price ->
                        { label = "SV950"
                        , note = "トロフィーなどに多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )

        SV925 ->
            calcSvByPercent market.sv 925 (Decimal.fromIntWithExponent 70 -2)
                |> (\price ->
                        { label = "SV925"
                        , note = "指輪に使用される場合が多いです"
                        , buyout = price.buyout
                        , pawn = price.pawn
                        }
                   )



-- Silver calculation functions


calcSv : Decimal -> Int -> Int -> { buyout : String, pawn : String }
calcSv price purity margin =
    calcByMargin price purity margin 7


calcSvByPercent : Decimal -> Int -> Decimal -> { buyout : String, pawn : String }
calcSvByPercent price purity percent =
    calcByPercent price purity percent 7



-- Coin calculation functions


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
