module StoryTask
    exposing
        ( StoryTask
        , CurrentDates
        , Scheduled(..)
        , makeNewTask
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
import Html.Attributes exposing (class, type_, placeholder, value, autofocus, disabled, name, checked)
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
    { today : String
    , tomorrow : String
    , later : String
    }


type Scheduled
    = ScheduledToday
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


timeToCurrentDates : TimeZone -> Time -> CurrentDates
timeToCurrentDates timeZone time =
    let
        now =
            DateTime.fromTimestamp time
                |> ZonedDateTime.fromDateTime timeZone

        today =
            Date.date (ZonedDateTime.year now) (ZonedDateTime.month now) (ZonedDateTime.day now)
    in
        { today = Date.toISO8601 today
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


storyTasksView : CurrentDates -> (StoryTask -> msg) -> List StoryTask -> Html msg
storyTasksView dates msg tasks =
    if List.isEmpty tasks then
        div [] []
    else
        div [ class "card" ]
            [ ul [ class "list-group list-group-flush" ]
                (List.map (oneTaskView dates msg) tasks)
            ]


oneTaskView : CurrentDates -> (StoryTask -> msg) -> StoryTask -> Html msg
oneTaskView dates msg task =
    let
        scheduled =
            taskSchedule dates task
    in
        li [ class "list-group-item d-flex flex-column align-items-start" ]
            [ div [ class " w-100 d-flex justify-content-between" ]
                [ span [] [ text task.label ]
                , div []
                    [ div [ class "btn-group" ]
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
                    , button
                        [ class "btn btn-sm btn-outline-danger ml-4"
                        , type_ "button"
                        ]
                        [ i [ class "fa fa-check" ] [] ]
                    ]
                ]
            ]


taskSchedule : CurrentDates -> StoryTask -> Scheduled
taskSchedule dates task =
    if task.scheduledOn <= dates.today then
        ScheduledToday
    else if task.scheduledOn == dates.tomorrow then
        ScheduledTomorrow
    else
        ScheduledLater


changeSchedule : (StoryTask -> msg) -> String -> StoryTask -> msg
changeSchedule msg scheduledOn task =
    msg { task | scheduledOn = scheduledOn }


scheduleButton : Scheduled -> Scheduled -> msg -> Html msg
scheduleButton option current msg =
    let
        ( level, label ) =
            case option of
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
