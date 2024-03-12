module Layout.Selling exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout
import Route


view : Html msg
view =
    div []
        [ Layout.hero [] [ text "取扱商品" ]
        , Layout.section []
            [ text "当店では様々な商品をお取り扱いしております。ほとんどのお品物は、買取だけではなく、質預かりで"
            , Layout.link "ご融資" Route.Pawn
            , text "する際の担保（質草）になります。"
            , text "買取の際は原則としてその場で"
            , strong [] [ text "現金" ]
            , text "にてお支払いをいたします。"
            ]
        , Layout.section []
            [ div [ class "space-y-8" ]
                (splitByTwo items |> List.map rows |> List.concat)
            ]
        ]


rows : ( Item msg, Maybe (Item msg) ) -> List (Html msg)
rows ( left, maybeRight ) =
    List.concat
        [ [ row Left left
          ]
        , case maybeRight of
            Just right ->
                [ row Right right
                ]

            Nothing ->
                []
        ]


row : Alignment -> Item msg -> Html msg
row alignment item =
    div [ class "grid grid-cols-1 md:grid-cols-3 items-center" ]
        [ div
            [ class "flex items-center justify-center"
            , case alignment of
                Left ->
                    class ""

                Right ->
                    class "md:order-last"
            ]
            [ img
                [ A.src item.image
                , class "w-full max-w-[240px] border border-black"
                , A.attribute "loading" "lazy"
                ]
                []
            ]
        , div [ class "md:col-span-2 bg-white w-full h-full p-4 shadow-sm" ]
            [ h3 [ class "font-bold" ] [ text item.header ]
            , p [ class "leading-loose" ] item.body
            ]
        ]


type Alignment
    = Left
    | Right


type alias Item msg =
    { header : String
    , body : List (Html msg)
    , image : String
    }


