module Tasker.Init exposing (ConfigFromJs, init)

import Navigation exposing (Location)
import Tasker.Model exposing (Model, Msg, Route, AppConfig)
import Tasker.Routing as Routing


type alias ConfigFromJs =
    { id : Int
    , name : String
    , email : String
    , access_token : String
    }


init : ConfigFromJs -> Location -> ( Model, Cmd Msg )
init rawConfig result =
    let
        currentRoute =
            Routing.parseLocation result
    in
        ( initialModel rawConfig currentRoute, Cmd.none )


initialAppConfig : ConfigFromJs -> AppConfig
initialAppConfig rawConfig =
    { id = rawConfig.id
    , name = rawConfig.name
    , email = rawConfig.email
    , accessToken = rawConfig.access_token
    }


initialModel : ConfigFromJs -> Route -> Model
initialModel rawConfig route =
    { config = initialAppConfig rawConfig
    , route = route
    }
