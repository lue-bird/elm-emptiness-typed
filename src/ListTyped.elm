module ListTyped exposing
    ( ListTyped, MaybeEmpty, NotEmpty
    , empty, only, fromCons, fromTuple, fromList
    , head, length
    , cons, append, appendNonEmpty
    , when, whenJust
    , map, fold, foldWith, toList, toTuple
    )

{-|


## types

@docs ListTyped, MaybeEmpty, NotEmpty


## create

@docs empty, only, fromCons, fromTuple, fromList


## scan

@docs head, length


## modify

@docs cons, append, appendNonEmpty


### filter

@docs when, whenJust


## transform

@docs map, fold, foldWith, toList, toTuple

-}

import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List
import MaybeTyped exposing (MaybeTyped(..), just, nothing)


{-| Describes an empty or non-empty list.

We can require a [`NotEmpty`](#NotEmpty) for example:

    head : ListTyped NotEmpty a -> a

**This is better than any `Nonempty`.**

-}
type alias ListTyped emptyOrNot a =
    MaybeTyped emptyOrNot ( a, List a )


{-| `ListTyped NotEmpty a` can be used to require a non-empty list as an argument:

    head : ListTyped NotEmpty a -> a

-}
type alias NotEmpty =
    MaybeTyped.Just { notEmpty : () }


{-| `ListTyped MaybeEmpty a` marks lists that could be empty:

    fromList : List a -> ListTyped MaybeEmpty a
    fromList list =
        case list of
            [] ->
                ListTyped.empty

            head :: tail ->
                ListTyped.fromCons head tail

-}
type alias MaybeEmpty =
    MaybeTyped.MaybeNothing { maybeEmpty : () }


{-| A `ListTyped` without elements.

Equivalent to `MaybeTyped.nothing`.

-}
empty : ListTyped MaybeEmpty a_
empty =
    nothing


{-| A `ListTyped` with just 1 element.

    ListTyped.only ":)"
    --> ListTyped.empty |> ListTyped.cons ":)"

-}
only : a -> ListTyped notEmpty_ a
only onlyElement =
    fromCons onlyElement []


{-| Convert a non-empty list tuple `( a, List a )` to a `ListTyped notEmpty_ a`.

Equivalent to `MaybeTyped.just`.

-}
fromTuple : ( a, List a ) -> ListTyped notEmpty_ a
fromTuple nonEmptyListAlias =
    just nonEmptyListAlias


{-| Build a `ListTyped notEmpty_ a` from its head and tail.
-}
fromCons : a -> List a -> ListTyped notEmpty_ a
fromCons head_ tail_ =
    fromTuple ( head_, tail_ )


{-| Convert a `List a` to a `ListTyped MaybeEmpty a`.

    [] |> ListTyped.fromList
    --> ListTyped.empty

    [ "hello", "emptiness" ] |> ListTyped.fromList
    --> ListTyped.fromCons "hello" [ "emptiness" ]
    --: ListTyped MaybeEmpty String

When constructing from known elements, always prefer

    ListTyped.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> ListTyped MaybeEmpty a
fromList list_ =
    case list_ of
        [] ->
            empty

        head_ :: tail_ ->
            fromCons head_ tail_



--


{-| The first value in the `ListTyped`.

    ListTyped.only 3
        |> ListTyped.cons 2
        |> ListTyped.head
    --> 3

-}
head : ListTyped NotEmpty a -> a
head =
    toTuple >> Tuple.first


{-| The element count in the `ListTyped`.

    ListTyped.only 3
        |> ListTyped.cons 2
        |> ListTyped.length
    --> 2

-}
length : ListTyped emptyOrNot_ a_ -> Int
length =
    \list ->
        case list of
            JustTyped ( _, tail_ ) ->
                1 + List.length tail_

            NothingTyped _ ->
                0



--


{-| Add an element to the front of a list.

    ListTyped.fromCons 2 [ 3 ] |> ListTyped.cons 1
    --> ListTyped.fromCons 1 [ 2, 3 ]

    ListTyped.empty |>  ListTyped.cons 1
    --> ListTyped.only 1

-}
cons : a -> ListTyped emptyOrNot_ a -> ListTyped NotEmpty a
cons toPutBeforeAllOtherElements =
    \list ->
        case list of
            NothingTyped _ ->
                only toPutBeforeAllOtherElements

            JustTyped ( head_, tail_ ) ->
                fromCons toPutBeforeAllOtherElements (head_ :: tail_)


{-| Glue the elements of a `ListTyped NotEmpty ...` to the end of a `ListTyped`.

    ListTyped.empty
        |> ListTyped.appendNonEmpty
            (ListTyped.fromCons 1 [ 2 ])
        |> ListTyped.append
            (ListTyped.fromCons 3 [ 4, 5 ])
    --> ListTyped.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `ListTyped` is already known as `NotEmpty`
or if both are `MaybeEmpty`.

-}
appendNonEmpty :
    ListTyped NotEmpty a
    -> ListTyped emptyOrNot_ a
    -> ListTyped NotEmpty a
appendNonEmpty nonEmptyToAppend =
    \list ->
        case list of
            NothingTyped _ ->
                nonEmptyToAppend

            JustTyped ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a `ListTyped` to the end of a `ListTyped`.

    ListTyped.fromCons 1 [ 2 ]
        |> ListTyped.append
            (ListTyped.fromCons 3 [ 4 ])
    --> ListTyped.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNonEmpty`](#appendNonEmpty) if the piped `ListTyped` is already known as `NotEmpty`
or if both are `MaybeEmpty`.

-}
append :
    ListTyped MaybeEmpty a
    -> ListTyped emptyOrNot a
    -> ListTyped emptyOrNot a
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( NothingTyped is, NothingTyped _ ) ->
                NothingTyped is

            ( NothingTyped _, JustTyped nonEmptyToAppend ) ->
                fromTuple nonEmptyToAppend

            ( JustTyped ( head_, tail_ ), _ ) ->
                fromCons head_ (tail_ ++ toList toAppend)


{-| Keep elements that satisfy the test.

    ListTyped.fromCons 1 [ 2, 5, -3, 10 ]
        |> ListTyped.when (\x -> x < 5)
    --> ListTyped.fromCons 1 [ 2, -3 ]
    --: ListTyped MaybeEmpty number

-}
when : (a -> Bool) -> ListTyped emptyOrNot_ a -> ListTyped MaybeEmpty a
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `Just` values and drop all `Nothing`s.

    ListTyped.fromCons (Just 1) [ Nothing, Just 3 ]
        |> ListTyped.whenJust
    --> ListTyped.fromCons 1 [ 3 ]
    --: ListTyped MaybeEmpty number

    ListTyped.fromCons Nothing [ Nothing ]
        |> ListTyped.whenJust
    --> ListTyped.empty

-}
whenJust : ListTyped emptyOrNot_ (Maybe value) -> ListTyped MaybeEmpty value
whenJust maybes =
    maybes |> toList |> List.filterMap identity |> fromList



--


{-| Apply a function to every element.

    ListTyped.fromCons 1 [ 4, 9 ]
        |> ListTyped.map negate
    --> ListTyped.fromCons -1 [ -4, -9 ]

-}
map : (a -> b) -> ListTyped emptyOrNot a -> ListTyped emptyOrNot b
map change =
    MaybeTyped.map (Tuple.mapBoth change (List.map change))


{-| Reduce a List in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    ListTyped.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListTyped.fold LastToFirst String.cons ""
    --> "live"

    ListTyped.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListTyped.fold FirstToLast String.cons ""
    --> "evil"

-}
fold : LinearDirection -> (a -> b -> b) -> b -> ListTyped emptyOrNot_ a -> b
fold direction reduce initial =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the `ListTyped`.

    import LinearDirection exposing (LinearDirection(..))

    ListTyped.fromCons 234 [ 345, 543 ]
        |> ListTyped.foldWith FirstToLast max
    --> 543

-}
foldWith : LinearDirection -> (a -> a -> a) -> ListTyped NotEmpty a -> a
foldWith direction reduce =
    toTuple
        >> (\( head_, tail_ ) ->
                List.fold direction reduce head_ tail_
           )


{-| Convert the `ListTyped` to a `List`.

    ListTyped.fromCons 1 [ 7 ]
        |> ListTyped.toList
    --> [ 1, 7 ]

-}
toList : ListTyped emptyOrNot_ a -> List a
toList =
    \list ->
        case list of
            JustTyped ( head_, tail_ ) ->
                head_ :: tail_

            NothingTyped _ ->
                []


{-| Convert a `ListTyped notEmpty a` to a non-empty list tuple `( a, List a )`.

Equivalent to `MaybeTyped.value`.

-}
toTuple : ListTyped NotEmpty a -> ( a, List a )
toTuple typedList =
    typedList |> MaybeTyped.value
