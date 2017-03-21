module Api
    exposing
        ( fetchTasksRequest
        , makeTaskRequest
        , updateTaskRequest
        , deleteTaskRequest
        , sendQueryRequest
        , sendMutationRequest
        )

import Json.Encode as JE
import Json.Decode as JD
import Http
import Task exposing (Task)


-- elm-graphql imports

import GraphQL.Request.Builder as B exposing (SelectionSpec, Field)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Client.Http as GraphQLClient


-- Local imports

import StoryTask exposing (StoryTask)
import Model exposing (Id, CreateTaskResponse)


-- Constants


graphqlUrl : String
graphqlUrl =
    "/graphql"



-- TYPES
-- DECODERS / ENCODERS


taskDecoder : JD.Decoder StoryTask
taskDecoder =
    JD.map6 StoryTask
        (JD.field "id" JD.string)
        (JD.field "label" JD.string)
        (JD.field "rank" JD.int)
        (JD.field "completed" JD.bool)
        (JD.field "completedOn" <| JD.nullable JD.string)
        (JD.field "scheduledOn" JD.string)


createTaskResponseDecoder : JD.Decoder CreateTaskResponse
createTaskResponseDecoder =
    JD.map2 CreateTaskResponse
        (JD.field "tid" JD.string)
        (JD.field "task" taskDecoder)
        |> JD.at [ "data", "createTask" ]


updateTaskResponseDecoder : JD.Decoder StoryTask
updateTaskResponseDecoder =
    JD.at [ "data", "updateTask" ] taskDecoder



-- Queries
-- Test elm-graphql


sendQueryRequest : B.Request B.Query a -> Task GraphQLClient.Error a
sendQueryRequest request =
    GraphQLClient.sendQuery graphqlUrl request


sendMutationRequest : B.Request B.Mutation a -> Task GraphQLClient.Error a
sendMutationRequest request =
    GraphQLClient.sendMutation graphqlUrl request


storyTask : B.ValueSpec B.NonNull B.ObjectType StoryTask vars
storyTask =
    B.object StoryTask
        |> B.with (B.field "id" [] B.id)
        |> B.with (B.field "label" [] B.string)
        |> B.with (B.field "rank" [] B.int)
        |> B.with (B.field "completed" [] B.bool)
        |> B.with (B.field "completedOn" [] (B.nullable B.string))
        |> B.with (B.field "scheduledOn" [] B.string)


fetchTasksQuery : B.Document B.Query (List StoryTask) { vars | includeYesterday : Bool }
fetchTasksQuery =
    let
        includeYesterdayVar =
            Var.required "includeYesterday" .includeYesterday Var.bool

        variables =
            [ ( "includeYesterday", Arg.variable includeYesterdayVar ) ]
    in
        B.field "tasks" variables (B.list storyTask)
            |> B.extract
            |> B.queryDocument


fetchTasksRequest : B.Request B.Query (List StoryTask)
fetchTasksRequest =
    fetchTasksQuery
        |> B.request { includeYesterday = True }


deleteTaskQuery : B.Document B.Mutation StoryTask { vars | taskID : String }
deleteTaskQuery =
    let
        taskIDVar =
            Var.required "taskID" .taskID Var.id

        variables =
            [ ( "id", Arg.variable taskIDVar ) ]
    in
        B.field "deleteTask" variables storyTask
            |> B.extract
            |> B.mutationDocument


deleteTaskRequest : Id -> B.Request B.Mutation StoryTask
deleteTaskRequest id =
    deleteTaskQuery
        |> B.request { taskID = id }



-- Plain style


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
        Http.post graphqlUrl body updateTaskResponseDecoder
