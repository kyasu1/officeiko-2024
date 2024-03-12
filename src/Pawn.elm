module Pawn exposing (Model, Msg, init, update, view)

import Date exposing (Date)
import Decimal exposing (Decimal)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Html.Events.Extra as E
import Layout
import Shared
import Utils


type alias Model =
    { form : Form
    , contract : Maybe Contract
    }


init : Date -> Model
init date =
    { form = initialForm date
    , contract = Nothing
    }


type alias Form =
    { amount : String
    , date : Date
    }


initialForm : Date -> Form
initialForm date =
    { amount = ""
    , date = date
    }


type alias Contract =
    { amount : Decimal
    , rate : Decimal
    , interest : Decimal
    , contractDate : Date
    }


calc : Decimal -> Date -> Contract
calc amount =
    if Decimal.gte amount (Decimal.fromInt 1000000) then
        calcHelper (Decimal.fromIntWithExponent 2 -2) amount

    else if Decimal.gte amount (Decimal.fromInt 500000) then
        calcHelper (Decimal.fromIntWithExponent 3 -2) amount

    else if Decimal.gte amount (Decimal.fromInt 100000) then
        calcHelper (Decimal.fromIntWithExponent 4 -2) amount

    else
        calcHelper (Decimal.fromIntWithExponent 5 -2) amount


calcHelper : Decimal -> Decimal -> Date -> Contract
calcHelper rate amount contractDate =
    { amount = amount
    , rate = rate
    , interest = Decimal.mul amount rate
    , contractDate = contractDate
    }


dueDate : Int -> Date -> Date
dueDate months contractDate =
    Date.add Date.Months months contractDate


totalWithdraw : Int -> Contract -> Decimal
totalWithdraw months contract =
    Decimal.add contract.amount (Decimal.mul (Decimal.fromInt months) contract.interest)


type Msg
    = ChangedForm Form
    | ClickedSubmit


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        ChangedForm form ->
            ( { model | form = form }, Effect.none )

        ClickedSubmit ->
            case Decimal.fromString model.form.amount of
                Just amount ->
                    if Decimal.gte amount (Decimal.fromInt 5000) then
                        ( { model | contract = Just (calc amount model.form.date) }, Effect.none )

                    else
                        ( { model | contract = Nothing }, Effect.none )

                Nothing ->
                    ( { model | contract = Nothing }, Effect.none )


view : Model -> Html Msg
view ({ form } as model) =
    div []
        [ Layout.subHeader [ text "お借入シミュレーション" ]
        , Html.form [ class "grid grid-cols-3 gap-4 items-end p-4" ]
            [ div [ class "flex flex-col" ]
                [ label [] [ text "お借入予定日" ]
                , input
                    [ A.type_ "date"
                    , A.value (Date.toIsoString form.date)
                    , E.onChange (\s -> ChangedForm { form | date = Date.fromIsoString s |> Result.withDefault (Date.fromRataDie 0) })
                    , class "border border-gray-400 focus:ring-1 p-2"
                    ]
                    []
                ]
            , div [ class "flex flex-col" ]
                [ label [] [ text "お借入金額" ]
                , div [ class "flex items-center" ]
                    [ input
                        [ A.value model.form.amount
                        , A.type_ "number"
                        , A.step "1000"
                        , A.min "5000"
                        , A.max "5000000"
                        , A.maxlength 7
                        , A.placeholder "100,000"
                        , A.attribute "require" ""

                        -- , A.required True
                        , E.onChange (\s -> ChangedForm { form | amount = s })
                        , class "border border-gray-400 focus:ring-1 p-2 w-full text-right"
                        ]
                        []
                    , span [ class "ml-2" ] [ text "円" ]
                    ]
                ]
            , div []
                [ button
                    [ A.type_ "submit"
                    , class "w-24 px-2 py-1 border border-gray-800 rounded text-sm font-bold mb-2"
                    , E.onClickPreventDefault ClickedSubmit
                    ]
                    [ text "試算する" ]
                ]
            ]
        , div [ class "mt-4 border rounded p-4" ]
            [ case model.contract of
                Just contract ->
                    div [ class "grid grid-cols-3 gap-4 text-sm items-end" ]
                        [ div [ class "mb-1 text-right" ]
                            [ text "1ヶ月あたりの質料"
                            ]
                        , div [ class "border border-gray-400 p-1 h-8 text-right bg-gray-100" ]
                            [ text
                                (contract.interest |> Decimal.truncate 0 |> Utils.toPrice)
                            , text "円"
                            ]
                        , div [ class "mb-1" ]
                            [ text "利率 "
                            , text (Decimal.toString (Decimal.mul (Decimal.fromInt 100) contract.rate))
                            , text "%"
                            ]
                        , div [ class "col-span-3" ] [ text "返済総額" ]
                        , div [ class "flex flex-col" ]
                            [ label [ class "text-xs md:text-sm" ] [ text (dueDate 1 contract.contractDate |> Utils.kanjiDate), text "まで" ]
                            , div [ class "border border-gray-400 p-1 h-8 text-right bg-gray-100" ]
                                [ text
                                    (totalWithdraw 1 contract |> Utils.toPrice)
                                , text "円"
                                ]
                            ]
                        , div [ class "flex flex-col" ]
                            [ label [ class "text-xs md:text-sm" ] [ text (dueDate 2 contract.contractDate |> Utils.kanjiDate), text "まで" ]
                            , div [ class "border border-gray-400 p-1 h-8 text-right bg-gray-100" ]
                                [ text
                                    (totalWithdraw 2 contract |> Utils.toPrice)
                                , text "円"
                                ]
                            ]
                        , div [ class "flex flex-col" ]
                            [ label [ class "text-xs md:text-sm" ] [ text (dueDate 3 contract.contractDate |> Utils.kanjiDate), text "まで" ]
                            , div [ class "border border-gray-400 p-1 h-8 text-right bg-gray-100" ]
                                [ text
                                    (totalWithdraw 3 contract |> Utils.toPrice)
                                , text "円"
                                ]
                            ]
                        ]

                Nothing ->
                    div [ class "text-sm md:text-base flex items-center justify-center px-2 py-16 " ]
                        [ text "お借入金額を入力し試算ボタンを押すと結果が表示されます"
                        ]
            ]
        ]
