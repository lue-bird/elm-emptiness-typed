module Scroll exposing
    ( Scroll(..), FocusGap
    , Location(..), nearest
    , empty, only
    , focusItem, focus
    , side
    , length
    , to, toGap
    , toEnd, toEndGap
    , toWhere
    , focusDrag
    , focusItemTry
    , map, focusSidesMap
    , foldFrom, fold
    , toStack, toList
    , mirror
    , focusAlter, sideAlter
    , focusGapAdapt
    )

{-| Items rolled up on both sides of a focus
→ good fit for dynamic choice selection: tabs, playlist, timeline...

[`Scroll`](#Scroll) can even focus a gap [`Down`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) and [`Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) every item.

1.  🔎 focus on a gap between two items
2.  🔌 plug that gap with a value
3.  💰 profit

@docs Scroll, FocusGap


## position

@docs Location, nearest


## create

@docs empty, only


## scan

@docs focusItem, focus
@docs side
@docs length


## move the focus

@docs to, toGap
@docs toEnd, toEndGap
@docs toWhere
@docs focusDrag


## transform

@docs focusItemTry
@docs map, focusSidesMap
@docs foldFrom, fold
@docs toStack, toList


### alter

@docs mirror
@docs focusAlter, sideAlter


## type-level

@docs focusGapAdapt

-}

import Hand exposing (Empty, Hand(..), emptyAdapt, fill, fillMap, fillMapFlat, filled)
import Linear exposing (DirectionLinear(..))
import Possibly exposing (Possibly(..))
import Stack exposing (Stacked, onTopLay, onTopStack, onTopStackAdapt, top, topRemove)


{-| Items rolled up on both sides of a focus
→ good fit for dynamic choice selection: tabs, playlist, ...

`Scroll` can even focus a gap `Down` and `Up` every item:

  - `🍍 🍓 <🍊> 🍉 🍇`: `Scroll ... Never FocusGap`

  - `🍍 🍓 <?> 🍉 🍇`: `Scroll ...` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `FocusGap`

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a gap between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`


#### in arguments

    empty : Scroll item_ Possibly FocusGap


#### in types

    type alias Model =
        RecordWithoutConstructorFunction
            { choice : Scroll Option Never FocusGap
            }

where [`RecordWithoutConstructorFunction`](https://dark.elm.dmy.fr/packages/lue-bird/elm-no-record-type-alias-constructor-function/latest/)
stops the compiler from creating a constructor function for `Model`.

-}
type Scroll item possiblyOrNever focusedOnGapTag
    = BeforeFocusAfter
        (Hand (Stacked item) Possibly Empty)
        (Hand item possiblyOrNever Empty)
        (Hand
            (Stacked item)
            Possibly
            Empty
        )


{-| A word in every [`Scroll`](#Scroll) type:

  - `🍍 🍓 <🍊> 🍉 🍇`: `Scroll ... Never FocusGap`

  - `🍍 🍓 <?> 🍉 🍇`: `Scroll ...` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `FocusGap`

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a gap between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`

-}
type FocusGap
    = FocusedOnGapTag Never



-- position


{-| Position in a [`Scroll`](#Scroll) relative to its focus.

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, filled, fillMap, fillMapFlat)
    import Stack exposing (topDown)

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.to (Scroll.AtSide Up 2)
        |> fillMap Scroll.focusItem
    --> filled 3
    --: Hand (Stacked number_) Possibly Empty

-}
type Location
    = AtSide DirectionLinear Int
    | AtFocus


{-| The [`Location`](#Location) directly [`Down`|`Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) the focus.

    import Hand exposing (Hand, Empty, filled, fillMap)
    import Stack exposing (onTopLay, topDown)
    import Scroll exposing (Scroll, FocusGap)
    import Linear exposing (DirectionLinear(..))

    Scroll.only "hello"
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "scrollable" [ "world" ] )
        |> Scroll.toEnd Up
        |> Scroll.to (Down |> Scroll.nearest)
        |> fillMap Scroll.focusItem
    --> filled "scrollable"
    --: Hand (Scroll String Never FocusGap) Possibly Empty

    Scroll.empty
        |> Scroll.sideAlter
            ( Down, \_ -> topDown "world" [ "scrollable" ] )
        |> Scroll.to (Down |> Scroll.nearest)
    --> Scroll.only "world"
    -->     |> Scroll.sideAlter
    -->         ( Down, \_ -> Stack.only "scrollable" )
    -->     |> filled
    --: Hand (Scroll String Never FocusGap) Possibly Empty

    Scroll.empty
        |> Scroll.sideAlter
            ( Up, onTopLay "foo" )
        |> Scroll.to (Up |> Scroll.nearest)
    --> filled (Scroll.only "foo")
    --: Hand (Scroll String Never FocusGap) Possibly

    nearest =
        \side ->
            Scroll.AtSide side 0

-}
nearest : DirectionLinear -> Location
nearest =
    \side_ ->
        AtSide side_ 0



--


{-| An empty `Scroll` on a gap
with nothing before and after it.
It's the loneliest of all [`Scroll`](#Scroll)s.

```monospace
<>
```

    import Hand

    Scroll.empty |> Scroll.toStack
    --> Hand.empty

-}
empty : Scroll item_ Possibly FocusGap
empty =
    BeforeFocusAfter Hand.empty Hand.empty Hand.empty


{-| A `Scroll` with a single focussed item in it,
nothing `Down` and `Up` it.

```monospace
🍊  ->  <🍊>
```

    import Stack

    Scroll.only "wat" |> Scroll.focusItem
    --> "wat"

    Scroll.only "wat" |> Scroll.toStack
    --> Stack.only "wat"

-}
only : element -> Scroll element never_ FocusGap
only currentItem =
    BeforeFocusAfter Hand.empty (filled currentItem) Hand.empty



--


{-| The focused item.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    import Stack exposing (topDown)
    import Linear exposing (DirectionLinear(..))

    Scroll.only "hi there" |> Scroll.focusItem
    --> "hi there"

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3, 4 ] )
        |> Scroll.toEnd Up
        |> Scroll.focusItem
    --> 4

