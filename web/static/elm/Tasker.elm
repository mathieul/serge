port module Tasker exposing (main)

import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import Task
import Html exposing (Html, div, span, text, nav, button, a, ul, li, h1, h2, h4, small, input)
import Html.Attributes exposing (class, classList, href, type_, placeholder, value, checked)
import Html.Events exposing (onClick)
import Http
import Dom
import String.Extra
import StoryTask exposing (StoryTask, Scheduled(..))
import Api exposing (CreateTaskResponse)


-- MAIN


main : Program AppConfig Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , access_token : String
    }


type alias Model =
    { config : AppConfig
    , message : AppMessage
    , currentDates : StoryTask.CurrentDates
    , timeZone : TimeZone
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , tasks : List StoryTask
    , taskSelection : TaskScheduleSelection
    , showCompleted : Bool
    }


type Msg
    = NoOp
    | FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error CreateTaskResponse)
    | UpdateTask (Result Http.Error StoryTask)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask
    | UpdateCurrentDates Time
    | SetTimeZone String
    | RequestTaskUpdate StoryTask
    | ChangeTaskScheduleSelection TaskScheduleSelection
    | ToggleShowCompleted
    | UpdateEditingTask String Bool String


type AppMessage
    = MessageNone
    | MessageNotice String
    | MessageError String


type TaskScheduleSelection
    = TaskScheduleAll
    | TaskScheduleToday
    | TaskScheduleTomorrow
    | TaskScheduleLater



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


initialModel : AppConfig -> Model
initialModel config =
    { config = config
    , message = MessageNone
    , currentDates = StoryTask.makeEmptyCurrentDates
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , taskSelection = TaskScheduleToday
    , showCompleted = False
    }



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

        UpdateCurrentDates time ->
            ( updateCurrentDatesFromTime time model, Cmd.none )

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
                            case model.taskSelection of
                                TaskScheduleToday ->
                                    model.currentDates.today

                                TaskScheduleTomorrow ->
                                    model.currentDates.tomorrow

                                _ ->
                                    model.currentDates.later

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
                | message = MessageError "An error occurred while fetching tasks."
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

        ChangeTaskScheduleSelection selection ->
            { model | taskSelection = selection } ! []

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


updateCurrentDatesFromTime : Time -> Model -> Model
updateCurrentDatesFromTime time model =
    { model | currentDates = StoryTask.timeToCurrentDates model.timeZone time }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ nav
            [ class "navbar navbar-toggleable-md navbar-inverse bg-primary " ]
            [ button [ class "navbar-toggler navbar-toggler-right", type_ "button" ]
                [ span [ class "navbar-toggler-icon" ] [] ]
            , h1
                [ class "navbar-brand" ]
                [ text model.config.name
                , small [ class "pl-3" ] [ text <| "(" ++ model.config.email ++ ")" ]
                ]
            , div
                [ class "collapse navbar-collapse" ]
                [ ul [ class "navbar-nav mr-auto" ] []
                , span
                    [ class "navbar-text pull-right mr-3" ]
                    [ text model.currentDates.today ]
                , span
                    [ class "pull-right" ]
                    [ a
                        [ href "/auth/logout", class "btn btn-danger" ]
                        [ text "Logout" ]
                    ]
                ]
            ]
        , div
            [ class "container below-navbar" ]
            [ messageView model.message
            , homeView model
            ]
        ]


homeView : Model -> Html Msg
homeView model =
    div [ class "mt-3" ]
        [ h2 [] [ text "Tasker" ]
        , taskForm model
        ]


taskForm : Model -> Html Msg
taskForm model =
    div [ class "card mt-3" ]
        [ div [ class "card-block" ]
            [ StoryTask.formView
                model.currentTaskLabel
                AddCurrentTask
                UpdateCurrentTask
            , taskList model
            ]
        ]


taskList : Model -> Html Msg
taskList model =
    let
        { currentDates, tasks, taskSelection } =
            model

        tasksWithSchedule schedules task =
            List.member (StoryTask.taskSchedule currentDates task) schedules

        selectedTasks =
            case taskSelection of
                TaskScheduleAll ->
                    tasks

                TaskScheduleToday ->
                    List.filter (tasksWithSchedule [ ScheduledYesterday, ScheduledToday ]) tasks

                TaskScheduleTomorrow ->
                    List.filter (tasksWithSchedule [ ScheduledTomorrow ]) tasks

                TaskScheduleLater ->
                    List.filter (tasksWithSchedule [ ScheduledLater ]) tasks
    in
        div [ class "card mt-3" ]
            [ taskSelectionTabs taskSelection
            , div [ class "card-block" ]
                [ StoryTask.listView
                    currentDates
                    RequestTaskUpdate
                    UpdateEditingTask
                    model.showCompleted
                    (taskSelection == TaskScheduleAll)
                    selectedTasks
                ]
            , taskListFooter selectedTasks model
            ]


taskListFooter : List StoryTask -> Model -> Html Msg
taskListFooter tasks model =
    let
        countCompleted =
            List.foldl
                (\task count ->
                    if task.completed then
                        count + 1
                    else
                        count
                )
                0
                tasks

        count =
            (List.length tasks) - countCompleted

        label =
            (String.Extra.pluralize "task" "tasks" count)
                ++ " / "
                ++ (toString countCompleted)
                ++ " completed"
    in
        div [ class "card-footer text-muted" ]
            [ div [ class "row" ]
                [ div [ class "col pl-3" ]
                    [ text label ]
                , div [ class "col pr-3 text-right" ]
                    [ text "show completed "
                    , input
                        [ type_ "checkbox"
                        , checked model.showCompleted
                        , onClick ToggleShowCompleted
                        ]
                        []
                    ]
                ]
            ]


taskSelectionTabs : TaskScheduleSelection -> Html Msg
taskSelectionTabs selection =
    let
        tab ( schedule, label ) =
            li [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , classList [ ( "active", selection == schedule ) ]
                    , href "#"
                    , onClick (ChangeTaskScheduleSelection schedule)
                    ]
                    [ text label ]
                ]

        tabs =
            List.map
                tab
                [ ( TaskScheduleToday, "Today" )
                , ( TaskScheduleTomorrow, "Tomorrow" )
                , ( TaskScheduleLater, "Later" )
                , ( TaskScheduleAll, "All" )
                ]
    in
        div [ class "card-header" ]
            [ ul
                [ class "nav nav-tabs card-header-tabs" ]
                tabs
            ]


messageView : AppMessage -> Html Msg
messageView message =
    let
        view level content =
            div [ class ("my-4 alert " ++ level) ]
                [ button
                    [ type_ "button"
                    , class "close"
                    , onClick ClearMessage
                    ]
                    [ span [] [ text "×" ] ]
                , text content
                ]
    in
        case message of
            MessageNone ->
                div [] []

            MessageNotice content ->
                view "alert-notice" content

            MessageError content ->
                view "alert-danger" content
