port module Tasker exposing (main)

import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import Task
import Html exposing (Html, div, span, text, nav, button, a, ul, li, h2, h4, small)
import Html.Attributes exposing (class, href, type_, placeholder, value)
import Html.Events exposing (onClick)
import Http
import String.Extra
import StoryTask exposing (StoryTask, CreateTaskResponse)


-- MAIN


main : Program ConfigFromJs Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias ConfigFromJs =
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
    }


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , accessToken : String
    }


type Msg
    = FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error CreateTaskResponse)
    | UpdateTask (Result Http.Error StoryTask)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask
    | UpdateCurrentDates Time
    | SetTimeZone String
    | RequestTaskUpdate StoryTask
    | ChangeTaskScheduleSelection TaskScheduleSelection


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


init : ConfigFromJs -> ( Model, Cmd Msg )
init rawConfig =
    ( initialModel rawConfig
    , Cmd.batch
        [ Task.perform UpdateCurrentDates Time.now
        , Http.send FetchTasks StoryTask.fetchTasksRequest
        , getTimeZone ()
        ]
    )


initialAppConfig : ConfigFromJs -> AppConfig
initialAppConfig rawConfig =
    { id = rawConfig.id
    , name = rawConfig.name
    , email = rawConfig.email
    , accessToken = rawConfig.access_token
    }


initialModel : ConfigFromJs -> Model
initialModel rawConfig =
    { config = initialAppConfig rawConfig
    , message = MessageNone
    , currentDates = StoryTask.CurrentDates "" "" ""
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , taskSelection = TaskScheduleAll
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
                        newTask =
                            StoryTask.makeNewTask
                                model.currentTaskSeq
                                model.currentTaskLabel
                                (List.length model.tasks)
                                model.currentDates.later
                    in
                        ( { model
                            | tasks = List.append model.tasks [ newTask ]
                            , currentTaskLabel = ""
                            , currentTaskSeq = model.currentTaskSeq + 1
                          }
                        , Http.send CreateTask <| StoryTask.makeTaskRequest newTask
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
            model ! [ Http.send UpdateTask <| StoryTask.updateTaskRequest task ]

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
            [ class "navbar navbar-toggleable-md navbar-inverse bg-inverse fixed-top" ]
            [ button
                [ class "navbar-toggler navbar-toggler-right", type_ "button" ]
                []
            , a
                [ class "navbar-brand", href "#" ]
                [ text "Tasker" ]
            , div
                [ class "collapse navbar-collapse" ]
                [ ul
                    [ class "navbar-nav mr-auto" ]
                    [ li
                        [ class "nav-item active" ]
                        [ a
                            [ class "nav-link", href "#" ]
                            [ text "Home" ]
                        ]
                    ]
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
            [ StoryTask.storyTaskForm
                model.currentTaskLabel
                AddCurrentTask
                UpdateCurrentTask
            , taskList model.currentDates model.taskSelection model.tasks
            ]
        ]


taskList : StoryTask.CurrentDates -> TaskScheduleSelection -> List StoryTask -> Html Msg
taskList dates selection tasks =
    let
        selectedTasks =
            case selection of
                TaskScheduleAll ->
                    tasks

                TaskScheduleToday ->
                    List.filter (\task -> (StoryTask.taskSchedule dates task) == StoryTask.ScheduledToday) tasks

                TaskScheduleTomorrow ->
                    List.filter (\task -> (StoryTask.taskSchedule dates task) == StoryTask.ScheduledTomorrow) tasks

                TaskScheduleLater ->
                    List.filter (\task -> (StoryTask.taskSchedule dates task) == StoryTask.ScheduledLater) tasks

        footer =
            String.Extra.pluralize "task" "tasks" (List.length selectedTasks)
    in
        div [ class "card mt-3" ]
            [ taskSelectionTabs selection
            , div [ class "card-block" ]
                [ StoryTask.storyTasksView dates RequestTaskUpdate selectedTasks ]
            , div [ class "card-footer text-muted" ]
                [ text footer ]
            ]


taskSelectionTabs : TaskScheduleSelection -> Html Msg
taskSelectionTabs selection =
    div [ class "card-header" ]
        [ ul [ class "nav nav-tabs card-header-tabs" ]
            [ li [ class "nav-item" ]
                [ a
                    [ class <| "nav-link" ++ (valueIfMatch selection TaskScheduleAll " active")
                    , href "#"
                    , onClick (ChangeTaskScheduleSelection TaskScheduleAll)
                    ]
                    [ text "All" ]
                ]
            , li [ class "nav-item" ]
                [ a
                    [ class <| "nav-link" ++ (valueIfMatch selection TaskScheduleToday " active")
                    , href "#"
                    , onClick (ChangeTaskScheduleSelection TaskScheduleToday)
                    ]
                    [ text "Today" ]
                ]
            , li [ class "nav-item" ]
                [ a
                    [ class <| "nav-link" ++ (valueIfMatch selection TaskScheduleTomorrow " active")
                    , href "#"
                    , onClick (ChangeTaskScheduleSelection TaskScheduleTomorrow)
                    ]
                    [ text "Tomorrow" ]
                ]
            , li [ class "nav-item" ]
                [ a
                    [ class <| "nav-link" ++ (valueIfMatch selection TaskScheduleLater " active")
                    , href "#"
                    , onClick (ChangeTaskScheduleSelection TaskScheduleLater)
                    ]
                    [ text "Later" ]
                ]
            ]
        ]


valueIfMatch : a -> a -> String -> String
valueIfMatch a b value =
    if a == b then
        value
    else
        ""


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
