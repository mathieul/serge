module Tasker.Routing exposing (matchers, parseLocation)

import Navigation exposing (Location)
import UrlParser exposing (Parser, map, oneOf, top)
import Tasker.Model exposing (Route(..))


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map HomeRoute top
        ]


parseLocation : Location -> Route
parseLocation location =
    let
        _ =
            Debug.log "location" location
    in
        case UrlParser.parseHash matchers location of
            Just route ->
                route

            Nothing ->
                NotFoundRoute
