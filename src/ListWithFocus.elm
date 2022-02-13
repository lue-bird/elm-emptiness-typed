module ListWithFocus exposing
    ( ListWhereFocusIs
    , empty, only
    , current, before, after
    , next, previous, nextHole, previousHole
    , first, last, beforeFirst, afterLast
    , findForward, findBackward
    , append, prepend
    , alterCurrent, plug, remove
    , alterBefore, alterAfter
    , insertAfter, insertBefore
    , squeezeInBefore, squeezeInAfter
    , map, mapParts, toListIs, toList
    , focussesItem, branchableType
    )

{-| A list zipper that can also focus on a hole _between_ items.

1.  🔎 focus on a hole between two items
2.  🔌 plug that hole with a value
3.  💰 profit


## types

@docs ListWhereFocusIs


## create

@docs empty, only


## scan

@docs current, before, after


## navigate

@docs next, previous, nextHole, previousHole
@docs first, last, beforeFirst, afterLast
@docs findForward, findBackward


## modify

@docs append, prepend


### modify the focus

@docs alterCurrent, plug, remove


### modify around the focus

@docs alterBefore, alterAfter
@docs insertAfter, insertBefore
@docs squeezeInBefore, squeezeInAfter


## transform

@docs map, mapParts, toListIs, toList


## type-level

@docs focussesItem, branchableType

-}

import Fillable exposing (Emptiable, Filled, Is(..), filled)
import ListIs exposing (ListIs)


