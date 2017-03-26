module TaskerCss exposing (..)

import Css exposing (..)


type CssClasses
    = FaEmpty
    | Py15
    | TaskControl
    | TextGhost
    | BadgeCompleted


css : Stylesheet
css =
    stylesheet
        [ class FaEmpty
            [ width (px 16) ]
        , class Py15
            [ paddingTop (em 0.4)
            , paddingBottom (em 0.4)
            ]
        , class TaskControl
            [ width (px 100)
            , textAlign right
            ]
        , class TextGhost
            [ color (hex "999")
            , hover
                [ color (hex "999") ]
            ]
        , selector "sup"
            [ verticalAlign super
            , withClass BadgeCompleted
                [ fontSize (px 8) ]
            ]
        ]
