module Scrum.Data.User exposing (User, decoder, empty, user)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import GraphQL.Request.Builder as B


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



-- GRAPHQL


user : B.ValueSpec B.NonNull B.ObjectType User vars
user =
    B.object User
        |> B.with (B.field "id" [] B.int)
        |> B.with (B.field "name" [] B.string)
        |> B.with (B.field "email" [] B.string)