items : List (Item msg)
items =
    [ { header = "金・プラチナ製品"
      , body =
            [ text "金価格は10,000円/g超えの高値圏で推移中、まだまだ上がるのかは判りませんがとにかく高いです。当店の買取価格も毎日更新、"
            , Route.link [ class "text-blue-600 visited:text-purple-600 underline underline-offset-1" ]
                [ text "相場表"
                ]
                Route.Stocks
            , text "にて確認いただけます。"
            , text "プラチナは4,500円/g前後のレンジで推移、決して安くはないのですが、昔に比べると安定した相場になっています。"
            , text "金・プラチナ製品であれば、どんな物でも買取可能です。"
            , Layout.link "蛍光X線分析装置" (Route.Post__Slug_ { slug = "tools-xrf" })
            , text "や"
            , Layout.link "比重計" (Route.Post__Slug_ { slug = "tools-hydrometer" })
            , text "も完備しておりますので、金歯や海外製品、刻印の無い物でもお買取可能です"
            ]
      , image = "/images/item-metal.jpg"
      }
    , { header = "時計"
      , body =
            [ text "ロレックスやオメガ、タグ・ホイヤーなどの海外高級ブランド、グランドセイコーやカシオなどと幅広くお取り扱いしています。"
            , text "使用感が少なく状態の良い個体はより高い査定が期待できます。"
            , text "近年では、世界的な需要の高まりもあり、箱や保証書の有無により査定金額に大きな差が出ますので、付属品がある場合には必ずお持ちください。"
            , text "電池切れや故障した状態でも買取可能ですのでご相談ください。"
            ]
      , image = "/images/item-watch.jpg"
      }
    , { header = "ブランド品"
      , body =
            [ text "ルイヴィトン、シャネル、エルメス、グッチなどのバッグや財布小物類のお取り扱いが多いです。"
            , text "最近は、バレンシアガやサンローラン、ディオールなども高いです。"
            , text "購入時に付いてた、ブランドの保存袋や保証書などがありましたら必ず一緒にお持ちください。"
            , br [] []
            , span [ class "text-pink-500" ] [ text "ルイヴィトンやシャネルであれば、古くて大きく傷んだ品物でも買取可能ですので、まずは拝見させてください。" ]
            ]
      , image = "/images/item-bag.jpg"
      }
    , { header = "ジュエリー"
      , body =
            [ text "金相場の上昇により、ブランドジュエリーもどんどん高くなっています。カルティエ・ブルガリ・ティファニーなどのお取り扱いが多いです。"
            , text "付属品がある場合には必ずお持ちください。"
            , text "ノンブランドでもダイヤの付いたデザインの良いファッションジュエリーであればプラス査定が期待できます。"
            , text "結婚指輪や婚約指輪などでネーム刻印が入っている物も買取可能です。"
            ]
      , image = "/images/item-jewelry.jpg"
      }
    , { header = "ダイヤモンド"
      , body =
            [ text "ルースダイヤ（裸石）、指輪やネックレスなどの一粒石であれば高額な査定が期待できます。"
            , text "価格はダイヤモンドの大きさとクオリティによって大きく変化します。"
            , text "鑑定書があれば必ずお持ちください。"
            , text "鑑定書が無い場合でも、熟練の鑑定士が的確に査定します。"
            , text "カラーダイヤや大粒のダイヤモンドは、鑑定機関でのソーティングをおすすめいたします。"
            , text "買取成立時のソーティング費用は当社で負担いたします。"
            , text "お預かりから10営業日程度を要します。"
            ]
      , image = "/images/item-diamond.jpg"
      }
    , { header = "宝石・色石"
      , body =
            [ text "大きめのエメラルド・サファイア・ルビーをあしらったジュエリーが高いです。"
            , text "作家物やデザインの良いお品物はプラス査定が期待できます。"
            , text "最近はでは、上質なあこや真珠のネックレスが以前に比べて高いです。"
            , text "鑑別書がありましたら必ずお持ちください。取り巻きのメレダイヤなどもプラス査定になります。"
            ]
      , image = "/images/item-stone.jpg"
      }
    , { header = "スマホ・パソコン"
      , body =
            [ text "スマートフォンやタブレットにノートパソコン、主にApple製品が多く、新品・中古を問わずにお取り扱い可能です。"
            , text "査定時に動作確認が必要ですので、充電された状態でお持ちください。"
            , text "また、パスコードやアクティベーションロックは解除した状態でお持ちください。"
            ]
      , image = "/images/item-smart.jpg"
      }
    , { header = "カメラ"
      , body =
            [ text "ソニー・キャノン・ニコン等のデジタル一眼レフ、コンデジのお取り扱いが多いです。"
            , text "フィルムカメラもお取り扱いしておりますが、入門機や普及価格帯のモデルはお値段がつかない場合があります。"
            , text "古いレンズに価値がある場合があります。カビ・クモリの有無によって大きく金額が変わります。充電器やバッテリーなどの付属品は必ずお持ちください。"
            ]
      , image = "/images/item-camera.jpg"
      }
    , { header = "楽器"
      , body =
            [ text "国内外一流メーカーの、ギター・ベース・管楽器・キーボードなどを各種お取り扱いしております。ケースや付属品は必ずお持ちください。質預かりでのご利用される方が多いです。"
            , br [] []
            , span [ class "text-red-500" ] [ text "嵩張り物や重量物はお断りする場合があります" ]
            ]
      , image = "/images/item-instrument.jpg"
      }
    , { header = "工具"
      , body =
            [ text "マキタやハイコーキの充電式インパクトドライバのお取り扱いが多いです。新品・中古問わずお取り扱いします。バッテリーの有無・状態によって大きく査定額が変わります。"
            , br [] []
            , span [ class "text-red-500" ] [ text "嵩張り物や重量物、古いコンプレッサーやエアツールはお断りす場合があります。" ]
            ]
      , image = "/images/item-tool.jpg"
      }
    , { header = "鉄道模型"
      , body =
            [ text "NゲージやHOゲージ、車両やレール、ストラクチャーなども買取させていただきます。"
            , text "HOゲージの車両や、Nゲージの車輌セットなど、高価格帯のお品物であれば質預かりも可能です。"
            ]
      , image = "/images/item-toy.jpg"
      }
    , { header = "金券"
      , body =
            [ text "商品券、ギフト券、旅行券、切手やテレカなど、各種金券を高価買取しております。詳細は"
            , Layout.link "リスト" Route.KaitoriTicket
            , text "をご参照ください。リストにない商品もお調べしますので、お気軽にお問合せください。切手類はお時間を要するため、一時預かりににて査定せていただく場合がございます。"
            , br [] []
            , span [ class "text-red-500" ] [ text "原則として金券類の質預かりはお取り扱いしていません。" ]
            ]
      , image = "/images/item-ticket.jpg"
      }
    ]


splitByTwo : List a -> List ( a, Maybe a )
splitByTwo list =
    case list of
        a :: b :: rest ->
            ( a, Just b ) :: splitByTwo rest

        [ a ] ->
            [ ( a, Nothing ) ]

        [] ->
            []
