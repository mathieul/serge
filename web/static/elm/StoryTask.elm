module StoryTask
    exposing
        ( StoryTask
        , CurrentDates
        , Scheduled(..)
        , makeNewTask
        , makeEmptyCurrentDates
        , timeToCurrentDates
        , taskSchedule
        , formView
        , listView
        )

import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)
import Html exposing (Html, div, span, form, label, input, button, text, ul, li, i)
import Html.Attributes
    exposing
        ( class
        , classList
        , style
        , type_
        , placeholder
        , value
        , autofocus
        , disabled
        , name
        , checked
        )
import Html.Events exposing (onInput, onSubmit, onClick, onDoubleClick)


-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , completed : Bool
    , scheduledOn : String
    , editing : Bool
    , editingLabel : String
    }


type alias CurrentDates =
    { yesterday : String
    , today : String
    , tomorrow : String
    , later : String
    }


type Scheduled
    = ScheduledYesterday
    | ScheduledToday
    | ScheduledTomorrow
    | ScheduledLater


makeNewTask : Int -> String -> Int -> String -> StoryTask
makeNewTask sequence label count scheduledOn =
    { id = "TMP:" ++ (toString sequence)
    , label = label
    , rank = count + 1
    , completed = False
    , scheduledOn = scheduledOn
    , editing = False
    , editingLabel = ""
    }


makeEmptyCurrentDates : CurrentDates
makeEmptyCurrentDates =
    CurrentDates "" "" "" ""


timeToCurrentDates : TimeZone -> Time -> CurrentDates
timeToCurrentDates timeZone time =
    let
        now =
            DateTime.fromTimestamp time
                |> ZonedDateTime.fromDateTime timeZone

        today =
            Date.date (ZonedDateTime.year now) (ZonedDateTime.month now) (ZonedDateTime.day now)
    in
        { yesterday = Date.toISO8601 <| Date.addDays -1 today
        , today = Date.toISO8601 today
        , tomorrow = Date.toISO8601 <| Date.addDays 1 today
        , later = Date.toISO8601 <| Date.addDays 30 today
        }



-- VIEW


formView : String -> msg -> (String -> msg) -> Html msg
formView currentLabel addTaskMsg updateTaskMsg =
    form [ onSubmit addTaskMsg ]
        [ div [ class "form-group row" ]
            [ div [ class "col-sm-10" ]
                [ input
                    [ type_ "text"
                    , class "form-control form-control-lg"
                    , placeholder "Enter new task..."
                    , autofocus True
                    , value currentLabel
                    , onInput updateTaskMsg
                    ]
                    []
                ]
            , div [ class "col-sm-2" ]
                [ button
                    [ type_ "submit"
                    , class "btn btn-primary btn-block btn-lg"
                    , disabled (currentLabel == "")
                    ]
                    [ text "Create" ]
                ]
            ]
        ]


listView :
    CurrentDates
    -> (StoryTask -> msg)
    -> (String -> Bool -> String -> msg)
    -> Bool
    -> Bool
    -> List StoryTask
    -> Html msg
listView dates updateMsg updateEditingMsg showCompleted allowYesterday tasks =
    let
        tasksToShow =
            if showCompleted then
                tasks
            else
                List.filter (\task -> not task.completed) tasks
    in
        if List.isEmpty tasksToShow then
            div [ class "alert alert-info mt-3" ]
                [ text "No tasks found." ]
        else
            div [ class "card" ]
                [ ul [ class "list-group list-group-flush" ]
                    (List.map (singleTaskView dates updateMsg updateEditingMsg allowYesterday) tasksToShow)
                ]


singleTaskView :
    CurrentDates
    -> (StoryTask -> msg)
    -> (String -> Bool -> String -> msg)
    -> Bool
    -> StoryTask
    -> Html msg
