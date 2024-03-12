module Layout.Pawn exposing (..)

import Heroicons.Outline as Outline
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Pawn
import Svg.Attributes as SA


view : Html Pawn.Msg -> Html Pawn.Msg
view simulatorView =
    div []
        [ Layout.hero [] [ text "質入・融資" ]
        , Layout.image [] (img [ A.src "/images/pawn.jpg" ] [])
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ div []
                [ Outline.currencyYen [ SA.class "w-8 h-8 inline mr-2 text-iko-500" ]
                , text "お客様が所有するお品物を担保として質屋が預かりそのかわりにお金をご融資するのが質契約です。"
                , text "当店にてお品物を査定させていただき、ご提示した金額を上限としてお借入ができます。"
                , text "万が一に返済が困難になっても、お品物の所有権を手放すことにより（質流れ）、借りたお金を返済する義務がなくなるのが、質屋による融資の最大の特徴です。"
                ]
            , div []
                [ Outline.currencyYen [ SA.class "w-8 h-8 inline mr-2 text-iko-500" ]
                , text "質屋営業法を遵守して営業しておりますので、基本的な仕組みはどの質屋も共通ですが、イコー独自のサービスもございます。"
                , text "質屋営業法の規定により、お取引が可能な場所は当店の店頭またはお客様の自宅のみとなっており、"
                , text "遠方の方からの宅配便を利用した質取引は禁止されていますのでご了承ください。"
                ]
            ]
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ Layout.subHeader [ text "STEP 1 : ご来店" ]
            , h3 [] [ text "ご利用の際には有効期限内の下記のいずれかの身分証明書をお持ちください（原本のみ）。" ]
            , div [] [ text "免許証" ]
            , div [] [ text "マイナンバーカード" ]
            , div [] [ text "在留カード" ]
            ]
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ Layout.subHeader [ text "STEP 2 : 査定" ]
            , div []
                [ text "お客様の目の前で査定しますが、点数が多い場合は査定にお時間を要する場合がありますのでご了承ください。"
                , text "もし必要な金額があれば、先にお伝えいただくとスムーズです。"
                ]
            , div [] [ text "査定が完了しますと、ご融資可能な上限の金額をお伝えします。もし、商談が不成立となった場合でも手数料・査定料などは発生しません" ]
            ]
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ div []
                [ Layout.subHeader [ text "STEP 3 : 成約" ]
                , div []
                    [ text "査定内容をご承諾いただき成約となりましたら、初めての方には初取引カードにご記入いただきます。"
                    , text "印鑑などは必要ありません。"
                    ]
                ]
            ]
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ div []
                [ Layout.subHeader [ text "STEP 4 : 融資" ]
                , div []
                    [ text "契約成約後に当店の"
                    , text "質札"
                    , text "を発行いたします。"
                    , text "質札は受戻しの際に必要となりますの紛失しないようにご注意ください。"
                    , text "質札にはお預かりした品物の概要と点数、契約日と流質期限が記載されています。"
                    , text "原則としてご本人様しか受戻しはできかねますのでご注意ください。"
                    ]
                , div [] [ text "お預かりしたお品物は、適切に梱包をして当店の大金庫に保管されます。" ]
                ]
            ]
        , Layout.section [ class "md:leading-loose md:text-xl" ]
            [ div []
                [ Layout.subHeader [ text "STEP 5 : ご返済・ご延長・質流れ" ]
                , h3 [ class "" ] [ text "ご返済" ]
                , h3 [] [ text "ご延長" ]
                , h3 [] [ text "質流れ" ]
                , div []
                    [ text "流質期限までにご返済またはご延長をしていただけない場合、質流れの対象となります。"
                    , text "質流れになりますと、お品物の所有権がお客様から当社へ移動します。"
                    ]
                ]
            ]
        , Layout.section []
            [ Layout.subHeader [ text "当店の質料" ]
            , div [ class "grid grid-cols-2 gap-px bg-gray-800 border border-gray-800 md:text-xl " ]
                [ div [ class "p-2 bg-white" ] [ text "ご融資金額" ]
                , div [ class "text-center p-2 bg-white" ] [ text "質料（1ヶ月あたり）" ]
                , div [ class "bg-gray-200 p-2" ] [ text "100万円以上" ]
                , div [ class "text-center bg-gray-200 p-2" ] [ text "2%" ]
                , div [ class "p-2 bg-white" ] [ text "50万円以上100万円未満" ]
                , div [ class "text-center p-2 bg-white" ] [ text "3%" ]
                , div [ class "bg-gray-200 p-2" ] [ text "10万円以上50万円未満" ]
                , div [ class "text-center bg-gray-200 p-2" ] [ text "4%" ]
                , div [ class "p-2 bg-white" ] [ text "5千円以上10万円未満" ]
                , div [ class "text-center p-2 bg-white" ] [ text "5%" ]
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
