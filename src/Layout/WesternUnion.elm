module Layout.WesternUnion exposing (..)

import Heroicons.Outline as Outline
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import List exposing (map5)
import Route
import Svg.Attributes as SA


iconInfo =
    Outline.informationCircle [ SA.class "w-10 h-10 inline text-yellow-500 bg-black rounded-full" ]


iconError =
    Outline.xCircle [ SA.class "w-10 h-10 inline text-red-500 bg-black rounded-full" ]


view : Html msg
view =
    div []
        [ Layout.hero [] [ text "ウエスタンユニオンの海外送金" ]
        , Layout.image []
            (img
                [ A.src "/images/western_union.png"
                , A.alt "ウエスタンユニオンの海外送金"
                , A.title "ウエスタンユニオンの海外送金"
                ]
                []
            )
        , Layout.section [ class "py-4" ]
            [ h3 [ class "text-center font-bold text-lg" ] [ text "LOCATION" ]
            , div [ class "text-center text-sm md:text-base bg-gray-200 p-2 " ]
                [ text "Google Maps is your friend! "
                , text "Open this "
                , Layout.externalLink "https://maps.app.goo.gl/GuHagUvSGzJ1qvaU8" [ text "LINK" ]
                , text " for more details."
                ]
            ]
        , Layout.section [ class "space-y-4 leading-loose" ]
            [ p []
                [ iconInfo
                , text " "
                , text "ウエスタンユニオンの代理店として2020年1月からお取り扱いしています。"
                , text "当店は窓口型店舗のため、現金での送金・受取に対応しています。"
                , Layout.externalLink "https://www.westernunion.com/jp/ja/mobile-app.html"
                    [ strong [] [ text "モバイルアプリ" ]
                    ]
                , text "を利用したお取引には対応しておりませんのでご注意ください。"
                ]
            , p []
                [ iconInfo
                , text " "
                , text "送金の際には下記の"
                , a [ A.href "/western-union#feeTable" ] [ text "手数料" ]
                , text "が発生いたします。"
                , text "送金時の為替レートにはウエスタンユニオンの両替手数料が含まれており、"
                , text "銀行間やネットに掲載の一般的な為替レートとは異なりますのでご了承ください。"
                , text "当日のレートは非公開のため店舗まで直接お問い合わせください。"
                ]
            , p []
                [ iconInfo
                , text " "
                , text "一回で送金可能な金額の上限は100万円程度とされていますが、相手国の情勢により異なります。"
                , span [ class "text-red-500 font-semibold" ]
                    [ text "同一店舗にて一日あたり3件の取引が可能です（同じ日にコンビニを含む違う店舗から送れません）。"
                    ]
                , text "年間の送金可能金額（数百万円程度とされていますが非公開）が存在し、それを超えて送ることはできません。"
                ]
            , p []
                [ iconInfo
                , text " "
                , text "通常はお手続きは10分程度で完了します。"
                , text "送金が完了しますと、およそ10分後には相手国の取扱店舗にて受取が可能となります。"
                , text "ただし時差および相手国の情勢によってはこの限りではありません。"
                ]
            , p []
                [ iconInfo
                , text " "
                , text "お取引の際には有効な身分証明書の他に"
                , strong [] [ text "マイナンバー" ]
                , text "が必須となっております。下記の説明にあります書類の原本をご提示いただけない場合、お取引をお断りいたします。"
                ]
            , p []
                [ iconInfo
                , text " "
                , text "当店は質屋が営業母体ですので、常時現金のご用意をしていますが、"
                , text "受取の金額が高額になる場合には、お取り扱いが可能かどうかお問い合わせください。"
                ]
            , p []
                [ iconError
                , text " "
                , text "他人から頼まれての代理送金、会社宛てや商品の購入代金としての送金は禁止されています。"
                , text "これらの目的であることが判明した場合には、お取引をお断りいたします。"
                ]
            ]
        , Layout.section []
            [ text "その他詳細は、ウエスタンユニオンの"
            , Layout.externalLink "https://www.westernunion.com/jp/ja/frequently-asked-questions.html"
                [ text "ホームページ"
                ]
            , text "にてご確認ください。"
            ]
        , Layout.section []
            [ div [ class "bg-white p-4 border" ]
                [ h3 [ class "text-center font-bold py-2" ] [ text "詐欺にあわないために" ]
                , p [ class "text-sm" ]
                    [ text "ネット上には、多岐にわたる手法であなたをだます詐欺師の罠が広がっています。"
                    , text "あなたが送金したお金が犯罪組織やテロ組織の資金に利用される可能性があります。"
                    ]
                , dl [ class "py-2 pl-2 space-y-2" ]
                    [ dt [ class "font-bold" ] [ text "ロマンス詐欺" ]
                    , dd [ class "pl-2 text-sm" ]
                        [ text "ネットやSNSで知り合った相手から、お金に困っているため少しだけ助けてほしいと頼まれることがあります。"
                        , text "心優しい方は、少額であればと送金を承諾してしまいますが、実際には詐欺師グループが運営しているアカウントがほとんどです。"
                        ]
                    , dt [ class "font-bold" ] [ text "チャリティ詐欺" ]
                    , dd [ class "pl-2 text-sm" ]
                        [ text "世界中で戦争や災害に苦しんでいる人々が援助を求めています。"
                        , text "そんな人々の苦境をネットやメディアで知り、詐欺師が設立した架空のボランティア団体に送金してしまいます。"
                        ]
                    , dt [ class "font-bold" ] [ text "商品購入代金" ]
                    , dd [ class "pl-2 text-sm" ]
                        [ text "厳密には詐欺ではないかもしれませんが、商品購入代金の支払いにはご利用いただけません。"
                        , text "違法薬物や日本では合法ではない商品を購入する際に送金を求められることがあります。"
                        , text "合法な商品購入であれば、ネット決済が可能なはずです。"
                        ]
                    ]
                , p [ class "text-center py-4" ] [ iconError ]
                , p [ class "text-base font-bold" ]
                    [ text "「実際に会ったことがない相手」への送金は非常に危険です。"
                    , text "あなたが送金したお金で詐欺師たちが贅沢三昧をしているかもしれません。"
                    ]
                ]
            ]
        , Layout.section []
            [ div [ class "bg-white p-4 border" ]
                [ h3 [ class "text-center py-2 font-bold" ] [ text "本人確認書類について" ]
                , div []
                    [ div [ class "py-4" ]
                        [ div [ class "font-bold" ] [ text "日本国籍の方" ]
                        , ul [ class "list-disc ml-8 text-sm" ]
                            [ li [] [ text "運転免許証 + マイナンバー確認書類" ]
                            , li [] [ text "マイナンバーカード" ]
                            , li [] [ text "パスポート + 居住地の証明書 + マイナンバー確認書類" ]
                            ]
                        ]
                    , div [ class "py-4" ]
                        [ div [ class "font-bold" ] [ text "外国籍の方" ]
                        , ul [ class "list-disc ml-8 text-sm" ]
                            [ li [] [ text "在留カード + マイナンバー確認書類" ]
                            , li [] [ text "パスポート（短期滞在者、ただし難民申請中の方はお取引ができません）" ]
                            ]
                        ]
                    , div [ class "py-4" ]
                        [ div [ class "font-thin text-sm" ] [ text "マイナンバー確認書類とは下記のいずれかを指します" ]
                        , ul [ class "list-disc ml-8 text-sm" ]
                            [ li [] [ text "マイナンバーカード" ]
                            , li [] [ text "マイナンバー通知カード（紙製）" ]
                            , li [] [ text "個人番号が記載された住民票（発行後6ヶ月以内）" ]
                            ]
                        ]
                    , div [ class "py-4" ]
                        [ div [ class "text-sm" ] [ text "居住地の証明書とは下記のいずれかを指します" ]
                        , ul [ class "list-disc ml-8 text-sm" ]
                            [ li [] [ text "住民票" ]
                            , li [] [ text "納税証明書" ]
                            , li [] [ text "印鑑登録証明書" ]
                            ]
                        ]
                    , div [ class "py-4 text-sm" ] [ text "いずれも原本が毎回必要となります。スマホの写真やコピーでは受付できません。" ]
                    ]
                ]
            ]
        , Layout.section []
            [ div [ class "bg-white p-4 border" ]
                [ h3 [ class "text-center py-2 font-bold" ] [ text "送金の流れ" ]
                , div [ class "py-4" ]
                    [ text "送金時にご用意いただくものは、上記の本人確認書類の他に、受取人様の名前が必要となります。"
                    , text "受取時に相手の身分証明書と照合しますので、スペルミスや氏名の順序が異なると受取ができません。"
                    , text "相手の身分証明書などの画像を送ってもらうと間違いが少ないです。"
                    , text "名前の訂正が必要な場合、当店まで再度お越し頂く必要があります。電話では受付できません。"
                    , text "手続が完了すると10分後に受取が可能となります。"
                    ]
                , let
                    th =
                        class "p-2 text-white text-center"

                    td =
                        class "p-2 bg-white text-center"
                  in
                  --   div [ class "flex flex-col lg:flex-row p-4 space-y-4 lg:space-y-0 lg:space-x-4" ]
                  div [ A.id "feeTable", class "grid grid-cols-1 lg:grid-cols-2 gap-4" ]
                    [ h4 [ class "text-center text-sm md:text-base lg:col-span-2" ]
                        [ text "送金に関わる手数料は下記のとおりとなります。"
                        ]
                    , div [ class "w-full" ]
                        [ div [ class "grid grid-cols-2 gap-px bg-gray-900 border border-gray-900" ]
                            [ div [ th ] [ text "Principal(送金額) JPY" ]
                            , div [ th ] [ text "Fee(手数料) JPY" ]
                            , div [ td ] [ text "1 - 10,000" ]
                            , div [ td ] [ text "990" ]
                            , div [ td ] [ text "10,001 - 50,000" ]
                            , div [ td ] [ text "1,500" ]
                            , div [ td ] [ text "50,001 - 100,000" ]
                            , div [ td ] [ text "2,000" ]
                            , div [ td ] [ text "100,001 - 250,000" ]
                            , div [ td ] [ text "3,000" ]
                            , div [ td ] [ text "250,001 - 500,000" ]
                            , div [ td ] [ text "5,000" ]
                            , div [ td ] [ text "500,001 - 1,000,000" ]
                            , div [ td ] [ text "6,000" ]
                            ]
                        , div [ class "text-sm mt-4 px-2" ]
                            [ text "中国、韓国、フィリピン、ブラジル、ペルー、タイ、"
                            , text "ベトナム、インドネシア、パキスタン、ネパール、"
                            , text "バングラデシュ、インド、スリランカ、ミャンマー"
                            ]
                        ]
                    , div [ class "w-full" ]
                        [ div [ class "grid grid-cols-2 gap-px bg-gray-900 border border-gray-900" ]
                            [ div [ th ] [ text "Principal(送金額) JPY" ]
                            , div [ th ] [ text "Fee(手数料) JPY" ]
                            , div [ td ] [ text "1 - 10,000" ]
                            , div [ td ] [ text "990" ]
                            , div [ td ] [ text "10,001 - 50,000" ]
                            , div [ td ] [ text "1,500" ]
                            , div [ td ] [ text "50,001 - 100,000" ]
                            , div [ td ] [ text "3,000" ]
                            , div [ td ] [ text "100,001 - 250,000" ]
                            , div [ td ] [ text "5,000" ]
                            , div [ td ] [ text "250,001 - 500,000" ]
                            , div [ td ] [ text "7,000" ]
                            , div [ td ] [ text "500,001 - 1,000,000" ]
                            , div [ td ] [ text "9,000" ]
                            ]
                        , div [ class "text-sm mt-4 lg:hidden px-2" ] [ text "上記以外の国" ]
                        , div [ class "text-sm mt-4 hidden lg:block px-2" ] [ text "左記以外の国" ]
                        ]
                    ]
                ]
            ]
        , Layout.section []
            [ div [ class "bg-white p-4 border" ]
                [ h3 [ class "text-center py-2 font-bold" ] [ text "受取の流れ" ]
                , div []
                    [ text "相手から受け取った10桁のMTCN番号と上記の本人確認書類をご用意のうえでご来店ください。"
                    , text "システムに登録されたお客様の氏名と本人確認書類を照合いたします。"
                    , text "手続きが完了すると、現金でお支払いいたします。"
                    ]
                , p [ class "text-center py-4" ] [ iconError ]
                , div []
                    [ text "スペルミスや氏名の順番が異なる場合、お手続きができません。"
                    , text "お客様から送金人様へご連絡していただき、現地の代理店にて修正を依頼してください。"
                    , text "時差にもよりますが、近隣の国であれば10分程度で手続き可能です。"
                    ]
                ]
            ]
        , Layout.section []
            [ div [ class "flex justify-center" ]
                [ iframe
                    [ A.src "https://www.facebook.com/plugins/post.php?href=https%3A%2F%2Fwww.facebook.com%2Fwucvs%2Fposts%2Fpfbid0iJ5c2KJoNbT1Gk8GYNEWo1iShbs73fPs4tAq98LvXQ4GPNBB4aA8K4BYrCXV1eSXl&show_text=true&width=500"
                    , A.width 500
                    , A.height 536
                    , class "overflow-hidden border-none"
                    , A.attribute "scrolling" "no"
                    , A.attribute "frameborder" "0"
                    , A.attribute "allowfullscreen" "true"
                    , A.attribute "allow" "autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
                    ]
                    []
                ]
            ]

        -- , Layout.section
        --     [ div [ class "space-y-8" ]
        --         (splitByTwo items |> List.map rows |> List.concat)
        --     ]
        ]
