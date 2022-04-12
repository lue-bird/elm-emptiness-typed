module Common exposing (actionUi, activeColor, eachSide0, interactColor, onEnter)

import Element as Ui exposing (rgb)
import Element.Font as Font
import Element.Input as UIn
import Html.Events as Html
import Json.Decode


interactColor : Ui.Color
interactColor =
    rgb 1 0.6 0


activeColor : Ui.Color
activeColor =
    rgb 0 1 0.3


eachSide0 : { right : number, top : number, left : number, bottom : number }
eachSide0 =
    { right = 0, top = 0, left = 0, bottom = 0 }


onEnter : event -> Ui.Attribute event
onEnter msg =
    Html.on "keyup"
        (Json.Decode.field "key" Json.Decode.string
            |> Json.Decode.andThen
                (\key ->
                    if key == "Enter" then
                        Json.Decode.succeed msg

                    else
                        Json.Decode.fail "Not the enter key"
                )
        )
        |> Ui.htmlAttribute


actionUi :
    { onPress : event, label : Ui.Element event }
    -> List (Ui.Attribute event)
    -> Ui.Element event
actionUi { onPress, label } attributes =
    { onPress = onPress |> Just
    , label =
        label
            |> Ui.el
                [ Font.color interactColor
                , Ui.mouseOver [ Font.color activeColor ]
                ]
    }
        |> UIn.button attributes
