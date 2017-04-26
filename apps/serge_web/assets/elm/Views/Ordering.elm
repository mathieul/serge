module Views.Ordering exposing (view)

import Dict exposing (Dict)
import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class, classList)
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.ListGroup as ListGroup
import Html5.DragDrop as DragDrop


-- LOCAL IMPORTS

import Model exposing (..)
import Views.TaskListCard exposing (datePeriodConfig)


view : Model -> Html Msg
view model =
    let
        taskEditorList =
            List.filter (not << .completed) model.taskEditors

        dragged =
            DragDrop.getDragId model.dragDrop

        hovered =
            case DragDrop.getDropId model.dragDrop of
                Just (MoveTaskBefore task) ->
                    Just task

                Just (MoveTaskAfter task) ->
                    Just task

                Nothing ->
                    Nothing

        dropTargetAttrs : MoveTaskRequest -> TaskEditor -> List (H.Attribute Msg)
        dropTargetAttrs request editor =
            if Just editor == dragged then
                [ class "hidden-xs-up" ]
            else
                List.concat
                    [ [ class "DropTarget align-items-center justify-content-between"
                      , classList [ ( "DropTargetHighlight", hovered == Just editor.task ) ]
                      ]
                    , DragDrop.droppable DragDropMsg request
                    ]

        dropTargetListForDay : ( String, List TaskEditor ) -> Html Msg
        dropTargetListForDay ( day, editors ) =
            let
                dropTarget request editor =
                    ListGroup.li
                        [ ListGroup.attrs <| dropTargetAttrs request editor ]
                        [ div []
                            [ H.i [ class "fa fa-chevron-right" ] []
                            , H.i [ class "fa fa-chevron-right" ] []
                            , H.i [ class "fa fa-chevron-right" ] []
                            ]
                        , div []
                            [ H.i [ class "fa fa-chevron-left" ] []
                            , H.i [ class "fa fa-chevron-left" ] []
                            , H.i [ class "fa fa-chevron-left" ] []
                            ]
                        ]

                taskReference editor =
                    ListGroup.li

                makeDropTargets before editors =
                    dropTarget (MoveTaskBefore before.task) before
                        :: List.concatMap
                            (\editor ->
                                [ taskItem False editor
                                , dropTarget (MoveTaskAfter editor.task) editor
                                ]
                            )
                            editors
            in
                div []
                    [ H.h6 [ class "text-muted" ] [ text day ]
                    , ListGroup.ul <|
                        case List.reverse editors of
                            first :: remainder ->
                                makeDropTargets first (first :: remainder)

                            [] ->
                                []
                    ]

        taskListByDay =
            taskEditorList
                |> List.map (taskItem True)
                |> ListGroup.ul

        dropTargetListByDay =
            taskEditorList
                |> taskEditorsByDay
                |> Dict.toList
                |> List.map dropTargetListForDay
                |> div []
    in
        Card.config [ Card.attrs [ class "mt-3" ] ]
            |> Card.block []
                [ Card.custom <|
                    div []
                        [ H.h3 [] [ text "Order Tasks" ]
                        , H.p [ class "mt-2 mb-4" ]
                            [ text "Drag and drop tasks to re-order them." ]
                        , case dragged of
                            Just _ ->
                                dropTargetListByDay

                            Nothing ->
                                taskListByDay
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


taskItem : Bool -> TaskEditor -> ListGroup.Item Msg
taskItem isDropTarget editor =
    let
        ( periodLabel, periodBadge ) =
            datePeriodConfig editor.period

        attrs =
            List.concat
                [ if isDropTarget then
                    DragDrop.draggable DragDropMsg editor
                  else
                    [ class "UnselectableTask" ]
                , [ class "justify-content-start" ]
                ]
    in
        ListGroup.li [ ListGroup.attrs attrs ]
            [ H.span
                [ class <| "PeriodBadge badge mr-3 " ++ periodBadge ]
                [ text periodLabel ]
            , text editor.task.label
            , Badge.pill [ class "ml-auto" ] [ H.i [ class "fa fa-arrows SortHandle" ] [] ]
            ]
