module Playlist exposing (main)

import Browser
import Common exposing (actionUi, activeColor, eachSide0, interactColor, onEnter)
import Element as Ui exposing (rgb, rgba)
import Element.Background as UiBack
import Element.Border as UiBorder
import Element.Events as UIn
import Element.Font as Font
import Element.Input as UIn
import Emptiable exposing (Emptiable(..), fill, fillElseOnEmpty, map, mapFlat, filled)
import Html exposing (Html)
import Html.Attributes as Html
import Linear exposing (Direction(..))
import Possibly exposing (Possibly(..))
import RecordWithoutConstructorFunction exposing (RecordWithoutConstructorFunction)
import Scroll exposing (FocusGap, Scroll)
import Stack exposing (Stacked, topBelow)


type alias Model =
    RecordWithoutConstructorFunction
        { playlist : Emptiable (Scroll Track FocusGap Never) Possibly
        , urlOfTrackToAdd : String
        }


type alias Track =
    RecordWithoutConstructorFunction
        { artistInUrl : String
        , set : Set
        , titleInUrl : String
        }


type Set
    = Individual
    | Set


modelInitial : Model
modelInitial =
    { playlist = scrollInitial |> filled
    , urlOfTrackToAdd = ""
    }


scrollInitial : Scroll Track FocusGap never_
scrollInitial =
    -- add your own track urls
    -- PR your fav art :)
    Scroll.one
        { artistInUrl = "prrrrrrr-records"
        , set = Individual
        , titleInUrl = "can-we-fly-away-i-love-u"
        }
        |> Scroll.sideAlter Down
            (\_ ->
                topBelow
                    { artistInUrl = "culprate"
                    , set = Individual
                    , titleInUrl = "aqueous"
                    }
                    [ { artistInUrl = "prrrrrrr-records"
                      , set = Individual
                      , titleInUrl = "public-garden-the-heat-is-melting-the-mountains"
                      }
                    , { artistInUrl = "prrrrrrr-records"
                      , set = Individual
                      , titleInUrl = "kordz-strange"
                      }
                    ]
            )
        |> Scroll.sideAlter Up
            (\_ ->
                topBelow
                    { artistInUrl = "canopy_music"
                    , set = Individual
                    , titleInUrl = "caustics"
                    }
                    [ { artistInUrl = "upscale-recordings"
                      , set = Individual
                      , titleInUrl = "delusions"
                      }
                    , { artistInUrl = "anomaliebeats"
                      , set = Individual
                      , titleInUrl = "notre-dame-est"
                      }
                    ]
            )


main : Program () Model Event
main =
    Browser.element
        { init = \() -> ( modelInitial, Cmd.none )
        , view = windowInterface
        , update =
            \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscribe
        }


type Event
    = TrackFocused ( Linear.Direction, Int )
    | FocusTrackRemoveClicked
    | TrackToAddUrlChanged String
    | TrackAddSubmitted Track
    | FocusTrackDrag Linear.Direction


subscribe : Model -> Sub event_
subscribe =
    \_ -> Sub.none


update : Event -> Model -> Model
update event model =
    case event of
        TrackFocused ( side, index ) ->
            { model
                | playlist =
                    model.playlist
                        |> mapFlat
                            (Scroll.to (Scroll.AtSide side index))
            }

        FocusTrackRemoveClicked ->
            { model
                | playlist =
                    model.playlist
                        |> map (Scroll.focusAlter (\_ -> Emptiable.empty))
                        |> mapFlat
                            (\playlist ->
                                playlist
                                    |> Scroll.to (Down |> Scroll.nearest)
                                    |> map filled
                                    |> fillElseOnEmpty
                                        (\_ ->
                                            playlist
                                                |> Scroll.to (Up |> Scroll.nearest)
                                        )
                            )
            }

        TrackToAddUrlChanged urlOfTrackToAddUrlChanged ->
            { model
                | urlOfTrackToAdd =
                    urlOfTrackToAddUrlChanged
            }

        TrackAddSubmitted track ->
            { model
                | urlOfTrackToAdd = ""
                , playlist =
                    model.playlist
                        |> map
                            (\playlist ->
                                playlist
                                    |> Scroll.toGap Up
                                    |> Scroll.focusAlter
                                        (\_ -> track |> filled)
                            )
            }

        FocusTrackDrag side ->
            { model
                | playlist =
                    model.playlist
                        |> mapFlat (Scroll.focusDrag side)
            }


windowInterface : Model -> Html Event
windowInterface =
    \model ->
        model
            |> interface
            |> Ui.layoutWith
                { options =
                    [ Ui.focusStyle
                        { borderColor = activeColor |> Just
                        , backgroundColor = Nothing
                        , shadow = Nothing
                        }
                    ]
                }
                [ UiBack.color (rgb 0 0 0)
                , Font.color (rgb 1 1 1)
                ]


