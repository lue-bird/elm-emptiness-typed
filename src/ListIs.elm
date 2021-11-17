module ListIs exposing
    ( ListIs, Emptiable, NotEmpty
    , ListWithHeadType
    , empty, only, fromCons, fromTuple, fromList
    , head, tail, length
    , cons
    , append, appendNonEmpty, concat
    , when, whenJust
    , map, mapHead, mapTail, fold, foldWith, toList, toTuple
    )

{-|


## types

@docs ListIs, Emptiable, NotEmpty
@docs ListWithHeadType


## create

@docs empty, only, fromCons, fromTuple, fromList


## scan

@docs head, tail, length


## modify

@docs cons


## glue

@docs append, appendNonEmpty, concat


### filter

@docs when, whenJust


## transform

@docs map, mapHead, mapTail, fold, foldWith, toList, toTuple

-}

import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List
import MaybeIs exposing (MaybeIs(..), just, nothing)


{-| Describes an empty or non-empty list, making it more convenient than any `Nonempty`.

We can require a [`NotEmpty`](#NotEmpty) for example:

    toNonempty : ListIs NotEmpty a -> Nonempty a

This is equivalent to a [`MaybeIs`](MaybeIs) of a non-empty list tuple:

    import MaybeIs exposing (MaybeIs(..))

    ListIs.empty
    --> MaybeIs.nothing

    [ ... ]
        |> ListIs.fromList
        |> MaybeIs.map ListIs.head
    --: MaybeIs Nothingable head_

    toList : ListIs emptyOrNot_ a -> List a
    toList list =
        case list of
            IsJust ( head_, tail_ ) ->
                head_ :: tail_

            IsNothing _ ->
                []

-}
type alias ListIs emptyOrNot a =
    ListWithHeadType a emptyOrNot a


{-| Describes an empty or non-empty list where the head type can be different from the tail element type.

Use [`ListIs`](#ListIs) if you have matching head and tail element types.

`ListWithHeadType` is the result of:

  - [`empty`](#empty)
  - [`only`](#only)
  - [`fromCons`](#fromCons)
  - [`fromTuple`](#fromTuple)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)

This is equivalent to a [`MaybeIs`](MaybeIs) of a `( head, tail )` tuple:

    import MaybeIs exposing (MaybeIs(..))

    ListIs.empty
    --> MaybeIs.nothing

    MaybeIs.map ListIs.head
    --: ListWithHeadType head emptyOrNot_ tailElement_
    --: -> MaybeIs Nothingable head

    tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
    tail listNotEmpty =
        case listNotEmpty of
            IsJust ( _, tailList ) ->
                tailList

            IsNothing _ ->
                []

-}
type alias ListWithHeadType head emptyOrNot tailElement =
    MaybeIs emptyOrNot ( head, List tailElement )


{-| `NotEmpty` can be used to require a non-empty list as an argument:

    head : ListWithHeadType head NotEmpty tailElement_ -> head

-}
type alias NotEmpty =
    MaybeIs.Just { notEmpty : () }


{-| `Emptiable` marks lists that could be empty:

    fromList : List a -> ListIs Emptiable a
    fromList list =
        case list of
            [] ->
                ListIs.empty

            head :: tail ->
                ListIs.fromCons head tail

-}
type alias Emptiable =
    MaybeIs.Nothingable { emptiable : () }


{-| A `ListIs` without elements.

Equivalent to `MaybeIs.nothing`.

-}
empty : ListWithHeadType head_ Emptiable tailElement_
empty =
    nothing


{-| A `ListIs` with just 1 element.

    ListIs.only ":)"
    --> ListIs.empty |> ListIs.cons ":)"

-}
only : head -> ListWithHeadType head notEmpty_ tailElement_
only onlyElement =
    fromCons onlyElement []


{-| Convert a non-empty list tuple `( a, List b )` to a `ListWithHeadType a notEmpty_ b`.

Equivalent to `MaybeIs.just`.

-}
fromTuple : ( head, List tailElement ) -> ListWithHeadType head notEmpty_ tailElement
fromTuple headAndTailTuple =
    just headAndTailTuple


{-| Build a `notEmpty_` from its head and tail.
-}
fromCons : head -> List tailElement -> ListWithHeadType head notEmpty_ tailElement
fromCons head_ tail_ =
    fromTuple ( head_, tail_ )


{-| Convert a `List a` to a `ListIs Emptiable a`.

    [] |> ListIs.fromList
    --> ListIs.empty

    [ "hello", "emptiness" ] |> ListIs.fromList
    --> ListIs.fromCons "hello" [ "emptiness" ]
    --: ListIs Emptiable String

When constructing from known elements, always prefer

    ListIs.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> ListIs Emptiable a
fromList list_ =
    case list_ of
        [] ->
            empty

        head_ :: tail_ ->
            fromCons head_ tail_



--


{-| The first value in the `ListIs`.

    ListIs.only 3
        |> ListIs.cons 2
        |> ListIs.head
    --> 2

-}
head : ListWithHeadType head NotEmpty tailElement_ -> head
head notEmptyList =
    notEmptyList |> toTuple |> Tuple.first


{-| Everything after the first value in the `ListIs`.

    ListIs.only 2
        |> ListIs.cons 3
        |> ListIs.append (ListIs.fromCons 1 [ 0 ])
        |> ListIs.tail
    --> [ 2, 1, 0 ]

-}
tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
tail notEmptyList =
    notEmptyList |> toTuple |> Tuple.second


{-| How many element there are.

    ListIs.only 3
        |> ListIs.cons 2
        |> ListIs.length
    --> 2

-}
length : ListWithHeadType head_ emptyOrNot_ tailElement_ -> Int
length =
    \list ->
        case list of
            IsJust ( _, tail_ ) ->
                1 + List.length tail_

            IsNothing _ ->
                0



--


{-| Add an element to the front of a list.

    ListIs.fromCons 2 [ 3 ] |> ListIs.cons 1
    --> ListIs.fromCons 1 [ 2, 3 ]

    ListIs.empty |> ListIs.cons 1
    --> ListIs.only 1

-}
cons : consed -> ListIs emptyOrNot_ a -> ListWithHeadType consed NotEmpty a
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a `ListIs NotEmpty ...` to the end of a `ListIs`.

    ListIs.empty
        |> ListIs.appendNonEmpty
            (ListIs.fromCons 1 [ 2 ])
        |> ListIs.append
            (ListIs.fromCons 3 [ 4, 5 ])
    --> ListIs.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `ListIs` is already known as `NotEmpty`
or if both are `Emptiable`.

-}
appendNonEmpty :
    ListIs NotEmpty a
    -> ListIs emptyOrNot_ a
    -> ListIs NotEmpty a
appendNonEmpty nonEmptyToAppend =
    \list ->
        case list of
            IsNothing _ ->
                nonEmptyToAppend

            IsJust ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a `ListIs` to the end of a `ListIs`.

    ListIs.fromCons 1 [ 2 ]
        |> ListIs.append
            (ListIs.fromCons 3 [ 4 ])
    --> ListIs.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNonEmpty`](#appendNonEmpty) if the piped `ListIs` is already known as `NotEmpty`
or if both are `Emptiable`.

-}
append :
    ListIs Emptiable a
    -> ListIs emptyOrNot a
    -> ListIs emptyOrNot a
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( IsNothing is, IsNothing _ ) ->
                IsNothing is

            ( IsNothing _, IsJust nonEmptyToAppend ) ->
                fromTuple nonEmptyToAppend

            ( IsJust ( head_, tail_ ), _ ) ->
                fromCons head_ (tail_ ++ toList toAppend)


{-| Glue together a bunch of lists.

    ListIs.fromCons
        (ListIs.fromCons 0 [ 1 ])
        [ ListIs.fromCons 10 [ 11 ]
        , ListIs.empty
        , ListIs.fromCons 20 [ 21, 22 ]
        ]
        |> ListIs.concat
    --> ListIs.fromCons 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a `ListIs notEmpty`, there must be a non-empty first list.

-}
concat :
    ListWithHeadType
        (ListIs emptyOrNot a)
        emptyOrNot
        (ListIs tailListsEmptyOrNot_ a)
    -> ListIs emptyOrNot a
concat listOfLists =
    case listOfLists of
        IsNothing canBeNothing ->
            IsNothing canBeNothing

        IsJust ( IsJust ( head_, firstListTail ), afterFirstList ) ->
            fromCons head_
                (firstListTail
                    ++ (afterFirstList |> List.concatMap toList)
                )

        IsJust ( IsNothing canBeNothing, lists ) ->
            case lists |> List.concatMap toList of
                [] ->
                    IsNothing canBeNothing

                head_ :: tail__ ->
                    fromCons head_ tail__



--


{-| Keep elements that satisfy the test.

    ListIs.fromCons 1 [ 2, 5, -3, 10 ]
        |> ListIs.when (\x -> x < 5)
    --> ListIs.fromCons 1 [ 2, -3 ]
    --: ListIs Emptiable number_

-}
when : (a -> Bool) -> ListIs emptyOrNot_ a -> ListIs Emptiable a
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `Just` values and drop all `Nothing`s.

    ListIs.fromCons (Just 1) [ Nothing, Just 3 ]
        |> ListIs.whenJust
    --> ListIs.fromCons 1 [ 3 ]
    --: ListIs Emptiable number

    ListIs.fromCons Nothing [ Nothing ]
        |> ListIs.whenJust
    --> ListIs.empty

-}
whenJust : ListIs emptyOrNot_ (Maybe value) -> ListIs Emptiable value
whenJust maybes =
    maybes |> toList |> List.filterMap identity |> fromList



--


{-| Apply a function to every element.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.map negate
    --> ListIs.fromCons -1 [ -4, -9 ]

-}
map : (a -> b) -> ListIs emptyOrNot a -> ListIs emptyOrNot b
map changeElement =
    MaybeIs.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Apply a function to every element of its tail.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.mapTail negate
    --> ListIs.fromCons 1 [ -4, -9 ]

-}
mapTail :
    (tailElement -> mappedTailElement)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType head emptyOrNot mappedTailElement
mapTail changeTailElement =
    MaybeIs.map
        (Tuple.mapBoth identity (List.map changeTailElement))


{-| Apply a function to the head only.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.mapHead negate
    --> ListIs.fromCons -1 [ 4, 9 ]

-}
mapHead :
    (head -> mappedHead)
    -> ListWithHeadType head emptyOrNot tailElement
    -> ListWithHeadType mappedHead emptyOrNot tailElement
mapHead changeHead =
    MaybeIs.map (Tuple.mapFirst changeHead)


{-| Reduce a List in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    ListIs.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListIs.fold LastToFirst String.cons ""
    --> "live"

    ListIs.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListIs.fold FirstToLast String.cons ""
    --> "evil"

-}
fold :
    LinearDirection
    -> (a -> acc -> acc)
    -> acc
    -> ListIs emptyOrNot_ a
    -> acc
fold direction reduce initial =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the `ListIs`.

    import LinearDirection exposing (LinearDirection(..))

    ListIs.fromCons 234 [ 345, 543 ]
        |> ListIs.foldWith FirstToLast max
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


{-| Convert the `ListIs` to a `List`.

    ListIs.fromCons 1 [ 7 ]
        |> ListIs.toList
    --> [ 1, 7 ]

-}
toList : ListIs emptyOrNot_ a -> List a
toList =
    \list ->
        case list of
            IsJust ( head_, tail_ ) ->
                head_ :: tail_

            IsNothing _ ->
                []


{-| Convert a `NotEmpty` to a non-empty list tuple `( a, List a )`.

Equivalent to `MaybeIs.value`.

-}
toTuple : ListWithHeadType head NotEmpty tailElement -> ( head, List tailElement )
toTuple listNotEmpty =
    listNotEmpty |> MaybeIs.value
