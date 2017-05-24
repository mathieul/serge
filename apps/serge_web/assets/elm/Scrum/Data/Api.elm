module Scrum.Data.Api
    exposing
        ( sendQueryRequest
        , sendMutationRequest
        , handleError
        , graphQLErrorToMessage
        )

import Task exposing (Task)
import Http
import GraphQL.Request.Builder as B
import GraphQL.Client.Http as GraphQLClient


-- LOCAL IMPORTS

import Scrum.Views.Page as Page
import Scrum.Page.Errored as Errored exposing (PageLoadError, pageLoadError)


-- CONSTANTS


graphqlUrl : String
graphqlUrl =
    "/graphql"



-- QUERIES, MUTATIONS & REQUESTS


sendQueryRequest : B.Request B.Query a -> Task GraphQLClient.Error a
sendQueryRequest request =
    GraphQLClient.sendQuery graphqlUrl request


sendMutationRequest : B.Request B.Mutation a -> Task GraphQLClient.Error a
sendMutationRequest request =
    GraphQLClient.sendMutation graphqlUrl request


handleError : Page.ActivePage -> Task GraphQLClient.Error a -> Task PageLoadError a
handleError page task =
    let
        handleLoadError error =
            let
                _ =
                    Debug.log "handleError - error=" error
            in
                pageLoadError page "Backlog is currently unavailable."
    in
        Task.mapError handleLoadError task


httpErrorToMessage : Http.Error -> String
httpErrorToMessage error =
    case error of
        Http.BadUrl message ->
            "error in URL: " ++ message

        Http.NetworkError ->
            "error with the network connection"

        Http.BadStatus response ->
            let
                _ =
                    Debug.log "BadStatus error" response.body
            in
                (toString response.status.code)
                    ++ " "
                    ++ response.status.message

        Http.BadPayload message _ ->
            "decoding Failed: " ++ message

        _ ->
            (toString error)


graphQLErrorToMessage : String -> GraphQLClient.Error -> String
graphQLErrorToMessage label error =
    let
        message =
            case error of
                GraphQLClient.HttpError error ->
                    httpErrorToMessage error

                GraphQLClient.GraphQLError errors ->
                    toString errors
    in
        label ++ ": " ++ message
