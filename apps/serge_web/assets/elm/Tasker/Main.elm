port module Tasker.Main exposing (main)

import Dict exposing (Dict)
import Time exposing (Time)
import Time.TimeZones as TimeZones
import Html
import Http
import Task
import Dom
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Button as Button
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import Tasker.Model exposing (..)
import Tasker.Views.Main exposing (view)
import Tasker.StoryTask exposing (StoryTask)
import Tasker.Api as Api


-- MAIN


main : Program AppConfig Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


init : AppConfig -> ( Model, Cmd Msg )
init config =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg
    in
        ( initialModel config navState
        , Cmd.batch
            [ navCmd
            , Task.perform UpdateAppContext Time.now
            , getTimeZone ()
            , Api.fetchTasksRequest
                |> Api.sendQueryRequest
                |> Task.attempt FetchTasks
            ]
        )



-- PORTS


port getTimeZone : () -> Cmd msg


port setTimeZone : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        dropdownSubscription ( name, state ) =
            Dropdown.subscriptions state (DropdownMsg name)
    in
        model.dropdownStates
            |> Dict.toList
            |> List.map dropdownSubscription
            |> List.append
                [ setTimeZone SetTimeZone
                , Time.every Time.minute UpdateAppContext
                ]
            |> Sub.batch



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        NavMsg state ->
            { model | navState = state } ! []

        SummaryModalMsg state ->
            { model | summaryModalState = state } ! []

        ConfirmModalMsg state ->
            { model | confirmModalState = state } ! []

        DropdownMsg name state ->
            { model | dropdownStates = Dict.insert name state model.dropdownStates } ! []

        ShowSummary ->
            { model | summaryModalState = Modal.visibleState } ! []

        HideSummary ->
            { model | summaryModalState = Modal.hiddenState } ! []

        RequestConfirmation confirmation ->
            { model
                | confirmation = confirmation
                , confirmModalState = Modal.visibleState
            }
                ! []

        DiscardConfirmation ->
            (hideConfirmModal model) ! []

        UpdateAppContext time ->
            (updateModelForTime time model) ! []

        ClearMessage ->
            { model | message = MessageNone } ! []

        SetTimeZone name ->
            let
                timeZone =
                    TimeZones.fromName name
                        |> Maybe.withDefault (TimeZones.utc ())
            in
                { model | timeZone = timeZone } ! []

        UpdateCurrentTask label ->
            { model | currentTaskLabel = label } ! []

        AddCurrentTask ->
            case model.currentTaskLabel of
                "" ->
                    model ! []

                _ ->
                    createNewTask model

        FetchTask (Ok task) ->
            let
                _ =
                    Debug.log "FetchTask: " task
            in
                model ! []

        FetchTask (Err error) ->
            { model | message = MessageError <| graphQLErrorToMessage "Fetching task failed" error } ! []

        FetchTasks (Ok tasks) ->
            { model
                | taskEditors =
                    tasks
                        |> List.map (taskToEditor model.context)
                        |> orderTaskEditors
                , dropdownStates = dropdownStatesForTasks tasks
            }
                ! []

        FetchTasks (Err error) ->
            { model | message = MessageError <| graphQLErrorToMessage "Fetching tasks failed" error } ! []

        CreateTask (Ok response) ->
            { model
                | taskEditors = replaceTask response.tid response.task model
                , dropdownStates = model.dropdownStates
            }
                ! []

        CreateTask (Err error) ->
            { model | message = MessageError <| graphQLErrorToMessage "Creating the task failed" error } ! []

        RequestTaskUpdate task ->
            model
                ! [ Api.updateTaskRequest task
                        |> Api.sendMutationRequest
                        |> Task.attempt UpdateTask
                  ]

        UpdateTask (Ok task) ->
            { model
                | taskEditors = replaceTask task.id task model
                , dropdownStates = model.dropdownStates
            }
                ! []

        UpdateTask (Err error) ->
            { model | message = MessageError <| graphQLErrorToMessage "Updating the task failed" error } ! []

        RequestTaskDeletion id ->
            model
                ! [ Api.deleteTaskRequest id
                        |> Api.sendMutationRequest
                        |> Task.attempt DeleteTask
                  ]

        DeleteTask (Ok task) ->
            let
                ( newModel, cmds ) =
                    model
                        |> hideConfirmModal
                        |> update DiscardConfirmation

                updatedTaskEditors =
                    List.filter (\editor -> editor.task.id /= task.id) model.taskEditors
            in
                ( { newModel
                    | taskEditors = updatedTaskEditors
                    , message = MessageSuccess <| "Task \"" ++ task.label ++ "\" was deleted successfully."
                  }
                , cmds
                )

        DeleteTask (Err error) ->
            let
                newModel =
                    hideConfirmModal model
            in
                { newModel | message = MessageError <| graphQLErrorToMessage "Updating the task failed" error } ! []

        ChangeDatePeriod selection ->
            { model | datePeriod = selection } ! []

        ToggleShowCompleted ->
            { model | showCompleted = not model.showCompleted } ! []

        ToggleShowYesterday ->
            { model
                | showYesterday = not model.showYesterday
                , datePeriod =
                    if model.datePeriod == Yesterday then
                        Today
                    else
                        model.datePeriod
            }
                ! []

        ConfirmTaskDeletion id label ->
            let
                confirmation =
                    { emptyConfirmation
                        | title = "Delete Task"
                        , text = "Do you really want to delete task \"" ++ label ++ "\"?"
                        , btnOk = Button.danger
                        , msgOk = RequestTaskDeletion id
                    }
            in
                update (RequestConfirmation confirmation) model

        UpdateEditingTask id editing editingLabel ->
            let
                updateTaskIfId editor =
                    if editor.task.id == id then
                        { editor
                            | editing = editing
                            , editingLabel = editingLabel
                        }
                    else
                        editor
            in
                ( { model
                    | taskEditors = List.map updateTaskIfId model.taskEditors
                    , dropdownStates = model.dropdownStates
                  }
                , Dom.focus ("edit-task-" ++ id) |> Task.attempt (\_ -> NoOp)
                )

        ShowOrdering ->
            { model | orderingMode = True } ! []

        HideOrdering ->
            ( { model
                | orderingMode = False
                , orderingTaskEditor = Nothing
              }
            , Cmd.none
            )

        StartOrdering editor ->
            { model | orderingTaskEditor = Just editor } ! []

        StopOrdering ->
            { model | orderingTaskEditor = Nothing } ! []

        ExecuteMoveRequest moveRequest ->
            let
                command =
                    case model.orderingTaskEditor of
                        Just taskEditor ->
                            Api.moveTaskRequest taskEditor.task moveRequest
                                |> Api.sendMutationRequest
                                |> Task.attempt UpdateTask

                        Nothing ->
                            Cmd.none
            in
                ( { model | orderingTaskEditor = Nothing }, command )


