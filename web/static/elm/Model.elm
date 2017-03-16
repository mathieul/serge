module Model exposing (..)

import Dict exposing (Dict)
import Http
import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Bootstrap.Dropdown as Dropdown
import StoryTask exposing (StoryTask, CurrentDates)
import Api exposing (CreateTaskResponse)


-- Types


type alias AppConfig =
    { id : Int
    , name : String
    , email : String
    , access_token : String
    }


type alias Model =
    { config : AppConfig
    , navState : Navbar.State
    , modalState : Modal.State
    , dropdownStates : Dict String Dropdown.State
    , message : AppMessage
    , dates : StoryTask.CurrentDates
    , timeZone : TimeZone
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , tasks : List StoryTask
    , datePeriod : DatePeriod
    , showCompleted : Bool
    }


type Msg
    = NoOp
    | NavMsg Navbar.State
    | ModalMsg Modal.State
    | DropdownMsg String Dropdown.State
    | ShowSummary
    | HideSummary
    | FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error CreateTaskResponse)
    | UpdateTask (Result Http.Error StoryTask)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask
    | UpdateCurrentDates Time
    | SetTimeZone String
    | RequestTaskUpdate StoryTask
    | ChangeDatePeriod DatePeriod
    | ToggleShowCompleted
    | UpdateEditingTask String Bool String


type AppMessage
    = MessageNone
    | MessageNotice String
    | MessageError String


type DatePeriod
    = Yesterday
    | Today
    | Tomorrow
    | Later



-- Functions


initialModel : AppConfig -> Navbar.State -> Model
initialModel config navState =
    { config = config
    , navState = navState
    , modalState = Modal.hiddenState
    , dropdownStates = Dict.empty
    , message = MessageNone
    , dates = StoryTask.makeEmptyCurrentDates
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , datePeriod = Today
    , showCompleted = False
    }


taskSchedule : CurrentDates -> StoryTask -> DatePeriod
taskSchedule dates task =
    if task.scheduledOn < dates.today then
        Yesterday
    else if task.scheduledOn == dates.today then
        Today
    else if task.scheduledOn == dates.tomorrow then
        Tomorrow
    else
        Later
