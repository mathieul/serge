module StoryTask
    exposing
        ( StoryTask
        , makeNewTask
        , storyTaskForm
        , fetchTasksRequest
        , storyTaskView
        )

import Html exposing (Html, form, div, input, button, text, li)
import Html.Attributes exposing (class, type_, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import Json.Encode as JE
import Json.Decode as JD
import Json.Decode.Pipeline as JP
import Http


-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    }


makeNewTask : String -> Int -> StoryTask
makeNewTask label count =
    StoryTask "" label (count + 1)



-- VIEW


storyTaskForm : String -> msg -> (String -> msg) -> Html msg
storyTaskForm currentLabel addTaskMsg updateTaskMsg =
    form [ onSubmit addTaskMsg ]
        [ div [ class "form-group row" ]
            [ div [ class "col-sm-10" ]
                [ input
                    [ type_ "text"
                    , class "form-control form-control-lg"
                    , placeholder "Enter new task..."
                    , value currentLabel
                    , onInput updateTaskMsg
                    ]
                    []
                ]
            , div [ class "col-sm-2" ]
                [ button
                    [ type_ "submit"
                    , class "btn btn-outline-primary btn-block btn-lg"
                    ]
                    [ text "Create" ]
                ]
            ]
        ]


storyTaskView : StoryTask -> Html msg
storyTaskView task =
    li [ class "list-group-item" ]
        [ text task.label ]



-- DECODERS / ENCODERS


taskDecoder : JD.Decoder StoryTask
taskDecoder =
    JP.decode StoryTask
        |> JP.required "id" JD.string
        |> JP.required "label" JD.string
        |> JP.required "rank" JD.int


tasksResponseDecoder : JD.Decoder (List StoryTask)
tasksResponseDecoder =
    JD.list taskDecoder
        |> JD.at [ "data", "tasks" ]



-- API


graphqlUrl : String
graphqlUrl =
    "/graphql"


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


fetchTasksRequest : Http.Request (List StoryTask)
fetchTasksRequest =
    let
        body =
            JE.object [ ( "query", JE.string fetchTasksQuery ) ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body tasksResponseDecoder


makeTaskMutation : String
makeTaskMutation =
    """
    mutation($label:String!, $position:Int!, $userId:ID!) {
      createTask(label:$label, position:$position, userId:$userId) {
        id
        label
        rank
      }
    }
  """



-- makeTaskRequest : HttpRequest StoryTask
-- makeTaskRequest variables =
--   let
--     body =
--       JE.object
--       [ ( "query", JE.string makeTaskMutation)
--       , ("variables", ... TODO ...)
--       ]
--   in
--     Http.post graphqlUrl body taskResponseDecoder
