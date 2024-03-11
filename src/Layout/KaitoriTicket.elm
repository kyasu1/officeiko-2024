module Layout.KaitoriTicket exposing (..)

import Html exposing (..)
import Html.Attributes as A exposing (class)
import Layout


view : List (Html msg)
view =
    [ Layout.hero [] [ text "金券買取" ]
    , Layout.image [] (img [ A.src "/images/cover_about.jpg" ] [])
    , Layout.section []
        [ text "準備中" ]
    ]


classTh =
    class "bg-gray-100 p-4"


classTd =
    class "bg-white p-4"
