module JsonFile exposing (Field, decoder)

import Image exposing (Image)
import Json.Decode as JD



-- Components


type alias Field =
    { description : String
    , image : Image
    }


decoder : JD.Decoder Field
decoder =
    JD.map2 Field
        (JD.field "description" JD.string)
        (JD.field "image" Image.decoder)
