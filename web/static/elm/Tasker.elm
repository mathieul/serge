port module Tasker exposing (main)

import Html exposing (Html, div, span, text, nav, button, a, ul, li, h2, h4, small)
import Html.Attributes exposing (class, href, type_, placeholder, value)
import Html.Events exposing (onClick)
import Http
import Navigation exposing (Location)
import UrlParser
import StoryTask exposing (StoryTask)


-- MAIN


main : Program ConfigFromJs Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = update
        , subscriptions = (\_ -> Sub.none)
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
    , route : Route
    , message : AppMessage
    , currentTaskLabel : String
    , tasks : List StoryTask
    }


type Route
    = HomeRoute
    | NotFoundRoute


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , accessToken : String
    }


type Msg
    = NoOp
    | UrlChange Navigation.Location
    | FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error StoryTask)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask


type AppMessage
    = MessageNone
    | MessageNotice String
    | MessageError String



-- INIT


init : ConfigFromJs -> Location -> ( Model, Cmd Msg )
init rawConfig result =
    let
        currentRoute =
            parseLocation result
    in
        ( initialModel rawConfig currentRoute
        , Http.send FetchTasks StoryTask.fetchTasksRequest
        )


initialAppConfig : ConfigFromJs -> AppConfig
initialAppConfig rawConfig =
    { id = rawConfig.id
    , name = rawConfig.name
    , email = rawConfig.email
    , accessToken = rawConfig.access_token
    }


initialModel : ConfigFromJs -> Route -> Model
initialModel rawConfig route =
    { config = initialAppConfig rawConfig
    , route = route
    , message = MessageNone
    , currentTaskLabel = ""
    , tasks = []
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UrlChange location ->
            model ! []

        ClearMessage ->
            { model | message = MessageNone } ! []

        UpdateCurrentTask label ->
            { model | currentTaskLabel = label } ! []

        AddCurrentTask ->
            let
                newTask =
                    StoryTask.makeNewTask model.currentTaskLabel (List.length model.tasks)

                tasks =
                    newTask :: model.tasks

                createTaskRequest =
                    StoryTask.makeTaskRequest newTask.label newTask.rank
            in
                ( { model
                    | tasks = tasks
                    , currentTaskLabel = ""
                  }
                , Http.send CreateTask createTaskRequest
                )

        FetchTasks (Ok tasks) ->
            { model | tasks = tasks } ! []

        FetchTasks (Err error) ->
            { model | message = MessageError "An error occurred while fetching tasks." } ! []

        CreateTask (Ok task) ->
            { model | tasks = task :: model.tasks } ! []

        CreateTask (Err error) ->
            { model | message = MessageError "Creating the task failed, please try again." } ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        view =
            case model.route of
                HomeRoute ->
                    homeView

                NotFoundRoute ->
                    notFoundView
    in
        layoutView model view


notFoundView : Model -> Html msg
notFoundView _ =
    div [] [ text "NOT FOUND ROUTE" ]


layoutView : Model -> (Model -> Html Msg) -> Html Msg
layoutView model view =
    div []
        [ nav
            [ class "navbar navbar-toggleable-md navbar-inverse bg-inverse fixed-top" ]
            [ button
                [ class "navbar-toggler navbar-toggler-right", type_ "button" ]
                []
            , a
                [ class "navbar-brand", href "#" ]
                [ text "Navbar" ]
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
            , view model
            ]
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
        , div [ class "card w-50" ]
            [ ul [ class "list-group list-group-flush" ]
                (List.map StoryTask.storyTaskView model.tasks)
            ]
        ]



-- ROUTING


matchers : UrlParser.Parser (Route -> a) a
matchers =
    UrlParser.oneOf
        [ UrlParser.map HomeRoute UrlParser.top
        ]


parseLocation : Location -> Route
parseLocation location =
    let
        _ =
            Debug.log "location" location
    in
        case UrlParser.parseHash matchers location of
            Just route ->
                route

            Nothing ->
                NotFoundRoute
