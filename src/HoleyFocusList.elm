module HoleyFocusList exposing
    ( HoleyFocusList, Item, HoleOrItem
    , empty, only, currentAndAfter, beforeAndCurrent
    , current, before, after
    , next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward
    , mapCurrent, mapBefore, mapAfter, plug, remove, append, prepend, insertAfter, insertBefore
    , map, mapParts, joinParts, toList
    , branchableType
    )

{-| Like a regular old list-zipper, except it can also focus on a hole
_between_ items.

This means you can represent an empty list, or point between two items and plug
that hole with a value.


## types

@docs HoleyFocusList, Item, HoleOrItem


## create

@docs empty, only, currentAndAfter, beforeAndCurrent


## scan

@docs current, before, after


## navigate

@docs next, previous, nextHole, previousHole, first, last, beforeFirst, afterLast, findForward, findBackward


## modify

@docs mapCurrent, mapBefore, mapAfter, plug, remove, append, prepend, insertAfter, insertBefore


## transform

@docs map, mapParts, joinParts, toList


## type-level

@docs branchableType

-}

import Lis exposing (Lis)
import Mayb exposing (CanBeNothing(..), Mayb(..), just, nothing)


{-| Represents a special kind of list with items of type `a`.

If the type `focus` is `Item`, an item is focussed.
If not, you could be looking at a hole between items.

-}
type HoleyFocusList focus a
    = HoleyFocusList (List a) (Mayb focus a) (List a)


{-| A `HoleyFocusList Item a` is pointing at an element of type `a`.
-}
type alias Item =
    Mayb.Just { item : () }


{-| A `HoleyFocusList HoleOrItem a` could be pointing at a hole between `a`s.

... Heh.

-}
type alias HoleOrItem =
    Mayb.Nothingable { holeOrItem : () }


