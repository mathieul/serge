module GraphQL.Client.Http.Util exposing (..)

import Json.Encode
import Json.Decode
import Http
import Time exposing (Time)
import GraphQL.Response as Response


postBodyJson : String -> Maybe Json.Encode.Value -> Json.Encode.Value
postBodyJson documentString variableValues =
    let
        documentValue =
            Json.Encode.string documentString

        extraParams =
            variableValues
                |> Maybe.map (\obj -> [ ( "variables", obj ) ])
                |> Maybe.withDefault []
    in
        Json.Encode.object ([ ( "query", documentValue ) ] ++ extraParams)


postBody : String -> Maybe Json.Encode.Value -> Http.Body
postBody documentString variableValues =
    Http.jsonBody (postBodyJson documentString variableValues)


parameterizedUrl : String -> String -> Maybe Json.Encode.Value -> String
parameterizedUrl url documentString variableValues =
    let
        firstParamPrefix =
            if String.contains "?" url then
                "&"
            else
                "?"

        queryParam =
            firstParamPrefix ++ "query=" ++ Http.encodeUri documentString

        variablesParam =
            variableValues
                |> Maybe.map
                    (\obj ->
                        "&variables=" ++ Http.encodeUri (Json.Encode.encode 0 obj)
                    )
                |> Maybe.withDefault ""
    in
        url ++ queryParam ++ variablesParam


type alias RequestOptions =
    { method : String
    , headers : List Http.Header
    , url : String
    , timeout : Maybe Time
    , withCredentials : Bool
    }


type alias RequestError =
    { message : String
    , locations : List DocumentLocation
    }


type alias DocumentLocation =
    { line : Int
    , column : Int
    }


type Error
    = HttpError Http.Error
    | GraphQLError (List RequestError)


type alias RequestConfig a =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , expect : Http.Expect a
    , timeout : Maybe Time
    , withCredentials : Bool
    }


defaultRequestOptions : String -> RequestOptions
defaultRequestOptions url =
    { method = "POST"
    , headers = []
    , url = url
    , timeout = Nothing
    , withCredentials = False
    }


requestConfig :
    RequestOptions
    -> String
    -> Json.Decode.Decoder a
    -> Maybe Json.Encode.Value
    -> RequestConfig a
requestConfig requestOptions documentString dataDecoder variableValues =
    let
        decoder =
            Json.Decode.field "data" dataDecoder

        ( url, body ) =
            if requestOptions.method == "GET" then
                ( parameterizedUrl requestOptions.url documentString variableValues, Http.emptyBody )
            else
                ( requestOptions.url, postBody documentString variableValues )
    in
        { method = requestOptions.method
        , headers = requestOptions.headers
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = requestOptions.timeout
        , withCredentials = requestOptions.withCredentials
        }


errorsResponseDecoder : Json.Decode.Decoder (List RequestError)
errorsResponseDecoder =
    Json.Decode.field "errors" Response.errorsDecoder


convertHttpError : (Http.Error -> err) -> (List RequestError -> err) -> Http.Error -> err
convertHttpError wrapHttpError wrapGraphQLError httpError =
    let
        handleErrorWithResponseBody responseBody =
            responseBody
                |> Json.Decode.decodeString errorsResponseDecoder
                |> Result.map wrapGraphQLError
                |> Result.withDefault (wrapHttpError httpError)
    in
        case httpError of
            Http.BadStatus { body } ->
                handleErrorWithResponseBody body

            Http.BadPayload _ { body } ->
                handleErrorWithResponseBody body

            _ ->
                wrapHttpError httpError
