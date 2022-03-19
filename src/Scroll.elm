module Scroll exposing
    ( Scroll(..), FocusedOnGap
    , Side(..)
    , empty, only
    , focusedItem, focus
    , side
    , focusItem, focusGap
    , focusItemEnd, focusGapBeyondEnd
    , focusWhere
    , focusDrag
    , sideOpposite
    , mirror
    , insert, sideAlter
    , focusRemove, focusAlter
    , focusedOnItem
    , map, focusSidesMap
    , toStack, toList
    , adaptTypeFocusedOnGap
    )

{-| Items rolled up on both sides of a focus
→ good fit for dynamic choice selection: tabs, playlist, ...

`Scroll` can even focus a gap `Before` and `After` every item.

1.  🔎 focus on a gap between two items
2.  🔌 plug that gap with a value
3.  💰 profit


## type

@docs Scroll, FocusedOnGap
@docs Side


## create

@docs empty, only


## scan

@docs focusedItem, focus
@docs side


## move the focus

@docs focusItem, focusGap
@docs focusItemEnd, focusGapBeyondEnd
@docs focusWhere
@docs focusDrag


## alter

@docs sideOpposite
@docs mirror


### at one side of the focus

@docs insert, sideAlter


### at the focus

@docs focusRemove, focusAlter


## transform

@docs focusedOnItem
@docs map, focusSidesMap
@docs toStack, toList


## type-level

@docs adaptTypeFocusedOnGap

-}

import Hand exposing (Empty, Hand(..), adaptTypeEmpty, alterFill, feedFill, fill, fillMap, fillMapFlat, filled)
import Possibly exposing (Possibly(..))
import Stack exposing (Stacked, layOnTop, removeTop, stackOnTop, stackOnTopTyped, top)


{-| Items rolled up on both sides of a focus
→ good fit for dynamic choice selection: tabs, playlist, ...

`Scroll` can even focus a gap `Before` and `After` every item:

  - `🍍 🍓 <🍊> 🍉 🍇`: `Scroll ... Never FocusedOnGap`

  - `🍍 🍓 <?> 🍉 🍇`: `Scroll ...` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `FocusedOnGap`

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a gap between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`


#### in arguments

    empty : Scroll item_ Possibly FocusedOnGap


#### in types

    type alias Model =
        RecordWithoutConstructorFunction
            { choice : Scroll Option Never FocusedOnGap
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

  - `🍍 🍓 <🍊> 🍉 🍇`: `Scroll ... Never FocusedOnGap`

  - `🍍 🍓 <?> 🍉 🍇`: `Scroll ...` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `FocusedOnGap`

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a gap between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`

-}
type FocusedOnGap
    = FocusedOnGapTag Never



--


{-| Direction looking from the focus:
Either the [stack](Stack) to the left or to the right.

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Stack exposing (Stacked, topDown)
    import Scroll exposing (Side(..), focusItem)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusItem After
        |> fillMapFlat (focusItem After)
        |> fillMapFlat (Scroll.side Before)
    --> topDown 1 [ 0 ]
    --: Hand (Stacked number_) Possibly Empty

-}
type Side
    = Before
    | After


{-| Looking to the other [`Side`](#Side) of the focus: `Before` ⇆ `After`
-}
sideOpposite : Side -> Side
sideOpposite =
    \side_ ->
        case side_ of
            Before ->
                After

            After ->
                Before



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
empty : Scroll item_ Possibly FocusedOnGap
empty =
    BeforeFocusAfter Hand.empty Hand.empty Hand.empty


{-| A `Scroll` with a single focussed item in it,
nothing `Before` and `After` it.

```monospace
🍊  ->  <🍊>
```

    import Stack
    import Scroll exposing (focusedItem)

    Scroll.only "wat" |> focusedItem
    --> "wat"

    Scroll.only "wat" |> Scroll.toStack
    --> Stack.only "wat"

-}
only : element -> Scroll element never_ FocusedOnGap
only currentItem =
    BeforeFocusAfter Hand.empty (filled currentItem) Hand.empty



--


{-| The focused item.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusedItem, focusItemEnd)

    Scroll.only "hi there" |> focusedItem
    --> "hi there"

    Scroll.only 1
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3, 4 ])
        |> focusItemEnd After
        |> focusedItem
    --> 4

