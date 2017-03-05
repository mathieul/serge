port module Tasker exposing (main)

import Time exposing (Time)
import Time.TimeZones as TimeZones
import Html
import Http
import Task
import Dom
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
    ( initialModel config
    , Cmd.batch
        [ Task.perform UpdateCurrentDates Time.now
        , Http.send FetchTasks Api.fetchTasksRequest
        , getTimeZone ()
        ]
    )



-- PORTS


port getTimeZone : () -> Cmd msg


port setTimeZone : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ setTimeZone SetTimeZone
        , Time.every Time.minute UpdateCurrentDates
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        ShowSummary ->
            { model | showSummary = True } ! []

        HideSummary ->
            { model | showSummary = False } ! []

        UpdateCurrentDates time ->
            ( { model | dates = StoryTask.timeToCurrentDates model.timeZone time }, Cmd.none )

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
                    let
                        scheduledOn =
                            case model.scheduleTab of
                                TabToday ->
                                    model.dates.today

                                TabTomorrow ->
                                    model.dates.tomorrow

                                _ ->
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
                            , currentTaskLabel = ""
                            , currentTaskSeq = model.currentTaskSeq + 1
                          }
                        , Http.send CreateTask <| Api.makeTaskRequest newTask
                        )

        FetchTasks (Ok tasks) ->
            { model | tasks = tasks } ! []

        FetchTasks (Err error) ->
            ( { model
                | message = MessageError <| "Fetching tasks failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

        CreateTask (Ok response) ->
            { model | tasks = replaceTask response.tid response.task model.tasks } ! []

        CreateTask (Err error) ->
            ( { model
                | message = MessageError <| "Creating the task failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )

        RequestTaskUpdate task ->
            model ! [ Http.send UpdateTask <| Api.updateTaskRequest task ]

        UpdateTask (Ok task) ->
            { model | tasks = replaceTask task.id task model.tasks } ! []

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
                tasks =
                    List.map
                        (\task ->
                            if task.id == id then
                                { task
                                    | editing = editing
                                    , editingLabel = editingLabel
                                }
                            else
                                task
                        )
                        model.tasks

                textFieldId =
                    "edit-task-" ++ id
            in
                ( { model | tasks = tasks }
                , Dom.focus textFieldId |> Task.attempt (\_ -> NoOp)
                )


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
