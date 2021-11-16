module ListTyped exposing
    ( ListTyped, Emptiable, NotEmpty
    , ListWithHeadType
    , empty, only, fromCons, fromTuple, fromList
    , head, tail, length
    , cons, append, appendNonEmpty
    , when, whenJust
    , map, mapHead, mapTail, fold, foldWith, toList, toTuple
    )

{-|


## types

@docs ListTyped, Emptiable, NotEmpty
@docs ListWithHeadType


## create

@docs empty, only, fromCons, fromTuple, fromList


## scan

@docs head, tail, length


## modify

@docs cons, append, appendNonEmpty


### filter

@docs when, whenJust


## transform

@docs map, mapHead, mapTail, fold, foldWith, toList, toTuple

-}

import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List
import MaybeTyped exposing (MaybeTyped(..), just, nothing)


{-| Describes an empty or non-empty list. **This is better than any `Nonempty`.**

We can require a [`NotEmpty`](#NotEmpty) for example:

    toNonempty : ListTyped NotEmpty a -> Nonempty a

This is equivalent to a [`MaybeTyped`](MaybeTyped) of a non-empty list tuple:

    import MaybeTyped exposing (MaybeTyped(..))

    ListTyped.empty
    --> MaybeTyped.nothing

    [ ... ]
        |> ListTyped.fromList
        |> MaybeTyped.map ListTyped.head
    --: MaybeTyped JustOrNothing head_

    toList : ListTyped emptyOrNot_ a -> List a
    toList list =
        case list of
            JustTyped ( head_, tail_ ) ->
                head_ :: tail_

            NothingTyped _ ->
                []

-}
type alias ListTyped emptyOrNot a =
    ListWithHeadType a emptyOrNot a


{-| Describes an empty or non-empty list where the head type can be different from the tail element type.

Use [`ListTyped`](#ListTyped) if you have matching head and tail element types.

`ListWithHeadType` is the result of:

  - [`empty`](#empty)
  - [`only`](#only)
  - [`fromCons`](#fromCons)
  - [`fromTuple`](#fromTuple)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)

This is equivalent to a [`MaybeTyped`](MaybeTyped) of a `( head, tail )` tuple:

    import MaybeTyped exposing (MaybeTyped(..))

    ListTyped.empty
    --> MaybeTyped.nothing

    MaybeTyped.map ListTyped.head
    --: ListWithHeadType head emptyOrNot_ tailElement_
    --: -> MaybeTyped JustOrNothing head

    tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
    tail listNotEmpty =
        case listNotEmpty of
            JustTyped ( _, tailList ) ->
                tailList

            NothingTyped _ ->
                []

-}
type alias ListWithHeadType head emptyOrNot tailElement =
    MaybeTyped emptyOrNot ( head, List tailElement )


{-| `NotEmpty` can be used to require a non-empty list as an argument:

    head : ListWithHeadType head NotEmpty tailElement_ -> head

-}
type alias NotEmpty =
    MaybeTyped.Just { notEmpty : () }


{-| `Emptiable` marks lists that could be empty:

    fromList : List a -> ListTyped Emptiable a
    fromList list =
        case list of
            [] ->
                ListTyped.empty

            head :: tail ->
                ListTyped.fromCons head tail

-}
type alias Emptiable =
    MaybeTyped.JustOrNothing { maybeEmpty : () }


{-| A `ListTyped` without elements.

Equivalent to `MaybeTyped.nothing`.

-}
empty : ListWithHeadType head_ Emptiable tailElement_
empty =
    nothing


{-| A `ListTyped` with just 1 element.

    ListTyped.only ":)"
    --> ListTyped.empty |> ListTyped.cons ":)"

-}
only : head -> ListWithHeadType head notEmpty_ tailElement_
only onlyElement =
    fromCons onlyElement []


{-| Convert a non-empty list tuple `( a, List b )` to a `ListWithHeadType a notEmpty_ b`.

Equivalent to `MaybeTyped.just`.

-}
fromTuple : ( head, List tailElement ) -> ListWithHeadType head notEmpty_ tailElement
fromTuple headAndTailTuple =
    just headAndTailTuple


{-| Build a `notEmpty_` from its head and tail.
-}
fromCons : head -> List tailElement -> ListWithHeadType head notEmpty_ tailElement
fromCons head_ tail_ =
    fromTuple ( head_, tail_ )


{-| Convert a `List a` to a `ListTyped Emptiable a`.

    [] |> ListTyped.fromList
    --> ListTyped.empty

    [ "hello", "emptiness" ] |> ListTyped.fromList
    --> ListTyped.fromCons "hello" [ "emptiness" ]
    --: ListTyped Emptiable String

When constructing from known elements, always prefer

    ListTyped.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> ListTyped Emptiable a
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
head : ListWithHeadType head NotEmpty tailElement_ -> head
head notEmptyList =
    notEmptyList |> toTuple |> Tuple.first


{-| Everything after the first value in the `ListTyped`.

    ListTyped.only 3
        |> ListTyped.cons 2
        |> ListTyped.append (ListTyped.fromCons 1 [ 0 ])
        |> ListTyped.tail
    --> [ 2, 1, 0 ]

-}
tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
tail notEmptyList =
    notEmptyList |> toTuple |> Tuple.second


{-| How many element there are.

    ListTyped.only 3
        |> ListTyped.cons 2
        |> ListTyped.length
    --> 2

-}
length : ListWithHeadType head_ emptyOrNot_ tailElement_ -> Int
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

    ListTyped.empty |> ListTyped.cons 1
    --> ListTyped.only 1

-}
cons : consed -> ListTyped emptyOrNot_ a -> ListWithHeadType consed NotEmpty a
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a `ListTyped NotEmpty ...` to the end of a `ListTyped`.

    ListTyped.empty
        |> ListTyped.appendNonEmpty
            (ListTyped.fromCons 1 [ 2 ])
        |> ListTyped.append
            (ListTyped.fromCons 3 [ 4, 5 ])
    --> ListTyped.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `ListTyped` is already known as `NotEmpty`
or if both are `Emptiable`.

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
or if both are `Emptiable`.

-}
append :
    ListTyped Emptiable a
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
    --: ListTyped Emptiable number_

-}
when : (a -> Bool) -> ListTyped emptyOrNot_ a -> ListTyped Emptiable a
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `Just` values and drop all `Nothing`s.

    ListTyped.fromCons (Just 1) [ Nothing, Just 3 ]
        |> ListTyped.whenJust
    --> ListTyped.fromCons 1 [ 3 ]
    --: ListTyped Emptiable number

    ListTyped.fromCons Nothing [ Nothing ]
        |> ListTyped.whenJust
    --> ListTyped.empty

-}
whenJust : ListTyped emptyOrNot_ (Maybe value) -> ListTyped Emptiable value
whenJust maybes =
    maybes |> toList |> List.filterMap identity |> fromList



--


{-| Apply a function to every element.

    ListTyped.fromCons 1 [ 4, 9 ]
        |> ListTyped.map negate
    --> ListTyped.fromCons -1 [ -4, -9 ]

-}
map : (a -> b) -> ListTyped emptyOrNot a -> ListTyped emptyOrNot b
map changeElement =
    MaybeTyped.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Apply a function to every element of its tail.

    ListTyped.fromCons 1 [ 4, 9 ]
        |> ListTyped.mapTail negate
    --> ListTyped.fromCons 1 [ -4, -9 ]

-}
mapTail :
    (tailElement -> mappedTailElement)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType head emptyOrNot mappedTailElement
mapTail changeTailElement =
    MaybeTyped.map
        (Tuple.mapBoth identity (List.map changeTailElement))


{-| Apply a function to the head only.

    ListTyped.fromCons 1 [ 4, 9 ]
        |> ListTyped.mapHead negate
    --> ListTyped.fromCons -1 [ 4, 9 ]

-}
mapHead :
    (head -> mappedHead)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType mappedHead emptyOrNot tailElement
mapHead changeHead =
    MaybeTyped.map (Tuple.mapFirst changeHead)


{-| Reduce a List in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    ListTyped.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListTyped.fold LastToFirst String.cons ""
    --> "live"

    ListTyped.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListTyped.fold FirstToLast String.cons ""
    --> "evil"

-}
fold :
    LinearDirection
    -> (a -> acc -> acc)
    -> acc
    -> ListTyped emptyOrNot_ a
    -> acc
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
foldWith :
    LinearDirection
    -> (tailElement -> acc -> acc)
    -> ListWithHeadType acc NotEmpty tailElement
    -> acc
foldWith direction reduce listNotEmpty =
    let
        ( head_, tail_ ) =
            toTuple listNotEmpty
    in
    List.fold direction reduce head_ tail_


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


{-| Convert a `NotEmpty` to a non-empty list tuple `( a, List a )`.

Equivalent to `MaybeTyped.value`.

-}
toTuple : ListWithHeadType head NotEmpty tailElement -> ( head, List tailElement )
toTuple listNotEmpty =
    listNotEmpty |> MaybeTyped.value