-}
focusItem : Scroll item Never FocusGap -> item
focusItem =
    \scroll -> scroll |> focus |> Hand.fill


{-| The focused item or gap.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
🍍 🍓 <> 🍉 🍇  ->  _
```

    import Hand exposing (filled, fill)

    Scroll.empty |> Scroll.focus
    --> Hand.empty

    Scroll.only "hi there" |> Scroll.focus |> fill
    --> "hi there"

[`focusItem`](#focusItem) is short for `focus |> fill`.

-}
focus :
    Scroll item possiblyOrNever FocusGap
    -> Hand item possiblyOrNever Empty
focus =
    \(BeforeFocusAfter _ focus_ _) ->
        focus_


{-| The [`Stack`](Stack) to one [side](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) of the focus.

`Down`

```monospace
🍍←🍓) <🍊> 🍉 🍇
```

`Up`

```monospace
🍍 🍓 <🍊> (🍉→🍇
```

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Stack exposing (Stacked, topDown)
    import Linear exposing (DirectionLinear(..))

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.to (Up |> Scroll.nearest)
        |> fillMapFlat (Scroll.to (Up |> Scroll.nearest))
        |> fillMapFlat (Scroll.side Down)
    --> topDown 1 [ 0 ]
    --: Hand (Stacked number_) Possibly Empty

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.to (Up |> Scroll.nearest)
        |> fillMapFlat (Scroll.side Up)
    --> topDown 2 [ 3 ]
    --: Hand (Stacked number_) Possibly Empty

-}
side :
    DirectionLinear
    -> Scroll item possiblyOrNever_ FocusGap
    -> Hand (Stacked item) Possibly Empty
side sideToAccess =
    \scroll ->
        let
            (BeforeFocusAfter sideBefore _ sideAfter) =
                scroll
        in
        case sideToAccess of
            Down ->
                sideBefore

            Up ->
                sideAfter


{-| Counting all contained items.

    import Stack exposing (topDown)
    import Linear exposing (DirectionLinear(..))

    Scroll.only 0
        |> Scroll.sideAlter
            ( Down, \_ -> topDown -1 [ -2 ] )
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.length
    --> 6

    Scroll.empty
        |> Scroll.sideAlter
            ( Down, \_ -> topDown -1 [ -2 ] )
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.length
    --> 5

-}
length : Scroll item_ possiblyOrNever_ FocusGap -> Int
length =
    \(BeforeFocusAfter before focus_ after) ->
        (before |> Stack.length)
            + (case focus_ of
                Filled _ ->
                    1

                Empty _ ->
                    0
              )
            + (after |> Stack.length)



--


{-| Try to move the focus to the nearest item [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/).

**Should not be exposed**

-}
toItemNearest :
    DirectionLinear
    -> Scroll item possiblyOrNever_ FocusGap
    -> Hand (Scroll item never_ FocusGap) Possibly Empty
toItemNearest side_ =
    \scroll ->
        (scroll |> side side_)
            |> fillMap
                (\stacked ->
                    let
                        sideNew =
                            stacked |> filled |> topRemove

                        focusNew =
                            stacked |> filled |> top |> filled

                        sideOppositeNew =
                            (scroll |> side (side_ |> Linear.opposite))
                                |> onTopStack (scroll |> focus |> fillMapFlat Stack.only)
                    in
                    case side_ of
                        Down ->
                            BeforeFocusAfter sideNew focusNew sideOppositeNew

                        Up ->
                            BeforeFocusAfter sideOppositeNew focusNew sideNew
                )


{-| Try to move the [`focus`](#focus) to the item at a given [`Scroll.Location`](#Location).


#### `Scroll.to (Down |> Scroll.nearest)`

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, filled, fillMap)
    import Scroll exposing (Scroll, FocusGap)

    Scroll.empty |> Scroll.to (Down |> Scroll.nearest)
    --> Hand.empty

    Scroll.only "hello"
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "scrollable" [ "world" ] )
        |> Scroll.toEnd Up
        |> Scroll.to (Down |> Scroll.nearest)
        |> fillMap Scroll.focusItem
    --> filled "scrollable"
    --: Hand (Scroll String Never FocusGap) Possibly Empty

This also works from within gaps:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, filled)
    import Stack exposing (onTopLay)
    import Scroll exposing (Scroll, FocusGap)

    Scroll.empty
        |> Scroll.sideAlter
            ( Down, onTopLay "foo" )
        |> Scroll.to (Down |> Scroll.nearest)
    --> filled (Scroll.only "foo")
    --: Hand (Scroll String Never FocusGap) Possibly Empty


#### `Scroll.to (Up |> Scroll.nearest)`

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, filled, fillMap)
    import Scroll exposing (Scroll, FocusGap)

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.to (Up |> Scroll.nearest)
        |> fillMap Scroll.focusItem
    --> filled 1
    --: Hand number_ Possibly Empty

This also works from within gaps:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, filled)
    import Stack exposing (onTopLay)
    import Scroll exposing (Scroll, FocusGap)

    Scroll.empty
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only "foo" )
        |> Scroll.to (Up |> Scroll.nearest)
    --> filled (Scroll.only "foo")
    --: Hand (Scroll String Never FocusGap) Possibly

If there is no next item, the result is [`empty`](Hand#empty).

    import Linear exposing (DirectionLinear(..))
    import Hand
    import Stack exposing (topDown)

    Scroll.empty |> Scroll.to (Up |> Scroll.nearest)
    --> Hand.empty

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.toEnd Up
        |> Scroll.to (Up |> Scroll.nearest)
    --> Hand.empty


#### `Scroll.to Location`

    import Element as Ui
    import Element.Input as UIn
    import Hand exposing (fillMap)
    import RecordWithoutConstructorFunction exposing (RecordWithoutConstructorFunction)
    import Scroll exposing (FocusGap, Scroll)
    import Stack

    type alias Model =
        RecordWithoutConstructorFunction
            { numbers : Scroll Int Never FocusGap
            }

    type Event
        = NumberClicked Scroll.Location

    update : Event -> Model -> ( Model, Cmd Event )
    update event model =
        case event of
            NumberClicked location ->
                ( { model
                    | numbers =
                        model.numbers
                            |> Scroll.to location
                            |> Hand.fillElseOnEmpty (\_ -> model.numbers)
                            |> Scroll.focusAlter (fillMap (\n -> n + 1))
                  }
                , Cmd.none
                )

    interface : Model -> Ui.Element Event
    interface =
        \{ numbers } ->
            numbers
                |> Scroll.map numberInterface
                |> Scroll.toList
                |> Ui.column []

    numberInterface :
        Scroll.Location
        -> Int
        -> Ui.Element Event
    numberInterface location =
        \number ->
            UIn.button []
                { onPress = NumberClicked location |> Just
                , label =
                    number
                        |> String.fromInt
                        |> Ui.text
                }

The same _functionality_ is often provided as `duplicate : Scroll item ... -> Scroll (Scroll item) ...`

  - [turboMaCk/non-empty-list-alias: `List.NonEmpty.Zipper.duplicate`](https://package.elm-lang.org/packages/turboMaCk/non-empty-list-alias/latest/List-NonEmpty-Zipper#duplicate)
  - [miyamoen/select-list: `SelectList.selectedMap`](https://dark.elm.dmy.fr/packages/miyamoen/select-list/latest/SelectList#selectedMap)
  - [jjant/elm-comonad-zipper: `Zipper.duplicate`](https://package.elm-lang.org/packages/jjant/elm-comonad-zipper/latest/Zipper#duplicate)
  - [arowM/elm-reference: `Reference.List.unwrap`](https://dark.elm.dmy.fr/packages/arowM/elm-reference/latest/Reference-List#unwrap)

Saving a [`Scroll`](#Scroll) with every item becomes expensive for long [`Scroll`](#Scroll)s, though!

-}
to :
    Location
    -> Scroll item possiblyOrNever_ FocusGap
    -> Hand (Scroll item never_ FocusGap) Possibly Empty
to location =
    \scroll ->
        case location of
            AtFocus ->
                scroll
                    |> focusItemTry
                    |> Hand.emptyAdapt (\_ -> Possible)

            AtSide side_ sideIndex ->
                case sideIndex of
                    0 ->
                        scroll |> toItemNearest side_

                    sideIndexNot0 ->
                        if sideIndexNot0 >= 1 then
                            scroll
                                |> toItemNearest side_
                                |> fillMapFlat
                                    (to (AtSide side_ (sideIndex - 1)))

                        else
                            Hand.empty


{-| Move the focus to the gap directly [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/).
Feel free to [plug](#focusAlter) that gap right up!


#### `Scroll.toGap Down`

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled)
    import Stack exposing (topDown)

    Scroll.only "world"
        |> Scroll.toGap Down
        |> Scroll.focusAlter (\_ -> "hello" |> filled)
        |> Scroll.toStack
    --> topDown "hello" [ "world" ]


#### `Scroll.toGap Up`

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled)
    import Stack exposing (topDown)

    Scroll.only "hello"
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only "world" )
        |> Scroll.toGap Up
        |> Scroll.focusAlter (\_ -> filled "scrollable")
        |> Scroll.toStack
    --> topDown "hello" [ "scrollable", "world" ]

-}
toGap :
    DirectionLinear
    -> Scroll item Never FocusGap
    -> Scroll item Possibly FocusGap
toGap side_ =
    \(BeforeFocusAfter before focus_ after) ->
        case side_ of
            Down ->
                BeforeFocusAfter
                    before
                    Hand.empty
                    (after |> onTopLay (focus_ |> fill))

            Up ->
                BeforeFocusAfter
                    (before |> onTopLay (focus_ |> fill))
                    Hand.empty
                    after


{-| Focus the furthest item [`Down/Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) the focus.

