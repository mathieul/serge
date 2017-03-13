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
import Bootstrap.Alert as Alert
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
                    completedOn >= model.dates.today

                Nothing ->
                    True

        tasks =
            List.filter notCompletedBeforeToday model.tasks

        withSchedule task =
            ( StoryTask.taskSchedule model.dates task, task )

        selectTasksForSchedule schedule =
            tasks
                |> List.map withSchedule
                |> List.filter (\( taskSchedule, _ ) -> taskSchedule == schedule)
                |> List.map Tuple.second

        selectedTasks =
            case model.scheduleTab of
                TabYesterday ->
                    selectTasksForSchedule ScheduledYesterday

                TabToday ->
                    selectTasksForSchedule ScheduledToday

                TabTomorrow ->
                    selectTasksForSchedule ScheduledTomorrow

                TabLater ->
                    selectTasksForSchedule ScheduledLater
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
        aTab ( schedule, label ) =
            li [ class "nav-item" ]
                [ a
                    [ class "nav-link"
                    , classList [ ( "active", model.scheduleTab == schedule ) ]
                    , href "#"
                    , onClick (ChangeScheduleTab schedule)
                    ]
                    [ text label ]
                ]

        theTabs =
            List.map
                aTab
                [ ( TabYesterday, "Yesterday" )
                , ( TabToday, "Today" )
                , ( TabTomorrow, "Tomorrow" )
                , ( TabLater, "Later" )
                ]
    in
        ul [ class "nav nav-tabs card-header-tabs" ] theTabs


taskList : Model -> List StoryTask -> Html Msg
taskList model tasks =
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
                taskViewer model task
    in
        if List.isEmpty tasksToShow then
            div [ class "alert alert-info mt-3" ]
                [ text "No tasks found." ]
        else
            div [ class "card" ]
                [ ul [ class "list-group list-group-flush" ]
                    (List.map view tasksToShow)
                ]


taskCompletionInfo : List StoryTask -> Model -> Html Msg
taskCompletionInfo tasks model =
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
        div [ class "row text-muted" ]
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


taskViewer : Model -> StoryTask -> Html Msg
taskViewer model task =
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
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between align-items-center" ]
                [ label
                , div
                    [ class "d-flex justify-content-end" ]
                    [ div [ class "btn-group" ]
                        [ taskControl model scheduled task ]
                    ]
                ]
            ]


actionButton : String -> String -> String -> StoryTask -> Dropdown.DropdownItem Msg
actionButton date label taskLabel task =
    if label == taskLabel then
        Dropdown.buttonItem
            [ class "disabled"
            , classList [ ( "text-danger", label == "Yesterday" ) ]
            ]
            [ Html.i [ class "fa fa-arrow-right" ] []
            , text <| " " ++ label
            ]
    else
        Dropdown.buttonItem
            [ classList [ ( "text-danger", label == "Yesterday" ) ]
            , onClick <| StoryTask.changeSchedule RequestTaskUpdate date task
            ]
            [ Html.i [ class "fa empty" ] []
            , text <| " " ++ label
            ]


taskControl : Model -> Scheduled -> StoryTask -> Html Msg
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
                ScheduledYesterday ->
                    "Yesterday"

                ScheduledToday ->
                    "Today"

                ScheduledTomorrow ->
                    "Tomorrow"

                ScheduledLater ->
                    "Later"

        actions =
            [ actionButton model.dates.yesterday "Yesterday" actionLabel task
            , actionButton model.dates.today "Today" actionLabel task
            , actionButton model.dates.tomorrow "Tomorrow" actionLabel task
            , actionButton model.dates.later "Later" actionLabel task
            , Dropdown.divider
            , Dropdown.buttonItem
                [ onClick <| StoryTask.toggleCompleted RequestTaskUpdate model.dates.today task ]
                completionDisplay
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


messageView : AppMessage -> Html Msg
messageView message =
    let
        view alert content =
            alert
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
                div [ class "my-4" ] [ view Alert.info content ]

            MessageError content ->
                div [ class "my-4" ] [ view Alert.danger content ]
