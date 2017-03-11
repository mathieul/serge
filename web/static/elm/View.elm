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
import Html.Attributes
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


-- import Bootstrap.ListGroup as Listgroup

import Bootstrap.Modal as Modal
import Model exposing (..)
import StoryTask exposing (StoryTask, Scheduled(..))


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ menu model
        , mainContent model
        , summaryModal model
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
                [ text model.dates.today ]
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
        [ messageView model.message
        , div [ class "mt-3" ]
            [ Grid.row []
                [ Grid.col []
                    [ h2 [] [ text "Tasker" ] ]
                , Grid.col []
                    [ Button.button
                        [ Button.outlineInfo
                        , Button.attrs [ class "pull-right mr-4", onClick ShowSummary ]
                        ]
                        [ Html.i [ class "fa fa-calendar" ] []
                        , text " Summary"
                        ]
                    ]
                ]
            , taskForm model
            ]
        ]


summaryModal : Model -> Html Msg
summaryModal model =
    let
        completedTasks =
            List.filter (\task -> task.completed) model.tasks

        scheduledTasks =
            List.filter (\task -> not task.completed && task.scheduledOn <= model.dates.today) model.tasks

        earliestYesterday =
            completedTasks
                |> List.map (\task -> Maybe.withDefault "" task.completedOn)
                |> List.minimum
                |> Maybe.withDefault ""

        summaryTaskView task =
            li [] [ text task.label ]
    in
        Modal.config ModalMsg
            |> Modal.h4 [ class "w-100 text-center" ] [ text "Scrum Summary" ]
            |> Modal.body []
                [ div [ class "mt-3 mb-4" ]
                    [ h6 [ class "text-center mb-3" ]
                        [ text "Yesterday"
                        , small [ class "ml-1 text-muted" ]
                            [ text <| "(" ++ earliestYesterday ++ ")" ]
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


taskForm : Model -> Html Msg
taskForm model =
    Card.config [ Card.attrs [ class "card mt-3" ] ]
        |> Card.block []
            [ Card.custom <| newTaskForm model
            , Card.custom <| tasksView model
            ]
        |> Card.view


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


tasksView : Model -> Html Msg
tasksView model =
    let
        notCompletedBeforeToday task =
            case task.completedOn of
                Just completedOn ->
                    completedOn >= model.dates.today

                Nothing ->
                    True

        tasks =
            List.filter notCompletedBeforeToday model.tasks

        withSchedule task =
            ( StoryTask.taskSchedule model.dates task, task )

        selectTasksForSchedules schedules =
            tasks
                |> List.map withSchedule
                |> List.filter (\( schedule, task ) -> List.member schedule schedules)
                |> List.map Tuple.second

        selectedTasks =
            case model.scheduleTab of
                TabAll ->
                    tasks

                TabToday ->
                    selectTasksForSchedules [ ScheduledYesterday, ScheduledToday ]

                TabTomorrow ->
                    selectTasksForSchedules [ ScheduledTomorrow ]

                TabLater ->
                    selectTasksForSchedules [ ScheduledLater ]
    in
        div [ class "card mt-3" ]
            [ taskSelectionTabs model.scheduleTab
            , div
                [ class "card-block" ]
                [ taskList model (model.scheduleTab == TabAll) selectedTasks ]
            , taskListFooter selectedTasks model
            ]


taskList : Model -> Bool -> List StoryTask -> Html Msg
taskList model allowYesterday tasks =
    let
        tasksToShow =
            if model.showCompleted then
                tasks
            else
                List.filter (\task -> not task.completed) tasks

        view task =
            if task.editing then
                taskEditor task
            else
                taskViewer model allowYesterday task
    in
        if List.isEmpty tasksToShow then
            div [ class "alert alert-info mt-3" ]
                [ text "No tasks found." ]
        else
            div [ class "card" ]
                [ ul [ class "list-group list-group-flush" ]
                    (List.map view tasksToShow)
                ]


taskViewer : Model -> Bool -> StoryTask -> Html Msg
taskViewer model allowYesterday task =
    let
        scheduled =
            StoryTask.taskSchedule model.dates task

        startEditingMsg =
            UpdateEditingTask task.id True task.editingLabel

        label =
            if task.completed then
                Html.s [ class "text-muted" ] [ text task.label ]
            else if scheduled == ScheduledYesterday then
                span [ onDoubleClick startEditingMsg ]
                    [ text task.label
                    , Html.i [ class "fa fa-clock-o text-danger ml-2" ] []
                    ]
            else
                span [ onDoubleClick startEditingMsg ]
                    [ text task.label ]

        scheduleControls =
            if task.completed then
                div [] []
            else
                div [ class "btn-group" ]
                    [ taskControls model allowYesterday scheduled task ]
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between align-items-center" ]
                [ label
                , div
                    [ class "d-flex justify-content-end"
                    , classList
                        [ ( "task-commands", not allowYesterday )
                        , ( "task-commands-yesterday", allowYesterday )
                        ]
                    ]
                    [ scheduleControls ]
                ]
            ]


actionButton : String -> String -> Bool -> StoryTask -> Dropdown.DropdownItem Msg
actionButton date label current task =
    if current then
        Dropdown.buttonItem
            [ class "text-muted" ]
            [ Html.i [ class "fa fa-check" ] []
            , text <| " " ++ label
            ]
    else
        Dropdown.buttonItem
            [ onClick <| StoryTask.changeSchedule RequestTaskUpdate date task ]
            [ text label ]


taskControls : Model -> Bool -> Scheduled -> StoryTask -> Html Msg
taskControls model allowYesterday scheduled task =
    let
        state =
            Dict.get task.id model.dropdownStates
                |> Maybe.withDefault Dropdown.initialState

        setSchedule date =
            StoryTask.changeSchedule RequestTaskUpdate date task

        completionLabel =
            if task.completed then
                "Uncomplete"
            else
                "Complete"

        actions =
            [ actionButton model.dates.today "Today" (scheduled == ScheduledToday) task
            , actionButton model.dates.tomorrow "Tomorrow" (scheduled == ScheduledTomorrow) task
            , actionButton model.dates.later "Later" (scheduled == ScheduledLater) task
            , Dropdown.divider
            , Dropdown.buttonItem
                [ onClick <| StoryTask.toggleCompleted RequestTaskUpdate model.dates.today task ]
                [ text completionLabel ]
            ]
    in
        Dropdown.dropdown state
            { options = [ Dropdown.alignMenuRight ]
            , toggleMsg = DropdownMsg task.id
            , toggleButton =
                Dropdown.toggle
                    [ Button.outlinePrimary, Button.small ]
                    [ text "Actions" ]
            , items = actions
            }


taskEditor : StoryTask -> Html Msg
taskEditor task =
    let
        updateEditingLabelMsg editingLabel =
            UpdateEditingTask task.id True editingLabel
    in
        Html.form
            [ class "px-2 py-1-5"
            , onSubmit (RequestTaskUpdate { task | label = task.editingLabel })
            ]
            [ input
                [ type_ "text"
                , Html.Attributes.id <| "edit-task-" ++ task.id
                , class "form-control pull-left"
                , style [ ( "width", "80%" ) ]
                , value task.editingLabel
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
                    , onClick <| UpdateEditingTask task.id False task.label
                    ]
                    [ text "Cancel" ]
                ]
            ]


taskListFooter : List StoryTask -> Model -> Html Msg
taskListFooter tasks model =
    let
        countCompleted =
            List.foldl
                (\task count ->
                    if task.completed then
                        count + 1
                    else
                        count
                )
                0
                tasks

        count =
            (List.length tasks) - countCompleted

        label =
            (String.Extra.pluralize "task" "tasks" count)
                ++ " / "
                ++ (toString countCompleted)
                ++ " completed"
    in
        div [ class "card-footer text-muted" ]
            [ div [ class "row" ]
                [ div [ class "col pl-3" ]
                    [ text label ]
                , div [ class "col pr-3 text-right" ]
                    [ Html.label [ for "show-completed" ] [ text "show completed" ]
                    , text " "
                    , input
                        [ type_ "checkbox"
                        , Html.Attributes.id "show-completed"
                        , checked model.showCompleted
                        , onClick ToggleShowCompleted
                        ]
                        []
                    ]
                ]
            ]


taskSelectionTabs : ScheduleTab -> Html Msg
taskSelectionTabs selection =
    let
        aTab ( schedule, label ) =
            li [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , classList [ ( "active", selection == schedule ) ]
                    , href "#"
                    , onClick (ChangeScheduleTab schedule)
                    ]
                    [ text label ]
                ]

        theTabs =
            List.map
                aTab
                [ ( TabToday, "Today" )
                , ( TabTomorrow, "Tomorrow" )
                , ( TabLater, "Later" )
                , ( TabAll, "All" )
                ]
    in
        div [ class "card-header" ]
            [ ul [ class "nav nav-tabs card-header-tabs" ] theTabs ]


messageView : AppMessage -> Html Msg
messageView message =
    let
        view level content =
            div [ class ("my-4 alert " ++ level) ]
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

            MessageNotice content ->
                view "alert-notice" content

            MessageError content ->
                view "alert-danger" content