`Down`

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

`Up`

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty)
    import Stack exposing (Stacked, topDown)

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3, 4 ] )
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 4 [ 3, 2 ] )
        |> Scroll.toEnd Down
        |> Scroll.focusItem
    --> 2

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3, 4 ] )
        |> Scroll.toEnd Up
        |> Scroll.focusItem
    --> 4

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3, 4 ] )
        |> Scroll.toEnd Up
        |> Scroll.side Down
    --> topDown 3 [ 2, 1 ]
    --: Hand (Stacked number_) Possibly Empty

-}
toEnd :
    DirectionLinear
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll item possiblyOrNever FocusGap
toEnd end =
    \scroll ->
        let
            stackWithEndOnTop =
                case end of
                    Up ->
                        mirror >> toStack

                    Down ->
                        toStack
        in
        case stackWithEndOnTop scroll of
            Empty possiblyOrNever ->
                empty |> focusGapAdapt (\_ -> possiblyOrNever)

            Filled (Stack.TopDown top_ down) ->
                case end of
                    Down ->
                        BeforeFocusAfter Hand.empty (top_ |> filled) (down |> Stack.fromList)

                    Up ->
                        BeforeFocusAfter (down |> Stack.fromList) (top_ |> filled) Hand.empty


{-| Focus the gap beyond the furthest item [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/).
Remember that gaps surround everything!

`Down`

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

`Up`

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled)
    import Stack exposing (topDown)

    Scroll.only 1
            -- <1>
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 3 [ 4 ] )
            -- <1> 3 4
        |> Scroll.toGap Up
            -- 1 <> 3 4
        |> Scroll.focusAlter (\_ -> filled 2)
            -- 1 <2> 3 4
        |> Scroll.toEndGap Down
            -- <> 1 2 3 4
        |> Scroll.focusAlter (\_ -> filled 0)
            -- <0> 1 2 3 4
        |> Scroll.toStack
    --> topDown 0 [ 1, 2, 3, 4 ]

    Scroll.only 1
            -- <1>
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3 ] )
            -- <1> 2 3
        |> Scroll.toEndGap Up
            -- 1 2 3 <>
        |> Scroll.focusAlter (\_ -> filled 4)
            -- 1 2 3 <4>
        |> Scroll.toStack
    --> topDown 1 [ 2, 3, 4 ]

