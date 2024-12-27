module Holiday exposing (Holiday, SpecialHoliday, isHoliday, load, view)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Date exposing (Date)
import FatalError exposing (FatalError)
import Html exposing (..)
import Image exposing (Image)
import Json.Decode as JD
import Time
import Utils


type alias Holiday =
    { specialHolidays : List SpecialHoliday
    , notice : Maybe { message : String, image : Maybe Image }
    }


type alias SpecialHoliday =
    { holidayType : SpecialHolidayType
    , from : Date
    , to : Date
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
                    , div [] [ text "CLOSED SUMMER HOLIDAY" ]
                    ]

                Winter ->
                    [ div [] [ text "冬季休業" ]
                    , div [] [ text "CLOSED WINTER HOLIDAY" ]
                    ]

                Temporary ->
                    [ div [] [ text "臨時休業" ]
                    , div [] [ text "TEMPORARY CLOSED" ]
                    ]


isHoliday : Date -> Holiday -> Maybe HolidayType
isHoliday date holiday =
    if Date.weekday date == Time.Wed then
        Just Regular

    else if Date.weekday date == Time.Tue then
        if isNthTuesday 0 date || isNthTuesday 2 date then
            Just Regular

        else
            Nothing

    else
        List.filter (\specialHoliday -> Date.isBetween specialHoliday.from specialHoliday.to date)
            holiday.specialHolidays
            |> List.head
            |> Maybe.map Special


isNthTuesday : Int -> Date -> Bool
isNthTuesday n date =
    (Date.fromCalendarDate (Date.year date) (Date.month date) 1
        |> Date.add Date.Weeks n
        |> Date.ceiling Date.Tuesday
    )
        == date


load : BackendTask FatalError Holiday
load =
    File.jsonFile decoder "./content/special-holiday.json"
        |> BackendTask.allowFatal


decoder : JD.Decoder Holiday
decoder =
    JD.map2 Holiday
        (JD.field "data"
            (JD.list
                (JD.map3 SpecialHoliday
                    (JD.field "holidayType" holidayTypeDecoder)
                    (JD.field "from" Utils.dateDecoder)
                    (JD.field "to" Utils.dateDecoder)
                    |> JD.andThen
                        (\holiday ->
                            if Date.compare holiday.to holiday.from == LT then
                                JD.fail "the `to` date must be greater than `from` date"

                            else
                                JD.succeed holiday
                        )
                )
            )
        )
        (JD.field "notice"
            (JD.maybe
                (JD.map2 (\message image -> { message = message, image = image })
                    (JD.field "message" JD.string)
                    (JD.field "image" (JD.maybe Image.decoder))
                )
            )
        )


holidayTypeDecoder : JD.Decoder SpecialHolidayType
holidayTypeDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case String.toLower s of
                    "summer" ->
                        JD.succeed Summer

                    "winter" ->
                        JD.succeed Winter

                    "temporary" ->
                        JD.succeed Temporary

                    _ ->
                        JD.fail "Invalid holiday type string"
            )
