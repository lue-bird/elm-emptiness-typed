module FocusList exposing
    ( ListFocusingHole
    , empty, only
    , current, before, after
    , next, previous, nextHole, previousHole
    , first, last, beforeFirst, afterLast
    , findForward, findBackward
    , alterCurrent, plug, remove
    , alterBefore, alterAfter
    , insertAfter, insertBefore
    , squeezeInBefore, squeezeInAfter
    , appendStack, append
    , prependStack, prepend
    , map, mapParts, toStack, toList
    , focusingItem
    , adaptHoleType
    )

{-| A list zipper that can also focus on a hole _between_ items.

1.  🔎 focus on a hole between two items
2.  🔌 plug that hole with a value
3.  💰 profit


## types

@docs ListFocusingHole


## create

@docs empty, only


## scan

@docs current, before, after


## navigate

@docs next, previous, nextHole, previousHole
@docs first, last, beforeFirst, afterLast
@docs findForward, findBackward


## modify


### modify the focus

@docs alterCurrent, plug, remove


### modify around the focus

@docs alterBefore, alterAfter
@docs insertAfter, insertBefore
@docs squeezeInBefore, squeezeInAfter


## glue

@docs appendStack, append
@docs prependStack, prepend


## transform

@docs map, mapParts, toStack, toList
@docs focusingItem


## type-level

@docs adaptHoleType

-}

import Fillable exposing (Empty(..), filled)
import Possibly exposing (Possibly(..))
import Stack exposing (StackFilled)


