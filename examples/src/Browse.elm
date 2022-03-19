module Browse exposing (main)

import Browser
import Element as Ui
import Hand exposing (Hand(..), fillMapFlat, fillOrWhenEmpty)
import Html exposing (Html)
import Possibly exposing (Possibly)
import Scroll exposing (FocusedOnGap, Scroll, Side(..), focusItem)


type alias Model =
    Scroll String Possibly FocusedOnGap


modelInitial : Model
modelInitial =
    Scroll.empty


main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( modelInitial, Cmd.none )
        , view = interface
        , update =
            \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscribe
        }


type Msg
    = Next
    | Previous
    | Remove
    | Add String
    | MoveItemUp
    | MoveItemDown


subscribe : Model -> Sub msg_
subscribe =
    \_ -> Sub.none


update : Msg -> Model -> Model
update msg model =
    case msg of
        Next ->
            -- Attempt to go forward, rollback if can't.
            model
                |> focusItem After
                |> fillOrWhenEmpty (\_ -> model)

        Previous ->
            -- Attempt to go back, rollback if can't.
            model
                |> focusItem Before
                |> fillOrWhenEmpty (\_ -> model)

        Remove ->
            case model |> fillMapFlat (focusItem Before) of
                -- Attempt to go back after.
                Filled collection ->
                    collection

                Nothing ->
                    model
                        |> Maybe.andThen (focusItem After)
                        |> fillOrWhenEmpty (\_ -> model)

        -- Attempt to go forward otherwise.
        Add item ->
            model
                |> fillMapFlat (P.appendGoR item)
                -- Attempt to append to an existing collection.
                |> fillOrWhenEmpty (\_ -> Scroll.only item)

        -- Make the collection a `Maybe` again.
        MoveItemUp ->
            -- Attempt to move item up, rollback if can't.
            model
                |> Maybe.map (P.withRollback P.switchR)

        MoveItemDown ->
            -- Attempt to move item down, rollback if can't.
            model
                |> Maybe.map (P.withRollback P.switchL)


interface : Model -> Html Msg
interface model =
    Ui.text ""
        |> Ui.layout []
