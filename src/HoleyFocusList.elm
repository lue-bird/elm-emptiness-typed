module HoleyFocusList exposing
    ( HoleyFocusList, Item, HoleOrItem
    , empty, only, currentAndAfter
    , current, before, after
    , next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward
    , mapCurrent, mapBefore, mapAfter, plug, remove, append, prepend, insertAfter, insertBefore
    , map, mapParts, toList
    , branchableType
    )

{-| Like a regular old list-zipper, except it can also focus on a hole
_between_ elements.

This means you can represent an empty list, or point between two items and plug
that hole with a value.


## types

@docs HoleyFocusList, Item, HoleOrItem


## create

@docs empty, only, currentAndAfter


## scan

@docs current, before, after


## navigate

@docs next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward


## modify

@docs mapCurrent, mapBefore, mapAfter, plug, remove, append, prepend, insertAfter, insertBefore


## transform

@docs map, mapParts, toList


## type-level

@docs branchableType

-}

import MaybeTyped exposing (MaybeTyped(..), just, nothing)


{-| Represents a special kind of list with items of type `a`.

If the type `focus` is `Item`, an item is focussed.
If not, you could be looking at a hole between elements.

-}
type HoleyFocusList focus a
    = HoleyFocusList (List a) (MaybeTyped focus a) (List a)


{-| A `HoleyFocusList Item a` is pointing at an element of type `a`.
-}
type alias Item =
    MaybeTyped.Just { item : () }


{-| A `HoleyFocusList HoleOrItem a` could be pointing at a hole between `a`s.

... Heh.

-}
type alias HoleOrItem =
    MaybeTyped.Nothingable { holeOrItem : () }


{-| Get the value the `HoleyFocusList` is currently pointing at.

Only applicable to zippers pointing at a value.

    HoleyFocusList.only "hi there"
        |> HoleyFocusList.current
    --> "hi there"


    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.current
    --> 4

-}
current : HoleyFocusList Item a -> a
current (HoleyFocusList _ focus _) =
    focus |> MaybeTyped.value


{-| Create an empty `HoleyFocusList`. It's pointing at nothing, there's nothing before it
and nothing after it. It's the loneliest of all zippers.

    HoleyFocusList.empty
        |> HoleyFocusList.toList
    --> []

-}
empty : HoleyFocusList HoleOrItem a_
empty =
    HoleyFocusList [] nothing []


{-| A `HoleyFocusList` with a single focussed item in it, nothing more.

    HoleyFocusList.only "wat"
        |> HoleyFocusList.toList
    --> [ "wat" ]

    HoleyFocusList.only "wat"
        |> HoleyFocusList.current
    --> "wat"

-}
only : a -> HoleyFocusList item_ a
only v =
    HoleyFocusList [] (just v) []


{-| Construct a `HoleyFocusList` from the head of a list and some elements to come after
it.

    HoleyFocusList.currentAndAfter "foo" []
    --> HoleyFocusList.only "foo"


    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.toList
    --> [ 0, 1, 2, 3 ]

-}
currentAndAfter : a -> List a -> HoleyFocusList item_ a
currentAndAfter v a =
    HoleyFocusList [] (just v) a


{-| List the things that come before the current location in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.andThen HoleyFocusList.next
        |> Maybe.map HoleyFocusList.before
    --> Just [ 0, 1 ]

-}
before : HoleyFocusList focus_ a -> List a
before (HoleyFocusList b _ _) =
    List.reverse b


{-| Conversely, list the things that come after the current location.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.after
    --> Just [ 2, 3 ]

-}
after : HoleyFocusList focus_ a -> List a
after (HoleyFocusList _ _ a) =
    a


{-| Move the `HoleyFocusList` to the next item, if there is one.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.current
    --> Just 1

This also works from within holes:

    HoleyFocusList.empty
        |> HoleyFocusList.insertAfter "foo"
        |> HoleyFocusList.next
    --> Just <| HoleyFocusList.only "foo"

If there is no `next` thing, `next` is `Nothing`.

    HoleyFocusList.empty
        |> HoleyFocusList.next
    --> Nothing


    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.next
    --> Nothing

-}
next : HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
next (HoleyFocusList before_ focus after_) =
    case after_ of
        [] ->
            Nothing

        n :: rest ->
            let
                newBefore =
                    case focus of
                        NothingTyped _ ->
                            before_

                        JustTyped v ->
                            v :: before_
            in
            HoleyFocusList newBefore (just n) rest
                |> Just


{-| Move the `HoleyFocusList` to the previous item, if there is one.

    HoleyFocusList.previous HoleyFocusList.empty
    --> Nothing


    HoleyFocusList.currentAndAfter "hello" [ "holey", "world" ]
        |> HoleyFocusList.last
        |> HoleyFocusList.previous
        |> Maybe.map HoleyFocusList.current
    --> Just "holey"

-}
previous : HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
previous ((HoleyFocusList before_ _ _) as holeySelectList) =
    case before_ of
        [] ->
            Nothing

        p :: rest ->
            HoleyFocusList rest (just p) (focusAndAfter holeySelectList)
                |> Just


