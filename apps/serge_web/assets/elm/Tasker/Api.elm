module Tasker.Api
    exposing
        ( sendQueryRequest
        , sendMutationRequest
        , fetchTaskRequest
        , fetchTasksRequest
        , createTaskRequest
        , updateTaskRequest
        , moveTaskRequest
        , deleteTaskRequest
        )

import GraphQL.Request.Builder as B
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import Tasker.StoryTask exposing (StoryTask)
import Tasker.Model exposing (Id, CreateTaskResponse, MoveTaskRequest(..))


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
        |> B.with (B.field "scheduledOn" [] (B.nullable B.string))
        |> B.with (B.field "completedOn" [] (B.nullable B.string))



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
            , scheduledOn : Maybe String
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
            , ( "scheduledOn", Arg.variable (Var.required "scheduledOn" .scheduledOn (Var.nullable Var.string)) )
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


type alias StoryTaskUpdateVars =
    { task : StoryTask
    , uncomplete : Bool
    , unschedule : Bool
    , beforeTaskId : Maybe String
    , afterTaskId : Maybe String
    }


updateTaskQuery : B.Document B.Mutation StoryTask StoryTaskUpdateVars
updateTaskQuery =
    let
        id =
            Var.required "taskID" (.task >> .id) Var.id

        label =
            Var.required "label" (.task >> .label) Var.string

        scheduledOn =
            Var.required "scheduledOn" (.task >> .scheduledOn) (Var.nullable Var.string)

        completedOn =
            Var.required "completedOn" (.task >> .completedOn) (Var.nullable Var.string)

        uncomplete =
            Var.required "uncomplete" .uncomplete Var.bool

        unschedule =
            Var.required "unschedule" .unschedule Var.bool

        beforeTaskId =
            Var.required "beforeTaskId" .beforeTaskId (Var.nullable Var.id)

        afterTaskId =
            Var.required "afterTaskId" .afterTaskId (Var.nullable Var.id)

        variables =
            [ ( "id", Arg.variable id )
            , ( "label", Arg.variable label )
            , ( "scheduledOn", Arg.variable scheduledOn )
            , ( "completedOn", Arg.variable completedOn )
            , ( "uncomplete", Arg.variable uncomplete )
            , ( "unschedule", Arg.variable unschedule )
            , ( "beforeTaskId", Arg.variable beforeTaskId )
            , ( "afterTaskId", Arg.variable afterTaskId )
            ]
    in
        storyTask
            |> B.field "updateTask" variables
            |> B.extract
            |> B.mutationDocument


updateTaskRequest : StoryTask -> B.Request B.Mutation StoryTask
updateTaskRequest task =
    updateTaskQuery
        |> B.request (makeUpdateTaskVars task)


moveTaskRequest : StoryTask -> MoveTaskRequest -> B.Request B.Mutation StoryTask
moveTaskRequest task moveRequest =
    let
        ( beforeTaskId, afterTaskId ) =
            case moveRequest of
                MoveTaskBefore other ->
                    ( Just other.id, Nothing )

                MoveTaskAfter other ->
                    ( Nothing, Just other.id )

        taskVars =
            makeUpdateTaskVars task

        moveTaskVars =
            { taskVars
                | beforeTaskId = beforeTaskId
                , afterTaskId = afterTaskId
            }
    in
        updateTaskQuery
            |> B.request moveTaskVars


makeUpdateTaskVars : StoryTask -> StoryTaskUpdateVars
makeUpdateTaskVars task =
    { task = task
    , uncomplete = task.completedOn == Nothing
    , unschedule = task.scheduledOn == Nothing
    , beforeTaskId = Nothing
    , afterTaskId = Nothing
    }



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
