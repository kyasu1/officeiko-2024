module Layout.Contact exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Route


view : List (Html msg)
view =
    [ Layout.hero [] [ text "お問い合わせ" ]
    , Layout.image [] (img [ A.src "/images/cover_line.jpg" ] [])
    , Layout.section []
        [ div []
            [ text "お問い合わせは、上記の"
            , Layout.externalLink "https://page.line.me/oue6072d?openQrModal=true" [ text "LINE公式アカウント" ]
            , text "またはメールにて承ります。"
            ]
        , div [ class "py-4" ]
            [ text "メールアドレス"
            , text " "
            , text "info@officeiko.co.jp"
            ]
        , div [ class "leading-loose" ]
            [ text "お問い合わせ内容によっては、回答にお時間がかかる場合や、回答を差し控えさせていただく場合がございます。"
            , text "また、定休日、夏期休業および冬期休業期間など営業時間外にいただいたお問い合わせは、"
            , text "翌営業日以降のご対応とさせていただきます。"
            , text "スマホなどのキャリアメールをご利用の場合、当社からの返信メールが受信できるように、当社のメールアドレスinfo@officeiko.co.jpを迷惑メールフィルタから除外してください。"
            ]
        ]
    , Layout.section []
        [ div [ class "leading-loose" ]
            [ text "お送りいただいた個人情報は、お客様とのご連絡等の目的以外では使用致しません。当社の"
            , Layout.link "プライバシーポリシー" Route.Privacy
            , text "をご確認いただき、同意いただいた上でご送信ください。ご入力いただいた情報は暗号化されて送信されます。"
            ]
        ]
    ]


classTh =
    class "bg-gray-100 p-4"


classTd =
    class "bg-white p-4"
