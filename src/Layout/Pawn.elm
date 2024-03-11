module Layout.Pawn exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Pawn


view : Html Pawn.Msg -> Html Pawn.Msg
view simulatorView =
    div []
        [ Layout.hero [] [ text "質入・融資" ]
        , Layout.image [] (img [ A.src "/images/pawn.jpg" ] [])
        , Layout.section []
            [ text "お客様のお品物を担保としてお預かりし、その品物の担保価値の上限の範囲でお金をご融資させて頂く契約です。"
            , text "質屋営業法を遵守して営業しておりますので、基本的な仕組みはどの質屋も共通ですが、イコー独自のサービスもございます。"
            , text "質屋営業法の規定により、お取引が可能な場所は当店の店頭またはお客様の自宅のみとなっております。"
            , text "遠方の方から宅配便を利用した質取引は禁止されていますのでご了承ください。"
            ]
        , Layout.section []
            [ h2 [] [ text "STEP 1 : ご来店" ]
            , h3 [] [ text "ご利用の際には有効な身分証明書が必要です" ]
            , div [] [ text "免許証" ]
            , div [] [ text "マイナンバーカード" ]
            , div [] [ text "在留カード" ]
            ]
        , Layout.section []
            [ h2 [] [ text "STEP 2 : 査定" ]
            , div [] [ text "お客様の目の前で査定します" ]
            , div [] [ text "先に必要な金額をお伝えいただくとスムーズです" ]
            , div [] [ text "ご融資可能な上限の金額をお伝えします" ]
            , div [] [ text "商談が不成立となった場合でも手数料・査定料などは発生しません" ]
            ]
        , Layout.section []
            [ div []
                [ h2 [] [ text "STEP 3 : 成約" ]
                , div [] [ text "査定内容にご承諾いただくと成約となります。" ]
                , div [] [ text "申し込み" ]
                ]
            ]
        , Layout.section []
            [ div []
                [ h2 [] [ text "STEP 4 : 融資" ]
                ]
            ]
        , Layout.section []
            [ div []
                [ h2 [] [ text "STEP 5 : ご返済・ご延長・質流れ" ]
                ]
            ]
        , Layout.section []
            [ div [ class "grid grid-cols-2 gap-2 md:gap-4 md:text-2xl" ]
                [ div [ class "p-2" ] [ text "ご融資金額" ]
                , div [ class "text-center p-2" ] [ text "質料（1ヶ月あたり）" ]
                , div [ class "bg-gray-200 p-2" ] [ text "100万円以上" ]
                , div [ class "text-center bg-gray-200 p-2" ] [ text "2%" ]
                , div [ class "p-2" ] [ text "50万円以上100万円未満" ]
                , div [ class "text-center p-2" ] [ text "3%" ]
                , div [ class "bg-gray-200 p-2" ] [ text "10万円以上50万円未満" ]
                , div [ class "text-center bg-gray-200 p-2" ] [ text "4%" ]
                , div [ class "p-2" ] [ text "5千円以上10万円未満" ]
                , div [ class "text-center p-2" ] [ text "5%" ]
                ]
            ]
        , Layout.section []
            [ simulatorView ]
        , Layout.section []
            [ ul [ class "text-sm md:text-lg leading-loose list-disc ml-4" ]
                [ li [] [ text "上記の質料は、当店が質屋営業法に則り定めたものです" ]
                , li [] [ text "質料の計算方法は満月計算とし、入質日より翌月の同日までを1ヶ月と計算します" ]
                , li [] [ text "流質期限は満3ヶ月、質流れの通知はいたしません" ]
                , li [] [ text "その他の事象につきましては質屋営業法ならびに法令の定めに従います" ]
                ]
            ]
        ]
