module Tasker.Views.Home exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, href, type_, placeholder)
import Tasker.Model exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div [ class "mt-3" ]
        [ h2 []
            [ text "Tasker" ]
        , div [ class "card mt-3" ]
            [ div [ class "card-header" ]
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
            , div [ class "card-block" ]
                [ h4 [ class "card-title" ] [ text "Tasks" ]
                , form []
                    [ div [ class "form-group row" ]
                        [ div [ class "col-sm-10" ]
                            [ input
                                [ type_ "text"
                                , class "form-control form-control-lg"
                                , placeholder "Enter new task..."
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
                , div [ class "card w-50" ]
                    [ ul [ class "list-group list-group-flush" ]
                        [ li [ class "list-group-item" ]
                            [ text "allo la terre???" ]
                        , li [ class "list-group-item" ]
                            [ text "ici londres" ]
                        ]
                    ]
                ]
            , div [ class "card-footer text-muted" ]
                [ small [] [ text "todo" ] ]
            ]
        ]
