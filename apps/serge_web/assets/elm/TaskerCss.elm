module TaskerCss exposing (..)

import Css exposing (..)
import Css.Elements as E exposing (a)


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
    | NavBrand
    | ColXs
    | ColSm
    | ColMd


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
        , a
            [ withClass NavBrand
                [ pseudoClass "not([href]):not([tabindex])"
                    [ color (hex "f0ad4e")
                    , hover [ color (hex "f0ad4e") ]
                    ]
                , children
                    [ E.small [ fontSize (px 12) ] ]
                ]
            ]
        , class ColXs [ width (px 40) ]
        , class ColSm [ width (px 80) ]
        , class ColMd [ width (px 160) ]
        ]
