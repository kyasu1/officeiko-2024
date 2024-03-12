module Settings exposing (canonicalUrl, image, locale, subtitle, title, withSubtitle)

import Head
import Head.Seo as Seo
import LanguageTag.Language as Language
import LanguageTag.Region as Region
import MimeType
import Pages.Url
import UrlPath


canonicalUrl : String
canonicalUrl =
    "https://www.officeiko.co.jp"


locale : Maybe ( Language.Language, Region.Region )
locale =
    Just ( Language.ja, Region.jp )


title : String
title =
    "株式会社オフイスイコー"


withSubtitle : String -> String
withSubtitle s =
    s ++ " | " ++ title


subtitle : String
subtitle =
    "質イコー 買取 埼玉県越谷市 ブランド品 ロレックス 高級時計 金 プラチナ 高価買取 質屋"


image : Seo.Image
image =
    { url = UrlPath.fromString "/images/logo.png" |> Pages.Url.fromPath
    , alt = "株式会社オフイスイコーのロゴ"
    , dimensions = Nothing
    , mimeType = Nothing
    }



-- head : List Head.Tag
-- head =
--     -- Layout.About.seoHeaders app.data.author
--     Seo.summary
--         { canonicalUrlOverride = Nothing
--         , siteName = title
--         , image = Image
--         , description = "質イコー 買取 埼玉県越谷市 ブランド品 ロレックス 高級時計 金 プラチナ 高価買取 質屋"
--         , title = "プライバシーポリシー" ++ "|" ++ title
--         , locale = Settings.locale
--         }
