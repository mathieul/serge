module StoryTask
    exposing
        ( StoryTask
        , CreateTaskResponse
        , makeNewTask
        , storyTaskForm
        , storyTasksView
        , fetchTasksRequest
        , makeTaskRequest
        )

import Html exposing (Html, form, div, span, label, input, button, text, ul, li, i)
import Html.Attributes exposing (class, type_, placeholder, value, autofocus, disabled, name, checked)
import Html.Events exposing (onInput, onSubmit)
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


storyTasksView : String -> List StoryTask -> Html msg
storyTasksView today tasks =
    if List.isEmpty tasks then
        div [] []
    else
        div [ class "card" ]
            [ ul [ class "list-group list-group-flush" ]
                (List.map (oneTaskView today) tasks)
            ]


oneTaskView : String -> StoryTask -> Html msg
oneTaskView today task =
    li [ class "list-group-item d-flex flex-column align-items-start" ]
        [ div [ class " w-100 d-flex justify-content-between" ]
            [ span []
                [ i [ class "fa fa-circle text-info mr-2" ] []
                , text task.label
                ]
            , div []
                [ div [ class "btn-group" ]
                    [ button
                        [ class "btn btn-sm btn-outline-success"
                        , type_ "button"
                        ]
                        [ text "Today" ]
                    , button
                        [ class "btn btn-sm btn-outline-info"
                        , type_ "button"
                        ]
                        [ text "Tomorrow" ]
                    , button
                        [ class "btn btn-sm btn-outline-secondary"
                        , type_ "button"
                        ]
                        [ text "Later" ]
                    ]
                , button
                    [ class "btn btn-sm btn-outline-danger ml-5"
                    , type_ "button"
                    ]
                    [ i [ class "fa fa-check" ] [] ]
                ]
            ]
        ]



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