-}
toEndGap :
    DirectionLinear
    -> Scroll item possiblyOrNever_ FocusGap
    -> Scroll item Possibly FocusGap
toEndGap side_ =
    \scroll ->
        case side_ of
            Down ->
                BeforeFocusAfter
                    Hand.empty
                    Hand.empty
                    (scroll
                        |> toStack
                        |> emptyAdapt (\_ -> Possible)
                    )

            Up ->
                BeforeFocusAfter
                    (scroll
                        |> mirror
                        |> toStack
                        |> emptyAdapt (\_ -> Possible)
                    )
                    Hand.empty
                    Hand.empty


{-| Move the focus to the nearest item [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) that matches a predicate.
If no such item was found return with [`Hand.empty`](Hand#empty).

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)
    import Linear exposing (DirectionLinear(..))

    Scroll.only 4
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 2 [ -1, 0, 3 ] )
        |> Scroll.toWhere ( Down, \_ item -> item < 0 )
        |> Hand.fillMap Scroll.focusItem
    --> filled -1

    Scroll.only 4
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ -1, 0, 3 ] )
        |> Scroll.toWhere ( Up, \_ item -> item < 0 )
        |> fillMap focusItem
    --> filled -1

    Scroll.only -4
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ -1, 0, 3 ] )
        |> Scroll.toWhere ( Up, \_ item -> item < 0 )
        |> fillMap focusItem
    --> filled -4

