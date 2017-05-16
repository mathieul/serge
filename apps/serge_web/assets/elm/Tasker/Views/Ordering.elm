module Tasker.Views.Ordering exposing (view)

import Dict exposing (Dict)
import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class, classList)
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.ListGroup as ListGroup


-- LOCAL IMPORTS

import Tasker.Model exposing (..)
import Tasker.Views.TaskListCard exposing (datePeriodConfig)


view : Model -> Html Msg
view model =
    let
        taskEditorList =
            List.filter (not << .completed) model.taskEditors

        taskListByDay =
            taskEditorList
                |> List.map (taskItem model.orderingTaskEditor)
                |> ListGroup.ul
    in
        Card.config [ Card.attrs [ class "mt-3" ] ]
            |> Card.block []
                [ Card.custom <|
                    div []
                        [ H.h3 [] [ text "Order Tasks" ]
                        , H.p [ class "mt-2 mb-4" ]
                            [ text "Drag and drop tasks to re-order them." ]
                        , taskListByDay
                        ]
                ]
            |> Card.footer []
                [ div [ class "col pr-3 text-right" ]
                    [ Button.button
                        [ Button.primary
                        , Button.small
                        , Button.onClick HideOrdering
                        ]
                        [ text "Done" ]
                    ]
                ]
            |> Card.view


taskEditorsByDay : List TaskEditor -> Dict String (List TaskEditor)
taskEditorsByDay taskList =
    let
        addOrAppend editor found =
            case found of
                Just list ->
                    Just (editor :: list)

                Nothing ->
                    Just [ editor ]
    in
        List.foldl
            (\editor dict ->
                case editor.task.scheduledOn of
                    Just scheduledOn ->
                        Dict.update scheduledOn (addOrAppend editor) dict

                    Nothing ->
                        Dict.update "Later" (addOrAppend editor) dict
            )
            Dict.empty
            taskList


taskItem : Maybe TaskEditor -> TaskEditor -> ListGroup.Item Msg
taskItem orderingEditor editor =
    let
        ( periodLabel, periodBadge ) =
            datePeriodConfig editor.period

        ( attrs, actions ) =
            case orderingEditor of
                Just source ->
                    if source == editor then
                        ( [ class "justify-content-start TaskItem MovingInProgress" ]
                        , [ ButtonGroup.button
                                [ Button.secondary
                                , Button.onClick StopOrdering
                                ]
                                [ H.i [ class "fa fa-ban" ] []
                                , text " Cancel"
                                ]
                          ]
                        )
                    else
                        ( [ class "justify-content-start TaskItem" ]
                        , [ ButtonGroup.button
                                [ Button.warning
                                , Button.onClick (ExecuteMoveRequest <| MoveTaskBefore editor.task)
                                ]
                                [ H.i [ class "fa fa-arrow-up" ] []
                                , text " Before"
                                ]
                          , ButtonGroup.button
                                [ Button.success
                                , Button.onClick (ExecuteMoveRequest <| MoveTaskAfter editor.task)
                                ]
                                [ H.i [ class "fa fa-arrow-down" ] []
                                , text " After"
                                ]
                          ]
                        )

                Nothing ->
                    ( [ class "justify-content-start TaskItem" ]
                    , [ ButtonGroup.button
                            [ Button.info
                            , Button.attrs [ class "ml-auto" ]
                            , Button.onClick (StartOrdering editor)
                            ]
                            [ H.i [ class "fa fa-arrows" ] []
                            , text " Move"
                            ]
                      ]
                    )
    in
        ListGroup.li [ ListGroup.attrs attrs ]
            [ H.span
                [ class <| "PeriodBadge badge mr-3 " ++ periodBadge ]
                [ text periodLabel ]
            , text editor.task.label
            , ButtonGroup.buttonGroup
                [ ButtonGroup.attrs [ class "ml-auto" ]
                , ButtonGroup.small
                ]
                actions
            ]
