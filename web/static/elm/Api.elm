module Api
    exposing
        ( CreateTaskResponse
        , fetchTasksRequest
        , makeTaskRequest
        , updateTaskRequest
        )

import Json.Encode as JE
import Json.Decode as JD
import Http
import StoryTask exposing (StoryTask)


-- TYPES


type alias CreateTaskResponse =
    { tid : String
    , task : StoryTask
    }



-- DECODERS / ENCODERS


taskDecoder : JD.Decoder StoryTask
taskDecoder =
    JD.map8 StoryTask
        (JD.field "id" JD.string)
        (JD.field "label" JD.string)
        (JD.field "rank" JD.int)
        (JD.field "completed" JD.bool)
        (JD.field "completedOn" <| JD.nullable JD.string)
        (JD.field "scheduledOn" JD.string)
        (JD.succeed False)
        (JD.field "label" JD.string)


tasksResponseDecoder : JD.Decoder (List StoryTask)
tasksResponseDecoder =
    JD.at [ "data", "tasks" ] (JD.list taskDecoder)


createTaskResponseDecoder : JD.Decoder CreateTaskResponse
createTaskResponseDecoder =
    JD.map2 CreateTaskResponse
        (JD.field "tid" JD.string)
        (JD.field "task" taskDecoder)
        |> JD.at [ "data", "createTask" ]


taskResponseDecoder : JD.Decoder StoryTask
taskResponseDecoder =
    JD.at [ "data", "updateTask" ] taskDecoder



-- API


graphqlUrl : String
graphqlUrl =
    "/graphql"


fetchTasksQuery : String
fetchTasksQuery =
    """
    query {
      tasks(includeYesterday: true) {
        id
        label
        rank
        completed
        completedOn
        scheduledOn
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
    mutation($tid: String!, $label: String!, $position: Int!, $scheduledOn: String!) {
      createTask(tid: $tid, label:$label, position:$position, scheduledOn: $scheduledOn) {
        tid
        task {
          id
          label
          rank
          completed
          completedOn
          scheduledOn
        }
      }
    }
  """


makeTaskRequest : StoryTask -> Http.Request CreateTaskResponse
makeTaskRequest task =
    let
        variables =
            JE.object
                [ ( "tid", JE.string task.id )
                , ( "label", JE.string task.label )
                , ( "position", JE.int task.rank )
                , ( "scheduledOn", JE.string task.scheduledOn )
                ]

        body =
            JE.object
                [ ( "query", JE.string makeTaskMutation )
                , ( "variables", variables )
                ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body createTaskResponseDecoder


updateTaskMutation : String
updateTaskMutation =
    """
  mutation($id: ID!, $scheduledOn: String!, $completed: Boolean!, $label: String!) {
    updateTask(id: $id, scheduledOn: $scheduledOn, completed: $completed, label: $label) {
      id
      label
      rank
      completed
      completedOn
      scheduledOn
    }
  }
  """


updateTaskRequest : StoryTask -> Http.Request StoryTask
updateTaskRequest task =
    let
        variables =
            JE.object
                [ ( "id", JE.string task.id )
                , ( "scheduledOn", JE.string task.scheduledOn )
                , ( "completed", JE.bool task.completed )
                , ( "label", JE.string task.label )
                ]

        body =
            JE.object
                [ ( "query", JE.string updateTaskMutation )
                , ( "variables", variables )
                ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body taskResponseDecoder
