module Layout.Stocks exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Market exposing (Market)


view : Market -> List (Html msg)
view market =
    [ Layout.hero [ class "print:hidden" ] [ text "金・プラチナの買取と質預り価格" ]
    , article [ class "max-w-[768px] mx-auto" ]
        [ section [ class "px-2 space-y-4 mb-4" ]
            [ div [ class "text-right pt-4 print:pt-0" ] [ text "更新日：", text <| Market.updated market ]
            , div [ class "text-sm grid grid-cols-[120px_1fr_1fr] md:grid-cols-[200px_1fr_1fr] w-full md:max-w-[600px] mx-auto" ]
                [ div [ class "col-span-3 text-center print:hidden" ] [ text "貴金属相場" ]
                , div [ class "text-center" ] [ text "金" ]
                , div [ class "text-right pr-2" ] [ text (Market.gdPrice market), text "円（税込み）" ]
                , div [ class "text-right pr-2" ]
                    [ text "前日比 "
                    , text (Market.gdDiff market)
                    , text "円"
                    ]
                , div [ class "text-center" ] [ text "プラチナ" ]
                , div [ class "text-right pr-2" ] [ text (Market.ptPrice market), text "円（税込み）" ]
                , div [ class "text-right pr-2" ]
                    [ text "前日比 "
                    , text (Market.ptDiff market)
                    , text "円"
                    ]
                ]
            , viewGd (Market.gdRates market)
            , div [ class "text-sm print:hidden" ] [ text "`18K/14K`刻印はX線でお調べしたうえでお買取いたします（一部買取不可あり）" ]
            , viewPt (Market.ptRates market)
            , div [ class "text-sm print:hidden" ] [ text "`Pm/PM`刻印はPt850として買取いたします" ]
            , viewSv (Market.svRates market)
            , div [ class "text-sm print:hidden" ] [ text "`SILVER`の刻印のみの場合は原則として買取不可となります" ]
            ]
        , section [ class "px-2 space-y-4 mb-4 print:hidden" ]
            [ viewCoin market
            , div [ class "text-sm" ] [ text "その他の金貨も高価買取いたします。お気軽にお問い合わせください。" ]
            , div []
                [ ul [ class "list-disc text-sm md:leading-loose ml-4" ]
                    [ li []
                        [ text "蛍光X線分析装置がありますので、金歯や刻印の無い品物でもお取り扱い可能でございます。" ]
                    , li
                        []
                        [ text "ジュエリーに付いたダイヤモンドや宝石なども評価の対象となります。" ]
                    , li
                        []
                        [ text "手数料や査定料などはかかりません。" ]
                    , li
                        []
                        [ text "破損や変形したお品物でも金・プラチナであればお買取が可能でございます。ご不明なお品物がございます場合は一度お問い合わせください。" ]
                    ]
                ]
            ]
        ]
    ]


outlineGd : Html.Attribute msg
outlineGd =
    class "outline outline-1 outline-yellow-600"


viewGd : List Market.Rate -> Html msg
viewGd rates =
    div [ class "grid grid-cols-[200px_1fr_1fr] gap-px" ]
        ([ div [ outlineGd, class "col-span-3 bg-yellow-400 py-2 text-center text-xl font-bold print:text-base" ] [ text "金製品" ]
         , div [ outlineGd, class "bg-yellow-400 text-center p-2 print:hidden" ] [ text "品位" ]
         , div [ outlineGd, class "bg-yellow-400 text-center p-2 print:hidden" ] [ text "買取価額" ]
         , div [ outlineGd, class "bg-yellow-400 text-center p-2 print:hidden" ] [ text "質預価額" ]
         ]
            ++ List.concat (List.map viewGdRow rates)
        )


viewGdRow : Market.Rate -> List (Html msg)
viewGdRow rate =
    [ div [ outlineGd, class "pl-2 py-1 bg-yellow-400" ] [ text rate.label ]
    , div [ outlineGd, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.buyout, text "円" ]
    , div [ outlineGd, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.pawn, text "円" ]
    , div [ outlineGd, class "px-2 py-1 text-xs col-span-3 print:hidden" ] [ text rate.note ]
    ]