-}
toWhere :
    ( DirectionLinear
    , { index : Int } -> item -> Bool
    )
    -> Scroll item possiblyOrNever_ FocusGap
    -> Hand (Scroll item never_ FocusGap) Possibly Empty
toWhere ( side_, isFound ) =
    let
        scrollToNext next =
            \scroll ->
                scroll
                    |> toItemNearest side_
                    |> Hand.fillMapFlat
                        (toWhereFrom next)

        toWhereFrom { index } =
            \scroll ->
                case scroll |> focus of
                    Filled currentItem ->
                        if currentItem |> isFound { index = index } then
                            BeforeFocusAfter
                                (scroll |> side Down)
                                (filled currentItem)
                                (scroll |> side Up)
                                |> filled

                        else
                            scroll |> scrollToNext { index = index + 1 }

                    Empty _ ->
                        scroll |> scrollToNext { index = index + 1 }
    in
    toWhereFrom { index = 0 }


{-| Try to move the focus to the nearest item [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/).

`Down`

```monospace
🍊 🍉 <🍓> 🍇  ->  🍊 <🍓> 🍉 🍇
🍊 🍉 <> 🍇  ->  🍊 <> 🍉 🍇
```

`Up`

```monospace
🍊 <🍓> 🍉 🍇  ->  🍊 🍉 <🍓> 🍇
🍊 <> 🍉 🍇  ->  🍊 🍉 <> 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (Hand, Empty, fillMapFlat)
    import Scroll exposing (Scroll, FocusGap)

    Scroll.only 0
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.focusDrag Down
        |> fillMapFlat Scroll.toStack
    --> topDown 3 [ 2, 0, 1 ]
    --: Hand (Stacked number_) Possibly Empty

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.focusDrag Up
        |> fillMapFlat Scroll.toStack
    --> topDown 1 [ 0, 2, 3 ]
    --: Hand (Stacked number_) Possibly Empty

If there is no nearest item, the result is [`empty`](Hand#empty).

    import Linear exposing (DirectionLinear(..))
    import Hand
    import Stack exposing (topDown)

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.focusDrag Down
    --> Hand.empty

    Scroll.only 0
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 1 [ 2, 3 ] )
        |> Scroll.focusDrag Up
    --> Hand.empty

-}
focusDrag :
    DirectionLinear
    -> Scroll item possiblyOrNever FocusGap
    -> Hand (Scroll item possiblyOrNever FocusGap) Possibly Empty
focusDrag side_ =
    \scroll ->
        (scroll |> side side_)
            |> fillMap filled
            |> fillMap
                (\stackFilled ->
                    let
                        sideOppositeNew : Hand (Stacked item) Possibly Empty
                        sideOppositeNew =
                            (scroll |> side (side_ |> Linear.opposite))
                                |> onTopLay (stackFilled |> top)

                        focus_ : Hand item possiblyOrNever Empty
                        focus_ =
                            scroll |> focus

                        sideNew : Hand (Stacked item) Possibly Empty
                        sideNew =
                            stackFilled |> topRemove
                    in
                    case side_ of
                        Down ->
                            BeforeFocusAfter sideNew focus_ sideOppositeNew

                        Up ->
                            BeforeFocusAfter sideOppositeNew focus_ sideNew
                )



--


{-| Look [`Down|Up`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) the [`focus`](#focus) and operate directly an the [`Stack`](Stack) you see.


#### `sideAlter ( DirectionLinear, \_ -> 🍒🍋 )`

`Down`

```monospace
🍓 <🍊> 🍉
      ↓
🍋 🍒 <🍊> 🍉
```

`Up`

```monospace
🍍 🍓 <🍊> 🍉
      ↓
🍍 🍓 <🍊> 🍒 🍋
```

    import Linear exposing (DirectionLinear(..))
    import Hand
    import Stack exposing (topDown)

    Scroll.only "selectoo"
        |> Scroll.sideAlter
            ( Down, \_ -> topDown "earlee" [ "agua", "enutai" ] )
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "orangloo" [ "iquipy", "oice" ] )
        |> Scroll.sideAlter
            ( Up, \_ -> Hand.empty )
        |> Scroll.toStack
    --> topDown "enutai" [ "agua", "earlee", "selectoo" ]


#### `sideAlter ( DirectionLinear, Stack.map ... )`

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only "second"
        |> Scroll.sideAlter
            ( Down, \_ -> topDown "first" [ "zeroth" ] )
        |> Scroll.sideAlter
            ( Down, Stack.map (\_ -> String.toUpper) )
        |> Scroll.toStack
    --> topDown "ZEROTH" [ "FIRST", "second" ]

    Scroll.only "zeroth"
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "first" [ "second" ] )
        |> Scroll.sideAlter
            ( Up, Stack.map (\_ -> String.toUpper) )
        |> Scroll.toStack
    --> topDown "zeroth" [ "FIRST", "SECOND" ]

Look to one [side](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/) from the focus
and slide items in directly at the nearest location.


#### `sideAlter ( DirectionLinear, Stack.onTopGlue/onTopStack 🍒🍋 )`

`Down`

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

`Up`

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only 0
        |> Scroll.sideAlter
            ( Down, Stack.onTopGlue [ -4, -5 ] )
        |> Scroll.sideAlter
            ( Down, Stack.onTopStack (topDown -1 [ -2, -3 ]) )
        |> Scroll.toStack
    --> topDown -5 [ -4, -3, -2, -1, 0 ]

    Scroll.only 0
        |> Scroll.sideAlter
            ( Up, Stack.onTopGlue [ 4, 5 ] )
        |> Scroll.sideAlter
            ( Up, Stack.onTopStack (topDown 1 [ 2, 3 ]) )
        |> Scroll.toStack
    --> topDown 0 [ 1, 2, 3, 4, 5 ]


#### `Scroll.sideAlter ( DirectionLinear, \side -> 🍒🍋 |> onTopStack side )`

`Down`

```monospace
🍋🍒
 \↓ 🍍 🍓 <🍊> 🍉
```

`Up`

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown, onTopStack)

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \after -> topDown 2 [ 3, 4 ] |> onTopStack after )
        |> Scroll.toEnd Up
        |> Scroll.sideAlter
            ( Down, \before -> topDown 7 [ 6, 5 ] |> onTopStack before )
        |> Scroll.toStack
    --> topDown 5 [ 6, 7, 1, 2, 3, 4 ]

    Scroll.only 123
        |> Scroll.sideAlter
            ( Up, \after -> Stack.only 456 |> onTopStack after )
        |> Scroll.sideAlter
            ( Up, \after -> topDown 789 [ 0 ] |> onTopStack after )
        |> Scroll.toStack
    --> topDown 123 [ 456, 789, 0 ]


#### `sideAlter ( DirectionLinear,`[`Stack.onTopLay`](Stack#onTopLay) `... )`

`Down`

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```


#### `Up`

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown, onTopLay)

    Scroll.only 123
        |> Scroll.sideAlter
            ( Down, onTopLay 456 )
        |> Scroll.toStack
    --> topDown 456 [ 123 ]

    Scroll.only 123
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only 789 )
        |> Scroll.sideAlter
            ( Up, onTopLay 456 )
        |> Scroll.toStack
    --> topDown 123 [ 456, 789 ]