{-| Move the `HoleyFocusList` to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

    HoleyFocusList.currentAndAfter "hello" [ "world" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug "holey"
        |> HoleyFocusList.toList
    --> [ "hello", "holey", "world" ]

-}
nextHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
nextHole ((HoleyFocusList before_ _ after_) as holeySelectList) =
    HoleyFocusList (current holeySelectList :: before_) nothing after_


{-| Move the `HoleyFocusList` to the hole right before the current item. Feel free to plug
that hole right up!

    HoleyFocusList.only "world"
        |> HoleyFocusList.previousHole
        |> HoleyFocusList.plug "hello"
        |> HoleyFocusList.toList
    --> [ "hello", "world" ]

-}
previousHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
previousHole ((HoleyFocusList before_ _ after_) as holeySelectList) =
    HoleyFocusList before_ nothing (current holeySelectList :: after_)


{-| Plug a `HoleyFocusList`.

    HoleyFocusList.plug "plug" HoleyFocusList.empty
    --> HoleyFocusList.only "plug"

-}
plug : a -> HoleyFocusList HoleOrItem a -> HoleyFocusList item_ a
plug v (HoleyFocusList b _ a) =
    HoleyFocusList b (just v) a


{-| Punch a hole into the `HoleyFocusList` by removing an element entirely. You can think
of this as collapsing the holes around the element into a single hole, but
honestly the holes are everywhere.

    HoleyFocusList.currentAndAfter "hello" [ "holey", "world" ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.remove
        |> Maybe.map HoleyFocusList.toList
    --> Just [ "hello", "world" ]

-}
remove : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
remove (HoleyFocusList b _ a) =
    HoleyFocusList b nothing a


{-| Insert something after the current location.

    HoleyFocusList.empty
        |> HoleyFocusList.insertAfter "hello"
        |> HoleyFocusList.toList
    --> [ "hello" ]


    HoleyFocusList.currentAndAfter 123 [ 789 ]
        |> HoleyFocusList.insertAfter 456
        |> HoleyFocusList.toList
    --> [ 123, 456, 789 ]

-}
insertAfter : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertAfter v (HoleyFocusList b c a) =
    HoleyFocusList b c (v :: a)


{-| Insert something before the current location.

    HoleyFocusList.empty
        |> HoleyFocusList.insertBefore "hello"
        |> HoleyFocusList.toList
    --> [ "hello" ]


    HoleyFocusList.only 123
        |> HoleyFocusList.insertBefore 456
        |> HoleyFocusList.toList
    --> [ 456, 123 ]

-}
insertBefore : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertBefore v (HoleyFocusList b c a) =
    HoleyFocusList (v :: b) c a


{-| Flattens the `HoleyFocusList` into a list.

    HoleyFocusList.toList HoleyFocusList.empty
    --> []


    HoleyFocusList.currentAndAfter 123 [ 789 ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug 456
        |> HoleyFocusList.toList
    --> [ 123, 456, 789 ]

-}
toList : HoleyFocusList focus_ a -> List a
toList holeySelectList =
    before holeySelectList ++ focusAndAfter holeySelectList


focusAndAfter : HoleyFocusList focus_ a -> List a
focusAndAfter (HoleyFocusList _ focus after_) =
    case focus of
        NothingTyped _ ->
            after_

        JustTyped v ->
            v :: after_


{-| Append a bunch of items after the `HoleyFocusList`. This appends all the way at the end.

    HoleyFocusList.currentAndAfter 123 [ 456 ]
        |> HoleyFocusList.append [ 789, 0 ]
        |> HoleyFocusList.toList
    --> [ 123, 456, 789, 0 ]

-}
append : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
append xs (HoleyFocusList b c a) =
    HoleyFocusList b c (a ++ xs)


{-| Prepend a bunch of things to the `HoleyFocusList`. All the way before anything else.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.prepend [ 5, 6, 7 ]
        |> HoleyFocusList.toList
    --> [ 5, 6, 7, 1, 2, 3, 4 ]

-}
prepend : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
prepend xs (HoleyFocusList b c a) =
    HoleyFocusList (b ++ List.reverse xs) c a


{-| Go to the first element in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.prepend [ 4, 3, 2 ]
        |> HoleyFocusList.first
        |> HoleyFocusList.current
    --> 4

-}
first : HoleyFocusList focus a -> HoleyFocusList focus a
first holeySelectList =
    case before holeySelectList of
        [] ->
            holeySelectList

        head :: afterHeadBeforeCurrent ->
            HoleyFocusList
                []
                (just head)
                (afterHeadBeforeCurrent ++ focusAndAfter holeySelectList)


{-| Go to the last element in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.current
    --> 4

-}
last : HoleyFocusList focus a -> HoleyFocusList focus a
last ((HoleyFocusList before_ focus after_) as holeySelectList) =
    case List.reverse after_ of
        [] ->
            holeySelectList

        last_ :: beforeLastUntilCurrent ->
            let
                focusToFirst =
                    case focus of
                        JustTyped cur ->
                            cur :: before_

                        NothingTyped _ ->
                            before_
            in
            HoleyFocusList
                (beforeLastUntilCurrent ++ focusToFirst)
                (just last_)
                []


{-| Go to the hole before the first element. Remember that holes surround
everything! They are everywhere.

    HoleyFocusList.currentAndAfter 1 [ 3, 4 ]
        |> HoleyFocusList.nextHole    -- we're after 1
        |> HoleyFocusList.plug 2      -- plug that hole
        |> HoleyFocusList.beforeFirst -- back to _before_ the first element
        |> HoleyFocusList.plug 0      -- put something in that hole
        |> HoleyFocusList.toList
    --> [ 0, 1, 2, 3, 4 ]

-}
beforeFirst : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
beforeFirst holeySelectList =
    HoleyFocusList [] nothing (toList holeySelectList)


{-| Go to the hole after the end of the `HoleyFocusList`. Into the nothingness.
-}
afterLast : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
afterLast (HoleyFocusList before_ focus after_) =
    let
        focusToFirst =
            case focus of
                NothingTyped _ ->
                    before_

                JustTyped v ->
                    v :: before_
    in
    HoleyFocusList (List.reverse after_ ++ focusToFirst) nothing []


{-| Find the first element in the `HoleyFocusList` the matches a predicate, returning a
`HoleyFocusList` pointing at that thing if it was found. When provided with a `HoleyFocusList`
pointing at a thing, that thing is also checked.

This start from the current location, and searches towards the end.

-}
findForward : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForward predicate z =
    findForwardHelp predicate z


findForwardHelp : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForwardHelp predicate ((HoleyFocusList before_ focus after_) as holeySelectList) =
    let
        goForward () =
            next holeySelectList
                |> Maybe.andThen (findForwardHelp predicate)
    in
    case focus of
        JustTyped cur ->
            if predicate cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goForward ()

        NothingTyped _ ->
            goForward ()


{-| Find the first element in the `HoleyFocusList` matching a predicate, moving backwards
from the current position.
-}
findBackward : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findBackward predicate z =
    findBackwardHelp predicate z


findBackwardHelp : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findBackwardHelp predicate ((HoleyFocusList before_ focus after_) as holeySelectList) =
    let
        goBack () =
            previous holeySelectList
                |> Maybe.andThen (findBackwardHelp predicate)
    in
    case focus of
        JustTyped cur ->
            if predicate cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goBack ()

        NothingTyped _ ->
            goBack ()


{-| Execute a function on every item in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter "first" [ "second", "third" ]
        |> HoleyFocusList.map String.toUpper
        |> HoleyFocusList.toList
    --> [ "FIRST", "SECOND", "THIRD" ]

-}
map : (a -> b) -> HoleyFocusList focus a -> HoleyFocusList focus b
map f (HoleyFocusList b c a) =
    HoleyFocusList (List.map f b) (MaybeTyped.map f c) (List.map f a)


{-| Execute a function on the current item in the `HoleyFocusList`, when pointing at an
item.

    HoleyFocusList.currentAndAfter "first" [ "second", "third" ]
        |> HoleyFocusList.mapCurrent String.toUpper
        |> HoleyFocusList.toList
    --> [ "FIRST", "second", "third" ]

-}
mapCurrent : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapCurrent f (HoleyFocusList b c a) =
    HoleyFocusList b (MaybeTyped.map f c) a


{-| Execute a function on all the things that came before the current location.

    HoleyFocusList.currentAndAfter "first" [ "second" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.mapBefore String.toUpper
        |> HoleyFocusList.toList
    --> [ "FIRST", "second" ]

-}
mapBefore : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapBefore f (HoleyFocusList b c a) =
    HoleyFocusList (List.map f b) c a


{-| Execute a function on all the things that come after the current location.
-}
mapAfter : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapAfter f (HoleyFocusList b c a) =
    HoleyFocusList b c (List.map f a)


{-| Execute a triplet of functions on the different parts of a `HoleyFocusList` - what
came before, what comes after, and the current thing if there is one.

    HoleyFocusList.currentAndAfter "first" [ "second" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug "one-and-a-halfth"
        |> HoleyFocusList.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> HoleyFocusList.toList
    --> [ "before: first"
    --> , "current: one-and-a-halfth"
    --> , "after: second"
    --> ]

-}
mapParts :
    { before : a -> b
    , current : a -> b
    , after : a -> b
    }
    -> HoleyFocusList focus a
    -> HoleyFocusList focus b
mapParts conf (HoleyFocusList before_ focus after_) =
    HoleyFocusList
        (List.map conf.before before_)
        (MaybeTyped.map conf.current focus)
        (List.map conf.after after_)



--


{-| When using a `HoleyFocusList Item ...` argument,
its type can't be unified with non-`Item` lists.

Please read more at [`MaybeTyped.branchableType`](MaybeTyped#branchableType).

-}
branchableType : HoleyFocusList Item a -> HoleyFocusList item_ a
branchableType (HoleyFocusList before_ focus after_) =
    HoleyFocusList before_ (focus |> MaybeTyped.branchableType) after_
