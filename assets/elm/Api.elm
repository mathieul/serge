module Api
    exposing
        ( sendQueryRequest
        , sendMutationRequest
        , fetchTaskRequest
        , fetchTasksRequest
        , createTaskRequest
        , updateTaskRequest
        , deleteTaskRequest
        )

import GraphQL.Request.Builder as B
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import StoryTask exposing (StoryTask)
import Model exposing (Id, CreateTaskResponse)


-- CONSTANTS


graphqlUrl : String
graphqlUrl =
    "/graphql"



-- QUERIES, MUTATIONS & REQUESTS


sendQueryRequest : B.Request B.Query a -> Platform.Task GraphQLClient.Error a
sendQueryRequest request =
    GraphQLClient.sendQuery graphqlUrl request


sendMutationRequest : B.Request B.Mutation a -> Platform.Task GraphQLClient.Error a
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



-- FETCH TASK


fetchTaskQuery : B.Document B.Query StoryTask { vars | id : String }
fetchTaskQuery =
    let
        taskIDVar =
            Var.required "id" .id Var.id

        variables =
            [ ( "id", Arg.variable taskIDVar ) ]
    in
        B.field "task" variables storyTask
            |> B.extract
            |> B.queryDocument


fetchTaskRequest : String -> B.Request B.Query StoryTask
fetchTaskRequest id =
    fetchTaskQuery
        |> B.request { id = id }



-- FETCH TASKS


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



-- CREATE TASK


createTaskQuery :
    B.Document B.Mutation
        CreateTaskResponse
        { vars
            | id : String
            , label : String
            , rank : Int
            , scheduledOn : String
        }
createTaskQuery =
    let
        response =
            B.object CreateTaskResponse
                |> B.with (B.field "tid" [] B.id)
                |> B.with (B.field "task" [] storyTask)

        variables =
            [ ( "tid", Arg.variable (Var.required "tmpId" .id Var.id) )
            , ( "label", Arg.variable (Var.required "label" .label Var.string) )
            , ( "position", Arg.variable (Var.required "position" .rank Var.int) )
            , ( "scheduledOn", Arg.variable (Var.required "scheduledOn" .scheduledOn Var.string) )
            ]
    in
        response
            |> B.field "createTask" variables
            |> B.extract
            |> B.mutationDocument


createTaskRequest : StoryTask -> B.Request B.Mutation CreateTaskResponse
createTaskRequest task =
    createTaskQuery
        |> B.request task



-- UPDATE TASK


updateTaskQuery :
    B.Document B.Mutation
        StoryTask
        { vars
            | id : String
            , label : String
            , completed : Bool
            , scheduledOn : String
        }
updateTaskQuery =
    let
        variables =
            [ ( "id", Arg.variable (Var.required "taskID" .id Var.id) )
            , ( "label", Arg.variable (Var.required "label" .label Var.string) )
            , ( "completed", Arg.variable (Var.required "completed" .completed Var.bool) )
            , ( "scheduledOn", Arg.variable (Var.required "scheduledOn" .scheduledOn Var.string) )
            ]
    in
        storyTask
            |> B.field "updateTask" variables
            |> B.extract
            |> B.mutationDocument


updateTaskRequest : StoryTask -> B.Request B.Mutation StoryTask
updateTaskRequest task =
    updateTaskQuery
        |> B.request task



-- DELETE TASK


deleteTaskQuery : B.Document B.Mutation StoryTask { vars | taskID : String }
deleteTaskQuery =
    let
        taskIDVar =
            Var.required "taskID" .taskID Var.id

        variables =
            [ ( "id", Arg.variable taskIDVar ) ]
    in
        storyTask
            |> B.field "deleteTask" variables
            |> B.extract
            |> B.mutationDocument


deleteTaskRequest : Id -> B.Request B.Mutation StoryTask
deleteTaskRequest id =
    deleteTaskQuery
        |> B.request { taskID = id }
