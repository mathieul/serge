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
import Scrum.Misc exposing (viewIf)


type ActivePage
    = Other
    | Backlog
    | Sprints


frame : Bool -> ActivePage -> Html msg -> Html msg
frame isLoading page content =
    Grid.containerFluid []
        [ div [ class "mt-3" ] [ viewHeader page isLoading ]
        , div [ class "mt-3" ] [ content ]
        ]


viewHeader : ActivePage -> Bool -> Html msg
viewHeader page isLoading =
    Grid.row []
        [ Grid.col [ Col.xs3 ]
            [ Html.h2 [ class "my-3" ] [ text "TODO" ] ]
        , Grid.col [ Col.xs3 ]
            [ ul
                [ class "nav nav-pills my-3" ]
              <|
                lazy2 viewIf isLoading spinner
                    :: [ pillLink (page == Backlog) Route.Backlog "Backlog"
                       , pillLink (page == Sprints) Route.Sprints "Sprints"
                       ]
            ]
        , Grid.col []
            [ div [ class "my-3" ]
                [ Alert.success [ text "This will be where notices and errors will be displayed." ] ]
            ]
        ]


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
