module Scrum.Main exposing (main)

import Html exposing (..)
import Json.Decode as Decode exposing (Value)


-- LOCAL IMPORTS

import Scrum.Data.Session as Session exposing (Session)


-- MAIN


main : Program Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type Page
    = Blank


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


init : Value -> ( Model, Cmd Msg )
init val =
    ( { pageState = Loaded initialPage
      , session = {}
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE --


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ text "OK" ]
