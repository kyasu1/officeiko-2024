module Utils exposing
    ( dateDecoder
    , kanjiDate
    , posixToDate
    , posixToKanji
    , toDiff
    , toPrice
    , zone
    )

import Date exposing (Date)
import Decimal exposing (Decimal)
import FormatNumber
import FormatNumber.Locales
import Json.Decode as JD
import Time exposing (Posix, Weekday(..))
import Time.Extra as Time


zone : Time.Zone
zone =
    Time.customZone (9 * 60) []


posixToDate : Posix -> Date
posixToDate posix =
    Date.fromPosix zone posix


kanjiDate : Date -> String
kanjiDate date =
    Date.format "y年MM月dd日" date


posixToKanji : Posix -> String
posixToKanji posix =
    Time.posixToParts zone posix
        |> (\parts ->
                [ Date.fromCalendarDate parts.year parts.month parts.day |> kanjiDate
                , "（"
                , Time.toWeekday zone posix |> weekdayToKanji
                , "）"
                , String.fromInt parts.hour |> String.padLeft 2 '0'
                , "時"
                , String.fromInt parts.minute |> String.padLeft 2 '0'
                , "分"
                ]
                    |> String.concat
           )


weekdayToKanji : Weekday -> String
weekdayToKanji weekday =
    case weekday of
        Mon ->
            "月"

        Tue ->
            "火"

        Wed ->
            "水"

        Thu ->
            "木"

        Fri ->
            "金"

        Sat ->
            "土"

        Sun ->
            "日"


dateDecoder : JD.Decoder Date
dateDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case Date.fromIsoString s of
                    Ok date ->
                        JD.succeed date

                    Err err ->
                        JD.fail err
            )



--


japanLocale : FormatNumber.Locales.Locale
japanLocale =
    { decimals = FormatNumber.Locales.Min 0
    , system = FormatNumber.Locales.Western
    , thousandSeparator = ","
    , decimalSeparator = "."
    , negativePrefix = "-"
    , negativeSuffix = ""
    , positivePrefix = ""
    , positiveSuffix = ""
    , zeroPrefix = ""
    , zeroSuffix = ""
    }


toPrice : Decimal -> String
toPrice price =
    Decimal.toFloat price |> FormatNumber.format japanLocale


japanLocaleWithPlus : FormatNumber.Locales.Locale
japanLocaleWithPlus =
    { decimals = FormatNumber.Locales.Min 0
    , system = FormatNumber.Locales.Western
    , thousandSeparator = ","
    , decimalSeparator = "."
    , negativePrefix = "-"
    , negativeSuffix = ""
    , positivePrefix = "+"
    , positiveSuffix = ""
    , zeroPrefix = ""
    , zeroSuffix = ""
    }


toDiff : Decimal -> String
toDiff diff =
    Decimal.toFloat diff |> FormatNumber.format japanLocaleWithPlus
