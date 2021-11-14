module HoleySelectList exposing
    ( HoleySelectList, Full, MaybeHole
    , empty, singleton, selecting
    , current, before, after, toList
    , next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward
    , map, mapCurrent, mapBefore, mapAfter, mapParts, plug, remove, append, prepend, insertAfter, insertBefore
    )

{-| Like a regular old list-zipper, except it can also focus on a hole
_between_ elements.

This means you can represent an empty list, or point between two items and plug
that hole with a value.


# Types

@docs HoleySelectList, Full, MaybeHole


# Creation

@docs empty, singleton, selecting


# Extraction

@docs current, before, after, toList


# Navigation

@docs next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward


# Modification

@docs map, mapCurrent, mapBefore, mapAfter, mapParts, plug, remove, append, prepend, insertAfter, insertBefore

-}

import MaybeTyped exposing (MaybeEmpty, MaybeTyped(..), NotEmpty, just, nothing)


{-| Represents a list with items of type `a`.

  - When the type `hasHole` is `Full`, an item is focussed.
  - When it is `MaybeHole`, you're looking at a hole between elements.

-}
type HoleySelectList hasHole a
    = HoleySelectList (List a) (MaybeTyped hasHole a) (List a)


{-| A `Zipper Full a` is pointing at an element of type `a`.
-}
type alias Full =
    NotEmpty


{-| A `Zipper MaybeHole a` is pointing at a hole between `a`s.

... Heh.

-}
type alias MaybeHole =
    MaybeEmpty


{-| Get the value the `Zipper` is currently pointing at.

Only applicable to zippers pointing at a value.

    HoleySelectList.singleton "hi there"
        |> HoleySelectList.current
    --> "hi there"


    HoleySelectList.selecting 1 [ 2, 3, 4 ]
        |> HoleySelectList.last
        |> HoleySelectList.current
    --> 4

-}
current : HoleySelectList Full a -> a
current (HoleySelectList _ focus _) =
    focus |> MaybeTyped.value


{-| Create an empty `HoleySelectList`. It's pointing at nothing, there's nothing before it
and nothing after it. It's the loneliest of all zippers.

    HoleySelectList.toList HoleySelectList.empty
    --> []

-}
empty : HoleySelectList MaybeHole a
empty =
    HoleySelectList [] nothing []


{-| A `HoleySelectList` with a single thing in it. Singleton is just fancy-speak for single
thing.

    HoleySelectList.singleton "wat"
        |> HoleySelectList.toList
    --> [ "wat" ]

-}
singleton : a -> HoleySelectList full a
singleton v =
    HoleySelectList [] (just v) []


{-| Construct a `HoleySelectList` from the head of a list and some elements to come after
it.

    HoleySelectList.selecting "foo" []
    --> HoleySelectList.singleton "foo"


    HoleySelectList.selecting 0 [ 1, 2, 3 ]
        |> HoleySelectList.toList
    --> [ 0, 1, 2, 3 ]

-}
selecting : a -> List a -> HoleySelectList full a
selecting v a =
    HoleySelectList [] (just v) a


{-| List the things that come before the current location in the `HoleySelectList`.

    HoleySelectList.selecting 0 [ 1, 2, 3 ]
        |> HoleySelectList.next
        |> Maybe.andThen HoleySelectList.next
        |> Maybe.map HoleySelectList.before
    --> Just [ 0, 1 ]

-}
before : HoleySelectList t a -> List a
before (HoleySelectList b _ _) =
    List.reverse b


{-| Conversely, list the things that come after the current location.

    HoleySelectList.selecting 0 [ 1, 2, 3 ]
        |> HoleySelectList.next
        |> Maybe.map HoleySelectList.after
    --> Just [ 2, 3 ]

-}
after : HoleySelectList t a -> List a
after (HoleySelectList _ _ a) =
    a


