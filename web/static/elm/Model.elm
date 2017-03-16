module Model exposing (..)

import Dict exposing (Dict)
import Http
import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import Bootstrap.Navbar as Navbar
import Bootstrap.Modal as Modal
import Bootstrap.Dropdown as Dropdown
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime)
import Time.TimeZone exposing (TimeZone)
import Time.ZonedDateTime as ZonedDateTime
import Time.Date as Date exposing (Date)


-- Local imports

import StoryTask exposing (StoryTask)
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
    , context : AppContext
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
    | UpdateAppContext Time
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


type alias AppContext =
    { yesterday : String
    , today : String
    , tomorrow : String
    , later : String
    }



-- Functions


initialModel : AppConfig -> Navbar.State -> Model
initialModel config navState =
    { config = config
    , navState = navState
    , modalState = Modal.hiddenState
    , dropdownStates = Dict.empty
    , message = MessageNone
    , context = makeEmptyAppContext
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , datePeriod = Today
    , showCompleted = False
    }


taskSchedule : AppContext -> StoryTask -> DatePeriod
taskSchedule context task =
    if task.scheduledOn < context.today then
        Yesterday
    else if task.scheduledOn == context.today then
        Today
    else if task.scheduledOn == context.tomorrow then
        Tomorrow
    else
        Later


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
