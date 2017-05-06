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
    | MovingInProgress
    | TaskItem
    | PeriodBadge
    | DropTarget
    | DropTargetHighlight


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
        , class TaskItem
            [ hover [ backgroundColor (hex "f1f1f1") ]
            , withClass MovingInProgress
                [ hover [ backgroundColor transparent ] ]
            ]
        , class PeriodBadge
            [ display inlineBlock
            , width (px 75)
            ]
        , li
            [ withClass DropTarget
                [ backgroundColor (hex "c7e6c7")
                , borderColor (hex "a3d7a3")
                , borderRadius (px 5) |> important
                , color (hex "959")
                , fontSize (px 10)
                , marginBottom (px 3)
                , marginLeft (pct 50)
                , marginTop (px 3)
                , paddingBottom (px 5)
                , paddingTop (px 5)
                , width (pct 50)
                , withClass DropTargetHighlight
                    [ backgroundColor (hex "a8d6fe")
                    , borderColor (hex "75bffe")
                    ]
                ]
            ]
        ]