outlinePt : Html.Attribute msg
outlinePt =
    class "outline outline-1 outline-gray-500"


viewPt : List Market.Rate -> Html msg
viewPt rates =
    div [ class "grid grid-cols-[200px_1fr_1fr] gap-px" ]
        ([ div [ outlinePt, class "col-span-3 bg-gray-300 py-2 text-center text-xl font-bold print:text-base" ] [ text "プラチナ" ]
         , div [ outlinePt, class "bg-gray-300 text-center p-2 print:hidden" ] [ text "品位" ]
         , div [ outlinePt, class "bg-gray-300 text-center p-2 print:hidden" ] [ text "買取価額" ]
         , div [ outlinePt, class "bg-gray-300 text-center p-2 print:hidden" ] [ text "質預価額" ]
         ]
            ++ List.concat (List.map viewPtRow rates)
        )


viewPtRow : Market.Rate -> List (Html msg)
viewPtRow rate =
    [ div [ outlinePt, class "pl-2 py-1 bg-gray-300" ] [ text rate.label ]
    , div [ outlinePt, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.buyout, text "円" ]
    , div [ outlinePt, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.pawn, text "円" ]
    , div [ outlinePt, class "px-2 py-1 text-xs col-span-3 print:hidden" ] [ text rate.note ]
    ]


outlineSv : Html.Attribute msg
outlineSv =
    class "outline outline-1 outline-gray-400"


viewSv : List Market.Rate -> Html msg
viewSv rates =
    div [ class "grid grid-cols-[200px_1fr_1fr] gap-px" ]
        ([ div [ outlineSv, class "col-span-3 bg-gray-100 py-2 text-center text-xl font-bold print:text-base" ] [ text "シルバー" ]
         , div [ outlineSv, class "bg-gray-100 text-center p-2" ] [ text "品位" ]
         , div [ outlineSv, class "bg-gray-100 text-center p-2" ] [ text "買取価額" ]
         , div [ outlineSv, class "bg-gray-100 text-center p-2" ] [ text "質預価額" ]
         ]
            ++ List.concat (List.map viewSvRow rates)
        )


viewSvRow : Market.Rate -> List (Html msg)
viewSvRow rate =
    [ div [ outlineSv, class "pl-2 py-1 bg-gray-100" ] [ text rate.label ]
    , div [ outlineSv, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.buyout, text "円" ]
    , div [ outlineSv, class "pr-2 md:pr-4 py-1 text-right font-medium" ] [ text rate.pawn, text "円" ]
    , div [ outlineSv, class "px-2 py-1 text-xs col-span-3 print:hidden" ] [ text rate.note ]
    ]


outlineCoin : Html.Attribute msg
outlineCoin =
    class "outline outline-1 outline-yellow-500"


viewCoin : Market -> Html msg
viewCoin market =
    div [ class "grid grid-cols-2 md:grid-cols-[400px_1fr_1fr] gap-px" ]
        ([ div [ outlineCoin, class "col-span-2 md:col-span-3 py-2 text-center text-xl font-bold bg-yellow-200" ] [ text "金貨" ]
         , div [ outlineCoin, class "col-span-2 md:col-span-1 py-2 text-center text-sm md:text-base bg-yellow-200" ] [ text "品目" ]
         , div [ outlineCoin, class "py-2 text-center text-sm md:text-base bg-yellow-200 font-bold" ] [ text "買取価額" ]
         , div [ outlineCoin, class "py-2 text-center text-sm md:text-base bg-yellow-200 font-bold" ] [ text "質預価額" ]
         ]
            ++ List.concat (List.map viewCoinRow (Market.coinRates market))
        )


viewCoinRow : Market.Coin -> List (Html msg)
viewCoinRow coin =
    [ div [ outlineCoin, class "col-span-2 md:col-span-1 pl-2 py-1 text-sm md:text-base" ] [ text coin.label ]
    , div [ outlineCoin, class "pr-4 py-1 text-right font-medium text-sm md:text-base" ] [ text coin.buyout, text "円" ]
    , div [ outlineCoin, class "pr-4 py-1 text-right font-medium text-sm md:text-base" ] [ text coin.pawn, text "円" ]
    ]
