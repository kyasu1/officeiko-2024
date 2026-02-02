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
    }


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
    JD.map6 Internal
        timestampDecoder
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


gdParams : Gd -> { purity : Int, percent : Decimal, label : String, note : String }
gdParams gd =
    case gd of
        AuIG ->
            { purity = 1000
            , percent = Decimal.fromIntWithExponent 96 -2
            , label = "AuIG"
            , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はK24S扱いとなります"
            }

        K24 ->
            { purity = 1000
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K24"
            , note = "純金のコイン、K24刻印のある指輪やネックレスなど"
            }

        K23 ->
            { purity = 958
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K23"
            , note = "イーグル金貨、クルーガーランド金貨、ブリタニア金貨、中華系のアクセサリーなど（支那金）"
            }

        K22 ->
            { purity = 916
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K22"
            , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
            }

        K21_6 ->
            { purity = 900
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K21.6"
            , note = "インディアンコインやイーグルコインなど米国や中南米のコインに多いです"
            }

        K20 ->
            { purity = 833
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K20"
            , note = "古いコインや、中華・中東圏の国々のアクセサリーに多いです"
            }

        K18S ->
            { purity = 750
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K18"
            , note = "国内では最も一般的です。検定刻印の有無に関わらず同じ金額でお買取りします"
            }

        K14 ->
            { purity = 585
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "K14"
            , note = "ハワイアンや米国のアクセサリーに多いです。日本でも最近ではよく見かけます"
            }

        K10 ->
            { purity = 416
            , percent = Decimal.fromIntWithExponent 86 -2
            , label = "K10"
            , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
            }

        K9 ->
            { purity = 375
            , percent = Decimal.fromIntWithExponent 86 -2
            , label = "K9"
            , note = "最近は金の高騰にともない、ファッションジュエリーなどで販売価格を抑えるために使われます"
            }


gdRatePercent : Market -> Gd -> { label : String, note : String, buyout : String, pawn : String }
gdRatePercent (Market market) gd =
    let
        params =
            gdParams gd
    in
    calcGdByPercent market.gd params.purity params.percent
        |> (\price ->
                { label = params.label
                , note = params.note
                , buyout = price.buyout
                , pawn = price.pawn
                }
           )



-- Core calculation functions


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
-- calcGd : Decimal -> Int -> Int -> { buyout : String, pawn : String }
-- calcGd price purity margin =
--     calcByMargin price purity margin 8


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


ptParams : Pt -> { purity : Int, percent : Decimal, label : String, note : String }
ptParams pt =
    case pt of
        PtIG ->
            { purity = 1000
            , percent = Decimal.fromIntWithExponent 95 -2
            , label = "PtIG"
            , note = "田中貴金属や徳力などのインゴット、ただし傷のある物はPt1000扱いとなります"
            }

        Pt1000 ->
            { purity = 1000
            , percent = Decimal.fromIntWithExponent 92 -2
            , label = "Pt1000"
            , note = "コイン・ネックレス・指輪等"
            }

        Pt950 ->
            { purity = 950
            , percent = Decimal.fromIntWithExponent 92 -2
            , label = "Pt950"
            , note = "ブランド品や結婚指輪などに多いです"
            }

        Pt900 ->
            { purity = 900
            , percent = Decimal.fromIntWithExponent 98 -2
            , label = "Pt900"
            , note = "指輪に使用される場合が多いです"
            }

        Pt850 ->
            { purity = 850
            , percent = Decimal.fromIntWithExponent 98 -2
            , label = "Pt850"
            , note = "ネックレスやブレスレットに使用される場合が多いです"
            }


ptRatePercent : Market -> Pt -> { label : String, note : String, buyout : String, pawn : String }
ptRatePercent (Market market) pt =
    let
        params =
            ptParams pt
    in
    calcPtByPercent market.pt params.purity params.percent
        |> (\price ->
                { label = params.label
                , note = params.note
                , buyout = price.buyout
                , pawn = price.pawn
                }
           )



-- Platinum calculation functions
-- calcPt : Decimal -> Int -> Int -> { buyout : String, pawn : String }
-- calcPt price purity margin =
--     calcByMargin price purity margin 9


calcPtByPercent : Decimal -> Int -> Decimal -> { buyout : String, pawn : String }
calcPtByPercent price purity percent =
    calcByPercent price purity percent 8



--


type Sv
    = SV1000
    | SV950
    | SV925


svRates : Market -> List Rate
svRates market =
    [ SV1000, SV950, SV925 ] |> List.map (svRatePercent market)


svParams : Sv -> { purity : Int, percent : Decimal, label : String, note : String }
svParams v =
    case v of
        SV1000 ->
            { purity = 1000
            , percent = Decimal.fromIntWithExponent 70 -2
            , label = "SV1000"
            , note = "インゴットや銀杯など"
            }

        SV950 ->
            { purity = 950
            , percent = Decimal.fromIntWithExponent 70 -2
            , label = "SV950"
            , note = "トロフィーなどに多いです"
            }

        SV925 ->
            { purity = 925
            , percent = Decimal.fromIntWithExponent 70 -2
            , label = "SV925"
            , note = "指輪に使用される場合が多いです"
            }


svRatePercent : Market -> Sv -> { label : String, note : String, buyout : String, pawn : String }
svRatePercent (Market market) v =
    let
        params =
            svParams v
    in
    calcSvByPercent market.sv params.purity params.percent
        |> (\price ->
                { label = params.label
                , note = params.note
                , buyout = price.buyout
                , pawn = price.pawn
                }
           )



-- Silver calculation functions


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