singleTaskView dates updateMsg updateEditingMsg allowYesterday task =
    let
        scheduled =
            taskSchedule dates task

        toggleEditingMsg =
            updateEditingMsg task.id (not task.editing) task.editingLabel

        updateEditingLabelMsg editingLabel =
            updateEditingMsg task.id task.editing editingLabel

        label =
            if task.completed then
                Html.s [ class "text-muted" ] [ text task.label ]
            else if scheduled == ScheduledYesterday then
                span [ onDoubleClick toggleEditingMsg ]
                    [ text task.label
                    , i [ class "fa fa-clock-o text-danger ml-2" ] []
                    ]
            else
                span [ onDoubleClick toggleEditingMsg ]
                    [ text task.label ]

        scheduleControls =
            if task.completed then
                div [] []
            else
                div [ class "btn-group" ]
                    (taskControls dates updateMsg allowYesterday scheduled task)

        view =
            li [ class "list-group-item d-flex flex-column align-items-start" ]
                [ div [ class " w-100 d-flex justify-content-between" ]
                    [ label
                    , div []
                        [ scheduleControls
                        , button
                            [ class "btn btn-sm btn-outline-primary ml-4"
                            , type_ "button"
                            , onClick (toggleCompleted updateMsg task)
                            ]
                            [ i
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

        edit =
            form
                [ class "px-2 py-1-5"
                , onSubmit (changeLabel updateMsg task)
                ]
                [ input
                    [ type_ "text"
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
                        , onClick toggleEditingMsg
                        ]
                        [ text "Cancel" ]
                    ]
                ]
    in
        if task.editing then
            edit
        else
            view


taskControls : CurrentDates -> (StoryTask -> msg) -> Bool -> Scheduled -> StoryTask -> List (Html msg)
taskControls dates updateMsg allowYesterday scheduled task =
    let
        commonButtons =
            [ scheduleButton ScheduledToday
                scheduled
                (changeSchedule updateMsg dates.today task)
            , scheduleButton ScheduledTomorrow
                scheduled
                (changeSchedule updateMsg dates.tomorrow task)
            , scheduleButton ScheduledLater
                scheduled
                (changeSchedule updateMsg dates.later task)
            ]
    in
        if allowYesterday then
            (scheduleButton
                ScheduledYesterday
                scheduled
                (changeSchedule updateMsg dates.yesterday task)
            )
                :: commonButtons
        else
            commonButtons


taskSchedule : CurrentDates -> StoryTask -> Scheduled
taskSchedule dates task =
    if task.scheduledOn < dates.today then
        ScheduledYesterday
    else if task.scheduledOn == dates.today then
        ScheduledToday
    else if task.scheduledOn == dates.tomorrow then
        ScheduledTomorrow
    else
        ScheduledLater


changeSchedule : (StoryTask -> msg) -> String -> StoryTask -> msg
changeSchedule msg scheduledOn task =
    msg { task | scheduledOn = scheduledOn }


changeLabel : (StoryTask -> msg) -> StoryTask -> msg
changeLabel msg task =
    msg { task | label = task.editingLabel }


toggleCompleted : (StoryTask -> msg) -> StoryTask -> msg
toggleCompleted msg task =
    msg { task | completed = not task.completed }


scheduleButton : Scheduled -> Scheduled -> msg -> Html msg
scheduleButton option current msg =
    let
        ( level, label ) =
            case option of
                ScheduledYesterday ->
                    ( "btn-outline-danger", "Yesterday" )

                ScheduledToday ->
                    ( "btn-outline-success", "Today" )

                ScheduledTomorrow ->
                    ( "btn-outline-info", "Tomorrow" )

                ScheduledLater ->
                    ( "btn-outline-secondary", "Later" )

        ( active, isDisabled ) =
            if option == current then
                ( " active", True )
            else
                ( "", False )
    in
        button
            [ class <| "btn btn-sm " ++ level ++ active
            , type_ "button"
            , disabled isDisabled
            , onClick msg
            ]
            [ text label ]