{-| The current focussed item in the `HoleyFocusList`.

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
    focus |> Mayb.value


{-| An empty `HoleyFocusList` focussed on a hole with nothing before it
and after it. It's the loneliest of all `HoleyFocusList`s.

    HoleyFocusList.empty
        |> HoleyFocusList.joinParts
    --> Lis.empty

-}
empty : HoleyFocusList HoleOrItem a_
empty =
    HoleyFocusList [] nothing []


{-| A `HoleyFocusList` with a single focussed item in it, nothing before and after it.

    HoleyFocusList.only "wat"
        |> HoleyFocusList.current
    --> "wat"

    HoleyFocusList.only "wat"
        |> HoleyFocusList.joinParts
    --> Lis.only "wat"

-}
only : a -> HoleyFocusList item_ a
only current_ =
    HoleyFocusList [] (just current_) []


{-| Construct a `HoleyFocusList` from a current item and items that come after it.

    HoleyFocusList.currentAndAfter "foo" []
    --> HoleyFocusList.only "foo"


    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 0 [ 1, 2, 3 ]

-}
currentAndAfter : a -> List a -> HoleyFocusList item_ a
currentAndAfter current_ after_ =
    HoleyFocusList [] (just current_) after_


{-| Construct a `HoleyFocusList` from a current item and items that come after it.

    HoleyFocusList.beforeAndCurrent [] "foo"
    --> HoleyFocusList.only "foo"


    HoleyFocusList.beforeAndCurrent [ -2, -1 ] 0
        |> HoleyFocusList.joinParts
    --> Lis.fromCons -2 [ -1, 0 ]

-}
beforeAndCurrent : List a -> a -> HoleyFocusList item_ a
beforeAndCurrent before_ current_ =
    HoleyFocusList (List.reverse before_) (just current_) []


{-| Everything that's before the location of the focus in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.andThen HoleyFocusList.next
        |> Maybe.map HoleyFocusList.before
    --> [ 0, 1 ]

-}
before : HoleyFocusList focus_ a -> List a
before (HoleyFocusList before_ _ _) =
    List.reverse before_


{-| Conversely, list the things that come after the current location.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.after
    --> Just [ 2, 3 ]

-}
after : HoleyFocusList focus_ a -> List a
after (HoleyFocusList _ _ after_) =
    after_


{-| Move the `HoleyFocusList` to the next item, if there is one.

    HoleyFocusList.currentAndAfter 0 [ 1, 2, 3 ]
        |> HoleyFocusList.next
        |> Maybe.map HoleyFocusList.current
    --> Just 1

This also works from within holes:

    HoleyFocusList.empty
        |> HoleyFocusList.insertAfter "foo"
        |> HoleyFocusList.next
    --> Just (HoleyFocusList.only "foo")

If there is no `next` thing, the result is `Nothing`.

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

        next_ :: afterNext ->
            let
                newBefore =
                    case focus of
                        Nothin _ ->
                            before_

                        Jus oldCurrent ->
                            oldCurrent :: before_
            in
            HoleyFocusList newBefore (just next_) afterNext
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
previous holeyFocusList =
    let
        (HoleyFocusList before_ _ _) =
            holeyFocusList
    in
    case before_ of
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

    HoleyFocusList.currentAndAfter "hello" [ "world" ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug "holey"
        |> HoleyFocusList.joinParts
    --> Lis.fromCons "hello" [ "holey", "world" ]

-}
nextHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
nextHole holeyFocusList =
    let
        (HoleyFocusList before_ _ after_) =
            holeyFocusList
    in
    HoleyFocusList (current holeyFocusList :: before_) nothing after_


{-| Move the `HoleyFocusList` to the hole right before the current item. Feel free to plug
that hole right up!

    HoleyFocusList.only "world"
        |> HoleyFocusList.previousHole
        |> HoleyFocusList.plug "hello"
        |> HoleyFocusList.joinParts
    --> Lis.fromCons "hello" [ "world" ]

-}
previousHole : HoleyFocusList Item a -> HoleyFocusList HoleOrItem a
previousHole holeyFocusList =
    let
        (HoleyFocusList before_ _ after_) =
            holeyFocusList
    in
    HoleyFocusList before_ nothing (current holeyFocusList :: after_)


{-| Fill in or replace the focussed thing in the `HoleyFocusList`.

    HoleyFocusList.plug "plug" HoleyFocusList.empty
    --> HoleyFocusList.only "plug"

-}
plug : a -> HoleyFocusList HoleOrItem a -> HoleyFocusList item_ a
plug newCurrent =
    \(HoleyFocusList before_ _ after_) ->
        HoleyFocusList before_ (just newCurrent) after_


{-| Punch a hole into the `HoleyFocusList` by removing the focussed thing.

    HoleyFocusList.currentAndAfter "hello" [ "holey", "world" ]
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

    HoleyFocusList.currentAndAfter 123 [ 789 ]
        |> HoleyFocusList.insertAfter 456
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 123 [ 456, 789 ]

-}
insertAfter : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertAfter toInsertAfterFocus =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (toInsertAfterFocus :: after_)


{-| Insert an item before the focussed location.

    HoleyFocusList.only 123
        |> HoleyFocusList.insertBefore 456
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 456 [ 123 ]

-}
insertBefore : a -> HoleyFocusList focus a -> HoleyFocusList focus a
insertBefore v (HoleyFocusList b c a) =
    HoleyFocusList (v :: b) c a


focusAndAfter : HoleyFocusList focus_ a -> List a
focusAndAfter (HoleyFocusList _ focus after_) =
    case focus of
        Nothin _ ->
            after_

        Jus current_ ->
            current_ :: after_


{-| Put items to the end of the `HoleyFocusList`. After anything else.

    HoleyFocusList.currentAndAfter 123 [ 456 ]
        |> HoleyFocusList.append [ 789, 0 ]
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 123 [ 456, 789, 0 ]

-}
append : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
append itemsToAppend =
    \(HoleyFocusList before_ focus after_) ->
        HoleyFocusList before_ focus (after_ ++ itemsToAppend)


{-| Put items to the beginning of the `HoleyFocusList`. Before anything else.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.prepend [ 5, 6, 7 ]
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 5 [ 6, 7, 1, 2, 3, 4 ]

-}
prepend : List a -> HoleyFocusList focus a -> HoleyFocusList focus a
prepend xs (HoleyFocusList b c a) =
    HoleyFocusList (b ++ List.reverse xs) c a


{-| Focus the first item in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
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
            currentAndAfter head
                (afterHeadBeforeCurrent ++ focusAndAfter holeyFocusList)


{-| Focus the last item in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter 1 [ 2, 3, 4 ]
        |> HoleyFocusList.last
        |> HoleyFocusList.current
    --> 4

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
                            Jus current_ ->
                                current_ :: before_

                            Nothin _ ->
                                before_
                in
                HoleyFocusList
                    (beforeLastUntilCurrent ++ focusToFirst)
                    (just last_)
                    []


{-| Focus the hole before the first item. Remember that holes surround
everything! They are everywhere.

    HoleyFocusList.currentAndAfter 1 [ 3, 4 ]
        |> HoleyFocusList.nextHole    -- we're after 1
        |> HoleyFocusList.plug 2      -- plug that hole
        |> HoleyFocusList.beforeFirst -- back to _before_ the first item
        |> HoleyFocusList.plug 0      -- put something in that hole
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 0 [ 1, 2, 3, 4 ]

-}
beforeFirst : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
beforeFirst holeyFocusList =
    HoleyFocusList [] nothing (holeyFocusList |> toList)


{-| Focus the hole after the end of the `HoleyFocusList`. Into the nothingness.

    HoleyFocusList.currentAndAfter 1 [ 2, 3 ]
        |> HoleyFocusList.afterLast -- to _after_ the last item
        |> HoleyFocusList.plug 4    -- put something in that hole
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 1 [ 2, 3, 4 ]

-}
afterLast : HoleyFocusList focus_ a -> HoleyFocusList HoleOrItem a
afterLast holeyFocusList =
    HoleyFocusList (toReverseList holeyFocusList) nothing []


toReverseList : HoleyFocusList focus_ a -> List a
toReverseList =
    \(HoleyFocusList before_ focus after_) ->
        let
            focusToFirst =
                case focus of
                    Nothin _ ->
                        before_

                    Jus current_ ->
                        current_ :: before_
        in
        List.reverse after_ ++ focusToFirst


{-| Find the first item in the `HoleyFocusList` the matches a predicate, returning a
`HoleyFocusList` pointing at that thing if it was found. When provided with a `HoleyFocusList`
pointing at a thing, that thing is also checked.

This start from the current focussed location and searches towards the end.

-}
findForward : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForward predicate z =
    findForwardHelp predicate z


findForwardHelp : (a -> Bool) -> HoleyFocusList focus_ a -> Maybe (HoleyFocusList item_ a)
findForwardHelp predicate ((HoleyFocusList before_ focus after_) as holeyFocusList) =
    let
        goForward () =
            next holeyFocusList
                |> Maybe.andThen (findForwardHelp predicate)
    in
    case focus of
        Jus cur ->
            if predicate cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goForward ()

        Nothin _ ->
            goForward ()


{-| Find the first item in the `HoleyFocusList` matching a predicate, moving backwards
from the current position.
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
        Jus cur ->
            if shouldStop cur then
                Just (HoleyFocusList before_ (just cur) after_)

            else
                goBack ()

        Nothin _ ->
            goBack ()


{-| Execute a function on every item in the `HoleyFocusList`.

    HoleyFocusList.currentAndAfter "first" [ "second", "third" ]
        |> HoleyFocusList.map String.toUpper
        |> HoleyFocusList.joinParts
    --> Lis.fromCons "FIRST" [ "SECOND", "THIRD" ]

-}
map : (a -> b) -> HoleyFocusList focus a -> HoleyFocusList focus b
map f (HoleyFocusList b c a) =
    HoleyFocusList (List.map f b) (Mayb.map f c) (List.map f a)


{-| Execute a function on the current item in the `HoleyFocusList`, when pointing at an
item.

    HoleyFocusList.currentAndAfter "first" [ "second", "third" ]
        |> HoleyFocusList.mapCurrent String.toUpper
        |> HoleyFocusList.joinParts
    --> Lis.fromCons "FIRST" [ "second", "third" ]

-}
mapCurrent : (a -> a) -> HoleyFocusList focus a -> HoleyFocusList focus a
mapCurrent f (HoleyFocusList b c a) =
    HoleyFocusList b (Mayb.map f c) a


{-| Execute a function on all the things that came before the current location.

    HoleyFocusList.beforeAndCurrent [ "first" ] "second"
        |> HoleyFocusList.mapBefore String.toUpper
        |> HoleyFocusList.joinParts
    --> Lis.fromCons "FIRST" [ "second" ]

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
        |> HoleyFocusList.joinParts
    --> Lis.fromCons
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
mapParts conf (HoleyFocusList before_ focus after_) =
    HoleyFocusList
        (List.map conf.before before_)
        (Mayb.map conf.current focus)
        (List.map conf.after after_)


{-| Flattens the `HoleyFocusList` into a list:

    HoleyFocusList.joinParts HoleyFocusList.empty
    --> []

    HoleyFocusList.currentAndAfter 123 [ 789 ]
        |> HoleyFocusList.toList
    --> [ 123, 789 ]

Only use this if you need a list in the end.
Otherwise [`joinParts`](#joinParts) can preserve some information about the length.

-}
toList : HoleyFocusList focus_ a -> List a
toList =
    \holeyFocusList ->
        before holeyFocusList ++ focusAndAfter holeyFocusList


{-| Flattens the `HoleyFocusList` into a [`Lis`](Lis):

    HoleyFocusList.joinParts HoleyFocusList.empty
    --> Lis.empty

    HoleyFocusList.currentAndAfter 123 [ 789 ]
        |> HoleyFocusList.nextHole
        |> HoleyFocusList.plug 456
        |> HoleyFocusList.joinParts
    --> Lis.fromCons 123 [ 456, 789 ]

the type information gets carried over, so

    Item -> NotEmpty
    HoleOrItem -> EmptyOrNot

-}
joinParts :
    HoleyFocusList (CanBeNothing valueIfNothing focusTag_) a
    -> Lis (CanBeNothing valueIfNothing emptyOrNotTag_) a
joinParts =
    \holeyFocusList ->
        let
            (HoleyFocusList _ focus after_) =
                holeyFocusList
        in
        case ( before holeyFocusList, focus, after_ ) of
            ( head_ :: afterFirstUntilFocus, _, _ ) ->
                Lis.fromCons head_
                    (afterFirstUntilFocus ++ focusAndAfter holeyFocusList)

            ( [], Jus cur, _ ) ->
                Lis.fromCons cur after_

            ( [], Nothin _, head_ :: tail_ ) ->
                Lis.fromCons head_ tail_

            ( [], Nothin (CanBeNothing canBeNothing), [] ) ->
                Nothin (CanBeNothing canBeNothing)



--


{-| When using a `HoleyFocusList Item ...` argument,
its type can't be unified with non-`Item` lists.

Please read more at [`Mayb.branchableType`](Mayb#branchableType).

-}
branchableType : HoleyFocusList Item a -> HoleyFocusList item_ a
branchableType (HoleyFocusList before_ focus after_) =
    HoleyFocusList before_ (focus |> Mayb.branchableType) after_
