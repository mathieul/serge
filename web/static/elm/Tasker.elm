port module Tasker exposing (main)

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


-- Local imports

import Model exposing (..)
import View exposing (..)
import StoryTask exposing (StoryTask)
import Api


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
            , Api.sendQueryRequest Api.fetchTasksRequest
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

        ModalMsg state ->
            { model | modalState = state } ! []

        ConfirmModalMsg state ->
            { model | confirmModalState = state } ! []

        DropdownMsg name state ->
            { model | dropdownStates = Dict.insert name state model.dropdownStates } ! []

        ShowSummary ->
            { model | modalState = Modal.visibleState } ! []

        HideSummary ->
            { model | modalState = Modal.hiddenState } ! []

        RequestConfirmation confirmation ->
            { model
                | confirmation = confirmation
                , confirmModalState = Modal.visibleState
            }
                ! []

        DiscardConfirmation ->
            (hideConfirmModal model) ! []

        UpdateAppContext time ->
            { model | context = timeToAppContext model.timeZone time } ! []

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

        FetchTasks (Ok tasks) ->
            { model
                | taskEditors = List.map taskToEditor tasks
                , dropdownStates = dropdownStatesForTasks tasks
            }
                ! []

        FetchTasks (Err error) ->
            let
                message =
                    case error of
                        GraphQLClient.HttpError error ->
                            httpErrorToMessage error

                        GraphQLClient.GraphQLError errors ->
                            toString errors
            in
                { model | message = MessageError <| "Fetching tasks failed: " ++ message } ! []

        CreateTask (Ok response) ->
            { model
                | taskEditors = replaceTask response.tid response.task model.taskEditors
                , dropdownStates = model.dropdownStates
            }
                ! []

        CreateTask (Err error) ->
            ( { model
                | message = MessageError <| "Creating the task failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

        RequestTaskUpdate task ->
            model ! [ Http.send UpdateTask <| Api.updateTaskRequest task ]

        UpdateTask (Ok task) ->
            { model
                | taskEditors = replaceTask task.id task model.taskEditors
                , dropdownStates = model.dropdownStates
            }
                ! []

        UpdateTask (Err error) ->
            ( { model
                | message = MessageError <| "Updating the task failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

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

                message =
                    case error of
                        GraphQLClient.HttpError error ->
                            httpErrorToMessage error

                        GraphQLClient.GraphQLError errors ->
                            toString errors
            in
                ( { newModel
                    | message = MessageError <| "Updating the task failed: " ++ message
                  }
                , Cmd.none
                )

        ChangeDatePeriod selection ->
            { model | datePeriod = selection } ! []

        ToggleShowCompleted ->
            { model | showCompleted = not model.showCompleted } ! []

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


hideConfirmModal : Model -> Model
hideConfirmModal model =
    { model | confirmModalState = Modal.hiddenState }


createNewTask : Model -> ( Model, Cmd Msg )
createNewTask model =
    let
        scheduledOn =
            case model.datePeriod of
                Yesterday ->
                    model.context.yesterday

                Today ->
                    model.context.today

                Tomorrow ->
                    model.context.tomorrow

                Later ->
                    model.context.later

        newTask =
            makeNewTaskEditor model scheduledOn
    in
        ( { model
            | taskEditors = List.append model.taskEditors [ newTask ]
            , dropdownStates = Dict.insert newTask.task.id Dropdown.initialState model.dropdownStates
            , currentTaskLabel = ""
            , currentTaskSeq = model.currentTaskSeq + 1
          }
        , Http.send CreateTask <| Api.makeTaskRequest newTask.task
        )


dropdownStatesForTasks : List StoryTask -> Dict String Dropdown.State
dropdownStatesForTasks tasks =
    tasks
        |> List.map (\task -> ( task.id, Dropdown.initialState ))
        |> Dict.fromList


replaceTask : String -> StoryTask -> List TaskEditor -> List TaskEditor
replaceTask id task taskEditors =
    List.map
        (\editor ->
            if editor.task.id == id then
                { editor | task = task }
            else
                editor
        )
        taskEditors


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
