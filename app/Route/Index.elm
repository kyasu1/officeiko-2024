module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image exposing (Image)
import Layout
import Market exposing (Market)
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Post exposing (Post)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import Url exposing (Url)
import Utils
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    { news : List Post
    , blog : List Post
    , tenpoTopImage : Image
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.succeed Data
        |> BackendTask.andMap Post.newsPosts
        |> BackendTask.andMap Post.blogPosts
        |> BackendTask.andMap tenpoTopImageTask


tenpoTopImageTask : BackendTask FatalError Image
tenpoTopImageTask =
    case Url.fromString "https://image.officeiko.work/tenpo-top-4-3.jpg" of
        Just url ->
            BackendTask.succeed (Image.new { url = url, width = 1600, height = 900 })

        Nothing ->
            BackendTask.fail (FatalError.fromString "Err")


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "質イコー Western Union - IKO Pawnshop"
        , image = Settings.image
        , description = "質イコーは国道4号バイパス沿いにあるお店です。イコー買取館の大きな看板が目印。専用駐車場完備でお車でのご来店が便利です。初めての方や女性にも安心してご利用いただける親切な対応を心がけています。ブランド …"
        , locale = Nothing
        , title = "越谷市の質屋 質イコー イコー買取館 ブランド品 金 プラチナ ロレックス 高級時計 金券 - 越谷市,草加市,川口市,春日部市,八潮市,吉川市 "
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    { title = "質イコー Western Union - IKO Pawnshop"
    , body =
        [ Layout.section []
            [ div [ class "flex flex-col lg:flex-row lg:space-x-4" ]
                [ div [ class "w-full lg:w-1/2" ]
                    [ Image.render app.data.tenpoTopImage ]
                , viewMarket app.sharedData.market
                ]
            ]
        , Layout.section []
            [ div [ class "border border-gray-800 p-2" ]
                [ h2 [ class "text-center py-2 font-bold" ] [ text "新着情報" ]
                , div [ class "md:w-1/2 mx-auto" ]
                    (List.map
                        (\post ->
                            div [ class "flex space-x-4" ]
                                [ div []
                                    [ text (Utils.kanjiDate post.publishedOn)
                                    ]
                                , div []
                                    [ Route.link [ class "hover:text-indigo-800" ] [ text post.title ] (Route.Post__Slug_ { slug = post.slug })
                                    ]
                                ]
                        )
                        app.data.news
                    )
                ]
            ]
        , Layout.section []
            [ div [ class "px-2 md:px-0 grid grid-cols-1 md:grid-cols-2 gap-4" ]
                [ Route.link [ class "w-full p-2 flex items-center justify-center bg-red-600" ]
                    [ div [ class "font-bold text-white text-lg md:text-xl lg:text-2xl" ] [ text "詐欺販売サイトに関するご注意" ]
                    ]
                    (Route.Post__Slug_ { slug = "fake-site-alert" })
                , Route.link []
                    [ div [ class "w-full flex items-center justify-center bg-black" ]
                        [ img [ A.src "/images/logo.wu.big.svg", class "max-w-[240px]" ] [] ]
                    ]
                    Route.WesternUnion
                ]
            ]
        , Layout.section []
            [ div [ class "flex flex-col md:flex-row md:space-x-4" ]
                [ div [ class "w-full md:w-1/2 p-4 bg-gray-200 flex flex-col items-center justify-center" ]
                    [ div [] [ text "質イコーの強み" ]
                    , div [] [ text "ABOUT US" ]
                    , div [] [ text "不要になったお品物は高価買取" ]
                    , div [] [ text "大切なお品物は質預かり" ]
                    ]
                , div [ class "w-full md:w-1/2 text-sm leading-loose" ]
                    [ div []
                        [ text "質イコーは、埼玉県越谷市にある質屋です。"
                        , text "当店では、金・プラチナ製品、ロレックスなどの高級時計、ブランド品、ジュエリー・ダイヤモンド、カメラや楽器、各種金券、お酒など、幅広い商品を買取しております。"
                        , text "原則として、その場で現金にてお支払いいたします。査定料や手数料はかかりません。"
                        ]
                    , div [] [ text "最寄り駅からはやや遠いですが、広い駐車場がありますのでお車でのご来店が便利です。" ]
                    ]
                ]
            ]
        , Layout.section [ A.id "access" ]
            [ div [ class "flex flex-col md:flex-row md:space-x-4" ]
                [ div [ class "w-full md:w-1/2" ]
                    [ h3 [ class "bg-iko-500 px-2 py-1 text-white mb-2" ] [ text "アクセス / Access" ]
                    , div [ class "pl-4" ] [ text "【住所】埼玉県越谷市七左町1-299-1" ]
                    , div [ class "pl-4" ] [ text "【電話番号】048-987-1020" ]
                    , h4 [ class "bg-gray-200 px-2 py-1 my-2" ] [ text "車でお越しのお客様" ]
                    , div [ class "text-sm pl-2 leading-loose" ]
                        [ text "東京外環自動車道、【草加IC】より約2Km北上、国道4号バイパス沿い、上り車線側になります。駐車場完備"
                        ]
                    , h4 [ class "bg-gray-200 px-2 py-1 my-2" ] [ text "電車でお越しお客様" ]
                    , div [ class "text-sm pl-2 leading-loose" ]
                        [ p [] [ text "東武スカイツリーライン蒲生駅 徒歩15分" ]
                        , p [] [ text "東武スカイツリーライン新越谷駅 徒歩20分" ]
                        , p [] [ text "JR武蔵野線南越谷駅 徒歩25分" ]
                        , p [ class "font-bold" ] [ text "バスの運行がないため、新越谷駅西口からタクシーのご利用が便利です。" ]
                        ]
                    ]
                , div [ class "w-full md:w-1/2 p-0 md:px-2" ]
                    [ iframe
                        [ A.src "https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d12933.155755233138!2d139.7797398!3d35.8664355!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x60189684c5a656c5%3A0xce45f80ac0cce0dc!2z6LOq44Kk44Kz44O8IFdlc3Rlcm4gVW5pb24gLSBJS08gUGF3bnNob3A!5e0!3m2!1sja!2sjp!4v1709905898535!5m2!1sja!2sjp"
                        , class "w-full h-[400px]"
                        , A.style "border" "0"
                        , A.attribute "allowfullscreen" ""
                        , A.attribute "loading" "lazy"
                        , A.attribute "referrerpolicy" "no-referrer-when-downgrade"
                        ]
                        []
                    ]
                ]
            ]
        , Layout.section [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2" ]
            (List.map
                (\post ->
                    div [ class "py-4" ]
                        [ div [ class "mb-4" ]
                            [ Route.link []
                                [ Image.render post.coverImage
                                ]
                                (Route.Post__Slug_ { slug = post.slug })
                            ]
                        , div [ class "text-sm" ] [ text (Utils.kanjiDate post.publishedOn) ]
                        , div [ class "text-sm text-ellipsis whitespace-nowrap overflow-hidden max-w-400px lg:max-w-[200px]" ] [ text post.title ]
                        ]
                )
                app.data.blog
            )
        , Layout.section []
            [ h3 [ class "text-center pb-4 text-2xl font-bold" ] [ text "当店の販売サイト" ]
            , div [ class "grid grid-cols-2 md:grid-cols-4 gap-1" ]
                [ div [ class "bg-white p-2" ]
                    [ Layout.link "https://www.chrono24.jp/dealer/pawnshopiko/index.htm"
                        [ img [ A.src "/images/logo_chrono24.png", A.alt "Chrono24" ] [] ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://store.shopping.yahoo.co.jp/pawnshopiko/"
                        [ img [ A.src "/images/logo_shopping.png", A.alt "ヤフーショッピング" ] [] ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://auctions.yahoo.co.jp/seller/pawnshopiko"
                        [ img [ A.src "/images/logo_auction.png", A.alt "ヤフーオークション" ] [] ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://jp.mercari.com/mypage/listings"
                        [ img [ A.src "/images/logo_mercari.png", A.alt "メルカリ" ] [] ]
                    ]
                ]
            ]
        , Layout.section []
            [ div [ class "text-center pb-4" ]
                [ div [ class " text-2xl font-bold" ] [ text "営業カレンダー" ]
                , div [ class " text-red-600 font-bold" ] [ text "赤丸は休業日です" ]
                ]
            , div [ class "flex flex-col md:flex-row md:justify-evenly" ]
                [ div [ class "md:max-w-80" ]
                    [ img
                        [ A.src "https://image.officeiko.work/calendars/this.png"
                        , A.width 771
                        , A.height 771
                        ]
                        []
                    ]
                , div [ class "md:max-w-80" ]
                    [ img
                        [ A.src "https://image.officeiko.work/calendars/next.png"
                        , A.width 771
                        , A.height 771
                        ]
                        []
                    ]
                ]
            ]
        , Layout.section []
            [ h3 [ class "text-center pb-4 text-2xl font-bold" ] [ text "関連サイト" ]
            , div [ class "grid grid-cols-2 md:grid-cols-4 gap-1" ]
                [ div [ class "bg-white p-2" ]
                    [ Layout.link "https://www.zenshichi.gr.jp/"
                        [ img [ A.src "/images/banner-zenshichi@2x.png", A.alt "全国質屋組合連合会" ] [] ]
                    , div [ class "text-sm mt-2 text-center" ] [ text "全国質屋組合連合会" ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://www.saitama783.com/"
                        [ img [ A.src "/images/banner_saitama783.png", A.alt "埼玉県質屋組合連合会" ] [] ]
                    , div [ class "text-sm mt-2 text-center" ] [ text "埼玉県質屋組合連合会" ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://www.iko78.com"
                        [ img [ A.src "/images/banner_iko78.png", A.alt "イコーグループ" ] [] ]
                    , div [ class "text-sm mt-2 text-center" ] [ text "イコーグループのサイト" ]
                    ]
                , div [ class "bg-white p-2" ]
                    [ Layout.link "https://www.shichimaru.com"
                        [ img [ A.src "/images/banner_shichimaru.png", A.alt "しちまる" ] [] ]
                    , div [ class "text-sm mt-2 text-center" ] [ text "質屋のマスコットしちまる" ]
                    ]
                ]
            ]
        ]
    }


viewMarket : Market -> Html msg
viewMarket market =
    div [ class "lg:basis-[500px] my-2 md:my-0" ]
        [ div [ class "flex flex-col md:flex-row md:justify-between items-center p-2 space-y-1 md:space-y-0 text-lg text-white bg-green-900" ]
            [ div [] [ text "本日の金プラチナ買取価格" ]
            , div [ class "text-sm" ] [ text (Market.updated market) ]
            ]
        , div [ class "flex flex-row justify-around lg:justify-between py-2 px-2 lg:px-0 space-x-2" ]
            [ div [ class "flex flex-col lg:flex-row bg-yellow-500 p-4 items-center w-full rounded-md max-w-60" ]
                [ div [ class "lg:w-1/3 text-center" ] [ text "金" ]
                , div [ class "w-full lg:w-2/3 font-semibold" ]
                    [ div [ class "flex flex-row justify-between" ]
                        [ div [] [ text "ｲﾝｺﾞｯﾄ" ]
                        , div [] [ text (Market.gdRatePercent market Market.AuIG |> .buyout), text "円" ]
                        ]
                    , div [ class "flex flex-row justify-between" ]
                        [ div [] [ text "K18" ]
                        , div [] [ text (Market.gdRatePercent market Market.K18S |> .buyout), text "円" ]
                        ]
                    , div [ class "flex flex-row justify-between" ]
                        [ div [] [ text "K14" ]
                        , div [] [ text (Market.gdRatePercent market Market.K14 |> .buyout), text "円" ]
                        ]
                    ]
                ]
            , div [ class "flex flex-col lg:flex-row bg-gray-400 p-4 items-center w-full rounded-md max-w-60" ]
                [ div [ class "lg:w-1/3" ] [ text "プラチナ" ]
                , div [ class "w-full lg:w-2/3 font-semibold" ]
                    [ div [ class "flex flex-row justify-between " ]
                        [ div [] [ text "ｲﾝｺﾞｯﾄ" ]
                        , div [] [ text (Market.ptRatePercent market Market.PtIG |> .buyout), text "円" ]
                        ]
                    , div [ class "flex flex-row justify-between" ]
                        [ div [] [ text "Pt900" ]
                        , div [] [ text (Market.ptRatePercent market Market.Pt900 |> .buyout), text "円" ]
                        ]
                    , div [ class "flex flex-row justify-between" ]
                        [ div [] [ text "Pt850" ]
                        , div [] [ text (Market.ptRatePercent market Market.Pt850 |> .buyout), text "円" ]
                        ]
                    ]
                ]
            ]
        , div [ class "space-y-2 px-2 md:px-0" ]
            [ Route.link [ class "flex items-center justify-center p-2 w-full border border-iko-500" ]
                [ div [ class "font-bold text-lg md:text-xl lg:text-2xl" ] [ text "金プラチナ相場表" ] ]
                Route.Stocks
            , Route.link [ class "flex items-center justify-center p-2 border border-iko-500" ]
                [ div [ class "font-bold text-lg md:text-xl lg:text-2xl" ] [ text "金券買取価格一覧" ]
                ]
                Route.KaitoriTicket
            ]
        ]
