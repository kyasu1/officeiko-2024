module Layout.Calendar exposing (view)

import Holiday exposing (Holiday)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Layout


view : Holiday -> List (Html msg)
view holiday =
    [ Layout.hero [ class "space-y-2 py-2" ]
        [ h2 [ class "text-center font-bold text-2xl" ] [ text "営業日カレンダー" ]
        , h3 [ class "text-center font-bold text-xl" ] [ text "OPENING CALENDAR" ]
        ]
    , Layout.section []
        [ div [ class "text-sm text-center print:text-left leading-8 print:leading-4 flex flex-col print:flex-row py-4 print:py-0" ]
            [ div [ class "print:w-1/2" ]
                [ div [] [ text "定休日：毎週水曜日 第1火曜日 第3火曜日" ]
                , div [] [ text "営業時間：10:00am - 7:00pm" ]
                , div [] [ text "ウェスタン・ユニオンの受付は6:30pmまで" ]
                ]
            , div [ class "print:w-1/2" ]
                [ div [] [ text "Closed Wednesday and 1st and 3rd Tuesday" ]
                , div [] [ text "Western Union is until 6:30pm" ]
                ]
            ]
        ]
    , Layout.section []
        [ div [ class "flex flex-col space-y-8 md:space-y-0 print:space-y-0 md:flex-row print:flex-row items-center md:space-x-8" ]
            [ div [ class "md:w-1/2 print:w-1/2 flex items-center justify-center" ]
                [ img
                    [ class "border border-black rounded print:border-transparent"
                    , A.src "https://image.officeiko.work/calendars/this.png"
                    , A.width 389
                    , A.height 389
                    ]
                    []
                ]
            , div [ class "md:w-1/2 print:w-1/2 flex items-center justify-center" ]
                [ img
                    [ class "border border-black rounded print:border-transparent"
                    , A.src "https://image.officeiko.work/calendars/next.png"
                    , A.width 389
                    , A.height 389
                    ]
                    []
                ]
            ]
        ]
    , case holiday.notice of
        Just notice ->
            Layout.section []
                [ h4 [ class "font-bold text-xl text-center" ] [ text "特別なお知らせ：", text notice.message ]
                , div [ class "print:hidden" ]
                    [ case notice.image of
                        Just image ->
                            Image.render image

                        Nothing ->
                            text ""
                    ]
                ]

        Nothing ->
            text ""
    ]