{-| Move the `HoleySelectList` to the next item, if there is one.

    HoleySelectList.selecting 0 [ 1, 2, 3 ]
        |> HoleySelectList.next
        |> Maybe.map HoleySelectList.current
    --> Just 1

This also works from within holes:

    HoleySelectList.empty
        |> HoleySelectList.insertAfter "foo"
        |> HoleySelectList.next
    --> Just <| HoleySelectList.singleton "foo"

If there is no `next` thing, `next` is `Nothing`.

    HoleySelectList.empty
        |> HoleySelectList.next
    --> Nothing


    HoleySelectList.selecting 0 [ 1, 2, 3 ]
        |> HoleySelectList.last
        |> HoleySelectList.next
    --> Nothing

-}
next : HoleySelectList hasHole a -> Maybe (HoleySelectList full a)
next (HoleySelectList before_ focus after_) =
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
            HoleySelectList newBefore (just n) rest
                |> Just


{-| Move the `HoleySelectList` to the previous item, if there is one.

    HoleySelectList.previous HoleySelectList.empty
    --> Nothing


    HoleySelectList.selecting "hello" [ "holey", "world" ]
        |> HoleySelectList.last
        |> HoleySelectList.previous
        |> Maybe.map HoleySelectList.current
    --> Just "holey"

-}
previous : HoleySelectList hasHole a -> Maybe (HoleySelectList full a)
previous ((HoleySelectList before_ _ _) as holeySelectList) =
    case before_ of
        [] ->
            Nothing

        p :: rest ->
            HoleySelectList rest (just p) (focusAndAfter holeySelectList)
                |> Just


{-| Move the `HoleySelectList` to the hole right after the current item. A hole is a whole
lot of nothingness, so it's always there.

    HoleySelectList.selecting "hello" [ "world" ]
        |> HoleySelectList.nextHole
        |> HoleySelectList.plug "holey"
        |> HoleySelectList.toList
    --> [ "hello", "holey", "world" ]

-}
nextHole : HoleySelectList Full a -> HoleySelectList MaybeHole a
nextHole ((HoleySelectList before_ _ after_) as holeySelectList) =
    HoleySelectList (current holeySelectList :: before_) nothing after_


{-| Move the `HoleySelectList` to the hole right before the current item. Feel free to plug
that hole right up!

    HoleySelectList.singleton "world"
        |> HoleySelectList.previousHole
        |> HoleySelectList.plug "hello"
        |> HoleySelectList.toList
    --> [ "hello", "world" ]

-}
previousHole : HoleySelectList Full a -> HoleySelectList MaybeHole a
previousHole ((HoleySelectList before_ _ after_) as holeySelectList) =
    HoleySelectList before_ nothing (current holeySelectList :: after_)


{-| Plug a `HoleySelectList`.

    HoleySelectList.plug "plug" HoleySelectList.empty
    --> HoleySelectList.singleton "plug"

-}
plug : a -> HoleySelectList MaybeHole a -> HoleySelectList full a
plug v (HoleySelectList b _ a) =
    HoleySelectList b (just v) a


{-| Punch a hole into the `HoleySelectList` by removing an element entirely. You can think
of this as collapsing the holes around the element into a single hole, but
honestly the holes are everywhere.

    HoleySelectList.selecting "hello" [ "holey", "world" ]
        |> HoleySelectList.next
        |> Maybe.map HoleySelectList.remove
        |> Maybe.map HoleySelectList.toList
    --> Just [ "hello", "world" ]

-}
remove : HoleySelectList hasHole a -> HoleySelectList MaybeHole a
remove (HoleySelectList b _ a) =
    HoleySelectList b nothing a


{-| Insert something after the current location.

    HoleySelectList.empty
        |> HoleySelectList.insertAfter "hello"
        |> HoleySelectList.toList
    --> [ "hello" ]


    HoleySelectList.selecting 123 [ 789 ]
        |> HoleySelectList.insertAfter 456
        |> HoleySelectList.toList
    --> [ 123, 456, 789 ]

-}
insertAfter : a -> HoleySelectList hasHole a -> HoleySelectList hasHole a
insertAfter v (HoleySelectList b c a) =
    HoleySelectList b c (v :: a)


{-| Insert something before the current location.

    HoleySelectList.empty
        |> HoleySelectList.insertBefore "hello"
        |> HoleySelectList.toList
    --> [ "hello" ]


    HoleySelectList.singleton 123
        |> HoleySelectList.insertBefore 456
        |> HoleySelectList.toList
    --> [ 456, 123 ]

-}
insertBefore : a -> HoleySelectList hasHole a -> HoleySelectList hasHole a
insertBefore v (HoleySelectList b c a) =
    HoleySelectList (v :: b) c a