-}
sideAlter :
    ( DirectionLinear
    , Hand (Stacked item) Possibly Empty
      -> Hand (Stacked item) possiblyOrNever_ Empty
    )
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll item possiblyOrNever FocusGap
sideAlter ( facedSide, sideStackAlter ) =
    \scroll ->
        scroll
            |> focusSidesMap
                { side =
                    \stackSide ->
                        if stackSide == facedSide then
                            \sideStack ->
                                sideStack
                                    |> sideStackAlter
                                    |> Hand.emptyAdapt (\_ -> Possible)

                        else
                            identity
                , focus = identity
                }


{-| Swap the [stack](Stack) on the [`side Down`](#side) the [`focus`](#focus)
with the [stack](Stack) on the [`side Up`](#side).

```monospace
🍓 <🍊> 🍉 🍇  <->  🍇 🍉 <🍊> 🍓
```

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only 1
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 3, 4 ] )
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 4 [ 3, 2 ] )

In contrast to `List` or [stack](Stack), this can be done in `O(1)` time.

-}
mirror :
    Scroll item possiblyOrNever FocusGap
    -> Scroll item possiblyOrNever FocusGap
mirror =
    \(BeforeFocusAfter before_ focus_ after_) ->
        BeforeFocusAfter after_ focus_ before_



-- transform


{-| Change every item based on its current value.

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only "first"
        |> Scroll.sideAlter
            ( Down, \_ -> Stack.only "zeroth" )
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "second" [ "third" ] )
        |> Scroll.map (\_ -> String.toUpper)
        |> Scroll.toStack
    --> topDown "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

