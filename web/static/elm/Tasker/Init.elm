module Tasker.Init exposing (ConfigFromJs, init)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Navigation exposing (Location)
import Tasker.Model exposing (Model, Msg(..), Route, AppConfig, Task)
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
      }
    }
  """


taskDecoder : Decode.Decoder Task
taskDecoder =
    Pipeline.decode Task
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "label" Decode.string
        |> Pipeline.required "rank" Decode.int


tasksResponseDecoder : Decode.Decoder (List Task)
tasksResponseDecoder =
    Decode.list taskDecoder
        |> Decode.at [ "data", "tasks" ]


fetchTasksRequest : Http.Request (List Task)
fetchTasksRequest =
    let
        url =
            "/graphql"

        body =
            Encode.object [ ( "query", Encode.string fetchTasksQuery ) ]
                |> Http.jsonBody
    in
        Http.post url body tasksResponseDecoder
