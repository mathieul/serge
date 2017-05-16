module Tasker.Views.TaskListCard exposing (view, datePeriodConfig)

import Dict exposing (Dict)
import String.Extra
import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class, classList)
import Html.Events exposing (onClick, onSubmit, onInput, onDoubleClick)
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Dropdown as Dropdown


-- LOCAL IMPORTS

import Tasker.Model exposing (..)
import Tasker.StoryTask as StoryTask exposing (StoryTask)


view : Model -> Html Msg
view model =
    let
        notCompletedBeforeToday task =
            case task.completedOn of
                Just completedOn ->
                    completedOn >= model.context.today

                Nothing ->
                    True

        selectedTasks =
            tasksForCurrentTaskPeriod model
    in
        Card.config [ Card.attrs [ class "mt-3" ] ]
            |> Card.header [] [ taskSelectionTabs model ]
            |> Card.block []
                [ Card.custom <| taskList model selectedTasks ]
            |> Card.footer [] [ taskCompletionInfo selectedTasks model ]
            |> Card.view


taskSelectionTabs : Model -> Html Msg
taskSelectionTabs model =
    let
        aTab schedule =
            H.li [ class "nav-item" ]
                [ H.a
                    [ class "nav-link"
                    , classList [ ( "active", model.datePeriod == schedule ) ]
                    , A.href "#"
                    , onClick (ChangeDatePeriod schedule)
                    ]
                    [ text <| datePeriodLabel schedule ]
                ]

        tabPeriods =
            if model.showYesterday then
                [ Yesterday, Today, Tomorrow, Later ]
            else
                [ Today, Tomorrow, Later ]
    in
        H.ul
            [ class "nav nav-tabs card-header-tabs" ]
            (List.map aTab tabPeriods)


taskCompletionInfo : List TaskEditor -> Model -> Html Msg
taskCompletionInfo editors model =
    let
        countCompleted =
            List.foldl
                (\editor count ->
                    if editor.completed then
                        count + 1
                    else
                        count
                )
                0
                editors

        count =
            (List.length editors) - countCompleted

        label =
            (String.Extra.pluralize "task" "tasks" count)
                ++ " / "
                ++ (toString countCompleted)
                ++ " completed"
    in
        div [ class "row text-muted" ]
            [ div [ class "col pl-3" ]
                [ text label ]
            , div [ class "col pr-3 text-right" ]
                [ H.span []
                    [ H.label [ A.for "show-yesterday" ] [ text "show yesterday" ]
                    , text " "
                    , H.input
                        [ A.type_ "checkbox"
                        , A.id "show-yesterday"
                        , A.checked model.showYesterday
                        , class "mr-4"
                        , onClick ToggleShowYesterday
                        ]
                        []
                    ]
                , H.span [ class "mr-4" ]
                    [ H.label [ A.for "show-completed" ] [ text "show completed" ]
                    , text " "
                    , H.input
                        [ A.type_ "checkbox"
                        , A.id "show-completed"
                        , A.checked model.showCompleted
                        , onClick ToggleShowCompleted
                        ]
                        []
                    ]
                , Button.button
                    [ Button.primary
                    , Button.small
                    , Button.onClick ShowOrdering
                    ]
                    [ H.i [ class "fa fa-sort" ] []
                    , text " Sort"
                    ]
                ]
            ]


taskList : Model -> List TaskEditor -> Html Msg
taskList model taskEditors =
    let
        tasksToShow =
            if model.showCompleted then
                taskEditors
            else
                List.filter (not << .completed) taskEditors

        view editor =
            if editor.editing then
                taskEditorView editor
            else
                taskViewerView model editor
    in
        if List.isEmpty tasksToShow then
            div [ class "alert alert-info mt-3" ]
                [ text "No tasks found." ]
        else
            div [ class "card" ]
                [ H.ul [ class "list-group list-group-flush" ]
                    (List.map view tasksToShow)
                ]


taskViewerView : Model -> TaskEditor -> Html Msg
taskViewerView model editor =
    let
        startEditingMsg =
            UpdateEditingTask editor.task.id True editor.editingLabel

        completedExponent task =
            case task.completedOn of
                Just completedOn ->
                    H.sup [ class "badge badge-default BadgeCompleted" ]
                        [ text <| formatShortDate completedOn ]

                Nothing ->
                    H.span [] []

        label =
            if editor.completed then
                div []
                    [ H.span []
                        [ H.s [ class "text-muted" ] [ text editor.task.label ]
                        , text " "
                        , completedExponent editor.task
                        ]
                    ]
            else if editor.period == Yesterday then
                H.span [ onDoubleClick startEditingMsg ]
                    [ text editor.task.label
                    , H.i [ class "fa fa-clock-o text-danger ml-2" ] []
                    ]
            else
                H.span [ onDoubleClick startEditingMsg ]
                    [ text editor.task.label ]
    in
        H.li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between align-items-center" ]
                [ label
                , div
                    [ class "d-flex justify-content-end" ]
                    [ div [ class "btn-group" ]
                        [ taskControl model editor ]
                    ]
                ]
            ]


