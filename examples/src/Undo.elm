module Undo exposing (main)

import Browser
import Common exposing (interactColor)
import Element as Ui exposing (rgb, rgba)
import Element.Background as UiBack
import Element.Font as Font
import Element.Input as UIn
import Emptiable exposing (Emptiable(..), fill, map, fillElseOnEmpty, filled)
import Html exposing (Html)
import Linear exposing (Direction(..))
import Scroll exposing (FocusGap, Scroll)
import Stack exposing (Stacked)



-- This was the model before


type alias CountersModel =
    { counter0 : Int
    , counter1 : Int
    }


countersInitial : CountersModel
countersInitial =
    { counter0 = 0
    , counter1 = 0
    }



-- Now we wrap it all in a Scroll


type alias Model =
    Scroll CountersModel FocusGap Never


modelInitial : Model
modelInitial =
    countersInitial
        |> Scroll.one


main : Program () Model Event
main =
    Browser.element
        { init = \() -> ( modelInitial, Cmd.none )
        , view = interface
        , update =
            \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscribe
        }



-- This was the update logic before


type CountersEvent
    = Increment0
    | Increment1


subscribe : Model -> Sub event_
subscribe =
    \_ -> Sub.none


countersUpdate : CountersEvent -> CountersModel -> CountersModel
countersUpdate countersEvent counters =
    case countersEvent of
        Increment0 ->
            { counters | counter0 = counters.counter0 + 1 }

        Increment1 ->
            { counters | counter1 = counters.counter1 + 1 }



-- Now it's all about Scrolls


type Event
    = CountersChanged CountersEvent
    | ReturnToState Linear.Direction


update : Event -> Model -> Model
update event eventScroll =
    case event of
        ReturnToState side ->
            eventScroll
                |> Scroll.to (side |> Scroll.nearest)
                |> fillElseOnEmpty (\_ -> eventScroll)

        CountersChanged countersEvent ->
            let
                next =
                    eventScroll
                        |> Scroll.focusItem
                        |> countersUpdate countersEvent
            in
            -- Adding the next state
            eventScroll
                |> Scroll.toGap Up
                |> Scroll.focusAlter (\_ -> next |> filled)



--


interface : Model -> Html Event
interface =
    \eventScroll ->
        [ eventScroll
            |> Scroll.focusItem
            |> countersInterface
            |> Ui.map CountersChanged
        , eventScroll
            |> scrollToEventInterface
        ]
            |> Ui.column
                [ Ui.spacing 58
                , Ui.centerX
                , Ui.centerY
                , Font.color (rgb 1 1 1)
                , Font.family [ Font.monospace ]
                , Font.size 50
                ]
            |> Ui.layout
                [ UiBack.color (rgb 0 0 0) ]


scrollToEventInterface :
    Scroll element_ FocusGap possiblyOrNever_
    -> Ui.Element Event
scrollToEventInterface =
    \eventScroll ->
        [ eventScroll
            |> Scroll.side Down
            |> eventScrollToOneSideInterface Down
        , eventScroll
            |> Scroll.side Up
            |> eventScrollToOneSideInterface Up
        ]
            |> Ui.row
                [ Ui.spacing 6
                , Ui.centerX
                ]


eventScrollToOneSideInterface :
    Linear.Direction
    -> Emptiable (Stacked element_) possiblyOrNever_
    -> Ui.Element Event
eventScrollToOneSideInterface side =
    \sideStack ->
        let
            length =
                sideStack |> Stack.length
        in
        [ length
            |> String.fromInt
            |> Ui.text
            |> Ui.el
                [ Font.size 24
                , Ui.centerX
                ]
        , case sideStack of
            Empty _ ->
                side
                    |> timeMovementInterface
                    |> Ui.el [ Ui.transparent True ]

            Filled _ ->
                UIn.button []
                    { onPress = ReturnToState side |> Just
                    , label =
                        side
                            |> timeMovementInterface
                            |> Ui.el [ Font.color interactColor ]
                    }
        ]
            |> Ui.column []


timeMovementInterface : Linear.Direction -> Ui.Element event_
timeMovementInterface side =
    side
        |> timeMovementSymbol
        |> Ui.text


timeMovementSymbol : Linear.Direction -> String
timeMovementSymbol =
    \side ->
        case side of
            Down ->
                "⟲"

            Up ->
                "⟳"



--


countersInterface : CountersModel -> Ui.Element CountersEvent
countersInterface =
    \counters ->
        [ [ counters.counter0 |> counterInterface
          , Increment0 |> incrementInterface
          ]
        , [ counters.counter1 |> counterInterface
          , Increment1 |> incrementInterface
          ]
        ]
            |> List.map (Ui.column [ Ui.spacing 8 ])
            |> Ui.row [ Ui.spacing 16 ]


counterInterface : Int -> Ui.Element event_
counterInterface =
    \counter ->
        counter
            |> String.fromInt
            |> Ui.text
            |> Ui.el
                [ Ui.centerX
                , Ui.centerY
                ]


incrementInterface : CountersEvent -> Ui.Element CountersEvent
incrementInterface countersEvent =
    UIn.button
        [ Ui.centerX
        , Ui.centerY
        , Font.color interactColor
        ]
        { onPress = countersEvent |> Just
        , label = "+" |> Ui.text
        }
