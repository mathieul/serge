module Scrum.Data.Team exposing (Team, decoder, empty)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


-- LOCAL IMPORTS

import Scrum.Data.User as User exposing (User)


type alias Team =
    { id : String
    , name : String
    , members : List User
    }


empty : Team
empty =
    Team "" "" []



-- SERIALIZATION


decoder : Decoder Team
decoder =
    decode Team
        |> required "id" Decode.string
        |> required "name" Decode.string
        |> required "members" (Decode.list User.decoder)
