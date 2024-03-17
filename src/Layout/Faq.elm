module Layout.Faq exposing (view)

import Heroicons.Outline as Outline
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Route
import Svg.Attributes as SA


view : List (Html msg)
view =
    [ Layout.hero [] [ text "よくあるご質問" ]

    -- , Layout.image [] (img [ A.src "/images/cover_line.jpg" ] [])
    , Layout.section []
        [ h2 [ class "text-lg font-bold mb-2" ] [ text "お取引について" ]
        , div [ class "space-y-4" ] (List.map qAndA general)
        ]
    , Layout.section []
        [ h2 [ A.id "pawn", class "text-lg font-bold mb-2" ] [ text "質の取引について" ]
        , div [ class "space-y-4" ] (List.map qAndA pawn)
        ]
    , Layout.section []
        [ h2 [ A.id "selling", class "text-lg font-bold mb-2" ] [ text "買取の取引について" ]
        , div [ class "space-y-4" ] (List.map qAndA selling)
        ]
    , Layout.section []
        [ div [ class "leading-loose" ]
            [ text "お送りいただいた個人情報は、お客様とのご連絡等の目的以外では使用致しません。当社の"
            , Layout.link "プライバシーポリシー" Route.Privacy
            , text "をご確認いただき、同意いただいた上でご送信ください。ご入力いただいた情報は暗号化されて送信されます。"
            ]
        ]
    ]


qAndA : ( String, List (Html msg) ) -> Html msg
qAndA ( q, a ) =
    div [ class "border text-lg md:text-xl border-gray-400" ]
        [ div [ class "py-2 flex items-center border-b border-dashed border-gray-400 p-4" ]
            [ Outline.questionMarkCircle [ SA.class "w-10 h-10 inline-block text-red-500" ]
            , span [ class "ml-2" ] [ text q ]
            ]
        , div [ class "py-2 flex items-center p-4" ]
            [ Outline.sun [ SA.class "w-10 h-10 text-green-600" ]
            , span [ class "ml-2" ] a
            ]
        ]


general =
    [ ( "取引をするにはどんな書類が必要ですか"
      , [ text "運転免許証・マイナンバーカード・在留カードなど顔つきの身分証明書をお持ちください" ]
      )
    , ( "自宅に電話連絡や郵便物が届いたりしますか"
      , [ text "災害などの緊急時を除き、当店からご連絡することはありませんのでご安心ください" ]
      )
    , ( "外国人ですがお取引は可能ですか"
      , [ text "お取引可能です、在留カードまたは運転免許証を身分証としてお持ちください" ]
      )
    ]


pawn =
    [ ( "期限を1日でも過ぎたら質流れになってしまいますか"
      , [ text "通常はすぐには処分しませんので、遅れる場合には当店までご連絡をください" ]
      )
    , ( "期限の日ですがお店が休みでした、どうなりますか"
      , [ text "期日が当店の休業日担った場合、翌営業日を期日とします。もし遅れる場合には当店までご連絡をください" ]
      )
    ]


selling =
    [ ( "気が変わったので買取してもらった品物を返してほしいです"
      , [ text "申し訳ございません、一度取引が成立した後はお品物を返しすることはできかねます" ]
      )
    ]


classTh =
    class "bg-gray-100 p-4"


classTd =
    class "bg-white p-4"
