module Scrum.Data.User exposing (User, decoder, empty)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias User =
    { id : Int
    , name : String
    , email : String
    }


empty : User
empty =
    User 0 "" ""



-- SERIALIZATION


decoder : Decoder User
decoder =
    decode User
        |> required "id" Decode.int
        |> required "name" Decode.string
        |> required "email" Decode.string
