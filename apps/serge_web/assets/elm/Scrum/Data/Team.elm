module Scrum.Data.Team exposing (Team, decoder, empty)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias Team =
    { id : Int
    , name : String
    }


empty : Team
empty =
    Team -1 ""



-- SERIALIZATION


decoder : Decoder Team
decoder =
    decode Team
        |> required "id" Decode.int
        |> required "name" Decode.string
