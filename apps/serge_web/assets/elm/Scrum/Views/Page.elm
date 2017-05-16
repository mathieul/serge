module Scrum.Views.Page exposing (frame, ActivePage(..))

{-| The frame around a typical page - that is, the header and footer.
-}

import Html exposing (..)
import Html.Attributes exposing (class, classList)
import Html.Lazy exposing (lazy2)


-- LOCAL IMPORTS

import Scrum.Route as Route exposing (Route)
import Scrum.Misc exposing (viewIf)
import Scrum.Views.Spinner exposing (spinner)


type ActivePage
    = Other
    | Backlog
    | Sprints


frame : Bool -> ActivePage -> Html msg -> Html msg
frame isLoading page content =
    div []
        [ viewHeader page isLoading
        , content
        , div [] [ text "Footer" ]
        ]


viewHeader : ActivePage -> Bool -> Html msg
viewHeader page isLoading =
    nav [ class "navbar navbar-light" ]
        [ div [ class "container" ]
            [ a [ class "navbar-brand", Route.href Route.Backlog ] [ text "Backlog" ]
            , ul [ class "nav navbar-nav pull-xs-right" ] <|
                lazy2 viewIf isLoading spinner
                    :: [ navbarLink (page == Backlog) Route.Backlog [ text "Backlog" ]
                       , navbarLink (page == Sprints) Route.Sprints [ text "Sprints" ]
                       ]
            ]
        ]


navbarLink : Bool -> Route -> List (Html msg) -> Html msg
navbarLink isActive route linkContent =
    li [ classList [ ( "nav-item", True ), ( "active", isActive ) ] ]
        [ a [ class "nav-link", Route.href route ] linkContent ]
