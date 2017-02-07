module Tasker.Model exposing (..)

import Navigation


type alias Model =
    { config : AppConfig
    , route : Route
    }


type Route
    = HomeRoute
    | NotFoundRoute


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , accessToken : String
    }


type Msg
    = NoOp
    | UrlChange Navigation.Location