interface : Model -> Ui.Element Event
interface =
    \{ playlist, urlOfTrackToAdd } ->
        [ [ case playlist of
                Empty _ ->
                    Ui.text "add tracks to listen to"

                Filled scrollFilled ->
                    scrollFilled |> playlistInterface
          , urlOfTrackToAdd
                |> trackAddInterface
                |> Ui.el [ Ui.alignRight ]
          ]
            |> Ui.column
                [ Ui.spacing 40
                , Ui.width Ui.fill
                , Ui.height Ui.fill
                ]
        , (case playlist of
            Empty _ ->
                "playing: silence (the original)" |> Ui.text

            Filled playlistFilled ->
                playlistFilled |> Scroll.focusItem |> trackInterface
          )
            |> Ui.el
                [ Ui.width Ui.fill
                , Ui.centerX
                ]
        ]
            |> Ui.column
                [ Ui.spacing 40
                , Ui.centerX
                , Ui.centerY
                ]


playlistInterface : Scroll Track FocusGap Never -> Ui.Element Event
playlistInterface =
    \playlist ->
        playlist
            |> Scroll.focusSidesMap
                { focus =
                    \focus ->
                        [ focus
                            |> fill
                            |> .titleInUrl
                            |> stringInUrlClean
                            |> Ui.text
                        , [ case playlist |> Scroll.side Down of
                                Empty _ ->
                                    Ui.none

                                Filled _ ->
                                    dragInterface Down
                          , actionUi
                                { onPress = FocusTrackRemoveClicked
                                , label = "⨯" |> Ui.text
                                }
                                []
                          , case playlist |> Scroll.side Up of
                                Empty _ ->
                                    Ui.none

                                Filled _ ->
                                    dragInterface Up
                          ]
                            |> Ui.column [ Font.size 22 ]
                        ]
                            |> Ui.row
                                [ Ui.spacing 5
                                , Ui.alignRight
                                ]
                            |> filled
                , side =
                    \side sideStack ->
                        sideStack
                            |> Stack.map
                                (\{ index } track ->
                                    track
                                        |> trackOnSideInterface ( side, index )
                                        |> Ui.el
                                            [ Ui.alignRight ]
                                )
                }
            |> Scroll.toList
            |> Ui.column
                [ Ui.spacing 16
                , Ui.width Ui.fill
                , Font.color (rgb 1 1 1)
                , Font.family [ Font.monospace ]
                , Font.size 22
                ]


trackAddInterface : String -> Ui.Element Event
trackAddInterface urlOfTrackToAdd =
    [ { onChange = TrackToAddUrlChanged
      , text = urlOfTrackToAdd
      , placeholder = Nothing
      , label =
            "+ track by url"
                |> Ui.text
                |> UIn.labelBelow []
      }
        |> UIn.text
            [ UiBack.color (rgb 0 0 0)
            , Font.color (rgb 1 1 1)
            , UiBorder.widthEach { eachSide0 | bottom = 2 }
            , UiBorder.color interactColor
            , Ui.width (Ui.fill |> Ui.minimum 360)
            , Ui.alignRight
            ]
    , case urlOfTrackToAdd |> urlToTrack of
        Ok track ->
            actionUi
                { onPress = track |> TrackAddSubmitted
                , label =
                    "+"
                        |> Ui.text
                        |> Ui.el [ Font.size 30 ]
                }
                []

        Err userMessage ->
            userMessage |> Ui.text
    ]
        |> Ui.column [ Ui.spacing 5 ]


trackInterface : Track -> Ui.Element event_
trackInterface =
    \track ->
        Html.iframe
            [ Html.src
                (String.concat
                    [ "https://w.soundcloud.com/player/?url="
                    , track |> trackToUrl
                    , "&visual=true"
                    ]
                )
            , Html.attribute "scrolling" "no"
            , Html.attribute "frameborder" "no"
            ]
            []
            |> Ui.html


trackToUrl : Track -> String
trackToUrl =
    \{ artistInUrl, set, titleInUrl } ->
        String.concat
            [ "https://soundcloud.com/"
            , artistInUrl
            , "/"
            , case set of
                Individual ->
                    ""

                Set ->
                    "sets/"
            , titleInUrl
            ]


trackOnSideInterface :
    ( Linear.Direction, Int )
    -> Track
    -> Ui.Element Event
trackOnSideInterface ( side, index ) =
    \sideItem ->
        actionUi
            { onPress = TrackFocused ( side, index )
            , label =
                sideItem
                    |> .titleInUrl
                    |> stringInUrlClean
                    |> Ui.text
            }
            []


stringInUrlClean : String -> String
stringInUrlClean =
    \name ->
        name |> String.replace "-" " "


urlToTrack : String -> Result String Track
urlToTrack =
    \url ->
        case url |> String.split "/" of
            "https:" :: "" :: "soundcloud.com" :: artistInUrl :: [ titleInUrl ] ->
                { artistInUrl = artistInUrl, set = Individual, titleInUrl = titleInUrl }
                    |> Ok

            "https:" :: "" :: "soundcloud.com" :: artistInUrl :: "sets" :: [ titleInUrl ] ->
                { artistInUrl = artistInUrl, set = Set, titleInUrl = titleInUrl }
                    |> Ok

            _ ->
                "expected full url"
                    |> Err


dragInterface :
    Linear.Direction
    -> Ui.Element Event
dragInterface side =
    actionUi
        { onPress = FocusTrackDrag side
        , label =
            (case side of
                Down ->
                    "▲"

                Up ->
                    "▼"
            )
                |> Ui.text
        }
        []
