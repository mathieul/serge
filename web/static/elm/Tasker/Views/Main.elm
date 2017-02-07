module Tasker.Views.Main exposing (view)

import Html exposing (Html, div, text)
import Tasker.Model exposing (Model, Msg(..), Route(..))
import Tasker.Views.Home as HomeView


view : Model -> Html Msg
view model =
    case model.route of
        HomeRoute ->
            HomeView.view model

        NotFoundRoute ->
            notFoundView


notFoundView : Html msg
notFoundView =
    div [] [ text "NOT FOUND ROUTE" ]
