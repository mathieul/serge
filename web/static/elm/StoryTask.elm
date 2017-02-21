module StoryTask
    exposing
        ( StoryTask
        , CreateTaskResponse
        , CurrentDates
        , makeNewTask
        , timeToCurrentDates
        , storyTaskForm
        , storyTasksView
        , fetchTasksRequest
        , makeTaskRequest
        )

import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)
import Html exposing (Html, form, div, span, label, input, button, text, ul, li, i)
import Html.Attributes exposing (class, type_, placeholder, value, autofocus, disabled, name, checked)
import Html.Events exposing (onInput, onSubmit, onClick)
import Json.Encode as JE
import Json.Decode as JD
import Json.Decode.Pipeline as JP
import Http


-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , completedOn : Maybe String
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


type alias CreateTaskResponse =
    { tid : String
    , task : StoryTask
    }


makeNewTask : Int -> String -> Int -> String -> StoryTask
makeNewTask sequence label count scheduledOn =
    { id = "TMP:" ++ (toString sequence)
    , label = label
    , rank = count + 1
    , completedOn = Nothing
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
            if task.scheduledOn <= dates.today then
                ScheduledToday
            else if task.scheduledOn == dates.tomorrow then
                ScheduledTomorrow
            else
                ScheduledLater
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



-- DECODERS / ENCODERS


taskDecoder : JD.Decoder StoryTask
taskDecoder =
    JP.decode StoryTask
        |> JP.required "id" JD.string
        |> JP.required "label" JD.string
        |> JP.required "rank" JD.int
        |> JP.required "completedOn" (nullOr JD.string)
        |> JP.required "scheduledOn" JD.string


nullOr : JD.Decoder a -> JD.Decoder (Maybe a)
nullOr decoder =
    JD.oneOf
        [ JD.null Nothing
        , JD.map Just decoder
        ]


tasksResponseDecoder : JD.Decoder (List StoryTask)
tasksResponseDecoder =
    JD.at [ "data", "tasks" ] (JD.list taskDecoder)


createTaskResponseDecoder : JD.Decoder CreateTaskResponse
createTaskResponseDecoder =
    JP.decode CreateTaskResponse
        |> JP.required "tid" JD.string
        |> JP.required "task" taskDecoder
        |> JD.at [ "data", "createTask" ]



-- API


graphqlUrl : String
graphqlUrl =
    "/graphql"


fetchTasksQuery : String
fetchTasksQuery =
    """
    query {
      tasks {
        id
        label
        rank
        completedOn
        scheduledOn
      }
    }
  """


fetchTasksRequest : Http.Request (List StoryTask)
fetchTasksRequest =
    let
        body =
            JE.object [ ( "query", JE.string fetchTasksQuery ) ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body tasksResponseDecoder


makeTaskMutation : String
makeTaskMutation =
    """
    mutation($tid: String!, $label: String!, $position: Int!, $scheduledOn: String!) {
      createTask(tid: $tid, label:$label, position:$position, scheduledOn: $scheduledOn) {
        tid
        task {
          id
          label
          rank
          completedOn
          scheduledOn
        }
      }
    }
  """


makeTaskRequest : StoryTask -> Http.Request CreateTaskResponse
makeTaskRequest task =
    let
        variables =
            JE.object
                [ ( "tid", JE.string task.id )
                , ( "label", JE.string task.label )
                , ( "position", JE.int task.rank )
                , ( "scheduledOn", JE.string task.scheduledOn )
                ]

        body =
            JE.object
                [ ( "query", JE.string makeTaskMutation )
                , ( "variables", variables )
                ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body createTaskResponseDecoder
