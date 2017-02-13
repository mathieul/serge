module Tasker.Views.Main exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Tasker.Model exposing (Model, Msg(..), Route(..))
import Tasker.Views.Home as HomeView


view : Model -> Html Msg
view model =
    let
        view =
            case model.route of
                HomeRoute ->
                    HomeView.view model

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
