module Holiday exposing (SpecialHoliday, isHoliday, load, view)

import BackendTask exposing (BackendTask)
import Date exposing (Date)
import FatalError exposing (FatalError)
import Html exposing (..)
import Json.Decode as JD
import Strapi
import Time
import Utils


type alias SpecialHoliday =
    { holidayType : SpecialHolidayType
    , date : Date
    }


type SpecialHolidayType
    = Summer
    | Winter
    | Temporary


type HolidayType
    = Regular
    | Special SpecialHoliday


view : HolidayType -> List (Html msg)
view v =
    case v of
        Regular ->
            [ div [] [ text "本日は定休日" ]
            , div [] [ text "CLOSED TODAY" ]
            ]

        Special h ->
            case h.holidayType of
                Summer ->
                    [ div [] [ text "夏季休業" ]
                    , div [] [ text "SUMMER HOLIDAY TODAY" ]
                    ]

                Winter ->
                    [ div [] [ text "冬季休業" ]
                    , div [] [ text "WINTER HOLIDAY TODAY" ]
                    ]

                Temporary ->
                    [ div [] [ text "臨時休業" ]
                    , div [] [ text "TEMPORARY CLOSED" ]
                    ]


isHoliday : Date -> List SpecialHoliday -> Maybe HolidayType
isHoliday date holidays =
    if Date.weekday date == Time.Wed then
        Just Regular

    else if Date.weekday date == Time.Tue then
        if isNthTuesday 0 date || isNthTuesday 2 date then
            Just Regular

        else
            Nothing

    else
        List.filter (\holiday -> holiday.date == date) holidays
            |> List.head
            |> Maybe.map Special


isNthTuesday : Int -> Date -> Bool
isNthTuesday n date =
    (Date.fromCalendarDate (Date.year date) (Date.month date) 1
        |> Date.add Date.Weeks n
        |> Date.ceiling Date.Tuesday
    )
        == date


load : BackendTask FatalError (List SpecialHoliday)
load =
    Strapi.load "/special-holidays" decoder


decoder : JD.Decoder (List SpecialHoliday)
decoder =
    JD.field "data"
        (JD.list
            (JD.field "attributes"
                (JD.map2 SpecialHoliday
                    (JD.field "holidayType" holydayTypeDecode)
                    (JD.field "date" Utils.dateDecoder)
                )
            )
        )


holydayTypeDecode : JD.Decoder SpecialHolidayType
holydayTypeDecode =
    JD.string
        |> JD.andThen
            (\s ->
                case s of
                    "Summer" ->
                        JD.succeed Summer

                    "Winter" ->
                        JD.succeed Winter

                    "Temporary" ->
                        JD.succeed Temporary

                    _ ->
                        JD.fail "Invalid holiday type string"
            )
