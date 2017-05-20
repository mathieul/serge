module Scrum.Data.Story exposing (Story, story)

import GraphQL.Request.Builder as B


-- LOCAL IMPORTS

import Scrum.Data.User as User exposing (User)


type alias Story =
    { id : String
    , dev : Maybe User
    , pm : Maybe User
    , sort : Float
    , epic : Maybe String
    , points : Int
    , description : String
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
