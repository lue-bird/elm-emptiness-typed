module Lis exposing
    ( Lis, Emptiable, NotEmpty
    , ListWithHeadType
    , empty, only, fromCons, fromTuple, fromList
    , head, tail, length
    , cons, append, appendNonEmpty
    , when, whenJust
    , map, mapHead, mapTail, fold, foldWith, toList, toTuple
    )

{-|


## types

@docs Lis, Emptiable, NotEmpty
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
import Mayb exposing (Mayb(..), just, nothing)


{-| Describes an empty or non-empty list, making it more convenient than any `Nonempty`.

We can require a [`NotEmpty`](#NotEmpty) for example:

    toNonempty : Lis NotEmpty a -> Nonempty a

This is equivalent to a [`Mayb`](Mayb) of a non-empty list tuple:

    import Mayb exposing (Mayb(..))

    Lis.empty
    --> Mayb.nothing

    [ ... ]
        |> Lis.fromList
        |> Mayb.map Lis.head
    --: Mayb Nothingable head_

    toList : Lis emptyOrNot_ a -> List a
    toList list =
        case list of
            JustTyped ( head_, tail_ ) ->
                head_ :: tail_

            NothingTyped _ ->
                []

-}
type alias Lis emptyOrNot a =
    ListWithHeadType a emptyOrNot a


{-| Describes an empty or non-empty list where the head type can be different from the tail element type.

Use [`Lis`](#Lis) if you have matching head and tail element types.

`ListWithHeadType` is the result of:

  - [`empty`](#empty)
  - [`only`](#only)
  - [`fromCons`](#fromCons)
  - [`fromTuple`](#fromTuple)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)

This is equivalent to a [`Mayb`](Mayb) of a `( head, tail )` tuple:

    import Mayb exposing (Mayb(..))

    Lis.empty
    --> Mayb.nothing

    Mayb.map Lis.head
    --: ListWithHeadType head emptyOrNot_ tailElement_
    --: -> Mayb Nothingable head

    tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
    tail listNotEmpty =
        case listNotEmpty of
            JustTyped ( _, tailList ) ->
                tailList

            NothingTyped _ ->
                []

-}
type alias ListWithHeadType head emptyOrNot tailElement =
    Mayb emptyOrNot ( head, List tailElement )


{-| `NotEmpty` can be used to require a non-empty list as an argument:

    head : ListWithHeadType head NotEmpty tailElement_ -> head

-}
type alias NotEmpty =
    Mayb.Just { notEmpty : () }


{-| `Emptiable` marks lists that could be empty:

    fromList : List a -> Lis Emptiable a
    fromList list =
        case list of
            [] ->
                Lis.empty

            head :: tail ->
                Lis.fromCons head tail

-}
type alias Emptiable =
    Mayb.Nothingable { maybeEmpty : () }


{-| A `Lis` without elements.

Equivalent to `Mayb.nothing`.

-}
empty : ListWithHeadType head_ Emptiable tailElement_
empty =
    nothing


{-| A `Lis` with just 1 element.

    Lis.only ":)"
    --> Lis.empty |> Lis.cons ":)"

-}
only : head -> ListWithHeadType head notEmpty_ tailElement_
only onlyElement =
    fromCons onlyElement []


{-| Convert a non-empty list tuple `( a, List b )` to a `ListWithHeadType a notEmpty_ b`.

Equivalent to `Mayb.just`.

-}
fromTuple : ( head, List tailElement ) -> ListWithHeadType head notEmpty_ tailElement
fromTuple headAndTailTuple =
    just headAndTailTuple


{-| Build a `notEmpty_` from its head and tail.
-}
fromCons : head -> List tailElement -> ListWithHeadType head notEmpty_ tailElement
fromCons head_ tail_ =
    fromTuple ( head_, tail_ )


{-| Convert a `List a` to a `Lis Emptiable a`.

    [] |> Lis.fromList
    --> Lis.empty

    [ "hello", "emptiness" ] |> Lis.fromList
    --> Lis.fromCons "hello" [ "emptiness" ]
    --: Lis Emptiable String

When constructing from known elements, always prefer

    Lis.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> Lis Emptiable a
fromList list_ =
    case list_ of
        [] ->
            empty

        head_ :: tail_ ->
            fromCons head_ tail_



--


{-| The first value in the `Lis`.

    Lis.only 3
        |> Lis.cons 2
        |> Lis.head
    --> 3

-}
head : ListWithHeadType head NotEmpty tailElement_ -> head
head notEmptyList =
    notEmptyList |> toTuple |> Tuple.first


{-| Everything after the first value in the `Lis`.

    Lis.only 3
        |> Lis.cons 2
        |> Lis.append (Lis.fromCons 1 [ 0 ])
        |> Lis.tail
    --> [ 2, 1, 0 ]

-}
tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
tail notEmptyList =
    notEmptyList |> toTuple |> Tuple.second


{-| How many element there are.

    Lis.only 3
        |> Lis.cons 2
        |> Lis.length
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

    Lis.fromCons 2 [ 3 ] |> Lis.cons 1
    --> Lis.fromCons 1 [ 2, 3 ]

    Lis.empty |> Lis.cons 1
    --> Lis.only 1

-}
cons : consed -> Lis emptyOrNot_ a -> ListWithHeadType consed NotEmpty a
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a `Lis NotEmpty ...` to the end of a `Lis`.

    Lis.empty
        |> Lis.appendNonEmpty
            (Lis.fromCons 1 [ 2 ])
        |> Lis.append
            (Lis.fromCons 3 [ 4, 5 ])
    --> Lis.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `Lis` is already known as `NotEmpty`
or if both are `Emptiable`.

-}
appendNonEmpty :
    Lis NotEmpty a
    -> Lis emptyOrNot_ a
    -> Lis NotEmpty a
appendNonEmpty nonEmptyToAppend =
    \list ->
        case list of
            NothingTyped _ ->
                nonEmptyToAppend

            JustTyped ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a `Lis` to the end of a `Lis`.

    Lis.fromCons 1 [ 2 ]
        |> Lis.append
            (Lis.fromCons 3 [ 4 ])
    --> Lis.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNonEmpty`](#appendNonEmpty) if the piped `Lis` is already known as `NotEmpty`
or if both are `Emptiable`.

-}
append :
    Lis Emptiable a
    -> Lis emptyOrNot a
    -> Lis emptyOrNot a
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

    Lis.fromCons 1 [ 2, 5, -3, 10 ]
        |> Lis.when (\x -> x < 5)
    --> Lis.fromCons 1 [ 2, -3 ]
    --: Lis Emptiable number_

-}
when : (a -> Bool) -> Lis emptyOrNot_ a -> Lis Emptiable a
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `Just` values and drop all `Nothing`s.

    Lis.fromCons (Just 1) [ Nothing, Just 3 ]
        |> Lis.whenJust
    --> Lis.fromCons 1 [ 3 ]
    --: Lis Emptiable number

    Lis.fromCons Nothing [ Nothing ]
        |> Lis.whenJust
    --> Lis.empty

-}
whenJust : Lis emptyOrNot_ (Maybe value) -> Lis Emptiable value
whenJust maybes =
    maybes |> toList |> List.filterMap identity |> fromList



--


{-| Apply a function to every element.

    Lis.fromCons 1 [ 4, 9 ]
        |> Lis.map negate
    --> Lis.fromCons -1 [ -4, -9 ]

-}
map : (a -> b) -> Lis emptyOrNot a -> Lis emptyOrNot b
map changeElement =
    Mayb.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Apply a function to every element of its tail.

    Lis.fromCons 1 [ 4, 9 ]
        |> Lis.mapTail negate
    --> Lis.fromCons 1 [ -4, -9 ]

-}
mapTail :
    (tailElement -> mappedTailElement)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType head emptyOrNot mappedTailElement
mapTail changeTailElement =
    Mayb.map
        (Tuple.mapBoth identity (List.map changeTailElement))


{-| Apply a function to the head only.

    Lis.fromCons 1 [ 4, 9 ]
        |> Lis.mapHead negate
    --> Lis.fromCons -1 [ 4, 9 ]

-}
mapHead :
    (head -> mappedHead)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType mappedHead emptyOrNot tailElement
mapHead changeHead =
    Mayb.map (Tuple.mapFirst changeHead)


{-| Reduce a List in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    Lis.fromCons 'l' [ 'i', 'v', 'e' ]
        |> Lis.fold LastToFirst String.cons ""
    --> "live"

    Lis.fromCons 'l' [ 'i', 'v', 'e' ]
        |> Lis.fold FirstToLast String.cons ""
    --> "evil"

-}
fold :
    LinearDirection
    -> (a -> acc -> acc)
    -> acc
    -> Lis emptyOrNot_ a
    -> acc
fold direction reduce initial =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the `Lis`.

    import LinearDirection exposing (LinearDirection(..))

    Lis.fromCons 234 [ 345, 543 ]
        |> Lis.foldWith FirstToLast max
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


{-| Convert the `Lis` to a `List`.

    Lis.fromCons 1 [ 7 ]
        |> Lis.toList
    --> [ 1, 7 ]

-}
toList : Lis emptyOrNot_ a -> List a
toList =
    \list ->
        case list of
            JustTyped ( head_, tail_ ) ->
                head_ :: tail_

            NothingTyped _ ->
                []


{-| Convert a `NotEmpty` to a non-empty list tuple `( a, List a )`.

Equivalent to `Mayb.value`.

-}
toTuple : ListWithHeadType head NotEmpty tailElement -> ( head, List tailElement )
toTuple listNotEmpty =
    listNotEmpty |> Mayb.value