{-| Flattens the `HoleySelectList` into a list.

    HoleySelectList.toList HoleySelectList.empty
    --> []


    HoleySelectList.selecting 123 [ 789 ]
        |> HoleySelectList.nextHole
        |> HoleySelectList.plug 456
        |> HoleySelectList.toList
    --> [ 123, 456, 789 ]

-}
toList : HoleySelectList hasHole a -> List a
toList holeySelectList =
    before holeySelectList ++ focusAndAfter holeySelectList


focusAndAfter : HoleySelectList hasHole a -> List a
focusAndAfter (HoleySelectList _ focus after_) =
    case focus of
        NothingTyped _ ->
            after_

        JustTyped v ->
            v :: after_


{-| Append a bunch of items after the `HoleySelectList`. This appends all the way at the end.

    HoleySelectList.selecting 123 [ 456 ]
        |> HoleySelectList.append [ 789, 0 ]
        |> HoleySelectList.toList
    --> [ 123, 456, 789, 0 ]

-}
append : List a -> HoleySelectList hasHole a -> HoleySelectList hasHole a
append xs (HoleySelectList b c a) =
    HoleySelectList b c (a ++ xs)


{-| Prepend a bunch of things to the `HoleySelectList`. All the way before anything else.

    HoleySelectList.selecting 1 [ 2, 3, 4 ]
        |> HoleySelectList.last
        |> HoleySelectList.prepend [ 5, 6, 7 ]
        |> HoleySelectList.toList
    --> [ 5, 6, 7, 1, 2, 3, 4 ]

-}
prepend : List a -> HoleySelectList hasHole a -> HoleySelectList hasHole a
prepend xs (HoleySelectList b c a) =
    HoleySelectList (b ++ List.reverse xs) c a


{-| Go to the first element in the `HoleySelectList`.

    HoleySelectList.selecting 1 [ 2, 3, 4 ]
        |> HoleySelectList.prepend [ 4, 3, 2 ]
        |> HoleySelectList.first
        |> HoleySelectList.current
    --> 4

-}
first : HoleySelectList hasHole a -> HoleySelectList hasHole a
first holeySelectList =
    case before holeySelectList of
        [] ->
            holeySelectList

        head :: afterHeadBeforeCurrent ->
            HoleySelectList
                []
                (just head)
                (afterHeadBeforeCurrent ++ focusAndAfter holeySelectList)


{-| Go to the last element in the `HoleySelectList`.

    HoleySelectList.selecting 1 [ 2, 3, 4 ]
        |> HoleySelectList.last
        |> HoleySelectList.current
    --> 4

-}
last : HoleySelectList hasHole a -> HoleySelectList hasHole a
last ((HoleySelectList before_ focus after_) as holeySelectList) =
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
            HoleySelectList
                (beforeLastUntilCurrent ++ focusToFirst)
                (just last_)
                []


{-| Go to the hole before the first element. Remember that holes surround
everything! They are everywhere.

    HoleySelectList.selecting 1 [ 3, 4 ]
        -- now we're after 1
        |> HoleySelectList.nextHole
        -- plug that hole
        |> HoleySelectList.plug 2
        -- back to _before_ the first element
        |> HoleySelectList.beforeFirst
        -- put something in that hole
        |> HoleySelectList.plug 0
        -- and check the result
        |> HoleySelectList.toList
    --> [ 0, 1, 2, 3, 4 ]

-}
beforeFirst : HoleySelectList hasHole a -> HoleySelectList MaybeHole a
beforeFirst holeySelectList =
    HoleySelectList [] nothing (toList holeySelectList)


{-| Go to the hole after the end of the `HoleySelectList`. Into the nothingness.
-}
afterLast : HoleySelectList hasHole a -> HoleySelectList MaybeHole a
afterLast (HoleySelectList before_ focus after_) =
    let
        focusToFirst =
            case focus of
                NothingTyped _ ->
                    before_

                JustTyped v ->
                    v :: before_
    in
    HoleySelectList (List.reverse after_ ++ focusToFirst) nothing []


