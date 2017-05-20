module Scrum.Main exposing (main)

import Navigation exposing (Location)
import Task
import Html exposing (..)
import Json.Decode as Decode exposing (Value)


-- LOCAL IMPORTS

import Scrum.Route as Route exposing (Route)
import Scrum.Page.NotFound as NotFound
import Scrum.Page.Backlog as Backlog
import Scrum.Page.Sprints as Sprints
import Scrum.Page.Errored as Errored exposing (PageLoadError)
import Scrum.Views.Page as Page exposing (ActivePage)
import Scrum.Data.Session as Session exposing (Session)
import Scrum.Misc exposing ((=>))


-- MAIN


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type Page
    = Blank
    | NotFound
    | Errored PageLoadError
    | Backlog Backlog.Model
    | Sprints Sprints.Model


type PageState
    = Loaded Page
    | TransitioningFrom Page


type alias Model =
    { session : Session
    , pageState : PageState
    }


initialPage : Page
initialPage =
    Blank



-- INIT


init : Value -> Location -> ( Model, Cmd Msg )
init json location =
    setRoute (Route.fromLocation location)
        { pageState = Loaded initialPage
        , session = Session.decodeFromJson json
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    pageSubscriptions (getPage model.pageState)


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page

        TransitioningFrom page ->
            page


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Backlog subModel ->
            subModel
                |> Backlog.subscriptions
                |> Sub.map BacklogMsg

        _ ->
            Sub.none



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | BacklogLoaded (Result PageLoadError Backlog.Model)
    | SprintsLoaded (Result PageLoadError Sprints.Model)
    | BacklogMsg Backlog.Msg
    | SprintsMsg Sprints.Msg


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        transition toMsg task =
            { model | pageState = TransitioningFrom (getPage model.pageState) }
                => Task.attempt toMsg task

        errored =
            pageErrored model
    in
        case maybeRoute of
            Nothing ->
                { model | pageState = Loaded NotFound } => Cmd.none

            Just Route.Backlog ->
                transition BacklogLoaded (Backlog.init model.session)

            Just Route.Sprints ->
                transition SprintsLoaded (Sprints.init model.session)


pageErrored : Model -> ActivePage -> String -> ( Model, Cmd msg )
pageErrored model activePage errorMessage =
    let
        error =
            Errored.pageLoadError activePage errorMessage
    in
        { model | pageState = Loaded (Errored error) } => Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage (getPage model.pageState) msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        session =
            model.session

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = Loaded (toModel newModel) }, Cmd.map toMsg newCmd )

        errored =
            pageErrored model
    in
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( BacklogLoaded (Ok subModel), _ ) ->
                { model | pageState = Loaded (Backlog subModel) } => Cmd.none

            ( BacklogLoaded (Err error), _ ) ->
                { model | pageState = Loaded (Errored error) } => Cmd.none

            ( SprintsLoaded (Ok subModel), _ ) ->
                { model | pageState = Loaded (Sprints subModel) } => Cmd.none

            ( SprintsLoaded (Err error), _ ) ->
                { model | pageState = Loaded (Errored error) } => Cmd.none

            ( BacklogMsg subMsg, Backlog subModel ) ->
                toPage Backlog BacklogMsg (Backlog.update session) subMsg subModel

            ( SprintsMsg subMsg, Sprints subModel ) ->
                toPage Sprints SprintsMsg (Sprints.update session) subMsg subModel

            ( _, NotFound ) ->
                -- Disregard incoming messages when we're on the
                -- NotFound page.
                model => Cmd.none

            ( _, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                model => Cmd.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.session False page

        TransitioningFrom page ->
            viewPage model.session True page


viewPage : Session -> Bool -> Page -> Html Msg
viewPage session isLoading page =
    let
        frame =
            Page.frame isLoading session
    in
        case page of
            NotFound ->
                NotFound.view session
                    |> frame Page.Other

            Blank ->
                -- This is for the very intiial page load, while we are loading
                -- data via HTTP. We could also render a spinner here.
                Html.text ""
                    |> frame Page.Other

            Errored subModel ->
                Errored.view session subModel
                    |> frame Page.Other

            Backlog subModel ->
                Backlog.view session subModel
                    |> frame Page.Backlog
                    |> Html.map BacklogMsg

            Sprints subModel ->
                Sprints.view session subModel
                    |> frame Page.Sprints
                    |> Html.map SprintsMsg
