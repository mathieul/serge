module Scrum.Page.NotFound exposing (view)

import Html exposing (..)
import Scrum.Data.Session as Session exposing (Session)


-- VIEW --


view : Session -> Html msg
view session =
    div [] [ text "Not Found page" ]
