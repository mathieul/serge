module Views.ContentCard exposing (view)

import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class)
import Html.Events exposing (onClick, onSubmit, onInput)
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col


-- LOCAL IMPORTS

import Model exposing (..)
import Views.Ordering as Ordering
import Views.TaskListCard as TaskListCard


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ div [ class "mt-3" ]
            [ Grid.row []
                [ Grid.col [ Col.sm2 ]
                    [ H.h2 [ class "mb-3" ] [ text "Tasker" ] ]
                , Grid.col [ Col.sm8 ]
                    [ div [ class "w-100 align-top" ] [ messageView model.message ] ]
                , Grid.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.warning
                        , Button.onClick ShowSummary
                        , Button.attrs [ class "pull-right" ]
                        ]
                        [ H.i [ class "fa fa-calendar" ] []
                        , text " Summary"
                        ]
                    ]
                ]
            , if model.orderingMode then
                Ordering.view model
              else
                taskCard model
            ]
        ]


messageView : AppMessage -> Html Msg
messageView message =
    let
        view kind content =
            div
                [ class <| "mb-0 alert alert-" ++ kind
                , A.attribute "role" "alert"
                ]
                [ H.button
                    [ A.type_ "button"
                    , class "close"
                    , onClick ClearMessage
                    ]
                    [ H.span [] [ text "×" ] ]
                , text content
                ]
    in
        case message of
            MessageNone ->
                div [] []

            MessageSuccess content ->
                view "success" content

            MessageNotice content ->
                view "info" content

            MessageError content ->
                view "danger" content


taskCard : Model -> Html Msg
taskCard model =
    Card.config [ Card.attrs [ class "mt-3" ] ]
        |> Card.block []
            [ Card.custom <| newTaskForm model
            , Card.custom <| TaskListCard.view model
            ]
        |> Card.view


newTaskForm : Model -> Html Msg
newTaskForm model =
    Form.form [ onSubmit AddCurrentTask ]
        [ Form.group []
            [ Form.row []
                [ Form.col [ Col.sm10 ]
                    [ Input.text
                        [ Input.large
                        , Input.onInput UpdateCurrentTask
                        , Input.value model.currentTaskLabel
                        , Input.attrs
                            [ A.placeholder "Enter new task..."
                            , A.autofocus True
                            ]
                        ]
                    ]
                , Form.col [ Col.sm2 ]
                    [ Button.button
                        [ Button.primary
                        , Button.block
                        , Button.large
                        , Button.attrs
                            [ A.type_ "submit"
                            , A.disabled (model.currentTaskLabel == "")
                            ]
                        ]
                        [ text "Create" ]
                    ]
                ]
            ]
        ]
