module Tasker.Views.Home exposing (view)

import Html exposing (Html, div, h2, p, text)
import Tasker.Model exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div []
        [ h2 []
            [ text "Home Route" ]
        , p []
            [ text "Authenticated. Now let's implement something...." ]
        ]
