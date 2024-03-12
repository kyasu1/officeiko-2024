module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Accessibility.Aria as Aria
import BackendTask exposing (BackendTask)
import BackendTask.File
import Date exposing (Date)
import Decimal exposing (Decimal)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Form.Field exposing (checkbox)
import Heroicons.Outline as Outline
import Html exposing (..)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Iso8601
import Json.Decode as JD
import Market
import Pages.Flags exposing (Flags(..))
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import Svg.Attributes as SA
import Time
import UrlPath exposing (UrlPath)
import Utils
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = SharedMsg SharedMsg
    | MenuClicked


type alias Data =
    { market : Market.Market
    }


type SharedMsg
    = NoOp


type alias Model =
    { showMenu : Bool
    , date : Date
    }


type alias Flags =
    { date : Date
    }


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "date"
            (JD.int
                |> JD.map
                    (\posix ->
                        Date.fromPosix Utils.zone (Time.millisToPosix posix)
                    )
            )
        )


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags maybePagePath =
    case flags of
        BrowserFlags value ->
            case JD.decodeValue flagsDecoder value of
                Ok decoded ->
                    ( { showMenu = False, date = decoded.date }
                    , Effect.none
                    )

                Err _ ->
                    ( { showMenu = False, date = Date.fromRataDie 0 }
                    , Effect.none
                    )

        PreRenderFlags ->
            ( { showMenu = False, date = Date.fromRataDie 0 }
            , Effect.none
            )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg globalMsg ->
            ( model, Effect.none )

        MenuClicked ->
            ( { model | showMenu = not model.showMenu }, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.File.jsonFile Market.decoder "market.json"
        |> BackendTask.map (\market -> { market = market })
        |> BackendTask.allowFatal


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view sharedData page model toMsg pageView =
    let
        menuClass active =
            if active then
                class "bg-iko-500 text-white rounded-md px-3 py-2 text-sm font-bold"

            else
                class "text-gray-900 hover:bg-gray-700 hover:text-white rounded-md px-3 py-2 text-sm font-bold"
    in
    { body =
        [ nav [ class "print:hidden print:bg-white" ]
            [ div [ class "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" ]
                [ div [ class "flex h-16 justify-between" ]
                    [ div [ class "flex" ]
                        [ div [ class "flex flex-shrink-0 items-center" ]
                            [ Route.link [] [ img [ A.src "/images/logo.svg", class "w-auto h-12", A.alt "質イコー" ] [] ] Route.Index
                            ]
                        , div [ class "hidden text-sm lg:text-base lg:ml-6 lg:flex lg:items-center lg:space-x-4 " ]
                            [ Route.link [ menuClass (page.route == Just Route.Pawn) ] [ text "質入・融資" ] Route.Pawn
                            , Route.link [ menuClass (page.route == Just Route.Selling) ] [ text "取扱商品" ] Route.Selling
                            , Route.link [ menuClass (page.route == Just Route.Stocks) ] [ text "金プラ相場" ] Route.Stocks
                            , Route.link [ menuClass (page.route == Just Route.WesternUnion) ] [ text "Western Union" ] Route.WesternUnion
                            , Route.link [ menuClass (page.route == Just Route.Contact) ] [ text "Contact" ] Route.Contact
                            , a [ menuClass False, A.href "/#access" ] [ text "Access" ]
                            ]
                        ]
                    , div [ class "flex flex-col items-center justify-center text-sm leading-tight" ]
                        [ div [ class "text-gray-800" ] [ text "048-987-1020" ]
                        , div [ class "text-gray-800" ] [ text "Open 10am-7pm" ]
                        , div [ class "text-gray-600 text-xs" ] [ text " (WU 6:30pm)" ]
                        ]
                    , div [ class "-ml-2 mr-2 flex items-center lg:hidden" ]
                        -- モバイルメニューボタン
                        [ label [ class "relative z-40 cursor-pointer px-3 py-6", A.for "mobile-menu" ]
                            [ input [ class "peer hidden", A.type_ "checkbox", A.id "mobile-menu", A.checked model.showMenu ] []
                            , div
                                [ class "relative z-50 block h-[1px] w-7 bg-black bg-transparent content-['']"
                                , class "before:absolute before:top-[-0.35rem] before:z-50 before:block before:h-full before:w-full"
                                , class "before:bg-black before:transition-all before:duration-200 before:ease-out before:content-['']"
                                , class "after:absolute after:right-0 after:bottom-[-0.35rem] after:block after:h-full after:w-full"
                                , class "after:bg-black after:transition-all after:duration-200 after:ease-out after:content-['']"
                                , class "peer-checked:bg-transparent before:peer-checked:top-0 before:peer-checked:w-full before:peer-checked:rotate-45 before:peer-checked:transform"
                                , class "after:peer-checked:bottom-0 after:peer-checked:w-full after:peer-checked:-rotate-45 after:peer-checked:transform"
                                ]
                                []
                            , div
                                [ class "fixed inset-0 z-40 hidden h-full w-full bg-black/50 backdrop-blur-sm peer-checked:block"
                                ]
                                [ text "\u{00A0}" ]
                            , div
                                [ class "fixed top-0 right-0 z-40 h-full w-full translate-x-full overflow-y-auto overscroll-y-none transition duration-500 peer-checked:translate-x-0"
                                ]
                                [ div [ class "float-right min-h-full w-[85%] bg-white px-6 pt-12 shadow-2xl" ]
                                    [ menu [ class "space-y-2" ]
                                        [ li [] [ Route.link [] [ text "ホーム" ] Route.Index ]
                                        , li [] [ Route.link [] [ text "質入・融資" ] Route.Pawn ]
                                        , li [] [ Route.link [] [ text "買取" ] Route.Selling ]
                                        , li [] [ Route.link [] [ text "金プラ相場" ] Route.Stocks ]
                                        , li [] [ Route.link [] [ text "Western Union" ] Route.WesternUnion ]
                                        , li [] [ Route.link [] [ text "Access" ] Route.About ]
                                        , li [] [ Route.link [] [ text "Contact" ] Route.Contact ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                        |> Html.map toMsg
                    ]
                ]
            ]
        , Html.main_ [ class "bg-gray-50 print:bg-white" ] pageView.body
        , viewFooter page.path
        ]
    , title = pageView.title
    }


viewFooter : UrlPath -> Html msg
viewFooter path =
    footer [ class "px-6 py-14 md:pt-[20px] md:pb-[40px] bg-iko-500 mt-10 print:mt-0 print:hidden" ]
        [ div [ class "md:max-w-[1120px] m-auto w-full" ]
            [ div [ class "flex flex-row md:flex-col" ]
                [ div []
                    [ ul [ class "flex flex-col md:flex-row text-sm text-white font-medium" ]
                        [ li [ class "px-4 py-2" ] [ Route.link [] [ text "ニュース" ] Route.Posts ]
                        ]
                    , ul [ class "flex flex-col md:flex-row text-sm text-white font-medium" ]
                        [ li [ class "px-4 py-2" ] [ Route.link [] [ text "質入・融資" ] Route.Pawn ]
                        , li [ class "px-4 py-2" ] [ Route.link [] [ text "取扱商品" ] Route.Calendar ]
                        , li [ class "px-4 py-2" ] [ Route.link [] [ text "金プラ相場" ] Route.Stocks ]
                        , li [ class "px-4 py-2" ] [ Route.link [] [ text "金券買取" ] Route.KaitoriTicket ]
                        , li [ class "px-4 py-2" ] [ Route.link [] [ text "WU" ] Route.WesternUnion ]
                        ]
                    ]
                , ul [ class "flex flex-col md:flex-row text-sm text-gray-300" ]
                    [ li [ class "px-4 py-2" ] [ Route.link [] [ text "カレンダー" ] Route.Calendar ]
                    , li [ class "px-4 py-2" ] [ Route.link [] [ text "アクセス" ] Route.Calendar ]
                    , li [ class "px-4 py-2" ] [ Route.link [] [ text "プリバシーポリシー" ] Route.Privacy ]
                    , li [ class "px-4 py-2" ] [ Route.link [] [ text "会社概要" ] Route.About ]
                    ]
                ]
            , hr [ class "border-gray-500 my-9 md:my-[20px]" ] []
            , div [ class "text-center leading-loose relative" ]
                [ Route.link [ class "text-white" ] [ text "株式会社オフイスイコー" ] Route.About
                , p [ class "text-white text-sm" ] [ text "OPEN 10AM - 7PM" ]
                , p [ class "text-white text-sm" ] [ text "Western Union 6:30PM" ]
                , p [ class "text-white text-sm" ] [ text "tel: 0120-41-1578" ]
                , p [ class "text-sm font-thin text-white" ] [ text "Copyright © Office IKO Co. All Rigts Reserved." ]
                , a [ class "absolute bottom-[32px] right-[10px] ", A.href (UrlPath.toRelative path) ]
                    [ div [ class "border rouned border-white p-2 flex items-center justify-center h-12 w-12 text-2xl text-white font-thin" ]
                        [ text "⇧" ]
                    ]
                ]
            ]
        ]
