port module Tasker exposing (main)

import Navigation
import Tasker.Model exposing (Model, Msg(UrlChange), Route, AppConfig)
import Tasker.Init exposing (ConfigFromJs, init)
import Tasker.Update exposing (update)
import Tasker.Views.Main exposing (view)


main : Program ConfigFromJs Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = update
        , subscriptions = (\_ -> Sub.none)
        , view = view
        }
