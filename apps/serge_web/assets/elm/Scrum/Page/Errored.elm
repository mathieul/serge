module Scrum.Page.Errored exposing (view, pageLoadError, PageLoadError)

{-| The page that renders when there was an error trying to load another page,
for example a Page Not Found error.
-}

import Html exposing (Html, text, p)
import Bootstrap.Alert as Alert


-- LOCAL IMPORTS

import Scrum.Data.Session as Session exposing (Session)
import Scrum.Views.Page as Page exposing (ActivePage)


-- MODEL --


type PageLoadError
    = PageLoadError Model


type alias Model =
    { activePage : ActivePage
    , errorMessage : String
    }


pageLoadError : ActivePage -> String -> PageLoadError
pageLoadError activePage errorMessage =
    PageLoadError { activePage = activePage, errorMessage = errorMessage }



-- VIEW --


view : Session -> PageLoadError -> Html msg
view session (PageLoadError model) =
    Alert.danger
        [ Alert.h4 [] [ text "Oops, an error occurred" ]
        , p [] [ text model.errorMessage ]
        ]
