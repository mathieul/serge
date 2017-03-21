module StoryTask
    exposing
        ( StoryTask
        , makeNewTask
        , changeSchedule
        , toggleCompleted
        )

-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , completed : Bool
    , completedOn : Maybe String
    , scheduledOn : String
    }


makeNewTask : Int -> String -> Int -> String -> StoryTask
makeNewTask sequence label count scheduledOn =
    { id = "TMP:" ++ (toString sequence)
    , label = label
    , rank = count + 1
    , completed = False
    , completedOn = Nothing
    , scheduledOn = scheduledOn
    }


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
