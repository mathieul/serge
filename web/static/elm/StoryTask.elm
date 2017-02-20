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
    }


type alias CreateTaskResponse =
    { tid : String
    , task : StoryTask
    }


makeNewTask : Int -> String -> Int -> StoryTask
makeNewTask sequence label count =
    let
        tid =
            "TMP:" ++ (toString sequence)
    in
        StoryTask tid label (count + 1)



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


storyTasksView : List StoryTask -> Html msg
storyTasksView tasks =
    if List.isEmpty tasks then
        div [] []
    else
        div [ class "card" ]
            [ ul [ class "list-group list-group-flush" ]
                (List.map oneTaskView tasks)
            ]


oneTaskView : StoryTask -> Html msg
oneTaskView task =
    li [ class "list-group-item d-flex flex-column align-items-start" ]
        [ div [ class " w-100 d-flex justify-content-between" ]
            [ span [] [ text task.label ]
            , form [ class "form-inline" ]
                [ scheduleOption "today" "Today" task
                , scheduleOption "tomorrow" "Tomorrow" task
                , scheduleOption "later" "Later" task
                , completedOption task
                ]
            ]
        ]


scheduleOption : String -> String -> StoryTask -> Html msg
scheduleOption theValue theLabel task =
    let
        badge =
            case theValue of
                "today" ->
                    "badge-success"

                "tomorrow" ->
                    "badge-info"

                _ ->
                    "badge-default"
    in
        div [ class "form-check form-check-inline" ]
            [ label [ class "form-check-label" ]
                [ input
                    [ class "form-check-input"
                    , type_ "radio"
                    , name <| "scheduled-for-" ++ task.id
                    , value theValue
                    , checked False
                    ]
                    []
                , span [ class <| "badge " ++ badge ]
                    [ text theLabel ]
                ]
            ]


completedOption : StoryTask -> Html msg
completedOption task =
    button
        [ class "btn btn-outline-danger btn-sm ml-5"
        , type_ "button"
        ]
        [ i [ class "fa fa-check" ] []
        ]



-- DECODERS / ENCODERS


taskDecoder : JD.Decoder StoryTask
taskDecoder =
    JP.decode StoryTask
        |> JP.required "id" JD.string
        |> JP.required "label" JD.string
        |> JP.required "rank" JD.int


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
    mutation($tid: String!, $label: String!, $position: Int!) {
      createTask(tid: $tid, label:$label, position:$position) {
        tid
        task {
          id
          label
          rank
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
                ]

        body =
            JE.object
                [ ( "query", JE.string makeTaskMutation )
                , ( "variables", variables )
                ]
                |> Http.jsonBody
    in
        Http.post graphqlUrl body createTaskResponseDecoder
