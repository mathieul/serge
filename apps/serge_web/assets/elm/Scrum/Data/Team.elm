module Scrum.Data.Team exposing (Team, decoder, empty)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias Team =
    { name : String
    }


empty : Team
empty =
    Team ""



-- SERIALIZATION


decoder : Decoder Team
decoder =
    decode Team
        |> required "name" Decode.string
