module Gen.Settings exposing (call_, canonicalUrl, image, locale, moduleName_, subtitle, title, values_, withSubtitle)

{-| 
@docs moduleName_, image, subtitle, withSubtitle, title, locale, canonicalUrl, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Settings" ]


{-| image: Head.Seo.Image -}
image : Elm.Expression
image =
    Elm.value
        { importFrom = [ "Settings" ]
        , name = "image"
        , annotation = Just (Type.namedWith [ "Head", "Seo" ] "Image" [])
        }


{-| subtitle: String -}
subtitle : Elm.Expression
subtitle =
    Elm.value
        { importFrom = [ "Settings" ]
        , name = "subtitle"
        , annotation = Just Type.string
        }


{-| withSubtitle: String -> String -}
withSubtitle : String -> Elm.Expression
withSubtitle withSubtitleArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Settings" ]
            , name = "withSubtitle"
            , annotation = Just (Type.function [ Type.string ] Type.string)
            }
        )
        [ Elm.string withSubtitleArg ]


{-| title: String -}
title : Elm.Expression
title =
    Elm.value
        { importFrom = [ "Settings" ]
        , name = "title"
        , annotation = Just Type.string
        }


{-| locale: Maybe ( LanguageTag.Language.Language, LanguageTag.Region.Region ) -}
locale : Elm.Expression
locale =
    Elm.value
        { importFrom = [ "Settings" ]
        , name = "locale"
        , annotation =
            Just
                (Type.maybe
                    (Type.tuple
                        (Type.namedWith
                            [ "LanguageTag", "Language" ]
                            "Language"
                            []
                        )
                        (Type.namedWith [ "LanguageTag", "Region" ] "Region" [])
                    )
                )
        }


{-| canonicalUrl: String -}
canonicalUrl : Elm.Expression
canonicalUrl =
    Elm.value
        { importFrom = [ "Settings" ]
        , name = "canonicalUrl"
        , annotation = Just Type.string
        }


call_ : { withSubtitle : Elm.Expression -> Elm.Expression }
call_ =
    { withSubtitle =
        \withSubtitleArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Settings" ]
                    , name = "withSubtitle"
                    , annotation =
                        Just (Type.function [ Type.string ] Type.string)
                    }
                )
                [ withSubtitleArg ]
    }


values_ :
    { image : Elm.Expression
    , subtitle : Elm.Expression
    , withSubtitle : Elm.Expression
    , title : Elm.Expression
    , locale : Elm.Expression
    , canonicalUrl : Elm.Expression
    }
values_ =
    { image =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "image"
            , annotation = Just (Type.namedWith [ "Head", "Seo" ] "Image" [])
            }
    , subtitle =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "subtitle"
            , annotation = Just Type.string
            }
    , withSubtitle =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "withSubtitle"
            , annotation = Just (Type.function [ Type.string ] Type.string)
            }
    , title =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "title"
            , annotation = Just Type.string
            }
    , locale =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "locale"
            , annotation =
                Just
                    (Type.maybe
                        (Type.tuple
                            (Type.namedWith
                                [ "LanguageTag", "Language" ]
                                "Language"
                                []
                            )
                            (Type.namedWith
                                [ "LanguageTag", "Region" ]
                                "Region"
                                []
                            )
                        )
                    )
            }
    , canonicalUrl =
        Elm.value
            { importFrom = [ "Settings" ]
            , name = "canonicalUrl"
            , annotation = Just Type.string
            }
    }