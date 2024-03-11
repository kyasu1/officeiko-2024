module Site exposing (config)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import LanguageTag
import LanguageTag.Language
import MimeType exposing (MimeType)
import Pages.Url
import SiteConfig exposing (SiteConfig)


config : SiteConfig
config =
    { canonicalUrl = "https://www.officeiko.co.jp"
    , head = head
    }


head : BackendTask FatalError (List Head.Tag)
head =
    [ Head.rootLanguage (LanguageTag.Language.ja |> LanguageTag.build LanguageTag.emptySubtags)
    , Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
    , Head.metaName "twtter:site" (Head.raw "@pawnshopiko")
    , Head.metaProperty "fb:app_id" (Head.raw "361836030508004")
    , Head.sitemapLink "/sitemap.xml"
    , Head.appleTouchIcon (Just 180) (Pages.Url.fromPath [ "/apple-touch-icon.png" ])
    , Head.icon [ ( 32, 32 ) ] MimeType.Png (Pages.Url.fromPath [ "/favicon-32x32.png" ])
    , Head.icon [ ( 16, 16 ) ] MimeType.Png (Pages.Url.fromPath [ "/favicon-16x16.png" ])
    , Head.manifestLink "/site.webmanifest"
    ]
        |> BackendTask.succeed
