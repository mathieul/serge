module Scrum.Data.Story exposing (Story, StoryId, story, newStory)

import String
import GraphQL.Request.Builder as B


-- LOCAL IMPORTS

import Scrum.Data.User as User exposing (User)


type alias StoryId =
    String


type alias Story =
    { id : StoryId
    , dev : Maybe User
    , pm : Maybe User
    , sort : Float
    , epic : Maybe String
    , points : Int
    , description : String
    }


newStory : List Story -> Story
newStory stories =
    let
        nextId =
            List.map .id stories
                |> List.maximum
                |> Result.fromMaybe "error"
                |> Result.andThen String.toInt
                |> Result.withDefault 0
                |> (+) 1
                |> toString
    in
        { id = nextId
        , dev = Nothing
        , pm = Nothing
        , sort = 0.0
        , epic = Nothing
        , points = 0
        , description = ""
        }



-- GRAPHQL


story : B.ValueSpec B.NonNull B.ObjectType Story vars
story =
    B.object Story
        |> B.with (B.field "id" [] B.string)
        |> B.with (B.field "dev" [] (B.nullable User.user))
        |> B.with (B.field "pm" [] (B.nullable User.user))
        |> B.with (B.field "sort" [] B.float)
        |> B.with (B.field "epic" [] (B.nullable B.string))
        |> B.with (B.field "points" [] B.int)
        |> B.with (B.field "description" [] B.string)