-}
focusedItem : Scroll item Never FocusedOnGap -> item
focusedItem =
    \scroll -> scroll |> focus |> Hand.fill


{-| The focused item or gap.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
🍍 🍓 <> 🍉 🍇  ->  _
```

    import Hand exposing (filled, fill)
    import Scroll exposing (focus)

    Scroll.empty |> focus
    --> Hand.empty

    Scroll.only "hi there" |> focus |> fill
    --> "hi there"

[`focusedItem`](#focusedItem) is short for `focus |> fill`.

-}
focus :
    Scroll item possiblyOrNever FocusedOnGap
    -> Hand item possiblyOrNever Empty
focus =
    \(BeforeFocusAfter _ focus_ _) ->
        focus_


{-| Look to one [side](#Side) from the focus.


#### `side Before`

```monospace
🍍←🍓) <🍊> 🍉 🍇
```

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Stack exposing (Stacked, topDown)
    import Scroll exposing (Side(..), focusItem)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusItem After
        |> fillMapFlat (focusItem After)
        |> fillMapFlat (Scroll.side Before)
    --> topDown 1 [ 0 ]
    --: Hand (Stacked number_) Possibly Empty


#### `side After`

```monospace
🍍 🍓 <🍊> (🍉→🍇
```

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Stack exposing (Stacked, topDown)
    import Scroll exposing (Side(..), focusItem)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusItem After
        |> fillMapFlat (Scroll.side After)
    --> topDown 2 [ 3 ]
    --: Hand (Stacked number_) Possibly Empty

-}
side :
    Side
    -> Scroll item possiblyOrNever_ FocusedOnGap
    -> Hand (Stacked item) Possibly Empty
side side_ =
    \(BeforeFocusAfter sideBefore _ sideAfter) ->
        case side_ of
            Before ->
                sideBefore

            After ->
                sideAfter



--


{-| Try to move the focus to the nearest item [`Before|After`](#Side) the focus.


#### `focusItem Before`

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    import Hand exposing (Hand, Empty, filled, fillMap)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusItem, focusItemEnd, focusedItem)

    Scroll.empty |> focusItem Before
    --> Hand.empty

    Scroll.only "hello"
        |> Scroll.sideAlter After
            (\_ -> topDown "scrollable" [ "world" ])
        |> focusItemEnd After
        |> focusItem Before
        |> fillMap focusedItem
    --> filled "scrollable"
    --: Hand (Scroll String Never FocusedOnGap) Possibly Empty

This also works from within gaps:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    import Hand exposing (Hand, Empty, filled)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusItem)

    Scroll.empty
        |> Scroll.insert Before "foo"
        |> focusItem Before
    --> filled (Scroll.only "foo")
    --: Hand (Scroll String Never FocusedOnGap) Possibly Empty


#### `focusItem After`

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Hand exposing (Hand, Empty, filled, fillMap)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusItem, focusedItem)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusItem After
        |> fillMap focusedItem
    --> filled 1
    --: Hand number_ Possibly Empty

This also works from within gaps:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Hand exposing (Hand, Empty, filled)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusItem)

    Scroll.empty
        |> Scroll.insert After "foo"
        |> focusItem After
    --> filled (Scroll.only "foo")
    --: Hand (Scroll String Never FocusedOnGap) Possibly

If there is no next item, the result is [`empty`](Hand#empty).

    import Hand
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusedItem, focusItem, focusItemEnd)

    Scroll.empty |> focusItem After
    --> Hand.empty

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusItemEnd After
        |> focusItem After
    --> Hand.empty

-}
focusItem :
    Side
    -> Scroll item possiblyOrNever_ FocusedOnGap
    -> Hand (Scroll item never_ FocusedOnGap) Possibly Empty
focusItem side_ =
    \scroll ->
        (scroll |> side side_)
            |> fillMap
                (\stacked ->
                    let
                        sideNew =
                            stacked |> filled |> removeTop

                        focusNew =
                            stacked |> filled |> top |> filled

                        sideOppositeNew =
                            (scroll |> side (side_ |> sideOpposite))
                                |> alterFill
                                    (layOnTop |> feedFill (scroll |> focus))
                    in
                    case side_ of
                        Before ->
                            BeforeFocusAfter sideNew focusNew sideOppositeNew

                        After ->
                            BeforeFocusAfter sideOppositeNew focusNew sideNew
                )


{-| Move the focus to the gap directly [`Before|After`](#Side) the focus.
Feel free to [plug](#focusAlter) that gap right up!


#### `focusGap Before`

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusGap, focusAlter)

    Scroll.only "world"
        |> focusGap Before
        |> focusAlter (\_ -> filled "hello")
        |> Scroll.toStack
    --> topDown "hello" [ "world" ]


#### `focusGap After`

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusAlter, focusGap)

    Scroll.only "hello"
        |> Scroll.sideAlter After
            (\_ -> Stack.only "world")
        |> focusGap After
        |> focusAlter (\_ -> filled "scrollable")
        |> Scroll.toStack
    --> topDown "hello" [ "scrollable", "world" ]

-}
focusGap :
    Side
    -> Scroll item Never FocusedOnGap
    -> Scroll item Possibly FocusedOnGap
focusGap side_ =
    \(BeforeFocusAfter before focus_ after) ->
        case side_ of
            Before ->
                BeforeFocusAfter
                    before
                    Hand.empty
                    (after |> layOnTop (focus_ |> fill))

            After ->
                BeforeFocusAfter
                    (before |> layOnTop (focus_ |> fill))
                    Hand.empty
                    after


{-| Focus the furthest item [`Before/After`](#Side) the focus.


#### `focusItemEnd Before`

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

    import Scroll exposing (Side(..), focusedItem)

    Scroll.only 1
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3, 4 ])
        |> Scroll.sideAlter Before
            (\_ -> topDown 4 [ 3, 2 ])
        |> Scroll.focusItemEnd Before
        |> focusedItem
    --> 2


#### `focusItemEnd After`

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    import Hand exposing (Hand, Empty)
    import Stack exposing (Stacked, topDown)
    import Scroll exposing (Side(..), focusItemEnd, focusedItem)

    Scroll.only 1
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3, 4 ])
        |> Scroll.focusItemEnd After
        |> focusedItem
    --> 4

    Scroll.only 1
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3, 4 ])
        |> focusItemEnd After
        |> Scroll.side Before
    --> topDown 3 [ 2, 1 ]
    --: Hand (Stacked number_) Possibly Empty

-}
focusItemEnd :
    Side
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNever FocusedOnGap
focusItemEnd side_ =
    \scroll ->
        let
            stackWithEndOnTop =
                case side_ of
                    After ->
                        mirror >> toStack

                    Before ->
                        toStack
        in
        case stackWithEndOnTop scroll |> fillMap filled of
            Empty possiblyOrNever ->
                empty |> focusAlter (\_ -> Empty possiblyOrNever)

            Filled stackFilled ->
                only (stackFilled |> top)
                    |> sideAlter (side_ |> sideOpposite)
                        (\_ -> stackFilled |> removeTop)


{-| Focus the gap beyond the furthest item [`Before|After`](#Side) the focus.
Remember that gaps surround everything!


#### `focusGapBeyondEnd Before`

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusAlter, focusGap, focusGapBeyondEnd)

    Scroll.only 1
            -- <1>
        |> Scroll.sideAlter After
            (\_ -> topDown 3 [ 4 ])
            -- <1> 3 4
        |> focusGap After
            -- 1 <> 3 4
        |> focusAlter (\_ -> filled 2)
            -- 1 <2> 3 4
        |> focusGapBeyondEnd Before
            -- <> 1 2 3 4
        |> focusAlter (\_ -> filled 0)
            -- <0> 1 2 3 4
        |> Scroll.toStack
    --> topDown 0 [ 1, 2, 3, 4 ]


#### `focusGapBeyondEnd After`

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusAlter, focusGapBeyondEnd)

    Scroll.only 1
            -- <1>
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3 ])
            -- <1> 2 3
        |> focusGapBeyondEnd After
            -- 1 2 3 <>
        |> focusAlter (\_ -> filled 4)
            -- 1 2 3 <4>
        |> Scroll.toStack
    --> topDown 1 [ 2, 3, 4 ]

-}
focusGapBeyondEnd :
    Side
    -> Scroll item possiblyOrNever_ FocusedOnGap
    -> Scroll item Possibly FocusedOnGap
focusGapBeyondEnd side_ =
    \scroll ->
        case side_ of
            Before ->
                BeforeFocusAfter
                    Hand.empty
                    Hand.empty
                    (scroll
                        |> toStack
                        |> adaptTypeEmpty (\_ -> Possible)
                    )

            After ->
                BeforeFocusAfter
                    (scroll
                        |> mirror
                        |> toStack
                        |> adaptTypeEmpty (\_ -> Possible)
                    )
                    Hand.empty
                    Hand.empty


{-| Move the focus to the nearest item [`Before|After`](#Side) that matches a predicate.
If no such item was found return with [`Hand.empty`](Hand#empty).


#### `focusWhere Before`

    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusWhere, focusedItem)

    Scroll.only 4
        |> Scroll.sideAlter Before
            (\_ -> topDown 2 [ -1, 0, 3 ])
        |> focusWhere Before (\item -> item < 0)
        |> Hand.fillMap focusedItem
    --> filled -1


#### `focusWhere After`

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusWhere)

    Scroll.only 4
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ -1, 0, 3 ])
        |> focusWhere After (\item -> item < 0)
        |> fillMap focusedItem
    --> filled -1

    Scroll.only -4
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ -1, 0, 3 ])
        |> focusWhere After (\item -> item < 0)
        |> fillMap focusedItem
    --> filled -4

-}
focusWhere :
    Side
    -> (item -> Bool)
    -> Scroll item possiblyOrNever_ FocusedOnGap
    -> Hand (Scroll item never_ FocusedOnGap) Possibly Empty
focusWhere side_ isFound =
    \scroll ->
        let
            step () =
                scroll
                    |> focusItem side_
                    |> Hand.fillMapFlat (focusWhere side_ isFound)
        in
        case scroll |> focus of
            Filled currentItem ->
                if currentItem |> isFound then
                    BeforeFocusAfter
                        (scroll |> side Before)
                        (filled currentItem)
                        (scroll |> side After)
                        |> filled

                else
                    step ()

            Empty _ ->
                step ()


{-| Try to move the focus to the nearest item [`Before|After`](#Side) the focus.


#### `focusDrag Before`

```monospace
🍊 🍉 <🍓> 🍇  ->  🍊 <🍓> 🍉 🍇
🍊 🍉 <> 🍇  ->  🍊 <> 🍉 🍇
```

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusDrag)

    Scroll.only 0
        |> Scroll.sideAlter Before
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusDrag Before
        |> fillMapFlat Scroll.toStack
    --> topDown 3 [ 2, 0, 1 ]
    --: Hand (Stacked number_) Possibly Empty

If there is no item `Before`, the result is [`empty`](Hand#empty).

    import Hand
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusDrag)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusDrag Before
    --> Hand.empty


#### `focusDrag After`

```monospace
🍊 <🍓> 🍉 🍇  ->  🍊 🍉 <🍓> 🍇
🍊 <> 🍉 🍇  ->  🍊 🍉 <> 🍇
```

    import Hand exposing (Hand, Empty, fillMapFlat)
    import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusDrag)

    Scroll.only 0
        |> Scroll.sideAlter After
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusDrag After
        |> fillMapFlat Scroll.toStack
    --> topDown 1 [ 0, 2, 3 ]
    --: Hand (Stacked number_) Possibly Empty

If there is no item `After`, the result is [`empty`](Hand#empty).

    import Hand
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusDrag)

    Scroll.only 0
        |> Scroll.sideAlter Before
            (\_ -> topDown 1 [ 2, 3 ])
        |> focusDrag After
    --> Hand.empty

-}
focusDrag :
    Side
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Hand (Scroll item possiblyOrNever FocusedOnGap) Possibly Empty
focusDrag side_ =
    \scroll ->
        (scroll |> side side_)
            |> fillMap filled
            |> fillMap
                (\stackFilled ->
                    let
                        sideOppositeNew : Hand (Stacked item) Possibly Empty
                        sideOppositeNew =
                            (scroll |> side (side_ |> sideOpposite))
                                |> layOnTop (stackFilled |> top)

                        focus_ : Hand item possiblyOrNever Empty
                        focus_ =
                            scroll |> focus

                        sideNew : Hand (Stacked item) Possibly Empty
                        sideNew =
                            stackFilled |> removeTop
                    in
                    case side_ of
                        Before ->
                            BeforeFocusAfter sideNew focus_ sideOppositeNew

                        After ->
                            BeforeFocusAfter sideOppositeNew focus_ sideNew
                )



--


{-| Remove the focussed thing and keep focusing on the created gap.

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusItem, focusRemove, focusAlter)

    Scroll.only "hello"
        |> Scroll.sideAlter After
            (\_ -> topDown "scrollable" [ "world" ])
        |> focusItem After
        |> fillMap focusRemove
        |> fillMap Scroll.toList
    --> filled [ "hello", "world" ]

    focusRemove =
        focusAlter (\_ -> Hand.empty)

-}
focusRemove :
    Scroll item possiblyOrNever_ FocusedOnGap
    -> Scroll item Possibly FocusedOnGap
focusRemove =
    focusAlter (\_ -> Hand.empty)


{-| Insert an item [`Before|After`](#Side) the focus.


#### `insert Before`

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```

    import Stack exposing (topDown)

    Scroll.only 123
        |> Scroll.insert Before 456
        |> Scroll.toStack
    --> topDown 456 [ 123 ]


#### `insert After`

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import Stack exposing (topDown)

    Scroll.only 123
        |> Scroll.sideAlter After (\_ -> Stack.only 789)
        |> Scroll.insert After 456
        |> Scroll.toStack
    --> topDown 123 [ 456, 789 ]

You can insert multiple items using [`sideAlter`](#sideAlter)`(`[`Stack.glueOnTop`](Stack#glueOnTop)/[`stackOnTop`](Stack#stackOnTop) ... `)`.
`insert` is just

    import Stack exposing (layOnTop)

    insert side item =
        Scroll.sideAlter side (layOnTop item)

-}
insert :
    Side
    -> item
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNever FocusedOnGap
insert side_ toInsertNearFocus =
    sideAlter side_ (layOnTop toInsertNearFocus)


{-| Look [`Before|After`](#Side) the [`focus`](#focus) and operate directly an the [`Stack`](Stack) you see.

    import Hand
    import Stack exposing (topDown)
    import Scroll exposing (Side(..))

    Scroll.only "selectoo"
        |> Scroll.sideAlter Before
            (\_ -> topDown "earlee" [ "agua", "enutai" ])
        |> Scroll.sideAlter After
            (\_ -> topDown "orangloo" [ "iquipy", "oice" ])
        |> Scroll.sideAlter After
            (\_ -> Hand.empty)
        |> Scroll.toStack
    --> topDown "enutai" [ "agua", "earlee", "selectoo" ]


#### `sideAlter Side (Stack.when ...)`

    import Stack exposing (topDown)
    import Scroll exposing (Side(..))

    Scroll.only "selectoo"
        |> Scroll.sideAlter Before
            (\_ -> topDown "earlee" [ "agua", "enutai" ])
        |> Scroll.sideAlter After
            (\_ -> topDown "orangloo" [ "iquipy", "oice" ])
        |> Scroll.sideAlter Before
            (Stack.when (String.startsWith "e"))
        |> Scroll.sideAlter After
            (Stack.when (String.startsWith "o"))
        |> Scroll.toStack
    --> topDown "enutai" [ "earlee", "selectoo", "orangloo", "oice" ]


#### `sideAlter Side (Stack.map ...)`

    import Stack exposing (topDown)
    import Scroll exposing (Side(..))

    Scroll.only "second"
        |> Scroll.sideAlter Before
            (\_ -> topDown "first" [ "zeroth" ])
        |> Scroll.sideAlter Before
            (Stack.map String.toUpper)
        |> Scroll.toStack
    --> topDown "ZEROTH" [ "FIRST", "second" ]

    Scroll.only "zeroth"
        |> Scroll.sideAlter After
            (\_ -> topDown "first" [ "second" ])
        |> Scroll.sideAlter After
            (Stack.map String.toUpper)
        |> Scroll.toStack
    --> topDown "zeroth" [ "FIRST", "SECOND" ]

Look to one [side](#Side) from the focus
and slide items in directly at the nearest location.


#### `sideAlter Side (Stack.glueOnTop/stackOnTop ...)`

`Before`

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

`After`

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import Stack exposing (topDown)
    import Scroll exposing (Side(..))

    Scroll.only 0
        |> Scroll.sideAlter Before
            (Stack.glueOnTop [ -4, -5 ])
        |> Scroll.sideAlter Before
            (Stack.stackOnTop (topDown -1 [ -2, -3 ]))
        |> Scroll.toStack
    --> topDown -5 [ -4, -3, -2, -1, 0 ]

    Scroll.only 0
        |> Scroll.sideAlter After
            (Stack.glueOnTop [ 4, 5 ])
        |> Scroll.sideAlter After
            (Stack.stackOnTop (topDown 1 [ 2, 3 ]))
        |> Scroll.toStack
    --> topDown 0 [ 1, 2, 3, 4, 5 ]


#### `Scroll.sideAlter Side (\side -> ... |> stackOnTop side)`

`Before`

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

`After`

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import Stack exposing (topDown, stackOnTop)
    import Scroll exposing (Side(..), focusItemEnd)

    Scroll.only 1
        |> Scroll.sideAlter After
            (\after -> topDown 2 [ 3, 4 ] |> stackOnTop after)
        |> focusItemEnd After
        |> Scroll.sideAlter Before
            (\before -> topDown 7 [ 6, 5 ] |> stackOnTop before)
        |> Scroll.toStack
    --> topDown 5 [ 6, 7, 1, 2, 3, 4 ]

    Scroll.only 123
        |> Scroll.sideAlter After
            (\after -> Stack.only 456 |> stackOnTop after)
        |> Scroll.sideAlter After
            (\after -> topDown 789 [ 0 ] |> stackOnTop after)
        |> Scroll.toStack
    --> topDown 123 [ 456, 789, 0 ]

-}
sideAlter :
    Side
    ->
        (Hand (Stacked item) Possibly Empty
         -> Hand (Stacked item) possiblyOrNever_ Empty
        )
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNever FocusedOnGap
sideAlter side_ sideStackAlter =
    let
        alterSideStack sideStack =
            sideStack
                |> sideStackAlter
                |> Hand.adaptTypeEmpty (\_ -> Possible)
    in
    case side_ of
        Before ->
            focusSidesMap
                { before = alterSideStack
                , focus = identity
                , after = identity
                }

        After ->
            focusSidesMap
                { before = identity
                , focus = identity
                , after = alterSideStack
                }


{-| Swap the [stack](Stack) on the [`side Before`](#side) the [`focus`](#focus)
with the [stack](Stack) on the [`side After`](#side) it.

```monospace
🍓 <🍊> 🍉 🍇  <->  🍇 🍉 <🍊> 🍓
```

    Scroll.only 1
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 3, 4 ])
        |> Scroll.sideAlter Before
            (\_ -> topDown 4 [ 3, 2 ])

In contrast to `List` or [stack](Stack), this can be done in `O(1)` time.

-}
mirror :
    Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNever FocusedOnGap
mirror =
    \(BeforeFocusAfter before_ focus_ after_) ->
        BeforeFocusAfter after_ focus_ before_



-- transform


{-| Change every item based on its current value.

    import Stack exposing (topDown)
    import Scroll exposing (Side(..))

    Scroll.only "first"
        |> Scroll.sideAlter Before
            (\_ -> Stack.only "zeroth")
        |> Scroll.sideAlter After
            (\_ -> topDown "second" [ "third" ])
        |> Scroll.map String.toUpper
        |> Scroll.toStack
    --> topDown "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

[`focusSidesMap`](#focusSidesMap) allows changing the individual parts separately.

-}
map :
    (item -> itemMapped)
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll itemMapped possiblyOrNever FocusedOnGap
map changeItem =
    \scroll ->
        scroll
            |> focusSidesMap
                { before = Stack.map changeItem
                , focus = fillMap changeItem
                , after = Stack.map changeItem
                }


{-| Alter the focus – [item or gap](Hand) – based on its current value.

```monospace
(?🍒 -> ?🍊)  ->  🍓 <?🍒> 🍉  ->  🍓 <?🍊> 🍉
```

    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)
    import Scroll exposing (focusAlter)

    focusRemove =
        focusAlter (\_ -> Hand.empty)

    Scroll.empty
            -- <>
        |> Scroll.insert Before "🍓"
            -- "🍓" <>
        |> Scroll.insert After "🍉"
            -- "🍓" <> "🍉"
        |> focusAlter (\_ -> filled "🍊")
            -- "🍓" <"🍊"> "🍉"
        |> Scroll.toStack
    --> topDown "🍓" [ "🍊", "🍉" ]

    Scroll.only "first"
        |> Scroll.sideAlter Before
            (\_ -> Stack.only "zeroth")
        |> Scroll.sideAlter After
            (\_ -> topDown "second" [ "third" ])
        |> focusAlter (fillMap String.toUpper)
        |> Scroll.toStack
    --> topDown "zeroth" [ "FIRST", "second", "third" ]

-}
focusAlter :
    (Hand item possiblyOrNever Empty
     -> Hand item possiblyOrNeverAltered Empty
    )
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNeverAltered FocusedOnGap
focusAlter focusHandAlter =
    \scroll ->
        BeforeFocusAfter
            (scroll |> side Before)
            (scroll |> focus |> focusHandAlter)
            (scroll |> side After)


{-| Change the [`focus`](#focus),
the [`side`](#side)s `Before` and `After`
using different functions.

    import Hand exposing (filled, fillMap)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusSidesMap, focusGap, focusAlter)

    Scroll.only "first"
        |> Scroll.sideAlter After
            (\_ -> Stack.only "second")
        |> focusGap After
        |> focusAlter (\_ -> filled "one-and-a-halfth")
        |> focusSidesMap
            { before =
                Stack.map (\item -> "before: " ++ item)
            , focus =
                fillMap (\item -> "focused item: " ++ item)
            , after =
                Stack.map (\item -> "after: " ++ item)
            }
        |> Scroll.toStack
    --> topDown
    -->     "before: first"
    -->     [ "focused item: one-and-a-halfth"
    -->     , "after: second"
    -->     ]

[`map`](#map) transforms every item
independent of its location relative to the [`focus`](#focus).

-}
focusSidesMap :
    { before :
        Hand (Stacked item) Possibly Empty
        -> Hand (Stacked itemMapped) possiblyOrNeverMappedBefore_ Empty
    , focus :
        Hand item possiblyOrNever Empty
        -> Hand itemMapped possiblyOrNeverMapped Empty
    , after :
        Hand (Stacked item) Possibly Empty
        -> Hand (Stacked itemMapped) possiblyOrNeverMappedAfter_ Empty
    }
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll itemMapped possiblyOrNeverMapped FocusedOnGap
focusSidesMap changeFocusAndSideStacks =
    \(BeforeFocusAfter sideBefore focus_ sideAfter) ->
        BeforeFocusAfter
            (sideBefore
                |> changeFocusAndSideStacks.before
                |> adaptTypeEmpty (\_ -> Possible)
            )
            (focus_ |> changeFocusAndSideStacks.focus)
            (sideAfter
                |> changeFocusAndSideStacks.after
                |> adaptTypeEmpty (\_ -> Possible)
            )


{-| Converts it to a `List`, rolled out to both ends:

    import Stack
    import Scroll exposing (Side(..))

    Scroll.only 456
        |> Scroll.sideAlter Before
            (\_ -> Stack.only 123)
        |> Scroll.sideAlter After
            (\_ -> Stack.only 789)
        |> Scroll.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`toStack`](#toStack) to preserve some information about its length.

-}
toList : Scroll item possiblyOrNever_ FocusedOnGap -> List item
toList =
    \scroll ->
        scroll
            |> toStack
            |> Stack.toList


{-| Roll out the `Scroll` to both ends into a [`Stack`](Stack):

    import Hand exposing (filled)
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusGap, focusAlter)

    Scroll.empty
        |> Scroll.toStack
    --> Hand.empty

    Scroll.only 123
        |> Scroll.sideAlter After
            (\_ -> Stack.only 789)
        |> focusGap After
        |> focusAlter (\_-> filled 456)
        |> Scroll.toStack
    --> topDown 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> Stack.Never
    Possibly

-}
toStack :
    Scroll item possiblyOrNever FocusedOnGap
    -> Hand (Stacked item) possiblyOrNever Empty
toStack =
    \(BeforeFocusAfter before_ focus_ after_) ->
        after_
            |> stackOnTopTyped
                (focus_ |> fillMapFlat Stack.only)
            |> stackOnTop
                (before_ |> Stack.reverse)



--


{-| [`Hand.empty`](Hand#empty) if the current focussed thing is a gap,
[`Hand.filled`](Hand#filled) if it's an item.

    import Hand
    import Stack exposing (topDown)
    import Scroll exposing (Side(..), focusGap, focusedOnItem)

    Scroll.only 3
        |> Scroll.sideAlter After
            (\_ -> topDown 2 [ 1 ])
        |> focusGap After
        |> focusedOnItem
    --> Hand.empty

-}
focusedOnItem :
    Scroll item possiblyOrNever FocusedOnGap
    -> Hand (Scroll item never_ FocusedOnGap) possiblyOrNever Empty
focusedOnItem =
    \scroll ->
        (scroll |> focus)
            |> Hand.fillMap
                (\focusedItem_ ->
                    scroll |> focusAlter (\_ -> filled focusedItem_)
                )



--


{-| Change the `possiblyOrNever` type

  - A `Scroll ... possiblyOrNever FocusedOnGap`
    can't be used as a `Scroll ... Possibly`?

        import Possibly exposing (Possibly(..))

        Scroll.adaptTypeFocusedOnGap (always Possible)

  - A `Scroll ... Never FocusedOnGap`
    can't be unified with `Scroll ... Possibly` or `possiblyOrNever FocusedOnGap`?

        Scroll.adaptTypeFocusedOnGap never

Please read more at [`Hand.adaptTypeEmpty`](Hand#adaptTypeEmpty).

-}
adaptTypeFocusedOnGap :
    (possiblyOrNever -> possiblyOrNeverAdapted)
    -> Scroll item possiblyOrNever FocusedOnGap
    -> Scroll item possiblyOrNeverAdapted FocusedOnGap
adaptTypeFocusedOnGap neverOrAlwaysPossible =
    \scroll ->
        scroll
            |> focusAlter (Hand.adaptTypeEmpty neverOrAlwaysPossible)