updateModelForTime : Time -> Model -> Model
updateModelForTime time model =
    let
        newContext =
            timeToAppContext model.timeZone time

        updateSchedule editor =
            { editor | period = taskSchedule newContext editor.task }
    in
        if newContext.today == model.context.today then
            model
        else
            { model
                | context = newContext
                , taskEditors =
                    model.taskEditors
                        |> discardOldTasks newContext
                        |> List.map updateSchedule
            }


hideConfirmModal : Model -> Model
hideConfirmModal model =
    { model | confirmModalState = Modal.hiddenState }


createNewTask : Model -> ( Model, Cmd Msg )
createNewTask model =
    let
        scheduledOn =
            case model.datePeriod of
                Yesterday ->
                    Just model.context.yesterday

                Today ->
                    Just model.context.today

                Tomorrow ->
                    Just model.context.tomorrow

                Later ->
                    Nothing

        newTask =
            makeNewTaskEditor model scheduledOn
    in
        ( { model
            | taskEditors = List.append model.taskEditors [ newTask ]
            , dropdownStates = Dict.insert newTask.task.id Dropdown.initialState model.dropdownStates
            , currentTaskLabel = ""
            , currentTaskSeq = model.currentTaskSeq + 1
          }
        , Api.createTaskRequest newTask.task
            |> Api.sendMutationRequest
            |> Task.attempt CreateTask
        )


dropdownStatesForTasks : List StoryTask -> Dict String Dropdown.State
dropdownStatesForTasks tasks =
    tasks
        |> List.map (\task -> ( task.id, Dropdown.initialState ))
        |> Dict.fromList


replaceTask : String -> StoryTask -> Model -> List TaskEditor
replaceTask id task model =
    List.map
        (\editor ->
            if editor.task.id == id then
                taskToEditor model.context task
            else
                editor
        )
        model.taskEditors
        |> orderTaskEditors


orderTaskEditors : List TaskEditor -> List TaskEditor
orderTaskEditors editors =
    List.sortWith
        (\a b ->
            if a.task.scheduledOn == b.task.scheduledOn then
                compare a.task.rank b.task.rank
            else
                case a.task.scheduledOn of
                    Just scheduleA ->
                        case b.task.scheduledOn of
                            Just scheduleB ->
                                compare scheduleA scheduleB

                            Nothing ->
                                LT

                    Nothing ->
                        GT
        )
        editors


httpErrorToMessage : Http.Error -> String
httpErrorToMessage error =
    case error of
        Http.BadUrl message ->
            "error in URL: " ++ message

        Http.NetworkError ->
            "error with the network connection"

        Http.BadStatus response ->
            let
                _ =
                    Debug.log "BadStatus error" response.body
            in
                (toString response.status.code)
                    ++ " "
                    ++ response.status.message

        Http.BadPayload message _ ->
            "decoding Failed: " ++ message

        _ ->
            (toString error)


graphQLErrorToMessage : String -> GraphQLClient.Error -> String
graphQLErrorToMessage label error =
    let
        message =
            case error of
                GraphQLClient.HttpError error ->
                    httpErrorToMessage error

                GraphQLClient.GraphQLError errors ->
                    toString errors
    in
        label ++ ": " ++ message
