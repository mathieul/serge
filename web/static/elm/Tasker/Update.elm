module Tasker.Update exposing (update)

import Tasker.Model exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UrlChange location ->
            model ! []

        UpdateCurrentTask label ->
            { model | currentTask = label } ! []

        AddCurrentTask ->
            let
                tasks =
                    model.currentTask :: model.tasks
            in
                { model | tasks = tasks, currentTask = "" } ! []

        FetchTasks (Ok response) ->
            let
                _ =
                    Debug.log "FetchTasks Ok" response
            in
                model ! []

        FetchTasks (Err error) ->
            let
                _ =
                    Debug.log "FetchTasks Err" error
            in
                model ! []
