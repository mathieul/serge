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
import Model exposing (..)
import View exposing (..)
import StoryTask exposing (StoryTask, Scheduled(..))
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
            , Task.perform UpdateCurrentDates Time.now
            , Http.send FetchTasks Api.fetchTasksRequest
            , getTimeZone ()
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
                , Time.every Time.minute UpdateCurrentDates
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

        DropdownMsg name state ->
            { model | dropdownStates = Dict.insert name state model.dropdownStates } ! []

        ShowSummary ->
            { model | modalState = Modal.visibleState } ! []

        HideSummary ->
            { model | modalState = Modal.hiddenState } ! []

        UpdateCurrentDates time ->
            { model | dates = StoryTask.timeToCurrentDates model.timeZone time } ! []

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
                | tasks = tasks
                , dropdownStates = dropdownStatesForTasks tasks
            }
                ! []

        FetchTasks (Err error) ->
            ( { model
                | message = MessageError <| "Fetching tasks failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

        CreateTask (Ok response) ->
            { model
                | tasks = replaceTask response.tid response.task model.tasks
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
                | tasks = replaceTask task.id task model.tasks
                , dropdownStates = model.dropdownStates
            }
                ! []

        UpdateTask (Err error) ->
            ( { model
                | message = MessageError <| "Updating the task failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

        ChangeScheduleTab selection ->
            { model | scheduleTab = selection } ! []

        ToggleShowCompleted ->
            { model | showCompleted = not model.showCompleted } ! []

        UpdateEditingTask id editing editingLabel ->
            let
                updateTaskIfId task =
                    if task.id == id then
                        { task
                            | editing = editing
                            , editingLabel = editingLabel
                        }
                    else
                        task
            in
                ( { model
                    | tasks = List.map updateTaskIfId model.tasks
                    , dropdownStates = model.dropdownStates
                  }
                , Dom.focus ("edit-task-" ++ id) |> Task.attempt (\_ -> NoOp)
                )


createNewTask : Model -> ( Model, Cmd Msg )
createNewTask model =
    let
        scheduledOn =
            case model.scheduleTab of
                TabYesterday ->
                    model.dates.yesterday

                TabToday ->
                    model.dates.today

                TabTomorrow ->
                    model.dates.tomorrow

                TabLater ->
                    model.dates.later

        newTask =
            StoryTask.makeNewTask
                model.currentTaskSeq
                model.currentTaskLabel
                (List.length model.tasks)
                scheduledOn
    in
        ( { model
            | tasks = List.append model.tasks [ newTask ]
            , dropdownStates = Dict.insert newTask.id Dropdown.initialState model.dropdownStates
            , currentTaskLabel = ""
            , currentTaskSeq = model.currentTaskSeq + 1
          }
        , Http.send CreateTask <| Api.makeTaskRequest newTask
        )


dropdownStatesForTasks : List StoryTask -> Dict String Dropdown.State
dropdownStatesForTasks tasks =
    tasks
        |> List.map (\task -> ( task.id, Dropdown.initialState ))
        |> Dict.fromList


replaceTask : String -> StoryTask -> List StoryTask -> List StoryTask
replaceTask id task tasks =
    List.map
        (\item ->
            if item.id == id then
                task
            else
                item
        )
        tasks


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
