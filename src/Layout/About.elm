module Layout.About exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout


view : List (Html msg)
view =
    [ Layout.hero [] [ text "会社概要" ]
    , Layout.image [] (img [ A.src "/images/cover_about.jpg" ] [])
    , Layout.section []
        [ div [ class "grid grid-cols-1 md:grid-cols-[1fr_2fr] gap-px bg-gray-500 border border-gray-500" ]
            [ div [ classTh ] [ text "会社名" ]
            , div [ classTd ] [ text "株式会社オフイスイコー" ]
            , div [ classTh ] [ text "代表者" ]
            , div [ classTd ] [ text "代表取締役 小松原 康行" ]
            , div [ classTh ] [ text "設立" ]
            , div [ classTd ] [ text "1995年5月19日" ]
            , div [ classTh ] [ text "資本金" ]
            , div [ classTd ] [ text "6,000万円" ]
            , div [ classTh ] [ text "所在地" ]
            , div [ classTd ] [ text "〒343-0851 埼玉県越谷市七左町1-299-1" ]
            , div [ classTh ] [ text "質屋許可" ]
            , div [ classTd ] [ text "埼玉県公安委員会 第43127A113900号" ]
            , div [ classTh ] [ text "古物商許可" ]
            , div [ classTd ] [ text "埼玉県公安委員会 第431270002100号" ]
            , div [ classTh ] [ text "TEL" ]
            , div [ classTd ] [ text "048-987-1020" ]
            , div [ classTh ] [ text "営業時間" ]
            , div [ classTd ] [ text "10:00am - 7:00pm" ]
            , div [ classTh ] [ text "定休日" ]
            , div [ classTd ] [ text "毎週水曜日・第1と第3火曜日" ]
            , div [ classTh ] [ text "所属団体" ]
            , div [ classTd ] [ Layout.externalLink "https://www.zenshichi.gr.jp/" [ text "全国質屋組合連合会" ] ]
            , div [ classTh ] [ text "所属団体" ]
            , div [ classTd ] [ Layout.externalLink "https://www.saitama783.com" [ text "埼玉県質屋組合連合会" ] ]
            ]
        ]
    ]


classTh =
    class "bg-gray-100 p-4"


classTd =
    class "bg-white p-4"
