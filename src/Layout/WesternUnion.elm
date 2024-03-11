module Layout.WesternUnion exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Route


view : Html msg
view =
    div []
        [ Layout.hero [] [ text "ウエスタンユニオンの海外送金" ]
        , Layout.image [] (img [ A.src "/images/western_union.png" ] [])
        , Layout.section []
            [ p [] [ text "ウエスタンユニオンの送金サービスは145年以上の実績があります" ]
            , p [] [ text "200を超える世界中の国や地域でサービスが展開されています" ]
            , p [] [ text "弊社はウエスタンユニオンの代理店として2020年1月からお取り扱いしています" ]
            ]
        , Layout.section []
            [ div [ class "bg-white p-4 leading-loose border" ]
                [ h3 [ class "text-center font-bold py-2" ] [ text "詐欺にあわないために" ]
                , p [ class "text-sm" ]
                    [ text "ネット上には、多岐にわたる手法であなたをだます詐欺師の罠が広がっています。"
                    , text "あなたが送金したお金が犯罪組織やテロ組織の資金に利用される可能性があります。"
                    ]
                , dl [ class "py-2 pl-2" ]
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
                , p [ class "text-sm" ]
                    [ text "「実際に会ったことがない相手」への送金は危険ですのでよく考えてください。"
                    , text "あなたが送金したお金で詐欺師たちが贅沢三昧をしているかもしれません。"
                    ]
                ]
            ]
        , Layout.section []
            [ h3 [ class "text-center py-2 font-bold border-b" ] [ text "本人確認書類について" ]
            , div [] []
            , div []
                [ div [ class "py-4" ]
                    [ div [] [ text "日本国籍の方" ]
                    , ul [ class "list-disc ml-8" ]
                        [ li [] [ text "運転免許証 + マイナンバー確認書類" ]
                        , li [] [ text "マイナンバーカード" ]
                        , li [] [ text "パスポート + 居住地の証明書 + マイナンバー確認書類" ]
                        ]
                    ]
                , div [ class "py-4" ]
                    [ div [] [ text "外国籍の方" ]
                    , ul [ class "list-disc ml-8" ]
                        [ li [] [ text "在留カード + マイナンバー確認書類" ]
                        , li [] [ text "パスポート（短期滞在者、ただし難民申請中の方はお取引ができません）" ]
                        ]
                    ]
                , div [ class "py-4" ]
                    [ div [] [ text "マイナンバー確認書類とは下記のいずれかを指します" ]
                    , ul [ class "list-disc ml-8" ]
                        [ li [] [ text "マイナンバーカード" ]
                        , li [] [ text "マイナンバー通知カード（紙製）" ]
                        , li [] [ text "個人番号が記載された住民票（発行後6ヶ月以内）" ]
                        ]
                    ]
                , div [ class "py-4" ]
                    [ div [] [ text "居住地の証明書とは下記のいずれかを指します" ]
                    , ul [ class "list-disc ml-8" ]
                        [ li [] [ text "住民票" ]
                        , li [] [ text "納税証明書" ]
                        , li [] [ text "印鑑登録証明書" ]
                        ]
                    ]
                , div [ class "py-4" ] [ text "いずれも原本が毎回必要となります。スマホの写真やコピーでは受付できません。" ]
                ]
            ]
        , Layout.section []
            [ h3 [ class "text-center py-2 font-bold border-b" ] [ text "送金の流れ" ]
            , dl []
                [ dt [] [ text "申込み用紙の記入と受取人情報の確認" ]
                , dd [] []
                , dt [] [ text "本文確認書類の提示" ]
                , dd []
                    [ text "上記の本人確認書類をご提示いただきます。「お名前」【現住所」「生年月日」「顔写真」が記載された部分のコピーを取ります。"
                    , text "マイナンバー記載部分のコピーはいたしません。"
                    ]
                , dt [] [ text "送金内容の確認" ]
                , dd [] []
                , dt [] [ text "お金の支払い" ]
                , dd [] []
                , dt [] [ text "送金完了" ]
                , dd [] []
                ]
            ]
        , Layout.section []
            [ h3 [ class "text-center py-2 font-bold border-b" ] [ text "受取の流れ" ]
            ]

        -- , Layout.section
        --     [ div [ class "space-y-8" ]
        --         (splitByTwo items |> List.map rows |> List.concat)
        --     ]
        ]
