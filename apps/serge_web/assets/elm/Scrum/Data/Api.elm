module Scrum.Data.Api exposing (sendQueryRequest, sendMutationRequest, handleError)

import Task exposing (Task)
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
