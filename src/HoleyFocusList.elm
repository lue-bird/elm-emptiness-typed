module HoleyFocusList exposing
    ( HoleyFocusList, Item, HoleOrItem
    , empty, only
    , current, before, after
    , next, previous, nextHole, previousHole
    , first, last, beforeFirst, afterLast
    , findForward, findBackward
    , append, prepend
    , mapCurrent, plug, remove
    , mapBefore, mapAfter
    , insertAfter, insertBefore
    , squeezeInBefore, squeezeInAfter
    , map, mapParts, joinParts, toList
    , focussesItem, branchableType
    )

{-| A list zipper that can also focus on a hole _between_ items.

1.  🔎 focus on a hole between two items
2.  🔌 plug that hole with a value
3.  💰 profit


## types

@docs HoleyFocusList, Item, HoleOrItem


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

@docs mapCurrent, plug, remove


### modify around the focus

@docs mapBefore, mapAfter
@docs insertAfter, insertBefore
@docs squeezeInBefore, squeezeInAfter


## transform

@docs map, mapParts, joinParts, toList


## type-level

@docs focussesItem, branchableType

-}

import ListIs exposing (ListIs)
import MaybeIs exposing (CanBeNothing(..), MaybeIs(..), just, nothing)


{-| Represents a special kind of list with items of type `a`.

The type `focus` can be

  - [`Item`](#Item): `🍍 🍓 <🍊> 🍉 🍇`

  - [`HoleOrItem`](#HoleOrItem): `🍍 🍓 <?> 🍉 🍇`

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a hole between items
      - `🍍 🍓 <🍊> 🍉 🍇`

-}
type HoleyFocusList focus a
    = HoleyFocusList (List a) (MaybeIs focus a) (List a)


{-| A `HoleyFocusList Item a` is focussed on an element of type `a`.

```monospace
🍍 🍓 <🍊> 🍉 🍇
```

-}
type alias Item =
    MaybeIs.Just { item : () }


{-| A `HoleyFocusList HoleOrItem a` could be focussed on a hole between `a`s.

... Heh.

```monospace
🍍 🍓 <?> 🍊 🍉 🍇
```

`<?>` means both are possible:

    - `🍍 🍓 <> 🍉 🍇`: a hole between items
    - `🍍 🍓 <🍊> 🍉 🍇`

-}
type alias HoleOrItem =
    MaybeIs.Nothingable { holeOrItem : () }


{-| An empty `HoleyFocusList` focussed on a hole with nothing before
and after it.
It's the loneliest of all `HoleyFocusList`s.

```monospace
<>
```

    import ListIs

    HoleyFocusList.empty
        |> HoleyFocusList.joinParts
    --> ListIs.empty

-}
empty : HoleyFocusList HoleOrItem a_
empty =
    HoleyFocusList [] nothing []


{-| A `HoleyFocusList` with a single focussed item in it, nothing before and after it.

```monospace
<🍊>
```

    import ListIs

    HoleyFocusList.only "wat"
        |> HoleyFocusList.current
    --> "wat"

    HoleyFocusList.only "wat"
        |> HoleyFocusList.joinParts
    --> ListIs.only "wat"

-}
only : a -> HoleyFocusList item_ a
only current_ =
    HoleyFocusList [] (just current_) []



--


{-| The current focussed item in the `HoleyFocusList`.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    HoleyFocusList.only "hi there"
        |> HoleyFocusList.current
    --> "hi there"

    HoleyFocusList.only 1
        |> HoleyFocusList.append [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.current
    --> 4

-}
current : HoleyFocusList Item a -> a
current =
    \(HoleyFocusList _ focus _) ->
        focus |> MaybeIs.value


{-| The items before the location of the focus in the `HoleyFocusList`.

```monospace
🍍 🍓) <🍊> 🍉 🍇
```

    HoleyFocusList.only 0
        |> HoleyFocusList.append [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.andThen HoleyFocusList.next
        |> Maybe.map HoleyFocusList.before
    --> Just [ 0, 1 ]

-}
before : HoleyFocusList focus_ a -> List a
before =
    \(HoleyFocusList beforeFocusUntilHead _ _) ->
        List.reverse beforeFocusUntilHead


{-| The items after the current focussed location in the `HoleyFocusList`.

```monospace
🍍 🍓 <🍊> (🍉 🍇
```

    HoleyFocusList.only 0
        |> HoleyFocusList.append [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.after
    --> Just [ 2, 3 ]

-}
after : HoleyFocusList focus_ a -> List a
after =
    \(HoleyFocusList _ _ after_) ->
        after_



--


{-| Move the focus of the `HoleyFocusList` to the next item, if there is one.

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    HoleyFocusList.only 0
        |> HoleyFocusList.append [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.current
    --> Just 1

This also works from within holes:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    HoleyFocusList.empty
        |> HoleyFocusList.insertAfter "foo"
        |> HoleyFocusList.next
    --> Just (HoleyFocusList.only "foo")

If there is no `next` item, the result is `Nothing`.

    HoleyFocusList.empty
        |> HoleyFocusList.next
    --> Nothing


    HoleyFocusList.only 0
        |> HoleyFocusList.append [ 1, 2, 3 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.next
    --> Nothing

-}
next : HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
next (HoleyFocusList beforeFocusUntilHead focus after_) =
    case after_ of
        [] ->
            Nothing

        next_ :: afterNext ->
            let
                newBeforeReversed =
                    case focus of
                        IsNothing _ ->
                            beforeFocusUntilHead

                        IsJust oldCurrent ->
                            oldCurrent :: beforeFocusUntilHead
            in
            HoleyFocusList newBeforeReversed (just next_) afterNext
                |> Just


{-| Move the focus of the `HoleyFocusList` to the previous item, if there is one.

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    HoleyFocusList.empty |> HoleyFocusList.previous
    --> Nothing

    HoleyFocusList.only "hello"
        |> HoleyFocusList.append [ "holey", "world" ]
        |> HoleyFocusList.last
        |> HoleyFocusList.previous
        |> Maybe.map HoleyFocusList.current
    --> Just "holey"

This also works from within holes:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    HoleyFocusList.empty
        |> HoleyFocusList.insertBefore "foo"
        |> HoleyFocusList.previous
    --> Just (HoleyFocusList.only "foo")

-}
previous : HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
previous holeyFocusList =
    let
        (HoleyFocusList beforeFocusUntilHead _ _) =
            holeyFocusList
    in
    case beforeFocusUntilHead of
        [] ->
            Nothing

        previous_ :: beforePreviousToHead ->
            HoleyFocusList
                beforePreviousToHead
                (just previous_)
                (focusAndAfter holeyFocusList)
                |> Just


{-| Move the `HoleyFocusList` to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import ListIs

    HoleyFocusList.only "hello"
        |> HoleyFocusList.append [ "world" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug "holey"
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "hello" [ "holey", "world" ]

-}
nextHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
nextHole holeyFocusList =
    let
        (HoleyFocusList beforeFocusUntilHead _ after_) =
            holeyFocusList
    in
    HoleyFocusList
        (current holeyFocusList :: beforeFocusUntilHead)
        nothing
        after_


{-| Move the `HoleyFocusList` to the hole right before the current item. Feel free to plug
that hole right up!

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import ListIs

    HoleyFocusList.only "world"
        |> HoleyFocusList.previousHole
        |> HoleyFocusList.plug "hello"
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "hello" [ "world" ]

-}
previousHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
previousHole holeyFocusList =
    let
        (HoleyFocusList before_ _ after_) =
            holeyFocusList
    in
    HoleyFocusList before_ nothing (current holeyFocusList :: after_)



--


{-| Fill in or replace the focussed thing in the `HoleyFocusList`.

```monospace
🍓 <?> 🍉  ->  🍓 <🍒> 🍉
```

    import ListIs

    HoleyFocusList.empty
        |> HoleyFocusList.insertBefore "🍓" -- "🍓" <>
        |> HoleyFocusList.insertAfter "🍉"  -- "🍓" <> "🍉"
        |> HoleyFocusList.plug "🍒"         -- "🍓" <"🍒"> "🍉"
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "🍓" [ "🍒", "🍉" ]

-}
plug : a -> HoleyFocusList HoleOrItem a -> HoleyFocusList item_ a
plug newCurrent =
    \(HoleyFocusList before_ _ after_) ->
        HoleyFocusList before_ (just newCurrent) after_


{-| Punch a hole into the `HoleyFocusList` by removing the focussed thing.

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    HoleyFocusList.only "hello"
        |> HoleyFocusList.append [ "holey", "world" ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.remove
        |> Maybe.map HoleyFocusList.toList
    --> Just [ "hello", "world" ]

-}
remove : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
remove =
    \(HoleyFocusList before_ _ after_) ->
        HoleyFocusList before_ nothing after_


{-| Insert an item after the focussed location.

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import ListIs

    HoleyFocusList.only 123
        |> HoleyFocusList.append [ 789 ]
        |> HoleyFocusList.insertAfter 456
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 123 [ 456, 789 ]

Insert multiple items using [`squeezeInAfter`](#squeezeInAfter).

-}
insertAfter : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertAfter toInsertAfterFocus =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (toInsertAfterFocus :: after_)


{-| Insert an item before the focussed location.

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```

    import ListIs

    HoleyFocusList.only 123
        |> HoleyFocusList.insertBefore 456
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 456 [ 123 ]

Insert multiple items using [`squeezeInBefore`](#squeezeInBefore).

-}
insertBefore : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertBefore itemToInsertBefore =
    \(HoleyFocusList beforeFocusUntilHead focus after_) ->
        HoleyFocusList
            (itemToInsertBefore :: beforeFocusUntilHead)
            focus
            after_


focusAndAfter : HoleyFocusList focus_ a -> List a
focusAndAfter =
    \(HoleyFocusList _ focus after_) ->
        case focus of
            IsNothing _ ->
                after_

            IsJust current_ ->
                current_ :: after_


{-| Append items directly after the focussed location in the `HoleyFocusList`.

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import ListIs

    HoleyFocusList.only 0
        |> HoleyFocusList.squeezeInAfter [ 4, 5 ]
        |> HoleyFocusList.squeezeInAfter [ 1, 2, 3 ]
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 0 [ 1, 2, 3, 4, 5 ]

-}
squeezeInAfter : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
squeezeInAfter toAppendDirectlyAfterFocus =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (toAppendDirectlyAfterFocus ++ after_)


{-| Prepend items directly before the focussed location in the `HoleyFocusList`.

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

    import ListIs

    HoleyFocusList.only 0
        |> HoleyFocusList.squeezeInBefore [ -5, -4 ]
        |> HoleyFocusList.squeezeInBefore [ -3, -2, -1 ]
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons -5 [ -4, -3, -2, -1, 0 ]

-}
squeezeInBefore : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
squeezeInBefore toPrependDirectlyBeforeFocus =
    \(HoleyFocusList beforeFocusUntilHead focus after_) ->
        HoleyFocusList
            (List.reverse toPrependDirectlyBeforeFocus ++ beforeFocusUntilHead)
            focus
            after_


{-| Put items to the end of the `HoleyFocusList`. After anything else.

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import ListIs

    HoleyFocusList.only 123
        |> HoleyFocusList.append [ 456 ]
        |> HoleyFocusList.append [ 789, 0 ]
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 123 [ 456, 789, 0 ]

-}
append : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
append itemsToAppend =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (after_ ++ itemsToAppend)


{-| Put items to the beginning of the `HoleyFocusList`. Before anything else.

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

    import ListIs

    HoleyFocusList.only 1
        |> HoleyFocusList.append [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.prepend [ 5, 6, 7 ]
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prepend : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
prepend itemsToPrepend =
    \(HoleyFocusList beforeFocusUntilHead focus after_) ->
        HoleyFocusList
            (beforeFocusUntilHead ++ List.reverse itemsToPrepend)
            focus
            after_


{-| Focus the first item in the `HoleyFocusList`.

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

    HoleyFocusList.only 1
        |> HoleyFocusList.append [ 2, 3, 4 ]
        |> HoleyFocusList.prepend [ 4, 3, 2 ]
        |> HoleyFocusList.first
        |> HoleyFocusList.current
    --> 4

-}
first : HoleyFocusList focus a -> HoleyFocusList focus a
first holeyFocusList =
    case before holeyFocusList of
        [] ->
            holeyFocusList

        head :: afterHeadBeforeCurrent ->
            HoleyFocusList []
                (just head)
                (afterHeadBeforeCurrent ++ focusAndAfter holeyFocusList)


{-| Focus the last item in the `HoleyFocusList`.

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    HoleyFocusList.only 1
        |> HoleyFocusList.append [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.current
    --> 4

    HoleyFocusList.only 1
        |> HoleyFocusList.append [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.before
    --> [ 1, 2, 3 ]

-}
last : HoleyFocusList focus a -> HoleyFocusList focus a
last =
    \holeyFocusList ->
        let
            (HoleyFocusList before_ focus after_) =
                holeyFocusList
        in
        case List.reverse after_ of
            [] ->
                holeyFocusList

            last_ :: beforeLastUntilCurrent ->
                let
                    focusToFirst =
                        case focus of
                            IsJust current_ ->
                                current_ :: before_

                            IsNothing _ ->
                                before_
                in
                HoleyFocusList
                    (beforeLastUntilCurrent ++ focusToFirst)
                    (just last_)
                    []


{-| Focus the hole before the first item.
Remember that holes surround everything!

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

    import ListIs

    HoleyFocusList.only 1                 -- <1>
        |> HoleyFocusList.append [ 3, 4 ] -- <1> 3 4
        |> HoleyFocusList.nextHole        -- 1 <> 3 4
        |> HoleyFocusList.plug 2          -- 1 <2> 3 4
        |> HoleyFocusList.beforeFirst     -- <> 1 2 3 4
        |> HoleyFocusList.plug 0          -- <0> 1 2 3 4
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 0 [ 1, 2, 3, 4 ]

-}
beforeFirst : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
beforeFirst holeyFocusList =
    HoleyFocusList [] nothing (holeyFocusList |> toList)


{-| Focus the hole after the end of the `HoleyFocusList`. Into the nothingness.

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import ListIs

    HoleyFocusList.only 1                 -- <1>
        |> HoleyFocusList.append [ 2, 3 ] -- <1> 2 3
        |> HoleyFocusList.afterLast       -- 1 2 3 <>
        |> HoleyFocusList.plug 4          -- 1 2 3 <4>
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 1 [ 2, 3, 4 ]

-}
afterLast : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
afterLast holeyFocusList =
    HoleyFocusList (toReverseList holeyFocusList) nothing []


toReverseList : HoleyFocusList focus_ a -> List a
toReverseList =
    \(HoleyFocusList beforeFocusUntilHead focus after_) ->
        let
            focusToFirst =
                case focus of
                    IsNothing _ ->
                        beforeFocusUntilHead

                    IsJust current_ ->
                        current_ :: beforeFocusUntilHead
        in
        List.reverse after_ ++ focusToFirst


{-| Find the first item in the `HoleyFocusList` the matches a predicate, returning a
`HoleyFocusList` focussed on that item if it was found.

This start from the current focussed location and searches towards the end.

    HoleyFocusList.only 4
        |> HoleyFocusList.append [ 2, -1, 0, 3 ]
        |> HoleyFocusList.findForward (\item -> item < 0)
        |> Maybe.map HoleyFocusList.current
    --> Just -1

    HoleyFocusList.only -4
        |> HoleyFocusList.append [ 2, -1, 0, 3 ]
        |> HoleyFocusList.findForward (\item -> item < 0)
        |> Maybe.map HoleyFocusList.current
    --> Just -4

-}
findForward : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForward predicate =
    findForwardHelp predicate


findForwardHelp : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForwardHelp predicate holeyFocusList =
    let
        (HoleyFocusList before_ focus after_) =
            holeyFocusList

        goForward () =
            next holeyFocusList
                |> Maybe.andThen (findForwardHelp predicate)
    in
    case focus of
        IsJust cur ->
            if predicate cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goForward ()

        IsNothing _ ->
            goForward ()


{-| Find the first item in the `HoleyFocusList` matching a predicate, moving backwards
from the current position.

    HoleyFocusList.only 4
        |> HoleyFocusList.prepend [ 2, -1, 0, 3 ]
        |> HoleyFocusList.findBackward (\item -> item < 0)
        |> Maybe.map HoleyFocusList.current
    --> Just -1

-}
findBackward : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findBackward shouldStop =
    findBackwardHelp shouldStop


findBackwardHelp : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findBackwardHelp shouldStop holeyFocusList =
    let
        (HoleyFocusList before_ focus after_) =
            holeyFocusList

        goBack () =
            previous holeyFocusList
                |> Maybe.andThen (findBackwardHelp shouldStop)
    in
    case focus of
        IsJust cur ->
            if shouldStop cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goBack ()

        IsNothing _ ->
            goBack ()


{-| Execute a function on every item in the `HoleyFocusList`.

    import ListIs

    HoleyFocusList.only "first"
        |> HoleyFocusList.prepend [ "zeroth" ]
        |> HoleyFocusList.append [ "second", "third" ]
        |> HoleyFocusList.map String.toUpper
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

-}
map : (a -> b) -> HoleyFocusList focus a -> HoleyFocusList focus b
map changeItem =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList
            (List.map changeItem before_)
            (MaybeIs.map changeItem focus)
            (List.map changeItem after_)


{-| If an item is focussed in the `HoleyFocusList`, apply a function to it.

    import ListIs

    HoleyFocusList.only "first"
        |> HoleyFocusList.prepend [ "zeroth" ]
        |> HoleyFocusList.append [ "second", "third" ]
        |> HoleyFocusList.mapCurrent String.toUpper
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "zeroth" [ "FIRST", "second", "third" ]

-}
mapCurrent : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapCurrent updateCurrent =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ (MaybeIs.map updateCurrent focus) after_


{-| Apply a function to all items coming before the current focussed location.

    import ListIs

    HoleyFocusList.only "second"
        |> HoleyFocusList.prepend [ "zeroth", "first" ]
        |> HoleyFocusList.mapBefore String.toUpper
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "ZEROTH" [ "FIRST", "second" ]

-}
mapBefore : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapBefore updateItemBefore =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList (List.map updateItemBefore before_) focus after_


{-| Apply a function to all items coming after the current focussed location.

    import ListIs

    HoleyFocusList.only "zeroth"
        |> HoleyFocusList.append [ "first", "second" ]
        |> HoleyFocusList.mapAfter String.toUpper
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons "zeroth" [ "FIRST", "SECOND" ]

-}
mapAfter : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapAfter updateItemAfter =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (List.map updateItemAfter after_)


{-| Apply multiple different functions on the parts of a `HoleyFocusList` - what
comes before, what comes after, and the current item if there is one.

    import ListIs

    HoleyFocusList.only "first"
        |> HoleyFocusList.append [ "second" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug "one-and-a-halfth"
        |> HoleyFocusList.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons
    -->     "before: first"
    -->     [ "current: one-and-a-halfth"
    -->     , "after: second"
    -->     ]

-}
mapParts :
    { before : a -> b
    , current : a -> b
    , after : a -> b
    }
    -> HoleyFocusList focus a
    -> HoleyFocusList focus b
mapParts changePart =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList
            (List.map changePart.before before_)
            (MaybeIs.map changePart.current focus)
            (List.map changePart.after after_)


{-| Flattens the `HoleyFocusList` into a list:

    HoleyFocusList.only 456
        |> HoleyFocusList.prepend [ 123 ]
        |> HoleyFocusList.append [ 789 ]
        |> HoleyFocusList.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`joinParts`](#joinParts) to preserve some information about its length.

-}
toList : HoleyFocusList focus_ a -> List a
toList =
    \holeyFocusList ->
        before holeyFocusList ++ focusAndAfter holeyFocusList


{-| Flattens the `HoleyFocusList` into a [`ListIs`](ListIs):

    import ListIs

    HoleyFocusList.empty
        |> HoleyFocusList.joinParts
    --> ListIs.empty

    HoleyFocusList.only 123
        |> HoleyFocusList.append [ 789 ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug 456
        |> HoleyFocusList.joinParts
    --> ListIs.fromCons 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> ListIs.NotEmpty
    HoleOrItem -> ListIs.Emptiable

-}
joinParts :
    HoleyFocusList (CanBeNothing valueIfNothing focusTag_) a
    -> ListIs (CanBeNothing valueIfNothing emptyOrNotTag_) a
joinParts =
    \holeyFocusList ->
        let
            (HoleyFocusList _ focus after_) =
                holeyFocusList
        in
        case ( before holeyFocusList, focus ) of
            ( head_ :: afterFirstUntilFocus, _ ) ->
                ListIs.fromCons head_
                    (afterFirstUntilFocus ++ focusAndAfter holeyFocusList)

            ( [], IsJust cur ) ->
                ListIs.fromCons cur after_

            ( [], IsNothing (CanBeNothing canBeNothing) ) ->
                case after_ of
                    head_ :: tail_ ->
                        ListIs.fromCons head_ tail_

                    [] ->
                        IsNothing (CanBeNothing canBeNothing)



--


{-| Find out if the current focussed thing is an item.

    import MaybeIs

    HoleyFocusList.only 3
        |> HoleyFocusList.append [ 2, 1 ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.focussesItem
    --> MaybeIs.nothing

-}
focussesItem :
    HoleyFocusList (CanBeNothing valueIfNothing focusTag_) a
    -> MaybeIs (CanBeNothing valueIfNothing emptyOrNotTag_) (HoleyFocusList item_ a)
focussesItem =
    \holeyFocusList ->
        let
            (HoleyFocusList before_ focus after_) =
                holeyFocusList
        in
        case focus of
            IsNothing (CanBeNothing canBeNothing) ->
                IsNothing (CanBeNothing canBeNothing)

            IsJust current_ ->
                HoleyFocusList before_ (just current_) after_
                    |> just


{-| When using a `HoleyFocusList Item ...` argument,
its type can't be unified with non-`Item` lists.

Please read more at [`MaybeIs.branchableType`](MaybeIs#branchableType).

-}
branchableType : HoleyFocusList Item a -> HoleyFocusList item_ a
branchableType =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ (focus |> MaybeIs.branchableType) after_
