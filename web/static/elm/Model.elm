module Model exposing (..)

import Http
import Time exposing (Time)
import Time.TimeZone exposing (TimeZone)
import Time.TimeZones as TimeZones
import StoryTask exposing (StoryTask, Scheduled(..))
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
    , message : AppMessage
    , dates : StoryTask.CurrentDates
    , timeZone : TimeZone
    , showSummary : Bool
    , currentTaskLabel : String
    , currentTaskSeq : Int
    , tasks : List StoryTask
    , scheduleTab : ScheduleTab
    , showCompleted : Bool
    }


type Msg
    = NoOp
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
    | ChangeScheduleTab ScheduleTab
    | ToggleShowCompleted
    | UpdateEditingTask String Bool String


type AppMessage
    = MessageNone
    | MessageNotice String
    | MessageError String


type ScheduleTab
    = TabAll
    | TabToday
    | TabTomorrow
    | TabLater



-- Functions


initialModel : AppConfig -> Model
initialModel config =
    { config = config
    , message = MessageNone
    , dates = StoryTask.makeEmptyCurrentDates
    , timeZone = TimeZones.utc ()
    , showSummary = False
    , currentTaskLabel = ""
    , currentTaskSeq = 1
    , tasks = []
    , scheduleTab = TabToday
    , showCompleted = False
    }
