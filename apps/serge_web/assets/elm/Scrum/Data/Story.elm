module Scrum.Data.Story exposing (Story, testing)

-- LOCAL IMPORTS

import Scrum.Data.User as User exposing (User)


type alias Story =
    { dev : Maybe User
    , pm : Maybe User
    , sort : Int
    , epic : String
    , points : Int
    , story : String
    }


testing : Story
testing =
    let
        dev =
            User 1 "John Zorn" "john@zorn.com"

        pm =
            User 2 "Jane Zune" "jane@zune.com"
    in
        { dev = Just dev
        , pm = Just pm
        , sort = 3
        , epic = ""
        , points = 3
        , story = "As a user I want to authenticate so I can use the application"
        }