{-| A special kind of list with elements of type `item`.

The focus can be

  - `🍍 🍓 <🍊> 🍉 🍇`: `ListFocusingHole Never`

  - `🍍 🍓 <?> 🍉 🍇`: `ListFocusingHole` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly)

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a hole between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`


#### in arguments

    empty : ListFocusingHole Possibly item_


#### in types

    type alias Model =
        WithoutConstructorFunction
            { choice : ListFocusingHole Never Option
            }

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

-}
type ListFocusingHole possiblyOrNever item
    = FocusList
        (Empty Possibly (StackFilled item))
        (FocusHole possiblyOrNever item)
        (Empty
            Possibly
            (StackFilled item)
        )



--


type FocusHole possiblyOrNever item
    = Item item
    | Hole possiblyOrNever


hole : FocusHole Possibly item_
hole =
    Hole Possible


focusMap :
    (item -> itemMapped)
    -> FocusHole possiblyOrNever item
    -> FocusHole possiblyOrNever itemMapped
focusMap changeItem focus =
    case focus of
        Item item ->
            item |> changeItem |> Item

        Hole possiblyOrNever ->
            Hole possiblyOrNever



--


{-| An empty `FocusList` on a hole
with nothing before and after it.
It's the loneliest of all `FocusList`s.

```monospace
<>
```

    import Fillable
    import Stack

    FocusList.empty
        |> FocusList.toStack
    --> Fillable.empty

-}
empty : ListFocusingHole Possibly item_
empty =
    FocusList Fillable.empty hole Fillable.empty


{-| A `FocusList` with a single focussed item in it,
nothing before and after it.

```monospace
<🍊>
```

    import Stack

    FocusList.only "wat"
        |> FocusList.current
    --> "wat"

    FocusList.only "wat"
        |> FocusList.toStack
    --> Stack.only "wat"

-}
only : element -> ListFocusingHole never_ element
only current_ =
    FocusList Fillable.empty (Item current_) Fillable.empty



--


{-| The current focussed item.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    FocusList.only "hi there"
        |> FocusList.current
    --> "hi there"

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.last
        |> FocusList.current
    --> 4

-}
current : ListFocusingHole Never item -> item
current =
    \(FocusList _ focus _) ->
        case focus of
            Item item ->
                item

            Hole possiblyOrNever ->
                possiblyOrNever |> never


{-| The items before the location of the focus.

```monospace
🍍 🍓) <🍊> 🍉 🍇
```

    import Fillable exposing (Empty, filled)
    import Stack exposing (StackFilled, topAndBelow)

    FocusList.only 0
        |> FocusList.append [ 1, 2, 3 ]
        |> FocusList.next
        |> Fillable.andThen FocusList.next
        |> Fillable.map FocusList.before
    --> filled (topAndBelow 0 [ 1 ])
    --: Empty Possibly (Empty Possibly (StackFilled number_))

-}
before :
    ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (StackFilled item)
before =
    \(FocusList beforeFocusToFirst _ _) ->
        beforeFocusToFirst |> Stack.reverse


{-| The items after the current focussed location.

```monospace
🍍 🍓 <🍊> (🍉 🍇
```

    import Fillable exposing (Empty, filled)
    import Stack exposing (StackFilled, topAndBelow)

    FocusList.only 0
        |> FocusList.append [ 1, 2, 3 ]
        |> FocusList.next
        |> Fillable.map FocusList.after
    --> filled (topAndBelow 2 [ 3 ])
    --: Empty Possibly (Empty Possibly (StackFilled number_))

-}
after :
    ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (StackFilled item)
after =
    \(FocusList _ _ after_) ->
        after_



--


{-| Move the focus to the next item, if there is one.

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Fillable exposing (filled)

    FocusList.only 0
        |> FocusList.append [ 1, 2, 3 ]
        |> FocusList.next
        |> Fillable.map FocusList.current
    --> filled 1

This also works from within holes:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    import Fillable exposing (Empty, filled)

    FocusList.empty
        |> FocusList.insertAfter "foo"
        |> FocusList.next
    --> filled (FocusList.only "foo")
    --: Empty Possibly (ListFocusingHole Never String)

If there is no `next` item, the result is [`empty`](Fillable#empty).

    import Fillable

    FocusList.empty
        |> FocusList.next
    --> Fillable.empty

    FocusList.only 0
        |> FocusList.append [ 1, 2, 3 ]
        |> FocusList.last
        |> FocusList.next
    --> Fillable.empty

-}
next :
    ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
next (FocusList beforeFocusUntilHead focus after_) =
    case after_ of
        Empty _ ->
            Fillable.empty

        Filled ( next_, afterNext ) ->
            let
                newBeforeReversed =
                    case focus of
                        Hole _ ->
                            beforeFocusUntilHead

                        Item oldCurrent ->
                            Stack.addOnTop oldCurrent beforeFocusUntilHead
            in
            FocusList
                newBeforeReversed
                (Item next_)
                (afterNext |> Stack.fromList)
                |> filled


{-| Move the focus to the previous item, if there is one.

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    import Fillable exposing (Empty, filled)

    FocusList.empty |> FocusList.previous
    --> Fillable.empty

    FocusList.only "hello"
        |> FocusList.append [ "holey", "world" ]
        |> FocusList.last
        |> FocusList.previous
        |> Fillable.map FocusList.current
    --> filled "holey"
    --: Empty Possibly (ListFocusingHole Never String)

This also works from within holes:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    import Fillable exposing (Empty, filled)

    FocusList.empty
        |> FocusList.insertBefore "foo"
        |> FocusList.previous
    --> filled (FocusList.only "foo")
    --: Empty Possibly (ListFocusingHole Never String)

-}
previous :
    ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
previous listWithFocus =
    let
        (FocusList beforeFocusUntilHead _ _) =
            listWithFocus
    in
    beforeFocusUntilHead
        |> Fillable.map
            (\( previous_, beforePreviousToHead ) ->
                FocusList
                    (beforePreviousToHead |> Stack.fromList)
                    (Item previous_)
                    ((listWithFocus |> focusAndAfter)
                        |> Fillable.adaptType (\_ -> Possible)
                    )
            )


{-| Move the focus to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import Stack exposing (topAndBelow)

    FocusList.only "hello"
        |> FocusList.append [ "world" ]
        |> FocusList.nextHole
        |> FocusList.plug "holey"
        |> FocusList.toStack
    --> topAndBelow "hello" [ "holey", "world" ]

-}
nextHole :
    ListFocusingHole Never item
    -> ListFocusingHole Possibly item
nextHole listWithFocus =
    let
        (FocusList beforeFocusUntilHead _ after_) =
            listWithFocus
    in
    FocusList
        (Stack.addOnTop (current listWithFocus) beforeFocusUntilHead)
        hole
        after_


{-| Move the focus to the hole right before the current item. Feel free to plug
that hole right up!

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import Stack

    FocusList.only "world"
        |> FocusList.previousHole
        |> FocusList.plug "hello"
        |> FocusList.toStack
    --> Stack.topAndBelow "hello" [ "world" ]

-}
previousHole :
    ListFocusingHole Never item
    -> ListFocusingHole Possibly item
previousHole listWithFocus =
    let
        (FocusList before_ _ after_) =
            listWithFocus
    in
    FocusList
        before_
        hole
        (Stack.addOnTop (listWithFocus |> current) after_)



--


{-| Fill in or replace the focussed thing in the `FocusList`.

```monospace
🍓 <?> 🍉  ->  🍓 <🍒> 🍉
```

    import Stack

    FocusList.empty
        |> FocusList.insertBefore "🍓" -- "🍓" <>
        |> FocusList.insertAfter "🍉"  -- "🍓" <> "🍉"
        |> FocusList.plug "🍒"         -- "🍓" <"🍒"> "🍉"
        |> FocusList.toStack
    --> Stack.topAndBelow "🍓" [ "🍒", "🍉" ]

-}
plug :
    item
    -> ListFocusingHole possiblyOrNever_ item
    -> ListFocusingHole never_ item
plug newCurrent =
    \(FocusList before_ _ after_) ->
        FocusList before_ (Item newCurrent) after_


{-| Punch a hole by removing the focussed thing.

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    import Fillable exposing (filled)

    FocusList.only "hello"
        |> FocusList.append [ "holey", "world" ]
        |> FocusList.next
        |> Fillable.map FocusList.remove
        |> Fillable.map FocusList.toList
    --> filled [ "hello", "world" ]

-}
remove :
    ListFocusingHole possiblyOrNever_ item
    -> ListFocusingHole Possibly item
remove =
    \(FocusList before_ _ after_) ->
        FocusList before_ hole after_


{-| Insert an item after the focussed location.

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import Stack

    FocusList.only 123
        |> FocusList.append [ 789 ]
        |> FocusList.insertAfter 456
        |> FocusList.toStack
    --> Stack.topAndBelow 123 [ 456, 789 ]

Insert multiple items using [`squeezeInAfter`](#squeezeInAfter).

-}
insertAfter :
    item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
insertAfter toInsertAfterFocus =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            focus
            (Stack.addOnTop toInsertAfterFocus after_)


{-| Insert an item before the focussed location.

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```

    import Stack

    FocusList.only 123
        |> FocusList.insertBefore 456
        |> FocusList.toStack
    --> Stack.topAndBelow 456 [ 123 ]

Insert multiple items using [`squeezeInBefore`](#squeezeInBefore).

-}
insertBefore :
    item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
insertBefore itemToInsertBefore =
    \(FocusList beforeFocusUntilHead focus after_) ->
        FocusList
            (Stack.addOnTop itemToInsertBefore beforeFocusUntilHead)
            focus
            after_


focusAndAfter :
    ListFocusingHole possiblyOrNever item
    -> Empty possiblyOrNever (StackFilled item)
focusAndAfter =
    \(FocusList _ focus after_) ->
        case focus of
            Item cur ->
                Stack.addOnTop cur after_

            Hole possiblyOrNever ->
                case after_ of
                    Filled ( head_, tail_ ) ->
                        Stack.topAndBelow head_ tail_

                    Empty _ ->
                        Empty possiblyOrNever


{-| Append items directly after the focussed location.

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import Stack exposing (topAndBelow)

    FocusList.only 0
        |> FocusList.squeezeInAfter [ 4, 5 ]
        |> FocusList.squeezeInAfter [ 1, 2, 3 ]
        |> FocusList.toStack
    --> topAndBelow 0 [ 1, 2, 3, 4, 5 ]

-}
squeezeInAfter :
    List item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
squeezeInAfter toAppendDirectlyAfterFocus =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            focus
            (after_
                |> Stack.stackOnTop
                    (toAppendDirectlyAfterFocus |> Stack.fromList)
            )


{-| Prepend items directly before the focussed location.

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

    import Stack exposing (topAndBelow)

    FocusList.only 0
        |> FocusList.squeezeInBefore [ -5, -4 ]
        |> FocusList.squeezeInBefore [ -3, -2, -1 ]
        |> FocusList.toStack
    --> topAndBelow -5 [ -4, -3, -2, -1, 0 ]

-}
squeezeInBefore :
    List item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
squeezeInBefore toPrependDirectlyBeforeFocus =
    \(FocusList beforeFocusToFirst focus after_) ->
        FocusList
            (beforeFocusToFirst
                |> Stack.stackOnTop
                    (toPrependDirectlyBeforeFocus
                        |> List.reverse
                        |> Stack.fromList
                    )
            )
            focus
            after_


{-| Put items to the end after anything else.

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import Stack exposing (topAndBelow)

    FocusList.only 123
        |> FocusList.append [ 456 ]
        |> FocusList.append [ 789, 0 ]
        |> FocusList.toStack
    --> topAndBelow 123 [ 456, 789, 0 ]

-}
append :
    List item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
append itemsToAppend =
    \focusList ->
        focusList
            |> appendStack (itemsToAppend |> Stack.fromList)


{-| Put a [stack](Stack) of items to the end after anything else.

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import Stack exposing (topAndBelow)

    FocusList.only 123
        |> FocusList.append [ 456 ]
        |> FocusList.append [ 789, 0 ]
        |> FocusList.toStack
    --> topAndBelow 123 [ 456, 789, 0 ]

-}
appendStack :
    Empty stackPossiblyOrNever_ (StackFilled item)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
appendStack stackToAppend =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            focus
            (stackToAppend
                |> Stack.stackOnTop after_
                |> Fillable.adaptType (\_ -> Possible)
            )


{-| Put items to the beginning before anything else.

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

    import Stack exposing (topAndBelow)

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.last
        |> FocusList.prepend [ 5, 6, 7 ]
        |> FocusList.toStack
    --> topAndBelow 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prepend :
    List item
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
prepend itemsToPrepend =
    \focusList ->
        focusList
            |> prependStack
                (itemsToPrepend |> Stack.fromList)


{-| Put a [stack](Stack) of items to the beginning before anything else.

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

    import Stack exposing (topAndBelow)

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.last
        |> FocusList.prependStack (topAndBelow 5 [ 6, 7 ])
        |> FocusList.toStack
    --> topAndBelow 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prependStack :
    Empty stackPossiblyOrNever_ (StackFilled item)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
prependStack stackToPrepend =
    \(FocusList beforeFocusUntilHead focus after_) ->
        FocusList
            (stackToPrepend
                |> Stack.reverse
                |> Stack.stackOnTop beforeFocusUntilHead
                |> Fillable.adaptType (\_ -> Possible)
            )
            focus
            after_


{-| Focus the first item.

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.prepend [ 4, 3, 2 ]
        |> FocusList.first
        |> FocusList.current
    --> 4

-}
first :
    ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
first =
    \listWithFocus ->
        case listWithFocus |> before of
            Empty _ ->
                listWithFocus

            Filled ( top, afterHeadBeforeCurrent ) ->
                FocusList
                    Fillable.empty
                    (Item top)
                    ((listWithFocus |> focusAndAfter)
                        |> Stack.stackOnTop
                            (afterHeadBeforeCurrent |> Stack.fromList)
                        |> Fillable.adaptType (\_ -> Possible)
                    )


{-| Focus the last item.

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    import Stack exposing (topAndBelow)

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.last
        |> FocusList.current
    --> 4

    FocusList.only 1
        |> FocusList.append [ 2, 3, 4 ]
        |> FocusList.last
        |> FocusList.before
    --> topAndBelow 1 [ 2, 3 ]
    --: Empty Possibly (StackFilled number_)

-}
last :
    ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
last =
    \focusList ->
        let
            (FocusList before_ focus after_) =
                focusList
        in
        case Stack.reverse after_ of
            Empty _ ->
                focusList

            Filled ( last_, beforeLastUntilFocus ) ->
                let
                    focusToFirst =
                        case focus of
                            Item current_ ->
                                Stack.addOnTop current_ before_

                            _ ->
                                before_
                in
                FocusList
                    (focusToFirst
                        |> Stack.stackOnTop
                            (beforeLastUntilFocus |> Stack.fromList)
                    )
                    (Item last_)
                    Fillable.empty


{-| Focus the hole before the first item.
Remember that holes surround everything!

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

    import Stack

    FocusList.only 1                 -- <1>
        |> FocusList.append [ 3, 4 ] -- <1> 3 4
        |> FocusList.nextHole        -- 1 <> 3 4
        |> FocusList.plug 2          -- 1 <2> 3 4
        |> FocusList.beforeFirst     -- <> 1 2 3 4
        |> FocusList.plug 0          -- <0> 1 2 3 4
        |> FocusList.toStack
    --> Stack.topAndBelow 0 [ 1, 2, 3, 4 ]

-}
beforeFirst :
    ListFocusingHole possiblyOrNever_ item
    -> ListFocusingHole Possibly item
beforeFirst =
    \listWithFocus ->
        FocusList
            Fillable.empty
            hole
            (listWithFocus |> toList |> Stack.fromList)


{-| Focus the hole after the end. Into the nothingness.

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import Stack

    FocusList.only 1                 -- <1>
        |> FocusList.append [ 2, 3 ] -- <1> 2 3
        |> FocusList.afterLast       -- 1 2 3 <>
        |> FocusList.plug 4          -- 1 2 3 <4>
        |> FocusList.toStack
    --> Stack.topAndBelow 1 [ 2, 3, 4 ]

-}
afterLast :
    ListFocusingHole possiblyOrNever_ item
    -> ListFocusingHole Possibly item
afterLast listWithFocus =
    FocusList (listWithFocus |> toReverseStack) hole Fillable.empty


toReverseStack :
    ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (StackFilled item)
toReverseStack =
    \(FocusList beforeFocusToFirst focus after_) ->
        let
            focusToFirst =
                case focus of
                    Hole _ ->
                        beforeFocusToFirst

                    Item current_ ->
                        Stack.addOnTop current_ beforeFocusToFirst
        in
        focusToFirst
            |> Stack.stackOnTop (after_ |> Stack.reverse)


{-| Find the first item in the `FocusList` the matches a predicate,
returning a `FocusList` focussed on that item if it was found.

This start from the current focussed location and searches towards the end.

    import Fillable exposing (filled)

    FocusList.only 4
        |> FocusList.append [ 2, -1, 0, 3 ]
        |> FocusList.findForward (\item -> item < 0)
        |> Fillable.map FocusList.current
    --> filled -1

    FocusList.only -4
        |> FocusList.append [ 2, -1, 0, 3 ]
        |> FocusList.findForward (\item -> item < 0)
        |> Fillable.map FocusList.current
    --> filled -4

-}
findForward :
    (item -> Bool)
    -> ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
findForward predicate =
    findForwardHelp predicate


findForwardHelp :
    (item -> Bool)
    -> ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
findForwardHelp predicate =
    \listWithFocus ->
        let
            (FocusList before_ focus after_) =
                listWithFocus

            goForward () =
                listWithFocus
                    |> next
                    |> Fillable.andThen (findForwardHelp predicate)
        in
        case focus of
            Item cur ->
                if predicate cur then
                    FocusList before_ (Item cur) after_
                        |> filled

                else
                    goForward ()

            _ ->
                goForward ()


{-| Find the first item matching a predicate, moving backwards
from the current position.

    import Fillable exposing (filled)

    FocusList.only 4
        |> FocusList.prepend [ 2, -1, 0, 3 ]
        |> FocusList.findBackward (\item -> item < 0)
        |> Fillable.map FocusList.current
    --> filled -1

-}
findBackward :
    (item -> Bool)
    -> ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
findBackward shouldStop =
    findBackwardHelp shouldStop


findBackwardHelp :
    (item -> Bool)
    -> ListFocusingHole possiblyOrNever_ item
    -> Empty Possibly (ListFocusingHole never_ item)
findBackwardHelp shouldStop =
    \listWithFocus ->
        let
            (FocusList before_ focus after_) =
                listWithFocus

            goBack () =
                listWithFocus
                    |> previous
                    |> Fillable.andThen (findBackwardHelp shouldStop)
        in
        case focus of
            Item cur ->
                if shouldStop cur then
                    FocusList before_ (Item cur) after_
                        |> filled

                else
                    goBack ()

            _ ->
                goBack ()


{-| Change every item based on its current value.

    import Stack

    FocusList.only "first"
        |> FocusList.prepend [ "zeroth" ]
        |> FocusList.append [ "second", "third" ]
        |> FocusList.map String.toUpper
        |> FocusList.toStack
    --> Stack.topAndBelow "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

-}
map :
    (item -> mappedItem)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever mappedItem
map changeItem =
    \(FocusList before_ focus after_) ->
        FocusList
            (before_ |> Stack.map changeItem)
            (focus |> focusMap changeItem)
            (after_ |> Stack.map changeItem)


{-| If an item is focussed, alter it based on its current value.

    import Stack

    FocusList.only "first"
        |> FocusList.prepend [ "zeroth" ]
        |> FocusList.append [ "second", "third" ]
        |> FocusList.alterCurrent String.toUpper
        |> FocusList.toStack
    --> Stack.topAndBelow "zeroth" [ "FIRST", "second", "third" ]

-}
alterCurrent :
    (item -> item)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
alterCurrent updateCurrent =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            (focus |> focusMap updateCurrent)
            after_


{-| Apply a function to all items coming before the current focussed location.

    import Stack

    FocusList.only "second"
        |> FocusList.prepend [ "zeroth", "first" ]
        |> FocusList.alterBefore String.toUpper
        |> FocusList.toStack
    --> Stack.topAndBelow "ZEROTH" [ "FIRST", "second" ]

-}
alterBefore :
    (item -> item)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
alterBefore updateItemBefore =
    \(FocusList before_ focus after_) ->
        FocusList
            (before_ |> Stack.map updateItemBefore)
            focus
            after_


{-| Apply a function to all items coming after the current focussed location.

    import Stack

    FocusList.only "zeroth"
        |> FocusList.append [ "first", "second" ]
        |> FocusList.alterAfter String.toUpper
        |> FocusList.toStack
    --> Stack.topAndBelow "zeroth" [ "FIRST", "SECOND" ]

-}
alterAfter :
    (item -> item)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever item
alterAfter updateItemAfter =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            focus
            (after_ |> Stack.map updateItemAfter)


{-| Apply multiple different functions on the parts of a `FocusList`- what
comes before, what comes after, and the current item if there is one.

    import Stack

    FocusList.only "first"
        |> FocusList.append [ "second" ]
        |> FocusList.nextHole
        |> FocusList.plug "one-and-a-halfth"
        |> FocusList.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> FocusList.toStack
    --> Stack.topAndBelow
    -->     "before: first"
    -->     [ "current: one-and-a-halfth"
    -->     , "after: second"
    -->     ]

-}
mapParts :
    { before : item -> mappedItem
    , current : item -> mappedItem
    , after : item -> mappedItem
    }
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNever mappedItem
mapParts changePart =
    \(FocusList before_ focus after_) ->
        FocusList
            (before_ |> Stack.map changePart.before)
            (focus |> focusMap changePart.current)
            (after_ |> Stack.map changePart.after)


{-| Converts it to a flattened list:

    FocusList.only 456
        |> FocusList.prepend [ 123 ]
        |> FocusList.append [ 789 ]
        |> FocusList.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`toStack`](#toStack) to preserve some information about its length.

-}
toList : ListFocusingHole possiblyOrNever_ item -> List item
toList =
    \listWithFocus ->
        listWithFocus
            |> toStack
            |> Stack.toList


{-| Flattens the `FocusList` into a [`Stack`](Stack#StackFilled):

    import Fillable
    import Stack

    FocusList.empty
        |> FocusList.toStack
    --> Fillable.empty

    FocusList.only 123
        |> FocusList.append [ 789 ]
        |> FocusList.nextHole
        |> FocusList.plug 456
        |> FocusList.toStack
    --> Stack.topAndBelow 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> Stack.Never
    Possibly

-}
toStack :
    ListFocusingHole possiblyOrNever item
    -> Empty possiblyOrNever (StackFilled item)
toStack =
    \listWithFocus ->
        let
            (FocusList _ focus after_) =
                listWithFocus
        in
        case before listWithFocus of
            Filled ( first_, afterFirstUntilFocus ) ->
                Stack.topAndBelow first_
                    (afterFirstUntilFocus
                        ++ (listWithFocus
                                |> focusAndAfter
                                |> Stack.toList
                           )
                    )

            Empty _ ->
                case focus of
                    Item cur ->
                        Stack.addOnTop cur after_

                    Hole possiblyOrNever ->
                        case after_ of
                            Filled ( head_, tail_ ) ->
                                Stack.topAndBelow head_ tail_

                            Empty _ ->
                                Empty possiblyOrNever



--


{-| [`Fillable.empty`](Fillable#empty) if the current focussed thing is a hole,
[`Fillable.filled`](Fillable#filled) if it is an item.

    import Fillable

    FocusList.only 3
        |> FocusList.append [ 2, 1 ]
        |> FocusList.nextHole
        |> FocusList.focusingItem
    --> Fillable.empty

-}
focusingItem :
    ListFocusingHole possiblyOrNever item
    -> Empty possiblyOrNever (ListFocusingHole never_ item)
focusingItem =
    \(FocusList before_ focus after_) ->
        case focus of
            Item current_ ->
                FocusList before_ (Item current_) after_
                    |> filled

            Hole possiblyOrNever ->
                Empty possiblyOrNever



--


{-| Change the `possiblyOrNever` type.

  - A `ListFocusingHole possiblyOrNever`
    can't be used as a `ListFocusingHole Possibly`?

        import Possibly exposing (Possible)

        FocusList.adaptType (always Possible)

  - A `ListFocusingHole Never`
    can't be unified with `Possibly` or `ListFocusingHole possiblyOrNever`?

        FocusList.adaptType never

Please read more at [`Fillable.adaptType`](Fillable#adaptType).

-}
adaptHoleType :
    (possiblyOrNever -> possiblyOrNeverAdapted)
    -> ListFocusingHole possiblyOrNever item
    -> ListFocusingHole possiblyOrNeverAdapted item
adaptHoleType neverOrAlwaysPossible =
    \(FocusList before_ focus after_) ->
        FocusList
            before_
            (case focus of
                Item item ->
                    item |> Item

                Hole hole_ ->
                    Hole (hole_ |> neverOrAlwaysPossible)
            )
            after_
