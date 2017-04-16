module TaskerCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (li)


type CssClasses
    = FaEmpty
    | Py15
    | TaskControl
    | TextGhost
    | BadgeCompleted
    | SortButton
    | SortHandle
    | UnselectableTask
    | HoveredUnselectableTask
    | HoveredTask
    | PeriodBadge
    | DropTarget


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
        , class SortButton
            [ position absolute
            , right (px 40)
            ]
        , class SortHandle
            [ fontSize (px 16) ]
        , class UnselectableTask
            [ opacity (num 0.4) ]
        , class HoveredUnselectableTask
            [ backgroundColor (hex "f2dede")
            , color (hex "a94442")
            , opacity (num 0.4)
            ]
        , class HoveredTask
            [ backgroundColor (hex "dff0d8")
            , color (hex "3c763d")
            ]
        , class PeriodBadge
            [ display inlineBlock
            , width (px 75)
            ]
        , li
            [ withClass DropTarget
                [ backgroundColor (hex "c7e6c7")
                , borderStyle none
                , borderRadius (px 10) |> important
                , color (hex "959")
                , marginBottom (px 3)
                , marginLeft (pct 25)
                , marginTop (px 3)
                , paddingBottom (px 5)
                , paddingTop (px 5)
                , width (pct 75)
                ]
            ]
        ]
