module Model exposing (..)

import Dict exposing (Dict)
import Http
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


-- Local imports

import StoryTask exposing (StoryTask)


-- Types


type alias Id =
    String


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
    , confirmModalState : Modal.State
    , dropdownStates : Dict String Dropdown.State
    , message : AppMessage
    , context : AppContext
    , timeZone : TimeZone
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , tasks : List StoryTask
    , datePeriod : DatePeriod
    , showCompleted : Bool
    , confirmation : Confirmation
    }


type Msg
    = NoOp
    | NavMsg Navbar.State
    | ModalMsg Modal.State
    | ConfirmModalMsg Modal.State
    | DropdownMsg String Dropdown.State
    | ShowSummary
    | HideSummary
    | RequestConfirmation Confirmation
    | DiscardConfirmation
    | FetchTasks (Result Http.Error (List StoryTask))
    | CreateTask (Result Http.Error CreateTaskResponse)
    | UpdateTask (Result Http.Error StoryTask)
    | ClearMessage
    | UpdateCurrentTask String
    | AddCurrentTask
    | UpdateAppContext Time
    | SetTimeZone String
    | RequestTaskUpdate StoryTask
    | ConfirmTaskDeletion Id String
    | ChangeDatePeriod DatePeriod
    | ToggleShowCompleted
    | UpdateEditingTask Id Bool String
    | RequestTaskDeletion Id
    | DeleteTask (Result Http.Error StoryTask)



-- | FetchTask (Result GraphQLClient.Error StoryTask)


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


type alias AppContext =
    { yesterday : String
    , today : String
    , tomorrow : String
    , later : String
    }


type alias Confirmation =
    { title : String
    , text : String
    , labelOk : String
    , btnOk : Button.Option Msg
    , msgOk : Msg
    , labelCancel : String
    , msgCancel : Msg
    }


type alias CreateTaskResponse =
    { tid : String
    , task : StoryTask
    }



-- Functions


initialModel : AppConfig -> Navbar.State -> Model
initialModel config navState =
    { config = config
    , navState = navState
    , modalState = Modal.hiddenState
    , confirmModalState = Modal.hiddenState
    , dropdownStates = Dict.empty
    , message = MessageNone
    , context = makeEmptyAppContext
    , timeZone = TimeZones.utc ()
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , datePeriod = Today
    , showCompleted = False
    , confirmation = emptyConfirmation
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
