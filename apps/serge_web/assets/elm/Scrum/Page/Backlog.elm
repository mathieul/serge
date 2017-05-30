module Scrum.Page.Backlog exposing (view, update, Model, Msg, init, subscriptions)

import Dict exposing (Dict)
import Html exposing (Html, div, text, h2, i)
import Html.Attributes exposing (class, value, selected)
import Html.Events exposing (onClick)
import Task exposing (Task)
import Bootstrap.Button as Button
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Table as Table
import GraphQL.Request.Builder as B
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import Scrum.Views.Page as Page
import Scrum.Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Scrum.Data.Session as Session exposing (Session, AppMessage(MessageError), setMessage)
import Scrum.Data.Team as Team exposing (Team)
import Scrum.Data.User as User exposing (User)
import Scrum.Data.Story as Story exposing (Story, StoryId)
import Scrum.Data.Api as Api
import Scrum.Misc exposing ((=>))


type alias Model =
    { mainDropState : Dropdown.State
    , dropStates : Dict StoryId Dropdown.State
    , stories : List Story
    , storyForms : Dict StoryId StoryVariables
    }


type alias StoryVariables =
    { teamId : String
    , devId : Maybe String
    , pmId : Maybe String
    , sort : Float
    , epic : Maybe String
    , points : Int
    , description : String
    }


initialModel : Session -> List Story -> Model
initialModel session stories =
    let
        insertState story dict =
            Dict.insert story.id Dropdown.initialState dict

        dropStates =
            List.foldl insertState Dict.empty stories

        insertVariable story dict =
            Dict.insert story.id (storyToVariables session story) dict
    in
        { mainDropState = Dropdown.initialState
        , dropStates = dropStates
        , stories = List.sortBy .sort stories
        , storyForms = List.foldl insertVariable Dict.empty stories
        }


init : Session -> Task PageLoadError Model
init session =
    session.team.id
        |> fetchStoriesRequest
        |> Api.sendQueryRequest
        |> Api.handleError Page.Backlog
        |> Task.map (initialModel session)



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        subs =
            Dict.toList model.dropStates
                |> List.map (\( storyId, state ) -> Dropdown.subscriptions state (DropMsg storyId))

        mainSub =
            Dropdown.subscriptions model.mainDropState MainDropMsg
    in
        Sub.batch (mainSub :: subs)



-- UPDATE --


type Msg
    = MainDropMsg Dropdown.State
    | DropMsg StoryId Dropdown.State
    | AddBlankStory
    | CreateStory (Result GraphQLClient.Error Story)
    | EpicValueChange StoryId String


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        MainDropMsg state ->
            { model | mainDropState = state } => Cmd.none

        DropMsg storyId state ->
            { model | dropStates = Dict.insert storyId state model.dropStates } => Cmd.none

        AddBlankStory ->
            let
                vars =
                    storyToVariables session <| Story.newStory model.stories

                cmd =
                    createStoryRequest vars
                        |> Api.sendMutationRequest
                        |> Task.attempt CreateStory
            in
                model => cmd

        CreateStory (Ok story) ->
            { model | stories = story :: model.stories } => Cmd.none

        CreateStory (Err error) ->
            let
                message =
                    Api.graphQLErrorToMessage "Creating the story failed" error

                _ =
                    Debug.log "ERROR" message
            in
                model => Cmd.none

        EpicValueChange storyId value ->
            let
                updateValue maybeFound =
                    Maybe.map (\found -> { found | epic = Just value }) maybeFound

                storyForms =
                    Dict.update storyId updateValue model.storyForms
            in
                { model | storyForms = storyForms } => Cmd.none



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

        tableRowWithModelAndTeam =
            tableRow model session.team
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
                        , Table.th [ col_md ] [ text "Epic" ]
                        , Table.th [] [ text "Story" ]
                        , Table.th [ col_sm ] [ text "Points" ]
                        , Table.th [ col_xs ] [ mainActionSelector model ]
                        ]
                , tbody =
                    Table.tbody []
                        (List.indexedMap tableRowWithModelAndTeam model.stories)
                }
            ]


