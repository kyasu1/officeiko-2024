module Ticket exposing (..)

import Decimal exposing (Decimal)


type alias Ticket =
    { category : Category
    , name : String
    , note : Maybe String
    , price : Price
    }


type Category
    = Shopping
    | Gift
    | Travel
    | Beer
    | Stamp
    | Ohter


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

        Ohter ->
            "その他"


type Price
    = Priced Int
    | Percent Decimal
