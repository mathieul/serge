module View exposing (..)

import Dict
import String.Extra
import Html
    exposing
        ( Html
        , div
        , span
        , text
        , nav
        , button
        , a
        , ul
        , li
        , h1
        , h2
        , h4
        , h6
        , small
        , input
        )
import Html.Attributes as A
    exposing
        ( class
        , classList
        , style
        , href
        , type_
        , placeholder
        , value
        , checked
        , autofocus
        , disabled
        , for
        )
import Html.Events exposing (onClick, onSubmit, onInput, onDoubleClick)
import Bootstrap.Navbar as Navbar
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Modal as Modal


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
        |> Navbar.brand [ href "/" ]
            [ text model.config.name
            , small [ class "pl-3" ] [ text <| "(" ++ model.config.email ++ ")" ]
            ]
        |> Navbar.customItems
            [ Navbar.textItem
                [ class "pull-right mr-3" ]
                [ text model.context.today ]
            , Navbar.customItem
                (span
                    [ class "pull-right " ]
                    [ Button.linkButton
                        [ Button.danger, Button.attrs [ href "/auth/logout" ] ]
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
                    [ h2 [ class "mb-3" ] [ text "Tasker" ] ]
                , Grid.col [ Col.sm8 ]
                    [ div [ class "w-100 align-top" ] [ messageView model.message ] ]
                , Grid.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.warning
                        , Button.attrs [ class "pull-right", onClick ShowSummary ]
                        ]
                        [ Html.i [ class "fa fa-calendar" ] []
                        , text " Summary"
                        ]
                    ]
                ]
            , Card.config [ Card.attrs [ class "mt-3" ] ]
                |> Card.block []
                    [ Card.custom <| newTaskForm model
                    , Card.custom <| tasksCardView model
                    ]
                |> Card.view
            ]
        ]


earliestYesterday : List TaskEditor -> String
earliestYesterday taskEditors =
    taskEditors
        |> List.filter (\editor -> editor.task.completed)
        |> List.map (\editor -> Maybe.withDefault "" editor.task.completedOn)
        |> List.minimum
        |> Maybe.withDefault ""


confirmModal : Model -> Html Msg
confirmModal model =
    let
        cfg =
            model.confirmation
    in
        Modal.config ConfirmModalMsg
            |> Modal.h4 [ class "w-100 -text-center" ] [ text cfg.title ]
            |> Modal.body []
                [ Html.p [ class "lead" ] [ text cfg.text ] ]
            |> Modal.footer []
                [ Button.button [ Button.secondary, Button.attrs [ onClick cfg.msgCancel ] ]
                    [ text cfg.labelCancel ]
                , Button.button
                    [ cfg.btnOk
                    , Button.attrs
                        [ onClick cfg.msgOk
                        , style [ ( "min-width", "100px" ) ]
                        ]
                    ]
                    [ text cfg.labelOk ]
                ]
            |> Modal.view model.confirmModalState


summaryModal : Model -> Html Msg
summaryModal model =
    let
        completedTasks =
            List.filter (\editor -> editor.task.completed) model.taskEditors

        scheduledTasks =
            List.filter (\editor -> not editor.task.completed && editor.task.scheduledOn <= model.context.today) model.taskEditors

        summaryTaskView editor =
            li [] [ text editor.task.label ]
    in
        Modal.config ModalMsg
            |> Modal.h4 [ class "w-100 text-center" ] [ text "Scrum Summary" ]
            |> Modal.body []
                [ div [ class "mt-3 mb-4" ]
                    [ h6 [ class "text-center mb-3" ]
                        [ text "Yesterday"
                        , small [ class "ml-1 text-muted" ]
                            [ text <| "(" ++ (earliestYesterday completedTasks) ++ ")" ]
                        ]
                    , ul [] (List.map summaryTaskView completedTasks)
                    ]
                , div [ class "mt-3 mb-4" ]
                    [ h6 [ class "text-center mb-3" ]
                        [ text "Today" ]
                    , ul [] (List.map summaryTaskView scheduledTasks)
                    ]
                ]
            |> Modal.footer []
                [ Button.button
                    [ Button.primary, Button.attrs [ onClick HideSummary ] ]
                    [ text "Done" ]
                ]
            |> Modal.view model.modalState


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
                            [ placeholder "Enter new task..."
                            , autofocus True
                            ]
                        ]
                    ]
                , Form.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.primary
                        , Button.block
                        , Button.large
                        , Button.attrs
                            [ type_ "submit"
                            , disabled (model.currentTaskLabel == "")
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
            List.filter (\editor -> editor.period == model.datePeriod) model.taskEditors
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
        yesterday =
            earliestYesterday model.taskEditors

        aTab schedule =
            li [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , classList [ ( "active", model.datePeriod == schedule ) ]
                    , href "#"
                    , onClick (ChangeDatePeriod schedule)
                    ]
                    [ text <| tabLabel schedule model.context yesterday ]
                ]

        theTabs =
            List.map
                aTab
                [ Yesterday, Today, Tomorrow, Later ]
    in
        ul [ class "nav nav-tabs card-header-tabs" ] theTabs


