module StoryTask
    exposing
        ( StoryTask
        , makeNewTask
        , changeSchedule
        , updateCompletedOn
        )

-- MODEL


type alias StoryTask =
    { id : String
    , label : String
    , rank : Int
    , scheduledOn : Maybe String
    , completedOn : Maybe String
    }



-- FUNCTIONS


makeNewTask : Int -> String -> Int -> Maybe String -> StoryTask
makeNewTask sequence label count scheduledOn =
    { id = "TMP:" ++ (toString sequence)
    , label = label
    , rank = count + 1
    , scheduledOn = scheduledOn
    , completedOn = Nothing
    }


changeSchedule : (StoryTask -> msg) -> Maybe String -> StoryTask -> msg
changeSchedule msg scheduledOn task =
    msg { task | scheduledOn = scheduledOn }


updateCompletedOn : (StoryTask -> msg) -> Maybe String -> StoryTask -> msg
updateCompletedOn msg completedOn task =
    msg { task | completedOn = completedOn }
