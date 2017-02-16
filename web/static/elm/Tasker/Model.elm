module Tasker.Model exposing (..)

import Navigation
import Http


type alias Model =
    { config : AppConfig
    , route : Route
    , currentTask : String
    , tasks : List String
    }


type alias Task =
    { id : String
    , label : String
    , rank : Int
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
    | UpdateCurrentTask String
    | AddCurrentTask
    | FetchTasks (Result Http.Error (List Task))
