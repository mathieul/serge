module Scrum.Page.Backlog exposing (view, update, Model, Msg, init, subscriptions)

import Html exposing (Html, div, text, h2, i)
import Html.Attributes exposing (class)
import Task exposing (Task)
import Bootstrap.Button as Button
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Table as Table
import GraphQL.Request.Builder as B
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import Scrum.Views.Page as Page
import Scrum.Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Scrum.Data.Session as Session exposing (Session)
import Scrum.Data.Story as Story exposing (Story)
import Scrum.Data.Api as Api
import Scrum.Misc exposing ((=>))


type alias Model =
    { mainDropState : Dropdown.State
    , stories : List Story
    }


initialModel : List Story -> Model
initialModel stories =
    { mainDropState = Dropdown.initialState
    , stories = stories
    }


init : Session -> Task PageLoadError Model
init session =
    session.team.id
        |> toString
        |> fetchStoriesRequest
        |> Api.sendQueryRequest
        |> handleError
        |> Task.map initialModel


fetchStoriesQuery : B.Document B.Query (List Story) { vars | teamId : String }
fetchStoriesQuery =
    let
        teamIDVar =
            Var.required "teamId" .teamId Var.id

        variables =
            [ ( "teamId", Arg.variable teamIDVar ) ]
    in
        B.field "stories" variables (B.list Story.story)
            |> B.extract
            |> B.queryDocument


fetchStoriesRequest : String -> B.Request B.Query (List Story)
fetchStoriesRequest teamId =
    fetchStoriesQuery
        |> B.request { teamId = teamId }


handleError : Task GraphQLClient.Error a -> Task PageLoadError a
handleError task =
    let
        handleLoadError error =
            let
                _ =
                    Debug.log "handleError - error=" error
            in
                pageLoadError Page.Backlog "Backlog is currently unavailable."
    in
        Task.mapError handleLoadError task



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Dropdown.subscriptions model.mainDropState MainDropMsg



-- UPDATE --


type Msg
    = MainDropMsg Dropdown.State


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        MainDropMsg state ->
            { model | mainDropState = state } => Cmd.none



-- VIEW --


view : Session -> Model -> Html Msg
view session model =
    let
        col_xs =
            Table.cellAttr <| class "ColXs"

        col_sm =
            Table.cellAttr <| class "ColSm"

        col_md =
            Table.cellAttr <| class "ColMd"
    in
        div []
            [ h2 [ class "mb-4" ] [ text "Product Backlog" ]
            , Table.table
                { options = [ Table.striped, Table.hover, Table.bordered ]
                , thead =
                    Table.simpleThead
                        [ Table.th [ col_xs ] [ text "#" ]
                        , Table.th [ col_md ] [ text "Dev" ]
                        , Table.th [ col_md ] [ text "PM" ]
                        , Table.th [ col_sm ] [ text "Sort" ]
                        , Table.th [ col_sm ] [ text "Epic" ]
                        , Table.th [] [ text "Story" ]
                        , Table.th [ col_sm ] [ text "Points" ]
                        , Table.th [ col_xs ] (mainActionSelector model)
                        ]
                , tbody = Table.tbody [] (List.indexedMap tableRow model.stories)
                }
            ]


mainActionSelector : Model -> List (Html Msg)
mainActionSelector model =
    [ Dropdown.dropdown
        model.mainDropState
        { options = [ Dropdown.alignMenuRight ]
        , toggleMsg = MainDropMsg
        , toggleButton = Dropdown.toggle [ Button.outlinePrimary ] [ i [ class "fa fa-ellipsis-v" ] [] ]
        , items =
            [ Dropdown.buttonItem [] [ text "Item 1" ]
            , Dropdown.buttonItem [] [ text "Item 2" ]
            ]
        }
    ]


tableRow : Int -> Story -> Table.Row Msg
tableRow index story =
    let
        userName user =
            user
                |> Maybe.map .name
                |> Maybe.withDefault "-"
    in
        Table.tr []
            [ Table.td [] [ text <| toString (index + 1) ]
            , Table.td [] [ text <| userName story.dev ]
            , Table.td [] [ text <| userName story.pm ]
            , Table.td [] [ text <| toString story.sort ]
            , Table.td [] [ text <| Maybe.withDefault "-" story.epic ]
            , Table.td [] [ text story.description ]
            , Table.td [] [ text <| toString story.points ]
            , Table.td [] [ i [ class "fa fa-ellipsis-v" ] [] ]
            ]
