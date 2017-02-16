port module Tasker exposing (main)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Html exposing (..)
import Html.Attributes exposing (class, href, type_, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import Navigation exposing (Location)
import UrlParser


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
    , currentTask : String
    , tasks : List String
    }


type alias Task =
    { id : String
    , label : String
    , rank : Int
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
    | UpdateCurrentTask String
    | AddCurrentTask
    | FetchTasks (Result Http.Error (List Task))



-- INIT


init : ConfigFromJs -> Location -> ( Model, Cmd Msg )
init rawConfig result =
    let
        currentRoute =
            parseLocation result
    in
        ( initialModel rawConfig currentRoute
        , Http.send FetchTasks fetchTasksRequest
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
    , currentTask = ""
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

        UpdateCurrentTask label ->
            { model | currentTask = label } ! []

        AddCurrentTask ->
            let
                tasks =
                    model.currentTask :: model.tasks
            in
                { model | tasks = tasks, currentTask = "" } ! []

        FetchTasks (Ok response) ->
            let
                _ =
                    Debug.log "FetchTasks Ok" response
            in
                model ! []

        FetchTasks (Err error) ->
            let
                _ =
                    Debug.log "FetchTasks Err" error
            in
                model ! []



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



-- DECODERS / ENCODERS


taskDecoder : Decode.Decoder Task
taskDecoder =
    Pipeline.decode Task
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "label" Decode.string
        |> Pipeline.required "rank" Decode.int


tasksResponseDecoder : Decode.Decoder (List Task)
tasksResponseDecoder =
    Decode.list taskDecoder
        |> Decode.at [ "data", "tasks" ]



-- API


fetchTasksQuery : String
fetchTasksQuery =
    """
    query {
      tasks {
        id
        label
        rank
      }
    }
  """


fetchTasksRequest : Http.Request (List Task)
fetchTasksRequest =
    let
        url =
            "/graphql"

        body =
            Encode.object [ ( "query", Encode.string fetchTasksQuery ) ]
                |> Http.jsonBody
    in
        Http.post url body tasksResponseDecoder



-- VIEW


view : Model -> Html Msg
view model =
    let
        view =
            case model.route of
                HomeRoute ->
                    homeView model

                NotFoundRoute ->
                    notFoundView
    in
        layoutView view


notFoundView : Html msg
notFoundView =
    div [] [ text "NOT FOUND ROUTE" ]


layoutView : Html Msg -> Html Msg
layoutView view =
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
            [ view ]
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
        , taskForm model
        , div [ class "card w-50" ]
            [ ul [ class "list-group list-group-flush" ]
                (List.map taskView model.tasks)
            ]
        ]


taskForm : Model -> Html Msg
taskForm model =
    form [ onSubmit AddCurrentTask ]
        [ div [ class "form-group row" ]
            [ div [ class "col-sm-10" ]
                [ input
                    [ type_ "text"
                    , class "form-control form-control-lg"
                    , placeholder "Enter new task..."
                    , value model.currentTask
                    , onInput UpdateCurrentTask
                    ]
                    []
                ]
            , div [ class "col-sm-2" ]
                [ button
                    [ type_ "submit"
                    , class "btn btn-outline-primary btn-block btn-lg"
                    ]
                    [ text "Create" ]
                ]
            ]
        ]


taskView : String -> Html Msg
taskView task =
    li [ class "list-group-item" ]
        [ text task ]
