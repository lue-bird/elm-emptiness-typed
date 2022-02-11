module ListWithFocusThat exposing
    ( ListWithFocusThat, Hole
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
    , map, mapParts, joinParts, toList
    , focussesItem, branchableType
    )

{-| A list zipper that can also focus on a hole _between_ items.

1.  🔎 focus on a hole between two items
2.  🔌 plug that hole with a value
3.  💰 profit


## types

@docs ListWithFocusThat, Hole


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

@docs map, mapParts, joinParts, toList


## type-level

@docs focussesItem, branchableType

-}

import ListThat exposing (ListThat)
import MaybeThat exposing (Be(..), Can(..), CanBe, Isnt, MaybeThat(..), just, nothing)


{-| Represents a special kind of list with items of type `item`.

The focus can be

  - `🍍 🍓 <🍊> 🍉 🍇`: use [`Isnt`](MaybeThat#Isnt) [`Hole`](#Hole) to require such an argument

  - `🍍 🍓 <?> 🍉 🍇`: use a type variable or [`CanBe`](MaybeThat#CanBe)[`Hole`](#Hole) to require such an argument

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a hole between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`

-}
type ListWithFocusThat canBeHoleOrNot item
    = ListWithFocusThat (List item) (MaybeThat canBeHoleOrNot item) (List item)


{-| Type tag, signaling focus on the space before or after an item.

Especially when stored as a value

  - `🍍 🍓 <🍊> 🍉 🍇`: [`Isnt`](MaybeThat#Isnt) [`Hole`](#Hole)

  - `🍍 🍓 <?> 🍉 🍇`: [`CanBe`](MaybeThat#CanBe) [`Hole`](#Hole)

    `<?>` means both are possible:

      - `🍍 🍓 <> 🍉 🍇`: a hole between items ... Heh.
      - `🍍 🍓 <🍊> 🍉 🍇`

```
type alias Model =
    WithoutConstructorFunction
        { choice : ListWithFocusThat (Isnt Hole) Option
        }
```

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

-}
type Hole
    = Hole Never


{-| An empty `ListWithFocusThat` focussed on a hole with nothing before
and after it.
It's the loneliest of all `ListWithFocusThat`s.

```monospace
<>
```

    import ListThat

    ListWithFocusThat.empty
        |> ListWithFocusThat.joinParts
    --> ListThat.empty

-}
empty : ListWithFocusThat (CanBe hole_) isntHole_
empty =
    ListWithFocusThat [] nothing []


{-| A `ListWithFocusThat` with a single focussed item in it, nothing before and after it.

```monospace
<🍊>
```

    import ListThat

    ListWithFocusThat.only "wat"
        |> ListWithFocusThat.current
    --> "wat"

    ListWithFocusThat.only "wat"
        |> ListWithFocusThat.joinParts
    --> ListThat.only "wat"

-}
only : element -> ListWithFocusThat isntHole_ element
only current_ =
    ListWithFocusThat [] (just current_) []



--


{-| The current focussed item in the `ListWithFocusThat`.

```monospace
🍍 🍓 <🍊> 🍉 🍇  ->  🍊
```

    ListWithFocusThat.only "hi there"
        |> ListWithFocusThat.current
    --> "hi there"

    ListWithFocusThat.only 1
        |> ListWithFocusThat.append [ 2, 3, 4 ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.current
    --> 4

-}
current : ListWithFocusThat (Isnt hole_) item -> item
current =
    \(ListWithFocusThat _ focus _) ->
        focus |> MaybeThat.value


{-| The items before the location of the focus in the `ListWithFocusThat`.

```monospace
🍍 🍓) <🍊> 🍉 🍇
```

    ListWithFocusThat.only 0
        |> ListWithFocusThat.append [ 1, 2, 3 ]
        |> ListWithFocusThat.next
        |> Maybe.andThen ListWithFocusThat.next
        |> Maybe.map ListWithFocusThat.before
    --> Just [ 0, 1 ]

-}
before : ListWithFocusThat canBeHoleOrNot_ item -> List item
before =
    \(ListWithFocusThat beforeFocusUntilHead _ _) ->
        List.reverse beforeFocusUntilHead


{-| The items after the current focussed location in the `ListWithFocusThat`.

```monospace
🍍 🍓 <🍊> (🍉 🍇
```

    ListWithFocusThat.only 0
        |> ListWithFocusThat.append [ 1, 2, 3 ]
        |> ListWithFocusThat.next
        |> Maybe.map ListWithFocusThat.after
    --> Just [ 2, 3 ]

-}
after : ListWithFocusThat canBeHoleOrNot_ item -> List item
after =
    \(ListWithFocusThat _ _ after_) ->
        after_



--


{-| Move the focus of the `ListWithFocusThat` to the next item, if there is one.

```monospace
<🍊> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocusThat.only 0
        |> ListWithFocusThat.append [ 1, 2, 3 ]
        |> ListWithFocusThat.next
        |> Maybe.map ListWithFocusThat.current
    --> Just 1

This also works from within holes:

```monospace
🍊 <> 🍉 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocusThat.empty
        |> ListWithFocusThat.insertAfter "foo"
        |> ListWithFocusThat.next
    --> Just (ListWithFocusThat.only "foo")

If there is no `next` item, the result is `Nothing`.

    ListWithFocusThat.empty
        |> ListWithFocusThat.next
    --> Nothing


    ListWithFocusThat.only 0
        |> ListWithFocusThat.append [ 1, 2, 3 ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.next
    --> Nothing

-}
next :
    ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
next (ListWithFocusThat beforeFocusUntilHead focus after_) =
    case after_ of
        [] ->
            Nothing

        next_ :: afterNext ->
            let
                newBeforeReversed =
                    case focus of
                        NothingThat _ ->
                            beforeFocusUntilHead

                        JustThat oldCurrent ->
                            oldCurrent :: beforeFocusUntilHead
            in
            ListWithFocusThat newBeforeReversed (just next_) afterNext
                |> Just


{-| Move the focus of the `ListWithFocusThat` to the previous item, if there is one.

```monospace
🍊 <🍉> 🍇  ->  <🍊> 🍉 🍇
```

    ListWithFocusThat.empty |> ListWithFocusThat.previous
    --> Nothing

    ListWithFocusThat.only "hello"
        |> ListWithFocusThat.append [ "holey", "world" ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.previous
        |> Maybe.map ListWithFocusThat.current
    --> Just "holey"

This also works from within holes:

```monospace
🍊 🍉 <> 🍇  ->  🍊 <🍉> 🍇
```

    ListWithFocusThat.empty
        |> ListWithFocusThat.insertBefore "foo"
        |> ListWithFocusThat.previous
    --> Just (ListWithFocusThat.only "foo")

-}
previous :
    ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
previous listWithFocusThat =
    let
        (ListWithFocusThat beforeFocusUntilHead _ _) =
            listWithFocusThat
    in
    case beforeFocusUntilHead of
        [] ->
            Nothing

        previous_ :: beforePreviousToHead ->
            ListWithFocusThat
                beforePreviousToHead
                (just previous_)
                (listWithFocusThat |> focusAndAfter)
                |> Just


{-| Move the `ListWithFocusThat` to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

```monospace
🍍 <🍊> 🍉  ->  🍍 🍊 <> 🍉
```

    import ListThat

    ListWithFocusThat.only "hello"
        |> ListWithFocusThat.append [ "world" ]
        |> ListWithFocusThat.nextHole
        |> ListWithFocusThat.plug "holey"
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "hello" [ "holey", "world" ]

-}
nextHole :
    ListWithFocusThat (Isnt hole) item
    -> ListWithFocusThat (CanBe hole) item
nextHole listWithFocusThat =
    let
        (ListWithFocusThat beforeFocusUntilHead _ after_) =
            listWithFocusThat
    in
    ListWithFocusThat
        (current listWithFocusThat :: beforeFocusUntilHead)
        nothing
        after_


{-| Move the `ListWithFocusThat` to the hole right before the current item. Feel free to plug
that hole right up!

```monospace
🍍 <🍊> 🍉  ->  🍍 <> 🍊 🍉
```

    import ListThat

    ListWithFocusThat.only "world"
        |> ListWithFocusThat.previousHole
        |> ListWithFocusThat.plug "hello"
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "hello" [ "world" ]

-}
previousHole :
    ListWithFocusThat (Isnt hole_) item
    -> ListWithFocusThat (CanBe holeResult_) item
previousHole listWithFocusThat =
    let
        (ListWithFocusThat before_ _ after_) =
            listWithFocusThat
    in
    ListWithFocusThat
        before_
        nothing
        ((listWithFocusThat |> current) :: after_)



--


{-| Fill in or replace the focussed thing in the `ListWithFocusThat`.

```monospace
🍓 <?> 🍉  ->  🍓 <🍒> 🍉
```

    import ListThat

    ListWithFocusThat.empty
        |> ListWithFocusThat.insertBefore "🍓" -- "🍓" <>
        |> ListWithFocusThat.insertAfter "🍉"  -- "🍓" <> "🍉"
        |> ListWithFocusThat.plug "🍒"         -- "🍓" <"🍒"> "🍉"
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "🍓" [ "🍒", "🍉" ]

-}
plug :
    item
    -> ListWithFocusThat canBeHoleOrNot_ item
    -> ListWithFocusThat isntHole_ item
plug newCurrent =
    \(ListWithFocusThat before_ _ after_) ->
        ListWithFocusThat before_ (just newCurrent) after_


{-| Punch a hole into the `ListWithFocusThat` by removing the focussed thing.

```monospace
🍓 <?> 🍉  ->  🍓 <> 🍉
```

    ListWithFocusThat.only "hello"
        |> ListWithFocusThat.append [ "holey", "world" ]
        |> ListWithFocusThat.next
        |> Maybe.map ListWithFocusThat.remove
        |> Maybe.map ListWithFocusThat.toList
    --> Just [ "hello", "world" ]

-}
remove :
    ListWithFocusThat canBeHoleOrNot_ item
    -> ListWithFocusThat (CanBe hole_) item
remove =
    \(ListWithFocusThat before_ _ after_) ->
        ListWithFocusThat before_ nothing after_


{-| Insert an item after the focussed location.

```monospace
        🍒
🍓 <🍊> ↓ 🍉 🍇
```

    import ListThat

    ListWithFocusThat.only 123
        |> ListWithFocusThat.append [ 789 ]
        |> ListWithFocusThat.insertAfter 456
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 123 [ 456, 789 ]

Insert multiple items using [`squeezeInAfter`](#squeezeInAfter).

-}
insertAfter :
    item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
insertAfter toInsertAfterFocus =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat before_ focus (toInsertAfterFocus :: after_)


{-| Insert an item before the focussed location.

```monospace
      🍒
🍍 🍓 ↓ <🍊> 🍉
```

    import ListThat

    ListWithFocusThat.only 123
        |> ListWithFocusThat.insertBefore 456
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 456 [ 123 ]

Insert multiple items using [`squeezeInBefore`](#squeezeInBefore).

-}
insertBefore :
    item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
insertBefore itemToInsertBefore =
    \(ListWithFocusThat beforeFocusUntilHead focus after_) ->
        ListWithFocusThat
            (itemToInsertBefore :: beforeFocusUntilHead)
            focus
            after_


focusAndAfter : ListWithFocusThat canBeHoleOrNot_ item -> List item
focusAndAfter =
    \(ListWithFocusThat _ focus after_) ->
        case focus of
            NothingThat _ ->
                after_

            JustThat current_ ->
                current_ :: after_


{-| Append items directly after the focussed location in the `ListWithFocusThat`.

```monospace
        🍒🍋
🍓 <🍊> \↓/ 🍉 🍇
```

    import ListThat

    ListWithFocusThat.only 0
        |> ListWithFocusThat.squeezeInAfter [ 4, 5 ]
        |> ListWithFocusThat.squeezeInAfter [ 1, 2, 3 ]
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 0 [ 1, 2, 3, 4, 5 ]

-}
squeezeInAfter :
    List item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
squeezeInAfter toAppendDirectlyAfterFocus =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat before_ focus (toAppendDirectlyAfterFocus ++ after_)


{-| Prepend items directly before the focussed location in the `ListWithFocusThat`.

```monospace
      🍒🍋
🍍 🍓 \↓/ <🍊> 🍉
```

    import ListThat

    ListWithFocusThat.only 0
        |> ListWithFocusThat.squeezeInBefore [ -5, -4 ]
        |> ListWithFocusThat.squeezeInBefore [ -3, -2, -1 ]
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons -5 [ -4, -3, -2, -1, 0 ]

-}
squeezeInBefore :
    List item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
squeezeInBefore toPrependDirectlyBeforeFocus =
    \(ListWithFocusThat beforeFocusUntilHead focus after_) ->
        ListWithFocusThat
            (List.reverse toPrependDirectlyBeforeFocus ++ beforeFocusUntilHead)
            focus
            after_


{-| Put items to the end of the `ListWithFocusThat`. After anything else.

```monospace
              🍒🍋
🍓 <🍊> 🍉 🍇 ↓/
```

    import ListThat

    ListWithFocusThat.only 123
        |> ListWithFocusThat.append [ 456 ]
        |> ListWithFocusThat.append [ 789, 0 ]
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 123 [ 456, 789, 0 ]

-}
append :
    List item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
append itemsToAppend =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat before_ focus (after_ ++ itemsToAppend)


{-| Put items to the beginning of the `ListWithFocusThat`. Before anything else.

```monospace
🍒🍋
 \↓ 🍍 🍓 <🍊> 🍉
```

    import ListThat

    ListWithFocusThat.only 1
        |> ListWithFocusThat.append [ 2, 3, 4 ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.prepend [ 5, 6, 7 ]
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prepend :
    List item
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
prepend itemsToPrepend =
    \(ListWithFocusThat beforeFocusUntilHead focus after_) ->
        ListWithFocusThat
            (beforeFocusUntilHead ++ List.reverse itemsToPrepend)
            focus
            after_


{-| Focus the first item in the `ListWithFocusThat`.

```monospace
🍍 🍓 <🍊> 🍉  ->  <🍍> 🍓 🍊 🍉
```

    ListWithFocusThat.only 1
        |> ListWithFocusThat.append [ 2, 3, 4 ]
        |> ListWithFocusThat.prepend [ 4, 3, 2 ]
        |> ListWithFocusThat.first
        |> ListWithFocusThat.current
    --> 4

-}
first :
    ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
first =
    \listWithFocusThat ->
        case listWithFocusThat |> before of
            [] ->
                listWithFocusThat

            head :: afterHeadBeforeCurrent ->
                ListWithFocusThat
                    []
                    (just head)
                    (afterHeadBeforeCurrent
                        ++ (listWithFocusThat |> focusAndAfter)
                    )


{-| Focus the last item in the `ListWithFocusThat`.

```monospace
🍓 <🍊> 🍉 🍇  ->  🍓 🍊 🍉 <🍇>
```

    ListWithFocusThat.only 1
        |> ListWithFocusThat.append [ 2, 3, 4 ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.current
    --> 4

    ListWithFocusThat.only 1
        |> ListWithFocusThat.append [ 2, 3, 4 ]
        |> ListWithFocusThat.last
        |> ListWithFocusThat.before
    --> [ 1, 2, 3 ]

-}
last :
    ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
last =
    \listWithFocusThat ->
        let
            (ListWithFocusThat before_ focus after_) =
                listWithFocusThat
        in
        case List.reverse after_ of
            [] ->
                listWithFocusThat

            last_ :: beforeLastUntilCurrent ->
                let
                    focusToFirst =
                        case focus of
                            JustThat current_ ->
                                current_ :: before_

                            NothingThat _ ->
                                before_
                in
                ListWithFocusThat
                    (beforeLastUntilCurrent ++ focusToFirst)
                    (just last_)
                    []


{-| Focus the hole before the first item.
Remember that holes surround everything!

```monospace
🍍 🍓 <🍊> 🍉  ->  <> 🍍 🍓 🍊 🍉
```

    import ListThat

    ListWithFocusThat.only 1                 -- <1>
        |> ListWithFocusThat.append [ 3, 4 ] -- <1> 3 4
        |> ListWithFocusThat.nextHole        -- 1 <> 3 4
        |> ListWithFocusThat.plug 2          -- 1 <2> 3 4
        |> ListWithFocusThat.beforeFirst     -- <> 1 2 3 4
        |> ListWithFocusThat.plug 0          -- <0> 1 2 3 4
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 0 [ 1, 2, 3, 4 ]

-}
beforeFirst :
    ListWithFocusThat canBeHoleOrNot_ item
    -> ListWithFocusThat (CanBe hole_) item
beforeFirst listWithFocusThat =
    ListWithFocusThat [] nothing (listWithFocusThat |> toList)


{-| Focus the hole after the end of the `ListWithFocusThat`. Into the nothingness.

```monospace
🍓 <🍊> 🍉  ->  🍓 🍊 🍉 <>
```

    import ListThat

    ListWithFocusThat.only 1                 -- <1>
        |> ListWithFocusThat.append [ 2, 3 ] -- <1> 2 3
        |> ListWithFocusThat.afterLast       -- 1 2 3 <>
        |> ListWithFocusThat.plug 4          -- 1 2 3 <4>
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 1 [ 2, 3, 4 ]

-}
afterLast :
    ListWithFocusThat canBeHoleOrNot_ item
    -> ListWithFocusThat (CanBe hole_) item
afterLast listWithFocusThat =
    ListWithFocusThat (toReverseList listWithFocusThat) nothing []


toReverseList : ListWithFocusThat canBeHoleOrNot_ a -> List a
toReverseList =
    \(ListWithFocusThat beforeFocusUntilHead focus after_) ->
        let
            focusToFirst =
                case focus of
                    NothingThat _ ->
                        beforeFocusUntilHead

                    JustThat current_ ->
                        current_ :: beforeFocusUntilHead
        in
        List.reverse after_ ++ focusToFirst


{-| Find the first item in the `ListWithFocusThat` the matches a predicate, returning a
`ListWithFocusThat` focussed on that item if it was found.

This start from the current focussed location and searches towards the end.

    ListWithFocusThat.only 4
        |> ListWithFocusThat.append [ 2, -1, 0, 3 ]
        |> ListWithFocusThat.findForward (\item -> item < 0)
        |> Maybe.map ListWithFocusThat.current
    --> Just -1

    ListWithFocusThat.only -4
        |> ListWithFocusThat.append [ 2, -1, 0, 3 ]
        |> ListWithFocusThat.findForward (\item -> item < 0)
        |> Maybe.map ListWithFocusThat.current
    --> Just -4

-}
findForward :
    (item -> Bool)
    -> ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
findForward predicate =
    findForwardHelp predicate


findForwardHelp :
    (item -> Bool)
    -> ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
findForwardHelp predicate =
    \listWithFocusThat ->
        let
            (ListWithFocusThat before_ focus after_) =
                listWithFocusThat

            goForward () =
                listWithFocusThat
                    |> next
                    |> Maybe.andThen (findForwardHelp predicate)
        in
        case focus of
            JustThat cur ->
                if predicate cur then
                    ListWithFocusThat before_ (just cur) after_
                        |> Just

                else
                    goForward ()

            NothingThat _ ->
                goForward ()


{-| Find the first item in the `ListWithFocusThat` matching a predicate, moving backwards
from the current position.

    ListWithFocusThat.only 4
        |> ListWithFocusThat.prepend [ 2, -1, 0, 3 ]
        |> ListWithFocusThat.findBackward (\item -> item < 0)
        |> Maybe.map ListWithFocusThat.current
    --> Just -1

-}
findBackward :
    (item -> Bool)
    -> ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
findBackward shouldStop =
    findBackwardHelp shouldStop


findBackwardHelp :
    (item -> Bool)
    -> ListWithFocusThat canBeHoleOrNot_ item
    -> Maybe (ListWithFocusThat isntHole_ item)
findBackwardHelp shouldStop =
    \listWithFocusThat ->
        let
            (ListWithFocusThat before_ focus after_) =
                listWithFocusThat

            goBack () =
                listWithFocusThat
                    |> previous
                    |> Maybe.andThen (findBackwardHelp shouldStop)
        in
        case focus of
            JustThat cur ->
                if shouldStop cur then
                    ListWithFocusThat before_ (just cur) after_
                        |> Just

                else
                    goBack ()

            NothingThat _ ->
                goBack ()


{-| Execute a function on every item in the `ListWithFocusThat`.

    import ListThat

    ListWithFocusThat.only "first"
        |> ListWithFocusThat.prepend [ "zeroth" ]
        |> ListWithFocusThat.append [ "second", "third" ]
        |> ListWithFocusThat.map String.toUpper
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "ZEROTH" [ "FIRST", "SECOND", "THIRD" ]

-}
map :
    (item -> mappedItem)
    -> ListWithFocusThat (Can possiblyOrNever Be hole) item
    -> ListWithFocusThat (Can possiblyOrNever Be hole) mappedItem
map changeItem =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            (List.map changeItem before_)
            (MaybeThat.map changeItem focus)
            (List.map changeItem after_)


{-| If an item is focussed in the `ListWithFocusThat`, apply a function to it.

    import ListThat

    ListWithFocusThat.only "first"
        |> ListWithFocusThat.prepend [ "zeroth" ]
        |> ListWithFocusThat.append [ "second", "third" ]
        |> ListWithFocusThat.alterCurrent String.toUpper
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "zeroth" [ "FIRST", "second", "third" ]

-}
alterCurrent :
    (item -> item)
    -> ListWithFocusThat (Can possiblyOrNever Be hole) item
    -> ListWithFocusThat (Can possiblyOrNever Be hole) item
alterCurrent updateCurrent =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            before_
            (MaybeThat.map updateCurrent focus)
            after_


{-| Apply a function to all items coming before the current focussed location.

    import ListThat

    ListWithFocusThat.only "second"
        |> ListWithFocusThat.prepend [ "zeroth", "first" ]
        |> ListWithFocusThat.alterBefore String.toUpper
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "ZEROTH" [ "FIRST", "second" ]

-}
alterBefore :
    (item -> item)
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
alterBefore updateItemBefore =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            (List.map updateItemBefore before_)
            focus
            after_


{-| Apply a function to all items coming after the current focussed location.

    import ListThat

    ListWithFocusThat.only "zeroth"
        |> ListWithFocusThat.append [ "first", "second" ]
        |> ListWithFocusThat.alterAfter String.toUpper
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons "zeroth" [ "FIRST", "SECOND" ]

-}
alterAfter :
    (item -> item)
    -> ListWithFocusThat canBeHoleOrNot item
    -> ListWithFocusThat canBeHoleOrNot item
alterAfter updateItemAfter =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            before_
            focus
            (List.map updateItemAfter after_)


{-| Apply multiple different functions on the parts of a `ListWithFocusThat` - what
comes before, what comes after, and the current item if there is one.

    import ListThat

    ListWithFocusThat.only "first"
        |> ListWithFocusThat.append [ "second" ]
        |> ListWithFocusThat.nextHole
        |> ListWithFocusThat.plug "one-and-a-halfth"
        |> ListWithFocusThat.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons
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
    -> ListWithFocusThat (Can possiblyOrNever Be hole) item
    -> ListWithFocusThat (Can possiblyOrNever Be hole) mappedItem
mapParts changePart =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            (List.map changePart.before before_)
            (MaybeThat.map changePart.current focus)
            (List.map changePart.after after_)


{-| Flattens the `ListWithFocusThat` into a list:

    ListWithFocusThat.only 456
        |> ListWithFocusThat.prepend [ 123 ]
        |> ListWithFocusThat.append [ 789 ]
        |> ListWithFocusThat.toList
    --> [ 123, 456, 789 ]

Only use this if you need a list in the end.
Otherwise, use [`joinParts`](#joinParts) to preserve some information about its length.

-}
toList : ListWithFocusThat canBeHoleOrNot_ item -> List item
toList =
    \listWithFocusThat ->
        (listWithFocusThat |> before)
            ++ (listWithFocusThat |> focusAndAfter)


{-| Flattens the `ListWithFocusThat` into a [`ListThat`](ListThat):

    import ListThat

    ListWithFocusThat.empty
        |> ListWithFocusThat.joinParts
    --> ListThat.empty

    ListWithFocusThat.only 123
        |> ListWithFocusThat.append [ 789 ]
        |> ListWithFocusThat.nextHole
        |> ListWithFocusThat.plug 456
        |> ListWithFocusThat.joinParts
    --> ListThat.fromCons 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> ListThat.(Isnt Empty)
    CanBe hole_ () -> CanBe empty_ ()

-}
joinParts :
    ListWithFocusThat (Can possiblyOrNever Be hole_) item
    -> ListThat (Can possiblyOrNever Be empty_) item
joinParts =
    \listWithFocusThat ->
        let
            (ListWithFocusThat _ focus after_) =
                listWithFocusThat
        in
        case ( before listWithFocusThat, focus ) of
            ( head_ :: afterFirstUntilFocus, _ ) ->
                ListThat.fromCons head_
                    (afterFirstUntilFocus
                        ++ (listWithFocusThat |> focusAndAfter)
                    )

            ( [], JustThat cur ) ->
                ListThat.fromCons cur after_

            ( [], NothingThat (Can possiblyOrNever Be) ) ->
                case after_ of
                    head_ :: tail_ ->
                        ListThat.fromCons head_ tail_

                    [] ->
                        NothingThat (Can possiblyOrNever Be)



--


{-| Find out if the current focussed thing is an item.

    import MaybeThat

    ListWithFocusThat.only 3
        |> ListWithFocusThat.append [ 2, 1 ]
        |> ListWithFocusThat.nextHole
        |> ListWithFocusThat.focussesItem
    --> MaybeThat.nothing

-}
focussesItem :
    ListWithFocusThat (Can possiblyOrNever Be hole_) item
    ->
        MaybeThat
            (Can possiblyOrNever Be nothing_)
            (ListWithFocusThat isntHole_ item)
focussesItem =
    \listWithFocusThat ->
        let
            (ListWithFocusThat before_ focus after_) =
                listWithFocusThat
        in
        focus
            |> MaybeThat.map
                (\current_ ->
                    ListWithFocusThat before_ (just current_) after_
                )


{-| When using a `ListWithFocusThat Item ...` argument,
its type can't be unified with non-`Item` lists.

Please read more at [`MaybeThat.branchableType`](MaybeThat#branchableType).

-}
branchableType :
    ListWithFocusThat (Isnt hole_) item
    -> ListWithFocusThat isntHole_ item
branchableType =
    \(ListWithFocusThat before_ focus after_) ->
        ListWithFocusThat
            before_
            (focus |> MaybeThat.branchableType)
            after_
