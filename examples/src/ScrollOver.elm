module ScrollOver exposing (main)

import Browser
import Common exposing (interactColor)
import Element as Ui exposing (rgb)
import Element.Background as UiBack
import Element.Font as Font
import Element.Input as UIn
import Emptiable exposing (map)
import Html exposing (Html)
import Linear exposing (Direction(..))
import List.Linear
import RecordWithoutConstructorFunction exposing (RecordWithoutConstructorFunction)
import Scroll exposing (FocusGap, Scroll)
import Stack


type alias Model =
    RecordWithoutConstructorFunction
        { numbers : List Int
        }


main : Program () Model Event
main =
    Browser.element
        { init = \() -> ( modelInitial, Cmd.none )
        , view = interface
        , update = update
        , subscriptions = subscribe
        }


modelInitial : Model
modelInitial =
    { numbers = [ 3, 4, 5, 6, 5, 46 ]
    }


type Event
    = NumberClicked Int


subscribe : Model -> Sub event_
subscribe =
    \_ -> Sub.none


update : Event -> Model -> ( Model, Cmd Event )
update event model =
    case event of
        NumberClicked index ->
            ( { model
                | numbers =
                    model.numbers
                        |> List.Linear.elementAlter ( Up, index )
                            (\n -> n + 1)
              }
            , Cmd.none
            )


interface : Model -> Html Event
interface =
    \{ numbers } ->
        numbers
            |> Stack.fromList
            |> Stack.map numberInterface
            |> Stack.toList
            |> Ui.column
                [ Ui.centerX
                , Ui.centerY
                ]
            |> Ui.layout
                [ UiBack.color (rgb 0 0 0)
                , Font.color (rgb 1 1 1)
                ]


numberInterface :
    { index : Int }
    -> Int
    -> Ui.Element Event
numberInterface { index } =
    \number ->
        UIn.button
            [ Ui.centerX
            , Ui.width Ui.fill
            ]
            { onPress = NumberClicked index |> Just
            , label =
                number
                    |> String.fromInt
                    |> Ui.text
                    |> Ui.el
                        [ Font.size 60
                        , Font.family [ Font.monospace ]
                        , Font.color interactColor
                        , Ui.centerX
                        , Ui.width Ui.fill
                        , Font.center
                        ]
            }
