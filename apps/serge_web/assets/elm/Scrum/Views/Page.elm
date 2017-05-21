module Scrum.Views.Page exposing (frame, ActivePage(..))

{-| The frame around a typical page - that is, the header and footer.
-}

import Html exposing (Html, div, text, ul, li, a, i, span)
import Html.Attributes exposing (class, classList, href)
import Html.Lazy exposing (lazy2)
import Bootstrap.Alert as Alert
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col


-- LOCAL IMPORTS

import Scrum.Route as Route exposing (Route)
import Scrum.Data.Session as Session exposing (Session, AppMessage(..))
import Scrum.Misc exposing (viewIf)


type ActivePage
    = Other
    | Backlog
    | Sprints


frame : Bool -> Session -> ActivePage -> Html msg -> Html msg
frame isLoading session page content =
    Grid.containerFluid []
        [ div [ class "mt-3" ] [ viewHeader page isLoading session ]
        , div [ class "mt-3" ] [ content ]
        ]


viewHeader : ActivePage -> Bool -> Session -> Html msg
viewHeader page isLoading session =
    Grid.row []
        [ Grid.col [ Col.sm3 ]
            [ ul
                [ class "nav nav-pills my-3" ]
              <|
                lazy2 viewIf isLoading spinner
                    :: [ pillLink (page == Backlog) Route.Backlog "Backlog"
                       , pillLink (page == Sprints) Route.Sprints "Sprints"
                       ]
            ]
        , Grid.col [ Col.sm3 ]
            [ Html.h2 [ class "my-3" ] [ text session.team.name ] ]
        , Grid.col []
            [ div [ class "my-3" ] (messageAlert session) ]
        ]


messageAlert : Session -> List (Html msg)
messageAlert session =
    case session.message of
        MessageNone ->
            []

        MessageSuccess content ->
            [ Alert.success [ text content ] ]

        MessageNotice content ->
            [ Alert.info [ text content ] ]

        MessageError content ->
            [ Alert.danger [ text content ] ]


pillLink : Bool -> Route -> String -> Html msg
pillLink isActive route label =
    li [ class "nav-item" ]
        [ a
            [ classList [ ( "nav-link", True ), ( "active", isActive ) ]
            , Route.href route
            ]
            [ text label ]
        ]


spinner : Html msg
spinner =
    li [ class "nav-item text-success mr-3" ]
        [ i [ class "fa fa-refresh fa-spin fa-3x fa-fw" ] []
        , span [ class "sr-only" ] [ text "Loading ..." ]
        ]