[`focusSidesMap`](#focusSidesMap) allows changing the individual parts separately.

-}
map :
    (Location -> item -> mappedItem)
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll mappedItem possiblyOrNever FocusGap
map changeItem =
    \scroll ->
        scroll
            |> focusSidesMap
                { side =
                    \side_ ->
                        Stack.map
                            (\{ index } ->
                                changeItem (AtSide side_ index)
                            )
                , focus = fillMap (changeItem AtFocus)
                }


{-| Fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
from the first item [`Up|Down`](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
as the initial accumulation value.

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only 234
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 345 [ 543 ] )
        |> Scroll.fold ( Up, max )
    --> 543

-}
fold :
    ( DirectionLinear
    , item -> item -> item
    )
    -> Scroll item Never FocusGap
    -> item
fold ( direction, reduce ) =
    \scroll ->
        (scroll |> side (direction |> Linear.opposite))
            |> onTopLay
                (scroll
                    |> side direction
                    |> onTopLay (scroll |> focusItem)
                    |> Stack.fold reduce
                )
            |> Stack.fold reduce


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    Scroll.only 'e'
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 'v' [ 'i', 'l' ] )
        |> Scroll.foldFrom ( "", Down, String.cons )
    --> "live"

    Scroll.only 'e'
        |> Scroll.sideAlter
            ( Down, \_ -> topDown 'v' [ 'i', 'l' ] )
        |> Scroll.foldFrom ( "", Up, String.cons )
    --> "evil"

-}
foldFrom :
    ( accumulationValue
    , DirectionLinear
    , item -> accumulationValue -> accumulationValue
    )
    -> Scroll item Never FocusGap
    -> accumulationValue
foldFrom ( accumulationValueInitial, direction, reduce ) =
    \(BeforeFocusAfter before focus_ after) ->
        after
            |> Stack.foldFrom
                ( before
                    |> onTopLay (focus_ |> fill)
                    |> Stack.foldFrom
                        ( accumulationValueInitial
                        , direction |> Linear.opposite
                        , reduce
                        )
                , direction
                , reduce
                )


