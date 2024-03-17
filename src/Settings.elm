module Settings exposing (canonicalUrl, image, locale, subtitle, title, withSubtitle)

import Head.Seo as Seo
import LanguageTag.Language as Language
import LanguageTag.Region as Region
import MimeType
import Pages.Url as Url


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
    { url = Url.external "https://image.officeiko.co.jp/top_tenpo_4_3_3261f260d9.jpg"
    , alt = "株式会社オフイスイコーのロゴ"
    , dimensions = Just { width = 1200, height = 675 }
    , mimeType = Just (MimeType.Image MimeType.Jpeg)
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
