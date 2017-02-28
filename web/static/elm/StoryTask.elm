module StoryTask
    exposing
        ( StoryTask
        , CurrentDates
        , Scheduled(..)
        , makeNewTask
        , makeEmptyCurrentDates
        , timeToCurrentDates
        , taskSchedule
        , taskControls
        , toggleCompleted
        )

import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)
import Html exposing (Html, div, button, text)
import Html.Attributes exposing (class, type_, disabled)
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
