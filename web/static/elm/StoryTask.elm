module StoryTask
    exposing
        ( StoryTask
        , CurrentDates
        , Scheduled(..)
        , makeNewTask
        , makeEmptyCurrentDates
        , timeToCurrentDates
        , taskSchedule
        , storyTaskForm
        , storyTasksView
        )

import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)
import Html exposing (Html, form, div, span, label, input, button, text, ul, li, i)
import Html.Attributes exposing (class, classList, type_, placeholder, value, autofocus, disabled, name, checked)
import Html.Events exposing (onInput, onSubmit, onClick)


-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , completed : Bool
    , scheduledOn : String
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


storyTaskForm : String -> msg -> (String -> msg) -> Html msg
storyTaskForm currentLabel addTaskMsg updateTaskMsg =
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


storyTasksView : CurrentDates -> (StoryTask -> msg) -> Bool -> Bool -> List StoryTask -> Html msg
storyTasksView dates msg showCompleted allowYesterday tasks =
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
                    (List.map (oneTaskView dates msg allowYesterday) tasksToShow)
                ]


oneTaskView : CurrentDates -> (StoryTask -> msg) -> Bool -> StoryTask -> Html msg
oneTaskView dates msg allowYesterday task =
    let
        scheduled =
            taskSchedule dates task

        label =
            if task.completed then
                Html.s [ class "text-muted" ] [ text task.label ]
            else
                span [] [ text task.label ]

        commonScheduleButtons =
            [ scheduleButton ScheduledToday
                scheduled
                (changeSchedule msg dates.today task)
            , scheduleButton ScheduledTomorrow
                scheduled
                (changeSchedule msg dates.tomorrow task)
            , scheduleButton ScheduledLater
                scheduled
                (changeSchedule msg dates.later task)
            ]

        scheduleButtons =
            if allowYesterday then
                (scheduleButton
                    ScheduledYesterday
                    scheduled
                    (changeSchedule msg dates.yesterday task)
                )
                    :: commonScheduleButtons
            else if scheduled == ScheduledYesterday then
                (div
                    [ class "badge badge-pill badge-danger mr-3" ]
                    [ text "late" ]
                )
                    :: commonScheduleButtons
            else
                commonScheduleButtons

        scheduleControls =
            if task.completed then
                div [] []
            else
                div [ class "btn-group" ] scheduleButtons
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between" ]
                [ label
                , div []
                    [ scheduleControls
                    , button
                        [ class "btn btn-sm btn-outline-primary ml-4"
                        , type_ "button"
                        , onClick (toggleCompleted msg task)
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