actionButton : Maybe String -> String -> String -> StoryTask -> Dropdown.DropdownItem Msg
actionButton date label taskLabel task =
    if label == taskLabel then
        Dropdown.buttonItem
            [ class "disabled"
            , classList [ ( "TextGhost", label == "Yesterday" ) ]
            ]
            [ H.i [ class "fa fa-arrow-right" ] []
            , text <| " " ++ label
            ]
    else
        Dropdown.buttonItem
            [ classList [ ( "TextGhost", label == "Yesterday" ) ]
            , onClick <| StoryTask.changeSchedule RequestTaskUpdate date task
            ]
            [ H.i [ class "FaEmpty" ] []
            , text <| " " ++ label
            ]


taskControl : Model -> TaskEditor -> Html Msg
taskControl model editor =
    let
        state =
            Dict.get editor.task.id model.dropdownStates
                |> Maybe.withDefault Dropdown.initialState

        completedOn =
            case model.datePeriod of
                Yesterday ->
                    Just model.context.yesterday

                _ ->
                    Just model.context.today

        completionButton =
            if editor.completed then
                Dropdown.buttonItem
                    [ onClick <| StoryTask.updateCompletedOn RequestTaskUpdate Nothing editor.task ]
                    [ H.i [ class "fa fa-square-o" ] []
                    , text " Uncomplete"
                    ]
            else
                Dropdown.buttonItem
                    [ onClick <| StoryTask.updateCompletedOn RequestTaskUpdate completedOn editor.task ]
                    [ H.i [ class "fa fa-check-square-o" ] []
                    , text " Complete"
                    ]

        buttonKind =
            if editor.completed then
                Button.secondary
            else
                Button.outlineInfo

        actionLabel =
            datePeriodLabel editor.period

        actions =
            [ completionButton
            , Dropdown.divider
            , actionButton (Just model.context.yesterday) "Yesterday" actionLabel editor.task
            , actionButton (Just model.context.today) "Today" actionLabel editor.task
            , actionButton (Just model.context.tomorrow) "Tomorrow" actionLabel editor.task
            , actionButton Nothing "Later" actionLabel editor.task
            , Dropdown.divider
            , Dropdown.buttonItem
                [ class "text-danger"
                , onClick <| ConfirmTaskDeletion editor.task.id editor.task.label
                ]
                [ text "Delete" ]
            ]
    in
        Dropdown.dropdown state
            { options = [ Dropdown.alignMenuRight ]
            , toggleMsg = DropdownMsg editor.task.id
            , toggleButton =
                Dropdown.toggle
                    [ buttonKind
                    , Button.small
                    , Button.attrs [ class "TaskControl" ]
                    ]
                    [ text actionLabel ]
            , items = actions
            }


taskEditorView : TaskEditor -> Html Msg
taskEditorView editor =
    let
        updateEditingLabelMsg editingLabel =
            UpdateEditingTask editor.task.id True editingLabel

        task =
            editor.task
    in
        H.form
            [ class "px-2 Py15"
            , onSubmit (RequestTaskUpdate { task | label = editor.editingLabel })
            ]
            [ H.input
                [ A.type_ "text"
                , A.id <| "edit-task-" ++ editor.task.id
                , class "form-control pull-left"
                , A.style [ ( "width", "80%" ) ]
                , A.value editor.editingLabel
                , onInput updateEditingLabelMsg
                ]
                []
            , div
                [ class "pull-left pt-1 pl-2 text-center"
                , A.style [ ( "width", "20%" ) ]
                ]
                [ H.button
                    [ A.type_ "submit"
                    , class "btn btn-primary btn-sm"
                    ]
                    [ text "Update" ]
                , text " "
                , H.button
                    [ A.type_ "button"
                    , class "btn btn-secondary btn-sm"
                    , onClick <| UpdateEditingTask editor.task.id False editor.task.label
                    ]
                    [ text "Cancel" ]
                ]
            ]


datePeriodConfig : DatePeriod -> ( String, String )
datePeriodConfig datePeriod =
    case datePeriod of
        Yesterday ->
            ( "Yesterday", "badge-warning" )

        Today ->
            ( "Today", "badge-success" )

        Tomorrow ->
            ( "Tomorrow", "badge-info" )

        Later ->
            ( "Later", "badge-default" )


datePeriodLabel : DatePeriod -> String
datePeriodLabel datePeriod =
    datePeriodConfig datePeriod |> Tuple.first
