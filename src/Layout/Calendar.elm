module Layout.Calendar exposing (view)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout


view : List (Html msg)
view =
    [ Layout.hero []
        [ h2 [ class "text-center font-bold text-2xl" ] [ text "営業日カレンダー" ]
        , h3 [ class "text-center font-bold text-xl" ] [ text "OPENING CALENDAR" ]
        ]
    , Layout.section []
        [ div [ class "text-sm text-center print:text-left leading-8 print:leading-4 flex flex-col print:flex-row py-4" ]
            [ div [ class "print:w-1/2" ]
                [ p [] [ text "定休日：毎週水曜日 第1火曜日 第3火曜日 / 営業時間：10:00am - 7:00pm" ]
                , p [] [ text "赤丸が定休日です。ウェスタン・ユニオンの受付は6:30pmまで" ]
                ]
            , div [ class "print:w-1/2" ]
                [ p [] [ text "Closed every Wednesday and 1st and 3rd Tuesday (RED circles)" ]
                , p [] [ text "Western Union International Money Transfer is until 6:30pm" ]
                ]
            ]
        ]
    , Layout.section []
        [ div [ class "flex flex-col md:flex-row print:flex-row items-center md:space-x-8" ]
            [ div [ class "md:w-1/2 print:w-1/2 py-4 print:py-0" ]
                [ img
                    [ class "border border-black rounded print:border-transparent"
                    , A.src "https://s3-ap-northeast-1.amazonaws.com/officeiko-public/calendars/this.png"
                    ]
                    []
                ]
            , div [ class "md:w-1/2 print:w-1/2 py-4 print:py-0" ]
                [ img
                    [ class "border border-black rounded print:border-transparent"
                    , A.src "https://s3-ap-northeast-1.amazonaws.com/officeiko-public/calendars/next.png"
                    ]
                    []
                ]
            ]
        ]
    , Layout.section []
        [ text "特別なお知らせ："
        ]
    ]
