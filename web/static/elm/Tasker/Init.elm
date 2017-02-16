module Tasker.Init exposing (ConfigFromJs, init)

import Http
import Navigation exposing (Location)
import Tasker.Model exposing (Model, Msg(..), Route, AppConfig)
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
        ( initialModel rawConfig currentRoute
        , Http.send FetchTasks fetchTasksRequest
        )


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
    , currentTask = ""
    , tasks = []
    }


fetchTasksQuery : String
fetchTasksQuery =
    """
    query {
      tasks {
        id
        label
        rank
        user {
          id
          name
        }
      }
    }
  """


fetchTasksRequest : Http.Request String
fetchTasksRequest =
    let
        encodedQuery =
            Http.encodeUri fetchTasksQuery
    in
        Http.getString ("/graphql?query=" ++ encodedQuery)