{-| A special kind of list with elements of type `item`.

The focus can be

  - `🍍 🍓 <🍊> 🍉 🍇`: [`Filled`](Fillable#Filled)

  - `🍍 🍓 <?> 🍉 🍇`: [`Emptiable`](Fillable#Emptiable)

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a hole between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`


#### in arguments

    empty : HoleWithFocusThat Emptiable


#### in types

    type alias Model =
        WithoutConstructorFunction
            { choice : ListWereFocusIs Filled
            }

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

-}
type ListWhereFocusIs emptiableOrFilled item
    = ListWithFocus (List item) (Is emptiableOrFilled item) (List item)


hole : Is Emptiable item_
hole =
    Fillable.empty


{-| An empty `ListWereFocusIs` on a hole
with nothing before and after it.
It's the loneliest of all `ListWereFocusIs`s.

```monospace
<>
```

    import ListIs

    ListWithFocus.empty
        |> ListWithFocus.toListIs
    --> Fillable.empty

-}
empty : ListWhereFocusIs Emptiable filled_
empty =
    ListWithFocus [] hole []


{-| A `ListWereFocusIs` with a single focussed item in it,
nothing before and after it.

```monospace
<🍊>
```

    import ListIs

    ListWithFocus.only "wat"
        |> ListWithFocus.current
    --> "wat"

    ListWithFocus.only "wat"
        |> ListWithFocus.toListIs
    --> ListIs.only "wat"

-}
only : element -> ListWhereFocusIs filled_ element
only current_ =
    ListWithFocus [] (filled current_) []



--


{-| The current focussed item.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    ListWithFocus.only "hi there"
        |> ListWithFocus.current
    --> "hi there"

    ListWithFocus.only 1
        |> ListWithFocus.append [ 2, 3, 4 ]
        |> ListWithFocus.last
        |> ListWithFocus.current
    --> 4

-}
current : ListWhereFocusIs Filled item -> item
current =
    \(ListWithFocus _ focus _) ->
        focus |> Fillable.filling


{-| The items before the location of the focus.

```monospace
🍍 🍓) <🍊> 🍉 🍇
```

    ListWithFocus.only 0
        |> ListWithFocus.append [ 1, 2, 3 ]
        |> ListWithFocus.next
        |> Maybe.andThen ListWithFocus.next
        |> Maybe.map ListWithFocus.before
    --> Just [ 0, 1 ]

-}
before : ListWhereFocusIs emptiableOrFilled_ item -> List item
before =
    \(ListWithFocus beforeFocusUntilHead _ _) ->
        List.reverse beforeFocusUntilHead


{-| The items after the current focussed location.

```monospace
🍍 🍓 <🍊> (🍉 🍇
```

    ListWithFocus.only 0
        |> ListWithFocus.append [ 1, 2, 3 ]
        |> ListWithFocus.next
        |> Maybe.map ListWithFocus.after
    --> Just [ 2, 3 ]

-}
after : ListWhereFocusIs emptiableOrFilled_ item -> List item
after =
    \(ListWithFocus _ _ after_) ->
        after_



--


{-| Move the focus of the `ListWereFocusIs`to the next item, if there is one.

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocus.only 0
        |> ListWithFocus.append [ 1, 2, 3 ]
        |> ListWithFocus.next
        |> Maybe.map ListWithFocus.current
    --> Just 1

This also works from within holes:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocus.empty
        |> ListWithFocus.insertAfter "foo"
        |> ListWithFocus.next
    --> Just (ListWithFocus.only "foo")

If there is no `next` item, the result is `Nothing`.

    ListWithFocus.empty
        |> ListWithFocus.next
    --> Nothing


    ListWithFocus.only 0
        |> ListWithFocus.append [ 1, 2, 3 ]
        |> ListWithFocus.last
        |> ListWithFocus.next
    --> Nothing

-}
next :
    ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
next (ListWithFocus beforeFocusUntilHead focus after_) =
    case after_ of
        [] ->
            Fillable.empty

        next_ :: afterNext ->
            let
                newBeforeReversed =
                    case focus of
                        Empty _ ->
                            beforeFocusUntilHead

                        Filled oldCurrent ->
                            oldCurrent :: beforeFocusUntilHead
            in
            ListWithFocus newBeforeReversed (filled next_) afterNext
                |> filled


{-| Move the focus of the `ListWereFocusIs`to the previous item, if there is one.

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    ListWithFocus.empty |> ListWithFocus.previous
    --> Nothing

    ListWithFocus.only "hello"
        |> ListWithFocus.append [ "holey", "world" ]
        |> ListWithFocus.last
        |> ListWithFocus.previous
        |> Maybe.map ListWithFocus.current
    --> Just "holey"

This also works from within holes:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocus.empty
        |> ListWithFocus.insertBefore "foo"
        |> ListWithFocus.previous
    --> Just (ListWithFocus.only "foo")

-}
previous :
    ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
previous listWithFocusThat =
    let
        (ListWithFocus beforeFocusUntilHead _ _) =
            listWithFocusThat
    in
    case beforeFocusUntilHead of
        [] ->
            Fillable.empty

        previous_ :: beforePreviousToHead ->
            ListWithFocus
                beforePreviousToHead
                (filled previous_)
                (listWithFocusThat |> focusAndAfter)
                |> filled


{-| Move the `ListWereFocusIs`to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import ListIs

    ListWithFocus.only "hello"
        |> ListWithFocus.append [ "world" ]
        |> ListWithFocus.nextHole
        |> ListWithFocus.plug "holey"
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "hello" [ "holey", "world" ]

-}
nextHole :
    ListWhereFocusIs Filled item
    -> ListWhereFocusIs Emptiable item
nextHole listWithFocusThat =
    let
        (ListWithFocus beforeFocusUntilHead _ after_) =
            listWithFocusThat
    in
    ListWithFocus
        (current listWithFocusThat :: beforeFocusUntilHead)
        hole
        after_


{-| Move the `ListWereFocusIs`to the hole right before the current item. Feel free to plug
that hole right up!

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import ListIs

    ListWithFocus.only "world"
        |> ListWithFocus.previousHole
        |> ListWithFocus.plug "hello"
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "hello" [ "world" ]

-}
previousHole :
    ListWhereFocusIs Filled item
    -> ListWhereFocusIs Emptiable item
previousHole listWithFocusThat =
    let
        (ListWithFocus before_ _ after_) =
            listWithFocusThat
    in
    ListWithFocus
        before_
        hole
        ((listWithFocusThat |> current) :: after_)



--


{-| Fill in or replace the focussed thing in the `ListWereFocusIs`.

```monospace
🍓 <?> 🍉  ->  🍓 <🍒> 🍉
```

    import ListIs

    ListWithFocus.empty
        |> ListWithFocus.insertBefore "🍓" -- "🍓" <>
        |> ListWithFocus.insertAfter "🍉"  -- "🍓" <> "🍉"
        |> ListWithFocus.plug "🍒"         -- "🍓" <"🍒"> "🍉"
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "🍓" [ "🍒", "🍉" ]

-}
plug :
    item
    -> ListWhereFocusIs emptiableOrFilled_ item
    -> ListWhereFocusIs filled_ item
plug newCurrent =
    \(ListWithFocus before_ _ after_) ->
        ListWithFocus before_ (filled newCurrent) after_


{-| Punch a hole into the `ListWereFocusIs`by removing the focussed thing.

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    ListWithFocus.only "hello"
        |> ListWithFocus.append [ "holey", "world" ]
        |> ListWithFocus.next
        |> Maybe.map ListWithFocus.remove
        |> Maybe.map ListWithFocus.toListIs
    --> Just [ "hello", "world" ]

-}
remove :
    ListWhereFocusIs emptiableOrFilled_ item
    -> ListWhereFocusIs Emptiable item
remove =
    \(ListWithFocus before_ _ after_) ->
        ListWithFocus before_ hole after_


{-| Insert an item after the focussed location.

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import ListIs

    ListWithFocus.only 123
        |> ListWithFocus.append [ 789 ]
        |> ListWithFocus.insertAfter 456
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 123 [ 456, 789 ]

Insert multiple items using [`squeezeInAfter`](#squeezeInAfter).

-}
insertAfter :
    item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
insertAfter toInsertAfterFocus =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus before_ focus (toInsertAfterFocus :: after_)


{-| Insert an item before the focussed location.

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```

    import ListIs

    ListWithFocus.only 123
        |> ListWithFocus.insertBefore 456
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 456 [ 123 ]

Insert multiple items using [`squeezeInBefore`](#squeezeInBefore).

-}
insertBefore :
    item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
insertBefore itemToInsertBefore =
    \(ListWithFocus beforeFocusUntilHead focus after_) ->
        ListWithFocus
            (itemToInsertBefore :: beforeFocusUntilHead)
            focus
            after_


focusAndAfter : ListWhereFocusIs emptiableOrFilled_ item -> List item
focusAndAfter =
    \(ListWithFocus _ focus after_) ->
        case focus of
            Empty _ ->
                after_

            Filled current_ ->
                current_ :: after_


{-| Append items directly after the focussed location.

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import ListIs

    ListWithFocus.only 0
        |> ListWithFocus.squeezeInAfter [ 4, 5 ]
        |> ListWithFocus.squeezeInAfter [ 1, 2, 3 ]
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 0 [ 1, 2, 3, 4, 5 ]

-}
squeezeInAfter :
    List item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
squeezeInAfter toAppendDirectlyAfterFocus =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus before_ focus (toAppendDirectlyAfterFocus ++ after_)


{-| Prepend items directly before the focussed location.

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

    import ListIs

    ListWithFocus.only 0
        |> ListWithFocus.squeezeInBefore [ -5, -4 ]
        |> ListWithFocus.squeezeInBefore [ -3, -2, -1 ]
        |> ListWithFocus.toListIs
    --> ListIs.fromCons -5 [ -4, -3, -2, -1, 0 ]

-}
squeezeInBefore :
    List item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
squeezeInBefore toPrependDirectlyBeforeFocus =
    \(ListWithFocus beforeFocusUntilHead focus after_) ->
        ListWithFocus
            (List.reverse toPrependDirectlyBeforeFocus ++ beforeFocusUntilHead)
            focus
            after_


{-| Put items to the end after anything else.

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import ListIs

    ListWithFocus.only 123
        |> ListWithFocus.append [ 456 ]
        |> ListWithFocus.append [ 789, 0 ]
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 123 [ 456, 789, 0 ]

-}
append :
    List item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
append itemsToAppend =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus before_ focus (after_ ++ itemsToAppend)


{-| Put items to the beginning before anything else.

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

    import ListIs

    ListWithFocus.only 1
        |> ListWithFocus.append [ 2, 3, 4 ]
        |> ListWithFocus.last
        |> ListWithFocus.prepend [ 5, 6, 7 ]
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prepend :
    List item
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
prepend itemsToPrepend =
    \(ListWithFocus beforeFocusUntilHead focus after_) ->
        ListWithFocus
            (beforeFocusUntilHead ++ List.reverse itemsToPrepend)
            focus
            after_


{-| Focus the first item.

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

    ListWithFocus.only 1
        |> ListWithFocus.append [ 2, 3, 4 ]
        |> ListWithFocus.prepend [ 4, 3, 2 ]
        |> ListWithFocus.first
        |> ListWithFocus.current
    --> 4

-}
first :
    ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
first =
    \listWithFocusThat ->
        case listWithFocusThat |> before of
            [] ->
                listWithFocusThat

            head :: afterHeadBeforeCurrent ->
                ListWithFocus
                    []
                    (filled head)
                    (afterHeadBeforeCurrent
                        ++ (listWithFocusThat |> focusAndAfter)
                    )


{-| Focus the last item.

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    ListWithFocus.only 1
        |> ListWithFocus.append [ 2, 3, 4 ]
        |> ListWithFocus.last
        |> ListWithFocus.current
    --> 4

    ListWithFocus.only 1
        |> ListWithFocus.append [ 2, 3, 4 ]
        |> ListWithFocus.last
        |> ListWithFocus.before
    --> [ 1, 2, 3 ]

-}
last :
    ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
last =
    \listWithFocusThat ->
        let
            (ListWithFocus before_ focus after_) =
                listWithFocusThat
        in
        case List.reverse after_ of
            [] ->
                listWithFocusThat

            last_ :: beforeLastUntilCurrent ->
                let
                    focusToFirst =
                        case focus of
                            Filled current_ ->
                                current_ :: before_

                            Empty _ ->
                                before_
                in
                ListWithFocus
                    (beforeLastUntilCurrent ++ focusToFirst)
                    (filled last_)
                    []


{-| Focus the hole before the first item.
Remember that holes surround everything!

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

    import ListIs

    ListWithFocus.only 1                 -- <1>
        |> ListWithFocus.append [ 3, 4 ] -- <1> 3 4
        |> ListWithFocus.nextHole        -- 1 <> 3 4
        |> ListWithFocus.plug 2          -- 1 <2> 3 4
        |> ListWithFocus.beforeFirst     -- <> 1 2 3 4
        |> ListWithFocus.plug 0          -- <0> 1 2 3 4
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 0 [ 1, 2, 3, 4 ]

-}
beforeFirst :
    ListWhereFocusIs emptiableOrFilled_ item
    -> ListWhereFocusIs Emptiable item
beforeFirst listWithFocusThat =
    ListWithFocus [] hole (listWithFocusThat |> toList)


{-| Focus the hole after the end. Into the nothingness.

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import ListIs

    ListWithFocus.only 1                 -- <1>
        |> ListWithFocus.append [ 2, 3 ] -- <1> 2 3
        |> ListWithFocus.afterLast       -- 1 2 3 <>
        |> ListWithFocus.plug 4          -- 1 2 3 <4>
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 1 [ 2, 3, 4 ]

-}
afterLast :
    ListWhereFocusIs emptiableOrFilled_ item
    -> ListWhereFocusIs Emptiable item
afterLast listWithFocusThat =
    ListWithFocus (toReverseList listWithFocusThat) hole []


toReverseList : ListWhereFocusIs emptiableOrFilled_ a -> List a
toReverseList =
    \(ListWithFocus beforeFocusUntilHead focus after_) ->
        let
            focusToFirst =
                case focus of
                    Empty _ ->
                        beforeFocusUntilHead

                    Filled current_ ->
                        current_ :: beforeFocusUntilHead
        in
        List.reverse after_ ++ focusToFirst


{-| Find the first item in the `ListWereFocusIs` the matches a predicate,
returning a `ListWereFocusIs` focussed on that item if it was found.

This start from the current focussed location and searches towards the end.

    ListWithFocus.only 4
        |> ListWithFocus.append [ 2, -1, 0, 3 ]
        |> ListWithFocus.findForward (\item -> item < 0)
        |> Maybe.map ListWithFocus.current
    --> Just -1

    ListWithFocus.only -4
        |> ListWithFocus.append [ 2, -1, 0, 3 ]
        |> ListWithFocus.findForward (\item -> item < 0)
        |> Maybe.map ListWithFocus.current
    --> Just -4

-}
findForward :
    (item -> Bool)
    -> ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
findForward predicate =
    findForwardHelp predicate


findForwardHelp :
    (item -> Bool)
    -> ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
findForwardHelp predicate =
    \listWithFocusThat ->
        let
            (ListWithFocus before_ focus after_) =
                listWithFocusThat

            goForward () =
                listWithFocusThat
                    |> next
                    |> Fillable.andThen (findForwardHelp predicate)
        in
        case focus of
            Filled cur ->
                if predicate cur then
                    ListWithFocus before_ (filled cur) after_
                        |> filled

                else
                    goForward ()

            Empty _ ->
                goForward ()


{-| Find the first item in the `ListWereFocusIs`matching a predicate, moving backwards
from the current position.

    ListWithFocus.only 4
        |> ListWithFocus.prepend [ 2, -1, 0, 3 ]
        |> ListWithFocus.findBackward (\item -> item < 0)
        |> Maybe.map ListWithFocus.current
    --> Just -1

-}
findBackward :
    (item -> Bool)
    -> ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
findBackward shouldStop =
    findBackwardHelp shouldStop


findBackwardHelp :
    (item -> Bool)
    -> ListWhereFocusIs emptiableOrFilled_ item
    -> Is Emptiable (ListWhereFocusIs filled_ item)
findBackwardHelp shouldStop =
    \listWithFocusThat ->
        let
            (ListWithFocus before_ focus after_) =
                listWithFocusThat

            goBack () =
                listWithFocusThat
                    |> previous
                    |> Fillable.andThen (findBackwardHelp shouldStop)
        in
        case focus of
            Filled cur ->
                if shouldStop cur then
                    ListWithFocus before_ (filled cur) after_
                        |> filled

                else
                    goBack ()

            Empty _ ->
                goBack ()


{-| Change every item based on its current value.

    import ListIs

    ListWithFocus.only "first"
        |> ListWithFocus.prepend [ "zeroth" ]
        |> ListWithFocus.append [ "second", "third" ]
        |> ListWithFocus.map String.toUpper
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

-}
map :
    (item -> mappedItem)
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled mappedItem
map changeItem =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            (List.map changeItem before_)
            (Fillable.map changeItem focus)
            (List.map changeItem after_)


{-| If an item is focussed, alter it based on its current value.

    import ListIs

    ListWithFocus.only "first"
        |> ListWithFocus.prepend [ "zeroth" ]
        |> ListWithFocus.append [ "second", "third" ]
        |> ListWithFocus.alterCurrent String.toUpper
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "zeroth" [ "FIRST", "second", "third" ]

-}
alterCurrent :
    (item -> item)
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
alterCurrent updateCurrent =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            before_
            (Fillable.map updateCurrent focus)
            after_


{-| Apply a function to all items coming before the current focussed location.

    import ListIs

    ListWithFocus.only "second"
        |> ListWithFocus.prepend [ "zeroth", "first" ]
        |> ListWithFocus.alterBefore String.toUpper
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "ZEROTH" [ "FIRST", "second" ]

-}
alterBefore :
    (item -> item)
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
alterBefore updateItemBefore =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            (List.map updateItemBefore before_)
            focus
            after_


{-| Apply a function to all items coming after the current focussed location.

    import ListIs

    ListWithFocus.only "zeroth"
        |> ListWithFocus.append [ "first", "second" ]
        |> ListWithFocus.alterAfter String.toUpper
        |> ListWithFocus.toListIs
    --> ListIs.fromCons "zeroth" [ "FIRST", "SECOND" ]

-}
alterAfter :
    (item -> item)
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled item
alterAfter updateItemAfter =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            before_
            focus
            (List.map updateItemAfter after_)


{-| Apply multiple different functions on the parts of a `ListWereFocusIs`- what
comes before, what comes after, and the current item if there is one.

    import ListIs

    ListWithFocus.only "first"
        |> ListWithFocus.append [ "second" ]
        |> ListWithFocus.nextHole
        |> ListWithFocus.plug "one-and-a-halfth"
        |> ListWithFocus.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> ListWithFocus.toListIs
    --> ListIs.fromCons
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
    -> ListWhereFocusIs emptiableOrFilled item
    -> ListWhereFocusIs emptiableOrFilled mappedItem
mapParts changePart =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            (List.map changePart.before before_)
            (Fillable.map changePart.current focus)
            (List.map changePart.after after_)


{-| Flattens the `ListWereFocusIs`into a list:

    ListWithFocus.only 456
        |> ListWithFocus.prepend [ 123 ]
        |> ListWithFocus.append [ 789 ]
        |> ListWithFocus.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`toListIs`](#toListIs) to preserve some information about its length.

-}
toList : ListWhereFocusIs emptiableOrFilled_ item -> List item
toList =
    \listWithFocusThat ->
        (listWithFocusThat |> before)
            ++ (listWithFocusThat |> focusAndAfter)


{-| Flattens the `ListWereFocusIs` into a [`ListIs`](ListIs#ListIs):

    import ListIs

    ListWithFocus.empty
        |> ListWithFocus.toListIs
    --> Fillable.empty

    ListWithFocus.only 123
        |> ListWithFocus.append [ 789 ]
        |> ListWithFocus.nextHole
        |> ListWithFocus.plug 456
        |> ListWithFocus.toListIs
    --> ListIs.fromCons 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> ListIs.Filled
    Emptiable

-}
toListIs :
    ListWhereFocusIs emptiableOrFilled item
    -> ListIs emptiableOrFilled item
toListIs =
    \listWithFocusThat ->
        let
            (ListWithFocus _ focus after_) =
                listWithFocusThat
        in
        case ( before listWithFocusThat, focus ) of
            ( head_ :: afterFirstUntilFocus, _ ) ->
                ListIs.fromCons head_
                    (afterFirstUntilFocus
                        ++ (listWithFocusThat |> focusAndAfter)
                    )

            ( [], Filled cur ) ->
                ListIs.fromCons cur after_

            ( [], Empty emptiableOrFilled ) ->
                case after_ of
                    head_ :: tail_ ->
                        ListIs.fromCons head_ tail_

                    [] ->
                        Empty emptiableOrFilled



--


{-| Find out if the current focussed thing is an item.

    import Fillable

    ListWithFocus.only 3
        |> ListWithFocus.append [ 2, 1 ]
        |> ListWithFocus.nextHole
        |> ListWithFocus.focussesItem
    --> Fillable.is Hole

-}
focussesItem :
    ListWhereFocusIs emptiableOrFilled item
    -> Is emptiableOrFilled (ListWhereFocusIs filled_ item)
focussesItem =
    \(ListWithFocus before_ focus after_) ->
        focus
            |> Fillable.map
                (\current_ ->
                    ListWithFocus before_ (filled current_) after_
                )


{-| When using a `ListWereFocusIs Filled ...` argument,
its type can't be unified with `Emptiable` lists.

Please read more at [`Fillable.branchableType`](Fillable#branchableType).

-}
branchableType :
    ListWhereFocusIs Filled item
    -> ListWhereFocusIs filled_ item
branchableType =
    \(ListWithFocus before_ focus after_) ->
        ListWithFocus
            before_
            (focus |> Fillable.branchableType)
            after_
