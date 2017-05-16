module Scrum.Page.Sprints exposing (view, update, Model, Msg, init)

import Html exposing (..)
import Task exposing (Task)


-- LOCAL IMPORTS

import Scrum.Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Scrum.Data.Session as Session exposing (Session)


type alias Model =
    {}


init : Session -> Task PageLoadError Model
init session =
    Task.succeed {}



-- UPDATE --


type Msg
    = NoOp


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            model ! []



-- VIEW --


view : Session -> Model -> Html Msg
view session model =
    div [] [ text "Sprints page" ]
