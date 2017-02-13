module Tasker.Views.Home exposing (view)

import Html exposing (Html, div, h2, p, text)
import Html.Attributes exposing (class)
import Tasker.Model exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div [ class "mt-5" ]
        [ h2 []
            [ text "Home Route" ]
        , p []
            [ text "Authenticated. Now let's implement something...." ]
        ]
