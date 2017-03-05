module View exposing (..)

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
import Model exposing (..)
import StoryTask exposing (StoryTask, Scheduled(..))


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ nav
            [ class "navbar navbar-toggleable-md navbar-inverse bg-primary " ]
            [ button [ class "navbar-toggler navbar-toggler-right", type_ "button" ]
                [ span [ class "navbar-toggler-icon" ] [] ]
            , h1
                [ class "navbar-brand" ]
                [ text model.config.name
                , small [ class "pl-3" ] [ text <| "(" ++ model.config.email ++ ")" ]
                ]
            , div
                [ class "collapse navbar-collapse" ]
                [ ul [ class "navbar-nav mr-auto" ] []
                , span
                    [ class "navbar-text pull-right mr-3" ]
                    [ text model.dates.today ]
                , span
                    [ class "pull-right" ]
                    [ a
                        [ href "/auth/logout", class "btn btn-danger" ]
                        [ text "Logout" ]
                    ]
                ]
            ]
        , div
            [ class "container below-navbar" ]
            [ messageView model.message
            , div [ class "mt-3" ]
                [ div [ class "row" ]
                    [ div [ class "col" ]
                        [ h2 [] [ text "Tasker" ] ]
                    , div [ class "col" ]
                        [ button
                            [ class "btn btn-outline-info pull-right"
                            , type_ "button"
                            , onClick ShowSummary
                            ]
                            [ Html.i [ class "fa fa-calendar" ] []
                            , text " Summary"
                            ]
                        ]
                    ]
                , taskForm model
                ]
            ]
        , summaryModal model
        ]


summaryModal : Model -> Html Msg
summaryModal model =
    let
        completedTasks =
            List.filter (\task -> task.completed) model.tasks

        scheduledTasks =
            List.filter (\task -> not task.completed && task.scheduledOn <= model.dates.today) model.tasks
    in
        if model.showSummary then
            div []
                [ div
                    [ class "modal fade show"
                    , style [ ( "display", "block" ) ]
                    ]
                    [ div [ class "modal-dialog" ]
                        [ div [ class "modal-content" ]
                            [ div [ class "modal-header" ]
                                [ h4 [ class "modal-title w-100 text-center" ]
                                    [ text "Scrum Summary" ]
                                , button
                                    [ type_ "button"
                                    , class "close"
                                    , onClick HideSummary
                                    ]
                                    [ span [] [ text "×" ] ]
                                ]
                            , div [ class "modal-body " ]
                                [ div [ class "mt-3 mb-4" ]
                                    [ h6 [ class "text-center mb-3" ] [ text "Yesterday" ]
                                    , ul [] (List.map summaryTaskView completedTasks)
                                    ]
                                , div [ class "mt-3 mb-4" ]
                                    [ h6 [ class "text-center mb-3" ] [ text "Today" ]
                                    , ul [] (List.map summaryTaskView scheduledTasks)
                                    ]
                                ]
                            , div [ class "modal-footer" ]
                                [ button
                                    [ type_ "button"
                                    , class "btn btn-primary"
                                    , onClick HideSummary
                                    ]
                                    [ text "Done" ]
                                ]
                            ]
                        ]
                    ]
                , div
                    [ class "modal-backdrop fade show"
                    , onClick HideSummary
                    ]
                    []
                ]
        else
            div [] []


summaryTaskView : StoryTask -> Html Msg
summaryTaskView task =
    li [] [ text task.label ]


taskForm : Model -> Html Msg
taskForm model =
    div [ class "card mt-3" ]
        [ div [ class "card-block" ]
            [ Html.form [ onSubmit AddCurrentTask ]
                [ div [ class "form-group row" ]
                    [ div [ class "col-sm-10" ]
                        [ input
                            [ type_ "text"
                            , class "form-control form-control-lg"
                            , placeholder "Enter new task..."
                            , autofocus True
                            , value model.currentTaskLabel
                            , onInput UpdateCurrentTask
                            ]
                            []
                        ]
                    , div [ class "col-sm-2" ]
                        [ button
                            [ type_ "submit"
                            , class "btn btn-primary btn-block btn-lg"
                            , disabled (model.currentTaskLabel == "")
                            ]
                            [ text "Create" ]
                        ]
                    ]
                ]
            , tasksView model
            ]
        ]


tasksView : Model -> Html Msg
tasksView model =
    let
        tasksWithSchedule schedules task =
            List.member (StoryTask.taskSchedule model.dates task) schedules

        selectedTasks =
            case model.scheduleTab of
                TabAll ->
                    model.tasks

                TabToday ->
                    List.filter (tasksWithSchedule [ ScheduledYesterday, ScheduledToday ]) model.tasks

                TabTomorrow ->
                    List.filter (tasksWithSchedule [ ScheduledTomorrow ]) model.tasks

                TabLater ->
                    List.filter (tasksWithSchedule [ ScheduledLater ]) model.tasks
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
                taskViewer model.dates allowYesterday task
    in
        if List.isEmpty tasksToShow then
            div [ class "alert alert-info mt-3" ]
                [ text "No tasks found." ]
        else
            div [ class "card" ]
                [ ul [ class "list-group list-group-flush" ]
                    (List.map view tasksToShow)
                ]


taskViewer : StoryTask.CurrentDates -> Bool -> StoryTask -> Html Msg
taskViewer dates allowYesterday task =
    let
        scheduled =
            StoryTask.taskSchedule dates task

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
                    (StoryTask.taskControls dates RequestTaskUpdate allowYesterday scheduled task)
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between" ]
                [ label
                , div []
                    [ scheduleControls
                    , button
                        [ class "btn btn-sm btn-outline-primary ml-4"
                        , type_ "button"
                        , onClick (StoryTask.toggleCompleted RequestTaskUpdate task)
                        ]
                        [ Html.i
                            [ class "fa "
                            , classList
                                [ ( "fa-check", task.completed )
                                , ( "empty", not task.completed )
                                ]
                            ]
                            []
                        ]
                    ]
                ]
            ]


taskEditor : StoryTask -> Html Msg
taskEditor task =
    let
        updateEditingLabelMsg editingLabel =
            UpdateEditingTask task.id False editingLabel
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
                    , onClick <| UpdateEditingTask task.id False task.editingLabel
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
