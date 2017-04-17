module View exposing (..)

import Dict exposing (Dict)
import String.Extra
import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class, classList)
import Html.Events exposing (onClick, onSubmit, onInput, onDoubleClick)
import Bootstrap.Button as Button
import Bootstrap.Badge as Badge
import Bootstrap.Card as Card
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Html5.DragDrop as DragDrop


-- LOCAL IMPORTS

import Model exposing (..)
import StoryTask exposing (StoryTask)


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ menu model
        , mainContent model
        , summaryModal model
        , confirmModal model
        ]


menu : Model -> Html Msg
menu model =
    Navbar.config NavMsg
        |> Navbar.withAnimation
        |> Navbar.primary
        |> Navbar.brand [ A.href "/" ]
            [ text model.config.name
            , H.small [ class "pl-3" ] [ text <| "(" ++ model.config.email ++ ")" ]
            ]
        |> Navbar.customItems
            [ Navbar.textItem
                [ class "pull-right mr-3" ]
                [ text <| formatShortDate model.context.today ]
            , Navbar.customItem
                (H.span
                    [ class "pull-right " ]
                    [ Button.linkButton
                        [ Button.danger, Button.attrs [ A.href "/auth/logout" ] ]
                        [ text "Logout" ]
                    ]
                )
            ]
        |> Navbar.view model.navState


mainContent : Model -> Html Msg
mainContent model =
    Grid.containerFluid []
        [ div [ class "mt-3" ]
            [ Grid.row []
                [ Grid.col [ Col.sm2 ]
                    [ H.h2 [ class "mb-3" ] [ text "Tasker" ] ]
                , Grid.col [ Col.sm8 ]
                    [ div [ class "w-100 align-top" ] [ messageView model.message ] ]
                , Grid.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.warning
                        , Button.onClick ShowSummary
                        , Button.attrs [ class "pull-right" ]
                        ]
                        [ H.i [ class "fa fa-calendar" ] []
                        , text " Summary"
                        ]
                    ]
                ]
            , if model.orderingMode then
                orderingCard model
              else
                taskCard model
            ]
        ]


taskCard : Model -> Html Msg
taskCard model =
    Card.config [ Card.attrs [ class "mt-3" ] ]
        |> Card.block []
            [ Card.custom <| newTaskForm model
            , Card.custom <| tasksCardView model
            ]
        |> Card.view


orderingCard : Model -> Html Msg
orderingCard model =
    let
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

        taskEditorList =
            List.filter (not << .completed) model.taskEditors

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

        dropTargetList =
            taskEditorsByDay taskEditorList
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
                                dropTargetList

                            Nothing ->
                                taskEditorList
                                    |> List.map (taskItem True)
                                    |> ListGroup.ul
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


confirmModal : Model -> Html Msg
confirmModal model =
    let
        cfg =
            model.confirmation
    in
        Modal.config ConfirmModalMsg
            |> Modal.h4 [ class "w-100 -text-center" ] [ text cfg.title ]
            |> Modal.body []
                [ H.p [ class "lead" ] [ text cfg.text ] ]
            |> Modal.footer []
                [ Button.button
                    [ Button.secondary, Button.onClick cfg.msgCancel ]
                    [ text cfg.labelCancel ]
                , Button.button
                    [ cfg.btnOk
                    , Button.onClick cfg.msgOk
                    , Button.attrs [ A.style [ ( "min-width", "100px" ) ] ]
                    ]
                    [ text cfg.labelOk ]
                ]
            |> Modal.view model.confirmModalState


summaryModal : Model -> Html Msg
summaryModal model =
    let
        completedTasks =
            List.filter .completed model.taskEditors

        isScheduled editor =
            not editor.completed
                && (Maybe.map (\date -> date <= model.context.today) editor.task.scheduledOn |> Maybe.withDefault False)

        scheduledTasks =
            List.filter isScheduled model.taskEditors

        summaryTaskView editor =
            H.li [] [ text editor.task.label ]

        shortYesterday =
            formatShortDate <| earliestYesterday completedTasks
    in
        Modal.config SummaryModalMsg
            |> Modal.h4 [ class "w-100 text-center" ] [ text "Scrum Summary" ]
            |> Modal.body []
                [ div [ class "mt-3 mb-4" ]
                    [ H.h6 [ class "text-center mb-3" ]
                        [ text "Yesterday"
                        , H.small [ class "ml-1 text-muted" ]
                            [ text <| "(" ++ shortYesterday ++ ")" ]
                        ]
                    , H.ul [] (List.map summaryTaskView completedTasks)
                    ]
                , div [ class "mt-3 mb-4" ]
                    [ H.h6 [ class "text-center mb-3" ]
                        [ text "Today" ]
                    , H.ul [] (List.map summaryTaskView scheduledTasks)
                    ]
                ]
            |> Modal.footer []
                [ Button.button
                    [ Button.primary, Button.onClick HideSummary ]
                    [ text "Done" ]
                ]
            |> Modal.view model.summaryModalState



--
-- ORDERING MODAL
--


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



--
-- TASK LIST CARD
--


newTaskForm : Model -> Html Msg
newTaskForm model =
    Form.form [ onSubmit AddCurrentTask ]
        [ Form.group []
            [ Form.row []
                [ Form.col [ Col.sm10 ]
                    [ Input.text
                        [ Input.large
                        , Input.onInput UpdateCurrentTask
                        , Input.value model.currentTaskLabel
                        , Input.attrs
                            [ A.placeholder "Enter new task..."
                            , A.autofocus True
                            ]
                        ]
                    ]
                , Form.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.primary
                        , Button.block
                        , Button.large
                        , Button.attrs
                            [ A.type_ "submit"
                            , A.disabled (model.currentTaskLabel == "")
                            ]
                        ]
                        [ text "Create" ]
                    ]
                ]
            ]
        ]


tasksCardView : Model -> Html Msg
tasksCardView model =
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

        completionButton =
            if editor.completed then
                Dropdown.buttonItem
                    [ onClick <| StoryTask.toggleCompleted RequestTaskUpdate model.context.today editor.task ]
                    [ H.i [ class "fa fa-square-o" ] []
                    , text " Uncomplete"
                    ]
            else
                Dropdown.buttonItem
                    [ onClick <| StoryTask.toggleCompleted RequestTaskUpdate model.context.today editor.task ]
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


messageView : AppMessage -> Html Msg
messageView message =
    let
        view kind content =
            div
                [ class <| "mb-0 alert alert-" ++ kind
                , A.attribute "role" "alert"
                ]
                [ H.button
                    [ A.type_ "button"
                    , class "close"
                    , onClick ClearMessage
                    ]
                    [ H.span [] [ text "×" ] ]
                , text content
                ]
    in
        case message of
            MessageNone ->
                div [] []

            MessageSuccess content ->
                view "success" content

            MessageNotice content ->
                view "info" content

            MessageError content ->
                view "danger" content