mainActionSelector : Model -> Html Msg
mainActionSelector model =
    Dropdown.dropdown
        model.mainDropState
        { options = [ Dropdown.alignMenuRight ]
        , toggleMsg = MainDropMsg
        , toggleButton =
            Dropdown.toggle
                [ Button.outlineSecondary
                , Button.small
                ]
                [ i [ class "fa fa-ellipsis-v" ] [] ]
        , items =
            [ Dropdown.buttonItem
                [ onClick AddBlankStory ]
                [ i [ class "fa fa-plus" ] []
                , text " Add story"
                ]
            ]
        }


tableRow : Model -> Team -> Int -> Story -> Table.Row Msg
tableRow model team index story =
    let
        userName user =
            user
                |> Maybe.map .name
                |> Maybe.withDefault "-"

        devId =
            case story.dev of
                Just dev ->
                    toString dev.id

                Nothing ->
                    ""
    in
        Table.tr []
            [ Table.td [] [ text <| toString (index + 1) ]
            , Table.td [] [ userSelector team.members story.dev ]
            , Table.td [] [ userSelector team.members story.pm ]
            , Table.td []
                [ Input.text
                    [ Input.small
                    , Input.value (toString story.sort)
                    ]
                ]
            , Table.td []
                [ Input.text
                    [ Input.small
                    , Input.value (Maybe.withDefault "" story.epic)
                    , Input.onInput <| EpicValueChange story.id
                    ]
                ]
            , Table.td []
                [ Input.text
                    [ Input.small
                    , Input.value story.description
                    ]
                ]
            , Table.td []
                [ Input.number
                    [ Input.small
                    , Input.value (toString story.points)
                    ]
                ]
            , Table.td [] [ actionSelector model story ]
            ]


userSelector : List User -> Maybe User -> Html Msg
userSelector users selectedUser =
    let
        makeOption user =
            Select.item
                [ value <| toString user.id
                , selected <| selectedUser == Just user
                ]
                [ text user.name ]

        options =
            List.map makeOption users
    in
        Select.select
            [ Select.small ]
            (Select.item [ value "" ] [ text "None" ] :: options)


actionSelector : Model -> Story -> Html Msg
actionSelector model story =
    let
        dropState =
            Dict.get story.id model.dropStates
                |> Maybe.withDefault Dropdown.initialState
    in
        Dropdown.dropdown
            dropState
            { options = [ Dropdown.alignMenuRight ]
            , toggleMsg = DropMsg story.id
            , toggleButton =
                Dropdown.toggle
                    [ Button.outlineInfo
                    , Button.small
                    ]
                    [ i [ class "fa fa-ellipsis-v" ] [] ]
            , items =
                [ Dropdown.buttonItem [ class "text-warning" ]
                    [ i [ class "fa fa-arrow-up" ] []
                    , text " Insert before"
                    ]
                , Dropdown.buttonItem [ class "text-success" ]
                    [ i [ class "fa fa-arrow-down" ] []
                    , text " Insert after"
                    ]
                ]
            }



-- FETCH STORIES


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



-- CREATE STORY


storyToVariables : Session -> Story -> StoryVariables
storyToVariables session story =
    { teamId = session.team.id
    , devId = Maybe.map .id story.dev
    , pmId = Maybe.map .id story.pm
    , sort = story.sort
    , epic = story.epic
    , points = story.points
    , description = story.description
    }


createStoryQuery : B.Document B.Mutation Story StoryVariables
createStoryQuery =
    let
        variables =
            [ ( "teamId", Arg.variable (Var.required "teamId" .teamId Var.id) )
            , ( "devId", Arg.variable (Var.required "devId" .devId (Var.nullable Var.id)) )
            , ( "pmId", Arg.variable (Var.required "pmId" .pmId (Var.nullable Var.id)) )
            , ( "sort", Arg.variable (Var.required "sort" .sort Var.float) )
            , ( "epic", Arg.variable (Var.required "epic" .epic (Var.nullable Var.string)) )
            , ( "points", Arg.variable (Var.required "points" .points Var.int) )
            , ( "description", Arg.variable (Var.required "description" .description Var.string) )
            ]
    in
        Story.story
            |> B.field "createStory" variables
            |> B.extract
            |> B.mutationDocument


createStoryRequest : StoryVariables -> B.Request B.Mutation Story
createStoryRequest variables =
    createStoryQuery
        |> B.request variables
