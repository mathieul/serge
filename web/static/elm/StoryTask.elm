module StoryTask
    exposing
        ( StoryTask
        , CurrentDates
        , Scheduled(..)
        , makeNewTask
        , makeEmptyCurrentDates
        , timeToCurrentDates
        , taskSchedule
        , changeSchedule
        , toggleCompleted
        )

import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)


-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , completed : Bool
    , completedOn : Maybe String
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
    , completedOn = Nothing
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


toggleCompleted : (StoryTask -> msg) -> String -> StoryTask -> msg
toggleCompleted msg today task =
    msg
        { task
            | completed = not task.completed
            , completedOn =
                if task.completed then
                    Nothing
                else
                    Just today
        }