{-| Alter the focus – [item or gap](Hand) – based on its current value.


#### `Scroll.focusAlter (\_ -> 🍊 |> filled)`

```monospace
🍊  ->  🍓 <?> 🍉  ->  🍓 <🍊> 🍉
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown, onTopLay)

    Scroll.empty
            -- <>
        |> Scroll.sideAlter
            ( Down, onTopLay "🍓" )
            -- "🍓" <>
        |> Scroll.sideAlter
            ( Up, onTopLay "🍉" )
            -- "🍓" <> "🍉"
        |> Scroll.focusAlter (\_ -> "🍊" |> filled)
            -- "🍓" <"🍊"> "🍉"
        |> Scroll.toStack
    --> topDown "🍓" [ "🍊", "🍉" ]


#### `Scroll.focusAlter (\_ -> Hand.empty)`

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)

    Scroll.only "hello"
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "scrollable" [ "world" ] )
        |> Scroll.to (Up |> Scroll.nearest)
        |> fillMap (Scroll.focusAlter (\_ -> Hand.empty))
        |> fillMap Scroll.toList
    --> filled [ "hello", "world" ]


#### `Scroll.focusAlter (?🍒 -> ?🍊)`

```monospace
(?🍒 -> ?🍊)  ->  🍓 <?🍒> 🍉  ->  🍓 <?🍊> 🍉
```

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown, onTopLay)

    Scroll.empty
            -- <>
        |> Scroll.sideAlter
            ( Down, onTopLay "🍓" )
            -- "🍓" <>
        |> Scroll.sideAlter
            ( Up, onTopLay "🍉" )
            -- "🍓" <> "🍉"
        |> Scroll.focusAlter
            (\_ -> filled "🍊")
            -- "🍓" <"🍊"> "🍉"
        |> Scroll.toStack
    --> topDown "🍓" [ "🍊", "🍉" ]

    Scroll.only "first"
        |> Scroll.sideAlter
            ( Down, \_ -> Stack.only "zeroth" )
        |> Scroll.sideAlter
            ( Up, \_ -> topDown "second" [ "third" ] )
        |> Scroll.focusAlter (fillMap String.toUpper)
        |> Scroll.toStack
    --> topDown "zeroth" [ "FIRST", "second", "third" ]

-}
focusAlter :
    (Hand item possiblyOrNever Empty
     -> Hand item possiblyOrNeverAltered Empty
    )
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll item possiblyOrNeverAltered FocusGap
focusAlter focusHandAlter =
    \(BeforeFocusAfter before focus_ after) ->
        BeforeFocusAfter
            before
            (focus_ |> focusHandAlter)
            after


{-| Change the [`focus`](#focus),
the [`side`](#side)s `Down` and `Up`
using different functions.

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)

    Scroll.only "first"
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only "second" )
        |> Scroll.toGap Up
        |> Scroll.focusAlter (\_ -> filled "one-and-a-halfth")
        |> Scroll.focusSidesMap
            { side =
                \side ->
                    Stack.map
                        (\_ item ->
                            String.concat
                                [ side |> sideToString, ": ", item ]
                        )
            , focus =
                fillMap (\item -> "focused item: " ++ item)
            }
        |> Scroll.toStack
    --→
    topDown
        "before: first"
        [ "focused item: one-and-a-halfth"
        , "after: second"
        ]

    sideToString =
        \side ->
            case side of
                Down ->
                    "before"

                Up ->
                    "after"

[`map`](#map) transforms every item.

-}
focusSidesMap :
    { focus :
        Hand item possiblyOrNever Empty
        -> Hand mappedItem possiblyOrNeverMapped Empty
    , side :
        DirectionLinear
        -> Hand (Stacked item) Possibly Empty
        -> Hand (Stacked mappedItem) possiblyOrNeverMappedBefore_ Empty
    }
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll mappedItem possiblyOrNeverMapped FocusGap
focusSidesMap changeFocusAndSideStacks =
    \(BeforeFocusAfter sideBefore focus_ sideAfter) ->
        BeforeFocusAfter
            (sideBefore
                |> changeFocusAndSideStacks.side Down
                |> emptyAdapt (\_ -> Possible)
            )
            (focus_ |> changeFocusAndSideStacks.focus)
            (sideAfter
                |> changeFocusAndSideStacks.side Up
                |> emptyAdapt (\_ -> Possible)
            )


{-| Converts it to a `List`, rolled out to both ends:

    import Linear exposing (DirectionLinear(..))
    import Stack

    Scroll.only 456
        |> Scroll.sideAlter
            ( Down, \_ -> Stack.only 123 )
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only 789 )
        |> Scroll.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`toStack`](#toStack) to preserve some information about its length.

-}
toList : Scroll item possiblyOrNever_ FocusGap -> List item
toList =
    \scroll ->
        scroll
            |> toStack
            |> Stack.toList


{-| Roll out the `Scroll` to both ends into a [`Stack`](Stack):

    import Linear exposing (DirectionLinear(..))
    import Hand exposing (filled)
    import Stack exposing (topDown)

    Scroll.empty
        |> Scroll.toStack
    --> Hand.empty

    Scroll.only 123
        |> Scroll.sideAlter
            ( Up, \_ -> Stack.only 789 )
        |> Scroll.toGap Up
        |> Scroll.focusAlter (\_-> filled 456)
        |> Scroll.toStack
    --> topDown 123 [ 456, 789 ]

the type information gets carried over, so

    Never Scroll.FocusGap -> Stacked Never Empty
    Possibly Scroll.FocusGap -> Stacked Possibly Empty

-}
toStack :
    Scroll item possiblyOrNever FocusGap
    -> Hand (Stacked item) possiblyOrNever Empty
toStack =
    \(BeforeFocusAfter before_ focus_ after_) ->
        after_
            |> onTopStackAdapt
                (focus_ |> fillMapFlat Stack.only)
            |> onTopStack
                (before_ |> Stack.reverse)



--


{-| [`Hand.empty`](Hand#empty) if the current focussed thing is a gap,
[`Hand.filled`](Hand#filled) if it's an item.

    import Hand
    import Stack exposing (topDown)
    import Linear exposing (DirectionLinear(..))

    Scroll.only 3
        |> Scroll.sideAlter
            ( Up, \_ -> topDown 2 [ 1 ] )
        |> Scroll.toGap Up
        |> Scroll.focusItemTry
    --> Hand.empty

-}
focusItemTry :
    Scroll item possiblyOrNever FocusGap
    -> Hand (Scroll item never_ FocusGap) possiblyOrNever Empty
focusItemTry =
    \scroll ->
        (scroll |> focus)
            |> Hand.fillMap
                (\focusedItem_ ->
                    scroll |> focusAlter (\_ -> focusedItem_ |> filled)
                )



--


{-| Change the `possiblyOrNever` type

  - A `Scroll ... possiblyOrNever FocusGap`
    can't be used as a `Scroll ... Possibly`?

        import Possibly exposing (Possibly(..))

        Scroll.focusGapAdapt (always Possible)

  - A `Scroll ... Never FocusGap`
    can't be unified with `Scroll ... Possibly` or `possiblyOrNever FocusGap`?

        Scroll.focusGapAdapt never

Please read more at [`Hand.emptyAdapt`](Hand#emptyAdapt).

-}
focusGapAdapt :
    (possiblyOrNever -> adaptedPossiblyOrNever)
    -> Scroll item possiblyOrNever FocusGap
    -> Scroll item adaptedPossiblyOrNever FocusGap
focusGapAdapt neverOrAlwaysPossible =
    \scroll ->
        scroll
            |> focusAlter
                (Hand.emptyAdapt neverOrAlwaysPossible)
