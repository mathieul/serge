port module Tasker exposing (main)

import Time exposing (Time)
import Date
import Date.Format
import Html exposing (Html, div, span, text, nav, button, a, ul, li, h2, h4, small)
import Html.Attributes exposing (class, href, type_, placeholder, value)
import Html.Events exposing (onClick)
import Http
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
    , today : String
    }


type alias Model =
    { config : AppConfig
    , message : AppMessage
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , tasks : List StoryTask
    }


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , accessToken : String
    , today : String
    }


type Msg
    = FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error CreateTaskResponse)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask
    | UpdateCurrentDate Time


type AppMessage
    = MessageNone
    | MessageNotice String
    | MessageError String



-- INIT


init : ConfigFromJs -> ( Model, Cmd Msg )
init rawConfig =
    let
        request =
            StoryTask.fetchTasksRequest
    in
        ( initialModel rawConfig
        , Http.send FetchTasks request
        )


initialAppConfig : ConfigFromJs -> AppConfig
initialAppConfig rawConfig =
    { id = rawConfig.id
    , name = rawConfig.name
    , email = rawConfig.email
    , accessToken = rawConfig.access_token
    , today = rawConfig.today
    }


initialModel : ConfigFromJs -> Model
initialModel rawConfig =
    { config = initialAppConfig rawConfig
    , message = MessageNone
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every Time.minute UpdateCurrentDate



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCurrentDate time ->
            ( updateTodayFromTime time model, Cmd.none )

        ClearMessage ->
            { model | message = MessageNone } ! []

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
                                model.config.today

                        request =
                            StoryTask.makeTaskRequest newTask
                    in
                        ( { model
                            | tasks = List.append model.tasks [ newTask ]
                            , currentTaskLabel = ""
                            , currentTaskSeq = model.currentTaskSeq + 1
                          }
                        , Http.send CreateTask request
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
            let
                tasks =
                    List.map
                        (\item ->
                            if item.id == response.tid then
                                response.task
                            else
                                item
                        )
                        model.tasks
            in
                { model | tasks = tasks } ! []

        CreateTask (Err error) ->
            ( { model
                | message = MessageError <| "Creating the task failed: " ++ (httpErrorToMessage error)
              }
            , Cmd.none
            )


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


updateTodayFromTime : Time -> Model -> Model
updateTodayFromTime time model =
    let
        today =
            time
                |> Date.fromTime
                |> Date.Format.format "%Y-%m-%d"

        config =
            model.config

        newConfig =
            { config | today = today }
    in
        { model | config = newConfig }



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
                    [ text model.config.today ]
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
        [ h2 []
            [ text "Tasker" ]
        , div [ class "card mt-3" ]
            [ cardHeader
            , cardBody model
            , div [ class "card-footer text-muted" ]
                [ small [] [ text "todo" ] ]
            ]
        ]


cardHeader : Html Msg
cardHeader =
    div [ class "card-header" ]
        [ ul [ class "nav nav-tabs card-header-tabs" ]
            [ li [ class "nav-item" ]
                [ a
                    [ class "nav-link active", href "#" ]
                    [ text "All" ]
                ]
            , li [ class "nav-item" ]
                [ a
                    [ class "nav-link", href "#" ]
                    [ text "Today" ]
                ]
            , li [ class "nav-item" ]
                [ a
                    [ class "nav-link", href "#" ]
                    [ text "Yesterday" ]
                ]
            ]
        ]


cardBody : Model -> Html Msg
cardBody model =
    div [ class "card-block" ]
        [ h4 [ class "card-title" ] [ text "Tasks" ]
        , StoryTask.storyTaskForm
            model.currentTaskLabel
            AddCurrentTask
            UpdateCurrentTask
        , StoryTask.storyTasksView model.config.today model.tasks
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
