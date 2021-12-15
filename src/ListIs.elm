module ListIs exposing
    ( ListIs, NotEmpty
    , ListWithHeadType
    , empty, only, fromCons, fromUnConsed, fromList
    , head, tail, length
    , cons
    , append, appendNotEmpty, concat
    , when, whenJust
    , map, mapHead, mapTail, foldFrom, fold, toList, unCons
    , map2, map2HeadsAndTails
    )

{-|


## types

@docs ListIs, NotEmpty
@docs ListWithHeadType


## create

@docs empty, only, fromCons, fromUnConsed, fromList


## scan

@docs head, tail, length


## modify

@docs cons


## glue

@docs append, appendNotEmpty, concat


### filter

@docs when, whenJust


## transform

@docs map, mapHead, mapTail, foldFrom, fold, toList, unCons
@docs map2, map2HeadsAndTails

-}

import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List
import MaybeIs exposing (CanBe, MaybeIs(..), just, nothing)


{-| Describes an empty or non-empty list, making it more convenient than any `Nonempty`.

We can require a [`NotEmpty`](#NotEmpty) for example:

    toNonempty : ListIs NotEmpty a -> Nonempty a

`ListIs` is equivalent to a [`MaybeIs`](MaybeIs) of a non-empty list tuple:

    MaybeIs emptyOrNot ( a, List a )

so we can treat it like a normal [`MaybeIs`](MaybeIs):

    import MaybeIs exposing (MaybeIs(..))

    ListIs.empty
    --> MaybeIs.nothing

    [ ... ]
        |> ListIs.fromList
        |> MaybeIs.map ListIs.head
    --: MaybeIs (CanBe nothingTag_ ()) head_

    toList : ListIs emptyOrNot_ a -> List a
    toList list =
        case list of
            JustIs ( head_, tail_ ) ->
                head_ :: tail_

            NothingIs _ ->
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
  - [`fromUnConsed`](#fromUnConsed)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)
  - [`map2HeadsAndTails`](#map2HeadsAndTails)

This is equivalent to a [`MaybeIs`](MaybeIs) of a `( head, tail )` tuple:

    import MaybeIs exposing (MaybeIs(..))

    ListIs.empty
    --> MaybeIs.nothing

    MaybeIs.map ListIs.head
    --: ListWithHeadType head (CanBe empty_ yesOrNever) tailElement_
    --: -> MaybeIs (CanBe nothingTag_ yesOrNever) head

    tail : ListWithHead head_ tailElement -> List tailElement
    tail listNotEmpty =
        case listNotEmpty of
            JustIs ( _, tailList ) ->
                tailList

            NothingIs _ ->
                []

-}
type alias ListWithHeadType head emptyOrNot tailElement =
    MaybeIs emptyOrNot ( head, List tailElement )


{-| `NotEmpty` can be used to require a non-empty list as an argument:

    head : ListWithHeadType head NotEmpty tailElement_ -> head

-}
type alias NotEmpty =
    CanBe { empty : () } Never


{-| A `ListIs` without elements.

Equivalent to `MaybeIs.nothing`.

-}
empty : ListWithHeadType head_ (CanBe empty_ ()) tailElement_
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
fromUnConsed :
    ( head, List tailElement )
    -> ListWithHeadType head notEmpty_ tailElement
fromUnConsed headAndTailTuple =
    just headAndTailTuple


{-| Build a `notEmpty_` from its head and tail.
-}
fromCons :
    head
    -> List tailElement
    -> ListWithHeadType head notEmpty_ tailElement
fromCons head_ tail_ =
    fromUnConsed ( head_, tail_ )


{-| Convert a `List a` to a `ListIs (CanBe emptyTag_ ()) a`.

    [] |> ListIs.fromList
    --> ListIs.empty

    [ "hello", "emptiness" ] |> ListIs.fromList
    --> ListIs.fromCons "hello" [ "emptiness" ]
    --: ListIs (CanBe emptyTag_ ()) String

When constructing from known elements, always prefer

    ListIs.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> ListIs (CanBe emptyTag_ ()) a
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
    notEmptyList |> unCons |> Tuple.first


{-| Everything after the first value in the `ListIs`.

    ListIs.only 2
        |> ListIs.cons 3
        |> ListIs.append (ListIs.fromCons 1 [ 0 ])
        |> ListIs.tail
    --> [ 2, 1, 0 ]

-}
tail : ListWithHeadType head_ NotEmpty tailElement -> List tailElement
tail notEmptyList =
    notEmptyList |> unCons |> Tuple.second


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
            JustIs ( _, tail_ ) ->
                1 + List.length tail_

            NothingIs _ ->
                0



--


{-| Add an element to the front of a list.

    ListIs.fromCons 2 [ 3 ] |> ListIs.cons 1
    --> ListIs.fromCons 1 [ 2, 3 ]

    ListIs.empty |> ListIs.cons 1
    --> ListIs.only 1

-}
cons :
    newHead
    -> ListIs emptyOrNot_ a
    -> ListWithHeadType newHead NotEmpty a
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a `ListIs NotEmpty ...` to the end of a `ListIs`.

    ListIs.empty
        |> ListIs.appendNotEmpty
            (ListIs.fromCons 1 [ 2 ])
        |> ListIs.append
            (ListIs.fromCons 3 [ 4, 5 ])
    --> ListIs.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `ListIs` is already known as `NotEmpty`
or if both can be empty.

-}
appendNotEmpty :
    ListIs NotEmpty a
    -> ListIs emptyOrNot_ a
    -> ListIs NotEmpty a
appendNotEmpty nonEmptyToAppend =
    \list ->
        case list of
            NothingIs _ ->
                nonEmptyToAppend

            JustIs ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a `ListIs` to the end of a `ListIs`.

    ListIs.fromCons 1 [ 2 ]
        |> ListIs.append
            (ListIs.fromCons 3 [ 4 ])
    --> ListIs.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNotEmpty`](#appendNotEmpty) if the piped `ListIs` is already known as `NotEmpty`
or if both can be empty.

-}
append :
    ListIs appendedEmptyOrNot_ a
    -> ListIs emptyOrNot a
    -> ListIs emptyOrNot a
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( NothingIs is, NothingIs _ ) ->
                NothingIs is

            ( NothingIs _, JustIs nonEmptyToAppend ) ->
                fromUnConsed nonEmptyToAppend

            ( JustIs ( head_, tail_ ), _ ) ->
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
        NothingIs canBeNothing ->
            NothingIs canBeNothing

        JustIs ( JustIs ( head_, firstListTail ), afterFirstList ) ->
            fromCons head_
                (firstListTail
                    ++ (afterFirstList |> List.concatMap toList)
                )

        JustIs ( NothingIs canBeNothing, lists ) ->
            case lists |> List.concatMap toList of
                [] ->
                    NothingIs canBeNothing

                head_ :: tail__ ->
                    fromCons head_ tail__



--


{-| Keep elements that satisfy the test.

    ListIs.fromCons 1 [ 2, 5, -3, 10 ]
        |> ListIs.when (\x -> x < 5)
    --> ListIs.fromCons 1 [ 2, -3 ]
    --: ListIs (CanBe emptyTag_ ()) number_

-}
when : (a -> Bool) -> ListIs emptyOrNot_ a -> ListIs (CanBe emptyTag_ ()) a
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `just` values and drop all `Nothing`s.

    ListIs.fromCons Nothing [ Nothing ]
        |> ListIs.whenJust
    --> ListIs.empty

    ListIs.fromCons (just 1) [ Nothing, just 3 ]
        |> ListIs.whenJust
    --> ListIs.fromCons 1 [ 3 ]
    --: ListIs NotEmpty number

As you can see, if the head is `just` a value, the result is [`NotEmpty`](#NotEmpty).

-}
whenJust :
    ListWithHeadType
        (MaybeIs emptyOrNot headValue)
        emptyOrNot
        (MaybeIs tailElementEmptyOrNot_ tailElementValue)
    -> ListWithHeadType headValue emptyOrNot tailElementValue
whenJust maybes =
    case maybes of
        NothingIs isPossible ->
            NothingIs isPossible

        JustIs ( head_, tail_ ) ->
            case head_ of
                NothingIs isPossible ->
                    NothingIs isPossible

                JustIs headValue ->
                    fromCons headValue
                        (tail_ |> List.filterMap MaybeIs.toMaybe)



--


{-| Apply a function to every element.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.map negate
    --> ListIs.fromCons -1 [ -4, -9 ]

-}
map :
    (a -> b)
    -> ListIs (CanBe empty_ yesOrNever) a
    -> ListIs (CanBe mappedEmpty_ yesOrNever) b
map changeElement =
    MaybeIs.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Combine 2 `ListIs`s with a given function.
If one list is longer, its extra elements are dropped.

    ListIs.map2 (+)
        (ListIs.fromCons 1 [ 2, 3 ])
        (ListIs.fromCons 4 [ 5, 6, 7 ])
    --> ListIs.fromCons 5 [ 7, 9 ]

    ListIs.map2 Tuple.pair
        (ListIs.fromCons 1 [ 2, 3 ])
        ListIs.empty
    --> ListIs.empty

For `ListWithHeadType head ... tailElement` where `head` and `tailElement` have a different type,
there's [`map2HeadsAndTails`](#map2HeadsAndTails).

-}
map2 :
    (a -> b -> combined)
    -> ListIs (CanBe aEmpty_ yesOrNever) a
    -> ListIs (CanBe bEmpty_ yesOrNever) b
    -> ListIs (CanBe combinedEmpty_ yesOrNever) combined
map2 combineAB aList bList =
    map2HeadsAndTails combineAB combineAB aList bList


{-| Combine the head and tail elements of 2 `ListIs`s using given functions.
If one list is longer, its extra elements are dropped.

    ListIs.map2HeadsAndTails Tuple.pair (+)
        (ListIs.fromCons "hey" [ 0, 1 ])
        (ListIs.fromCons "there" [ 1, 6, 7 ])
    --> ListIs.fromCons ( "hey", "there" ) [ 1, 7 ]

    ListIs.map2HeadsAndTails Tuple.pair (+)
        (ListIs.fromCons 1 [ 2, 3 ])
        ListIs.empty
    --> ListIs.empty

For matching `head` and `tailElement` types, there's [`map2`](#map2).

-}
map2HeadsAndTails :
    (aHead -> bHead -> combinedHead)
    -> (aTailElement -> bTailElement -> combinedTailElement)
    -> ListWithHeadType aHead (CanBe aEmpty_ yesOrNever) aTailElement
    -> ListWithHeadType bHead (CanBe bEmpty_ yesOrNever) bTailElement
    ->
        ListWithHeadType
            combinedHead
            (CanBe combinedEmpty_ yesOrNever)
            combinedTailElement
map2HeadsAndTails combineHeads combineTailElements aList bList =
    MaybeIs.map2
        (\( aHead, aTail ) ( bHead, bTail ) ->
            ( combineHeads aHead bHead
            , List.map2 combineTailElements aTail bTail
            )
        )
        aList
        bList


{-| Apply a function to every element of its tail.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.mapTail negate
    --> ListIs.fromCons 1 [ -4, -9 ]

-}
mapTail :
    (tailElement -> mappedTailElement)
    -> ListWithHeadType head (CanBe empty_ yesOrNever) tailElement
    -> ListWithHeadType head (CanBe mappedEmpty_ yesOrNever) mappedTailElement
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
    -> ListWithHeadType head (CanBe empty_ yesOrNever) tailElement
    -> ListWithHeadType mappedHead (CanBe mappedEmpty_ yesOrNever) tailElement
mapHead changeHead =
    MaybeIs.map (Tuple.mapFirst changeHead)


{-| Reduce a List in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    ListIs.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListIs.foldFrom "" LastToFirst String.cons
    --> "live"

    ListIs.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListIs.foldFrom "" FirstToLast String.cons
    --> "evil"

-}
foldFrom :
    acc
    -> LinearDirection
    -> (a -> acc -> acc)
    -> ListIs emptyOrNot_ a
    -> acc
foldFrom initial direction reduce =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the `ListIs`.

    import LinearDirection exposing (LinearDirection(..))

    ListIs.fromCons 234 [ 345, 543 ]
        |> ListIs.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (tailElement -> acc -> acc)
    -> ListWithHeadType acc NotEmpty tailElement
    -> acc
fold direction reduce listNotEmpty =
    let
        ( head_, tail_ ) =
            unCons listNotEmpty
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
            JustIs ( head_, tail_ ) ->
                head_ :: tail_

            NothingIs _ ->
                []


{-| Convert a `ListWithHeadType a NotEmpty b` to a non-empty list tuple `( a, List b )`.

Equivalent to `MaybeIs.value`.

-}
unCons : ListWithHeadType head NotEmpty tailElement -> ( head, List tailElement )
unCons listNotEmpty =
    listNotEmpty |> MaybeIs.value
