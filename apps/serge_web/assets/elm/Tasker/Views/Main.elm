module Tasker.Views.Main exposing (view)

import Html as H exposing (Html, div, text)
import Html.Attributes as A exposing (class, classList)
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal


-- LOCAL IMPORTS

import Tasker.Model exposing (..)
import Tasker.Views.ContentCard as ContentCard


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ ContentCard.view model
        , summaryModal model
        , confirmModal model
        ]


summaryModal : Model -> Html Msg
summaryModal model =
    let
        completedTasks =
            List.filter .completed model.taskEditors

        isScheduled editor =
            not editor.completed
                && (Maybe.map (\date -> date <= model.context.today) editor.task.scheduledOn |> Maybe.withDefault False)

        scheduledTasks =
            List.filter isScheduled model.taskEditors

        summaryTaskView editor =
            H.li [] [ text editor.task.label ]

        shortYesterday =
            formatShortDate <| earliestYesterday completedTasks
    in
        Modal.config SummaryModalMsg
            |> Modal.h4
                [ class "w-100 text-center" ]
                [ text <| "Scrum Summary (" ++ (formatShortDate model.context.today) ++ ")" ]
            |> Modal.body []
                [ div [ class "mt-3 mb-4" ]
                    [ H.h6 [ class "text-center mb-3" ]
                        [ text "Yesterday"
                        , H.small [ class "ml-1 text-muted" ]
                            [ text <| "(" ++ shortYesterday ++ ")" ]
                        ]
                    , H.ul [] (List.map summaryTaskView completedTasks)
                    ]
                , div [ class "mt-3 mb-4" ]
                    [ H.h6 [ class "text-center mb-3" ]
                        [ text "Today" ]
                    , H.ul [] (List.map summaryTaskView scheduledTasks)
                    ]
                ]
            |> Modal.footer []
                [ Button.button
                    [ Button.primary, Button.onClick HideSummary ]
                    [ text "Done" ]
                ]
            |> Modal.view model.summaryModalState


confirmModal : Model -> Html Msg
confirmModal model =
    let
        cfg =
            model.confirmation
    in
        Modal.config ConfirmModalMsg
            |> Modal.h4 [ class "w-100 -text-center" ] [ text cfg.title ]
            |> Modal.body []
                [ H.p [ class "lead" ] [ text cfg.text ] ]
            |> Modal.footer []
                [ Button.button
                    [ Button.secondary, Button.onClick cfg.msgCancel ]
                    [ text cfg.labelCancel ]
                , Button.button
                    [ cfg.btnOk
                    , Button.onClick cfg.msgOk
                    , Button.attrs [ A.style [ ( "min-width", "100px" ) ] ]
                    ]
                    [ text cfg.labelOk ]
                ]
            |> Modal.view model.confirmModalState