{-| Find the first element in the `HoleySelectList` the matches a predicate, returning a
`HoleySelectList` pointing at that thing if it was found. When provided with a `HoleySelectList`
pointing at a thing, that thing is also checked.

This start from the current location, and searches towards the end.

-}
findForward : (a -> Bool) -> HoleySelectList hasHole a -> Maybe (HoleySelectList Full a)
findForward predicate z =
    findForwardHelp predicate z


findForwardHelp : (a -> Bool) -> HoleySelectList hasHole a -> Maybe (HoleySelectList Full a)
findForwardHelp predicate ((HoleySelectList before_ focus after_) as holeySelectList) =
    let
        goForward () =
            next holeySelectList
                |> Maybe.andThen (findForwardHelp predicate)
    in
    case focus of
        JustTyped cur ->
            if predicate cur then
                Just (HoleySelectList before_ (just cur) after_)

            else
                goForward ()

        NothingTyped _ ->
            goForward ()


{-| Find the first element in the `HoleySelectList` matching a predicate, moving backwards
from the current position.
-}
findBackward : (a -> Bool) -> HoleySelectList hasHole a -> Maybe (HoleySelectList full a)
findBackward predicate z =
    findBackwardHelp predicate z


findBackwardHelp : (a -> Bool) -> HoleySelectList hasHole a -> Maybe (HoleySelectList full a)
findBackwardHelp predicate ((HoleySelectList before_ focus after_) as holeySelectList) =
    let
        goBack () =
            previous holeySelectList
                |> Maybe.andThen (findBackwardHelp predicate)
    in
    case focus of
        JustTyped cur ->
            if predicate cur then
                Just (HoleySelectList before_ (just cur) after_)

            else
                goBack ()

        NothingTyped _ ->
            goBack ()


markFlex : HoleySelectList Full a -> HoleySelectList hasHole a
markFlex (HoleySelectList before_ focus after_) =
    let
        restoredFocus =
            just (MaybeTyped.value focus)
    in
    HoleySelectList before_ restoredFocus after_


{-| Execute a function on every item in the `HoleySelectList`.

    HoleySelectList.selecting "first" [ "second", "third" ]
        |> HoleySelectList.map String.toUpper
        |> HoleySelectList.toList
    --> [ "FIRST", "SECOND", "THIRD" ]

-}
map : (a -> b) -> HoleySelectList t a -> HoleySelectList t b
map f (HoleySelectList b c a) =
    HoleySelectList (List.map f b) (MaybeTyped.map f c) (List.map f a)


{-| Execute a function on the current item in the `HoleySelectList`, when pointing at an
item.

    HoleySelectList.selecting "first" [ "second", "third" ]
        |> HoleySelectList.mapCurrent String.toUpper
        |> HoleySelectList.toList
    --> [ "FIRST", "second", "third" ]

-}
mapCurrent : (a -> a) -> HoleySelectList t a -> HoleySelectList t a
mapCurrent f (HoleySelectList b c a) =
    HoleySelectList b (MaybeTyped.map f c) a


{-| Execute a function on all the things that came before the current location.

    HoleySelectList.selecting "first" [ "second" ]
        |> HoleySelectList.nextHole
        |> HoleySelectList.mapBefore String.toUpper
        |> HoleySelectList.toList
    --> [ "FIRST", "second" ]

-}
mapBefore : (a -> a) -> HoleySelectList t a -> HoleySelectList t a
mapBefore f (HoleySelectList b c a) =
    HoleySelectList (List.map f b) c a


{-| Execute a function on all the things that come after the current location.
-}
mapAfter : (a -> a) -> HoleySelectList t a -> HoleySelectList t a
mapAfter f (HoleySelectList b c a) =
    HoleySelectList b c (List.map f a)


{-| Execute a triplet of functions on the different parts of a `HoleySelectList` - what
came before, what comes after, and the current thing if there is one.

    HoleySelectList.selecting "first" [ "second" ]
        |> HoleySelectList.nextHole
        |> HoleySelectList.plug "one-and-a-halfth"
        |> HoleySelectList.mapParts
            { before = (++) "before: "
            , current = (++) "current: "
            , after = (++) "after: "
            }
        |> HoleySelectList.toList
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
    -> HoleySelectList t a
    -> HoleySelectList t b
mapParts conf (HoleySelectList before_ focus after_) =
    HoleySelectList
        (List.map conf.before before_)
        (MaybeTyped.map conf.current focus)
        (List.map conf.after after_)
