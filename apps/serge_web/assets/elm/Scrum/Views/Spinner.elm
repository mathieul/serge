module Scrum.Views.Spinner exposing (spinner)

import Html exposing (Html, Attribute, li, i, span, text)
import Html.Attributes exposing (class)


spinner : Html msg
spinner =
    li []
        [ i [ class "fa fa-refresh fa-spin fa-3x fa-fw" ] []
        , span [ class "sr-only" ] [ text "Loading ..." ]
        ]