tabLabel : DatePeriod -> AppContext -> String -> String
tabLabel datePeriod context yesterday =
    let
        day date =
            String.slice 5 10 date
    in
        case datePeriod of
            Yesterday ->
                "Yesterday (" ++ (day yesterday) ++ ")"

            Today ->
                "Today"

            Tomorrow ->
                "Tomorrow"

            Later ->
                "Later"


taskList : Model -> List TaskEditor -> Html Msg
taskList model taskEditors =
    let
        tasksToShow =
            if model.showCompleted then
                taskEditors
            else
                List.filter (\editor -> not editor.task.completed) taskEditors

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
                [ ul [ class "list-group list-group-flush" ]
                    (List.map view tasksToShow)
                ]


taskCompletionInfo : List TaskEditor -> Model -> Html Msg
taskCompletionInfo editors model =
    let
        countCompleted =
            List.foldl
                (\editor count ->
                    if editor.task.completed then
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
                [ Html.label [ for "show-completed" ] [ text "show completed" ]
                , text " "
                , input
                    [ type_ "checkbox"
                    , A.id "show-completed"
                    , checked model.showCompleted
                    , onClick ToggleShowCompleted
                    ]
                    []
                ]
            ]


taskViewerView : Model -> TaskEditor -> Html Msg
taskViewerView model editor =
    let
        startEditingMsg =
            UpdateEditingTask editor.task.id True editor.editingLabel

        label =
            if editor.task.completed then
                Html.s [ class "text-muted" ] [ text editor.task.label ]
            else if editor.period == Yesterday then
                span [ onDoubleClick startEditingMsg ]
                    [ text editor.task.label
                    , Html.i [ class "fa fa-clock-o text-danger ml-2" ] []
                    ]
            else
                span [ onDoubleClick startEditingMsg ]
                    [ text editor.task.label ]
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between align-items-center" ]
                [ label
                , div
                    [ class "d-flex justify-content-end" ]
                    [ div [ class "btn-group" ]
                        [ taskControl model editor.period editor.task ]
                    ]
                ]
            ]


actionButton : String -> String -> String -> StoryTask -> Dropdown.DropdownItem Msg
actionButton date label taskLabel task =
    if label == taskLabel then
        Dropdown.buttonItem
            [ class "disabled"
            , classList [ ( "text-ghost", label == "Yesterday" ) ]
            ]
            [ Html.i [ class "fa fa-arrow-right" ] []
            , text <| " " ++ label
            ]
    else
        Dropdown.buttonItem
            [ classList [ ( "text-ghost", label == "Yesterday" ) ]
            , onClick <| StoryTask.changeSchedule RequestTaskUpdate date task
            ]
            [ Html.i [ class "fa empty" ] []
            , text <| " " ++ label
            ]


taskControl : Model -> DatePeriod -> StoryTask -> Html Msg
taskControl model scheduled task =
    let
        state =
            Dict.get task.id model.dropdownStates
                |> Maybe.withDefault Dropdown.initialState

        setSchedule date =
            StoryTask.changeSchedule RequestTaskUpdate date task

        ( completionDisplay, buttonKind ) =
            if task.completed then
                ( [ Html.i [ class "fa fa-square-o" ] []
                  , text " Uncomplete"
                  ]
                , Button.secondary
                )
            else
                ( [ Html.i [ class "fa fa-check-square-o" ] []
                  , text " Complete"
                  ]
                , Button.outlineInfo
                )

        actionLabel =
            case scheduled of
                Yesterday ->
                    "Yesterday"

                Today ->
                    "Today"

                Tomorrow ->
                    "Tomorrow"

                Later ->
                    "Later"

        actions =
            [ Dropdown.buttonItem
                [ onClick <| StoryTask.toggleCompleted RequestTaskUpdate model.context.today task ]
                completionDisplay
            , Dropdown.divider
            , actionButton model.context.yesterday "Yesterday" actionLabel task
            , actionButton model.context.today "Today" actionLabel task
            , actionButton model.context.tomorrow "Tomorrow" actionLabel task
            , actionButton model.context.later "Later" actionLabel task
            , Dropdown.divider
            , Dropdown.buttonItem
                [ class "text-danger"
                , onClick <| ConfirmTaskDeletion task.id task.label
                ]
                [ text "Delete" ]
            ]
    in
        Dropdown.dropdown state
            { options = [ Dropdown.alignMenuRight ]
            , toggleMsg = DropdownMsg task.id
            , toggleButton =
                Dropdown.toggle
                    [ buttonKind
                    , Button.small
                    , Button.attrs [ class "task-control" ]
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
        Html.form
            [ class "px-2 py-1-5"
            , onSubmit (RequestTaskUpdate { task | label = editor.editingLabel })
            ]
            [ input
                [ type_ "text"
                , A.id <| "edit-task-" ++ editor.task.id
                , class "form-control pull-left"
                , style [ ( "width", "80%" ) ]
                , value editor.editingLabel
                , onInput updateEditingLabelMsg
                ]
                []
            , div
                [ class "pull-left pt-1 pl-2 text-center"
                , style [ ( "width", "20%" ) ]
                ]
                [ button
                    [ type_ "submit"
                    , class "btn btn-primary btn-sm"
                    ]
                    [ text "Update" ]
                , text " "
                , button
                    [ type_ "button"
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
                [ button
                    [ type_ "button"
                    , class "close"
                    , onClick ClearMessage
                    ]
                    [ span [] [ text "×" ] ]
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
