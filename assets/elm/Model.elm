module Model
    exposing
        ( AppConfig
        , AppMessage(..)
        , Confirmation
        , CreateTaskResponse
        , DatePeriod(..)
        , Id
        , Model
        , Msg(..)
        , TaskEditor
        , discardOldTasks
        , earliestYesterday
        , emptyConfirmation
        , formatShortDate
        , initialModel
        , makeNewTaskEditor
        , taskSchedule
        , tasksForCurrentTaskPeriod
        , taskToEditor
        , timeToAppContext
        )

import Dict exposing (Dict)
import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Button as Button
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)
import GraphQL.Client.Http as GraphQLClient
import Html5.DragDrop as DragDrop


-- LOCAL IMPORTS

import StoryTask exposing (StoryTask)


-- MODEL


type alias Model =
    { config : AppConfig
    , navState : Navbar.State
    , summaryModalState : Modal.State
    , confirmModalState : Modal.State
    , orderingModalState : Modal.State
    , dropdownStates : Dict String Dropdown.State
    , message : AppMessage
    , context : AppContext
    , timeZone : TimeZone
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , taskEditors : List TaskEditor
    , datePeriod : DatePeriod
    , showCompleted : Bool
    , showYesterday : Bool
    , confirmation : Confirmation
    , dragDrop : DragDrop.Model TaskEditor TaskEditor
    , reOrdered : List TaskEditor
    }


initialModel : AppConfig -> Navbar.State -> Model
initialModel config navState =
    { config = config
    , navState = navState
    , summaryModalState = Modal.hiddenState
    , confirmModalState = Modal.hiddenState
    , orderingModalState = Modal.hiddenState
    , dropdownStates = Dict.empty
    , message = MessageNone
    , context = makeEmptyAppContext
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , taskEditors = []
    , datePeriod = Today
    , showCompleted = False
    , showYesterday = False
    , confirmation = emptyConfirmation
    , dragDrop = DragDrop.init
    , reOrdered = []
    }



-- MESSAGES


type Msg
    = NoOp
    | NavMsg Navbar.State
    | SummaryModalMsg Modal.State
    | ConfirmModalMsg Modal.State
    | OrderingModalMsg Modal.State
    | DropdownMsg String Dropdown.State
    | ShowSummary
    | HideSummary
    | RequestConfirmation Confirmation
    | DiscardConfirmation
    | ShowOrdering
    | HideOrdering
    | UpdateCurrentTask String
    | UpdateEditingTask Id Bool String
    | AddCurrentTask
    | RequestTaskUpdate StoryTask
    | RequestTaskDeletion Id
    | FetchTasks (Result GraphQLClient.Error (List StoryTask))
    | CreateTask (Result GraphQLClient.Error CreateTaskResponse)
    | UpdateTask (Result GraphQLClient.Error StoryTask)
    | DeleteTask (Result GraphQLClient.Error StoryTask)
    | ClearMessage
    | UpdateAppContext Time
    | SetTimeZone String
    | ConfirmTaskDeletion Id String
    | ChangeDatePeriod DatePeriod
    | ToggleShowCompleted
    | ToggleShowYesterday
    | DragDropMsg (DragDrop.Msg TaskEditor TaskEditor)



-- APPLICATION CONTEXT


type alias AppContext =
    { yesterday : String
    , today : String
    , tomorrow : String
    , later : String
    }


makeEmptyAppContext : AppContext
makeEmptyAppContext =
    AppContext "" "" "" ""


timeToAppContext : TimeZone -> Time -> AppContext
timeToAppContext timeZone time =
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


taskSchedule : AppContext -> StoryTask -> DatePeriod
taskSchedule context task =
    case task.completedOn of
        Just completedOn ->
            if completedOn < context.today then
                Yesterday
            else if completedOn == context.today then
                Today
            else
                Tomorrow

        Nothing ->
            if task.scheduledOn < context.today then
                Yesterday
            else if task.scheduledOn == context.today then
                Today
            else if task.scheduledOn == context.tomorrow then
                Tomorrow
            else
                Later


formatShortDate : String -> String
formatShortDate date =
    (String.slice 5 7 date) ++ "/" ++ (String.slice 8 10 date)



-- CONFIRMATION


type alias Confirmation =
    { title : String
    , text : String
    , labelOk : String
    , btnOk : Button.Option Msg
    , msgOk : Msg
    , labelCancel : String
    , msgCancel : Msg
    }


emptyConfirmation : Confirmation
emptyConfirmation =
    { title = ""
    , text = ""
    , labelOk = "Ok"
    , msgOk = NoOp
    , btnOk = Button.primary
    , labelCancel = "Cancel"
    , msgCancel = DiscardConfirmation
    }



-- TASK EDITOR


type alias TaskEditor =
    { task : StoryTask
    , editing : Bool
    , editingLabel : String
    , period : DatePeriod
    }


makeNewTaskEditor : Model -> String -> TaskEditor
makeNewTaskEditor model scheduledOn =
    StoryTask.makeNewTask
        model.currentTaskSeq
        model.currentTaskLabel
        (List.length model.taskEditors)
        scheduledOn
        |> taskToEditor model.context


taskToEditor : AppContext -> StoryTask -> TaskEditor
taskToEditor context task =
    { task = task
    , editing = False
    , editingLabel = task.label
    , period = taskSchedule context task
    }


earliestYesterday : List TaskEditor -> String
earliestYesterday editors =
    editors
        |> List.filter (\editor -> editor.task.completed)
        |> List.map (\editor -> Maybe.withDefault "" editor.task.completedOn)
        |> List.minimum
        |> Maybe.withDefault ""


latestYesterday : String -> List TaskEditor -> String
latestYesterday today editors =
    let
        completedBeforeToday editor =
            case editor.task.completedOn of
                Just completedOn ->
                    completedOn < today

                Nothing ->
                    False
    in
        editors
            |> List.filter completedBeforeToday
            |> List.map (\editor -> Maybe.withDefault "" editor.task.completedOn)
            |> List.maximum
            |> Maybe.withDefault ""


discardOldTasks : AppContext -> List TaskEditor -> List TaskEditor
discardOldTasks context editors =
    let
        yesterday =
            latestYesterday context.today editors

        shouldKeep editor =
            case editor.task.completedOn of
                Just completedOn ->
                    completedOn >= yesterday

                Nothing ->
                    True
    in
        List.filter shouldKeep editors


tasksForCurrentTaskPeriod : Model -> List TaskEditor
tasksForCurrentTaskPeriod model =
    let
        selectPeriod editor =
            if not model.showYesterday && model.datePeriod == Today then
                editor.period == Yesterday || editor.period == Today
            else
                editor.period == model.datePeriod
    in
        List.filter selectPeriod model.taskEditors



-- MISCELLANEOUS


type alias Id =
    String


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , access_token : String
    }


type AppMessage
    = MessageNone
    | MessageSuccess String
    | MessageNotice String
    | MessageError String


type DatePeriod
    = Yesterday
    | Today
    | Tomorrow
    | Later


type alias CreateTaskResponse =
    { tid : String
    , task : StoryTask
    }
