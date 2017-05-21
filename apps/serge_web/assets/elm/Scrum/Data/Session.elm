module Scrum.Data.Session exposing (Session, AppMessage(..), decodeFromJson)

import Json.Decode as Decode exposing (Value, Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required, hardcoded)


-- LOCAL IMPORTS

import Scrum.Data.User as User exposing (User)
import Scrum.Data.Team as Team exposing (Team)


type AppMessage
    = MessageNone
    | MessageSuccess String
    | MessageNotice String
    | MessageError String


type alias Session =
    { user : User
    , team : Team
    , message : AppMessage
    }


decodeFromJson : Value -> Session
decodeFromJson json =
    case Decode.decodeValue decoder json of
        Ok session ->
            session

        Err error ->
            let
                _ =
                    Debug.log "decodeFromJson ERROR" error
            in
                { user = User.empty
                , team = Team.empty
                , message = MessageNone
                }


decoder : Decoder Session
decoder =
    decode Session
        |> required "user" User.decoder
        |> required "team" Team.decoder
        |> hardcoded MessageNone
