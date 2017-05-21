module Scrum.Page.NotFound exposing (view)

import Html exposing (Html, text, p)
import Bootstrap.Alert as Alert


-- LOCAL IMPORTS

import Scrum.Data.Session as Session exposing (Session)


-- VIEW --


view : Session -> Html msg
view session =
    Alert.warning
        [ Alert.h4 [] [ text "Page not found" ]
        , p [] [ text "Oops, this page doesn't exist." ]
        ]
