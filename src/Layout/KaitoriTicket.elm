module Layout.KaitoriTicket exposing (TicketFile, data, view)

import BackendTask exposing (BackendTask)
import BackendTask.File
import Css exposing (decimal)
import Date exposing (Date)
import Decimal exposing (Decimal)
import FatalError exposing (FatalError)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Image
import Json.Decode as JD
import Json.Decode.Extra as JD
import Layout
import Ticket exposing (Category)
import Url
import Utils


type alias TicketFile =
    { date : Date
    , items : List Ticket
    }


decoder : JD.Decoder TicketFile
decoder =
    JD.map2 TicketFile
        (JD.at [ "ticket", "date" ] Utils.dateDecoder)
        (JD.at [ "ticket", "items" ] (JD.list ticketDecoder))


type alias Ticket =
    { category : Category
    , comment : Maybe String
    , name : String
    , priceRate : PriceRate
    }


ticketDecoder : JD.Decoder Ticket
ticketDecoder =
    JD.map4 Ticket
        (JD.field "category" categoryDecoder)
        (JD.field "comment" (JD.nullable JD.string))
        (JD.field "name" JD.string)
        priceRateDecoder


type PriceRate
    = Price Decimal
    | Rate Decimal


priceRateDecoder : JD.Decoder PriceRate
priceRateDecoder =
    JD.map2 Tuple.pair (JD.optionalField "price" JD.int) (JD.optionalField "rate" JD.float)
        |> JD.andThen
            (\( maybePrice, maybeRate ) ->
                case ( maybePrice, maybeRate ) of
                    ( Just price, Nothing ) ->
                        JD.succeed (Price (Decimal.fromInt price))

                    ( Nothing, Just rate ) ->
                        case Decimal.fromFloat rate of
                            Just decimal ->
                                JD.succeed (Rate decimal)

                            Nothing ->
                                JD.fail "Invalid float string"

                    _ ->
                        JD.fail "Price or Rate must be specfied"
            )


priceRateToString : PriceRate -> String
priceRateToString v =
    case v of
        Price price ->
            Utils.toPrice price ++ "円"

        Rate rate ->
            (Decimal.mul (Decimal.fromInt 100) rate |> Decimal.truncate -1 |> Decimal.toString) ++ "%"


type Category
    = Shopping
    | Gift
    | Travel
    | Beer
    | Stamp
    | Other


categoryDecoder : JD.Decoder Category
categoryDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case s of
                    "商品券" ->
                        JD.succeed Shopping

                    "ギフト券" ->
                        JD.succeed Gift

                    "旅行券" ->
                        JD.succeed Travel

                    "ビール券" ->
                        JD.succeed Beer

                    "切手・印紙" ->
                        JD.succeed Stamp

                    "その他" ->
                        JD.succeed Other

                    _ ->
                        JD.fail "Invalid category string"
            )


categoryToString : Category -> String
categoryToString v =
    case v of
        Shopping ->
            "商品券"

        Gift ->
            "ギフト券"

        Travel ->
            "旅行券"

        Beer ->
            "ビール券"

        Stamp ->
            "切手・印紙"

        Other ->
            "その他"


view : TicketFile -> List (Html msg)
view file =
    let
        cover =
            case Url.fromString "https://image.officeiko.work/cover_ticket.jpg" of
                Just url ->
                    Image.render
                        (Image.new
                            { url = url
                            , width = 1600
                            , height = 1200
                            }
                        )

                Nothing ->
                    text ""
    in
    [ Layout.hero [] [ text "金券買取" ]
    , Layout.image [] cover
    , Layout.section [ class "leading-loose" ]
        [ div [] [ text "質イコーでは商品券やギフト券、旅行券、ビール券、切手、収入印紙、テレカ、株主優待券などの金券類を1枚から買取をさせていただいております。一覧表に掲載のない場合は  お問い合わせ ください。お気軽にご利用ください！" ]
        , div [ class "font-bold" ] [ text "原則として金券類の質預かりはいたしておりません。" ]
        ]
    , Layout.section [ class "text-center" ]
        [ text "更新日 "
        , text (Utils.kanjiDate file.date)
        ]
    , Layout.section []
        [ tbl Shopping file.items
        , div [ class "text-sm mt-2" ] [ text "その他の商品券については  お問い合わせ ください。" ]
        ]
    , Layout.section []
        [ tbl Gift file.items
        , div [ class "text-sm mt-2" ] [ text "現行の柄が対象となります。その他のギフト券については  お問い合わせ ください。" ]
        ]
    , Layout.section []
        [ tbl Travel file.items
        , div [ class "text-sm mt-2" ] [ text "その他の旅行券については  お問い合わせ ください。" ]
        ]
    , Layout.section []
        [ tbl Beer file.items
        , div [ class "text-sm mt-2" ] [ text "その他の古いビール券についてはお問い合わせください。" ]
        ]
    , Layout.section []
        [ tbl Stamp file.items
        , div [ class "text-sm mt-2" ] [ text "バラ切手は指定様式に台紙に貼っていただくと買取額がアップします。" ]
        ]
    , Layout.section []
        [ tbl Other file.items
        , div [ class "text-sm mt-2" ] [ text "記載のないお品物もお調べして買取させていただきますのでお気軽に  お問い合わせ ください。" ]
        ]
    , Layout.section []
        [ tbl Other []
        , div [ class "text-sm mt-2" ] [ text "各種株主優待券(JALやANAなど)も買取いたしております。有効期限があるものが多いですので余裕をもってお持ちください。時期によって変動します。" ]
        ]
    ]


tbl : Category -> List Ticket -> Html msg
tbl category list =
    List.filter (\item -> item.category == category) list
        |> List.indexedMap row
        |> (\contents ->
                div []
                    [ h3 [ class "p-2 font-bold" ] [ text (categoryToString category) ]
                    , div [ class "" ] contents
                    ]
           )


row : Int -> Ticket -> Html msg
row index ticket =
    div
        [ class "flex flex-row justify-between p-2"
        , if modBy 2 index == 0 then
            class "bg-green-200"

          else
            class "bg-green-100"
        ]
        [ div []
            [ div [] [ text ticket.name ]
            , div [ class "text-sm text-red-700 h-4 font-bold" ] [ text (Maybe.withDefault "" ticket.comment) ]
            ]
        , div [ class "w-24 align-right text-right font-bold self-center" ] [ text (priceRateToString ticket.priceRate) ]
        ]



--


data : BackendTask FatalError TicketFile
data =
    BackendTask.File.jsonFile decoder "ticket.json"
        |> BackendTask.allowFatal
