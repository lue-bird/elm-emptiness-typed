module ListThat exposing
    ( ListThat, Empty
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

@docs ListThat, Empty


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
import MaybeThat exposing (Be, Can, CanBe, Isnt, MaybeThat(..), just, nothing)


{-| Describes an empty or non-empty list, making it more convenient than any `Nonempty`.

`(`[`Isnt`](MaybeThat#Isnt)\``[`Empty`](#Empty)`)\` can be used to require a non-empty list as an argument:

    head : ListThat (Isnt Empty) element -> element

[`ListThat`](#ListThat) is equivalent to a [`MaybeThat`](MaybeThat) of a non-empty list tuple:

    MaybeThat canBeEmptyOrNot ( element, List element )

so we can treat it like a normal [`MaybeThat`](MaybeThat):

    import MaybeThat exposing (MaybeThat(..))

    ListThat.empty
    --> MaybeThat.nothing

    [ ... ]
        |> ListThat.fromList
        |> MaybeThat.map ListThat.head
    --: MaybeThat (CanBe nothing_ ()) head_

    toList : ListThat canBeEmptyOrNot_ element -> List element
    toList list =
        case list of
            JustThat ( head_, tail_ ) ->
                head_ :: tail_

            NothingThat _ ->
                []

Most operations also work with empty or non-empty list where the head type is be different from the tail element type:

    head : MaybeThat (Isnt Empty) ( head, tail_ ) -> head

it's also the result of:

  - [`empty`](#empty)
  - [`only`](#only)
  - [`fromCons`](#fromCons)
  - [`fromUnConsed`](#fromUnConsed)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)
  - [`map2HeadsAndTails`](#map2HeadsAndTails)

-}
type alias ListThat canItBeEmpty element =
    MaybeThat canItBeEmpty ( element, List element )


{-| Type tag:

    head : ListThat (Isnt Empty) element -> element

Use it when describing a [`ListThat`](#ListThat) in a `type`/`type alias`:

    type alias Model =
        WithoutConstructorFunction
            { searchKeyWords : ListThat (Isnt Empty) String
            , planets : ListThat (CanBe Empty) Planet
            }

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

-}
type Empty
    = Empty Never


{-| A [`ListThat`](#ListThat) without elements.

[`MaybeThat.nothing`](MaybeThat#nothing) will also work.

-}
empty : MaybeThat (CanBe empty_) ( head_, tail_ )
empty =
    nothing


{-| A [`ListThat`](#ListThat) with just 1 element.

    ListThat.only ":)"
    --> ListThat.empty |> ListThat.cons ":)"

-}
only : head -> MaybeThat isntEmpty_ ( head, List tailElement_ )
only onlyElement =
    fromCons onlyElement []


{-| Convert from a non-empty structure tuple `( head, tail )`.

Equivalent to `MaybeThat.just`.

-}
fromUnConsed :
    ( head, tail )
    -> MaybeThat isntEmpty_ ( head, tail )
fromUnConsed headAndTailTuple =
    just headAndTailTuple


{-| A non-empty structure from its head and tail.
-}
fromCons :
    head
    -> tail
    -> MaybeThat isntEmpty_ ( head, tail )
fromCons head_ tail_ =
    fromUnConsed ( head_, tail_ )


{-| Convert a `List a` to a `ListThat (CanBe empty_ ()) a`.

    [] |> ListThat.fromList
    --> ListThat.empty

    [ "hello", "emptiness" ] |> ListThat.fromList
    --> ListThat.fromCons "hello" [ "emptiness" ]
    --: ListThat (CanBe empty_ ()) String

When constructing from known elements, always prefer

    ListThat.fromCons "hello" [ "emptiness" ]

-}
fromList : List element -> ListThat (CanBe empty_) element
fromList list =
    case list of
        [] ->
            empty

        head_ :: tail_ ->
            fromCons head_ tail_



--


{-| The first value.

    ListThat.only 3
        |> ListThat.cons 2
        |> ListThat.head
    --> 2

-}
head : MaybeThat (Isnt empty_) ( head, tail_ ) -> head
head notEmpty =
    notEmpty |> unCons |> Tuple.first


{-| Everything after the first value.

    ListThat.only 2
        |> ListThat.cons 3
        |> ListThat.append (ListThat.fromCons 1 [ 0 ])
        |> ListThat.tail
    --> [ 2, 1, 0 ]

-}
tail : MaybeThat (Isnt empty_) ( head_, tail ) -> tail
tail notEmpty =
    notEmpty |> unCons |> Tuple.second


{-| How many element there are.

    ListThat.only 3
        |> ListThat.cons 2
        |> ListThat.length
    --> 2

-}
length : MaybeThat emptyOrNot_ ( head_, List tailElement_ ) -> Int
length =
    \list ->
        case list of
            JustThat ( _, tail_ ) ->
                1 + List.length tail_

            NothingThat _ ->
                0



--


{-| Add an element to the front.

    ListThat.fromCons 2 [ 3 ] |> ListThat.cons 1
    --> ListThat.fromCons 1 [ 2, 3 ]

    ListThat.empty |> ListThat.cons 1
    --> ListThat.only 1

-}
cons :
    newHead
    -> ListThat emptyOrNot_ tailElement
    -> MaybeThat isntEmpty_ ( newHead, List tailElement )
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a non-empty [`ListThat`](#ListThat) to the end of a [`ListThat`](#ListThat).

    ListThat.empty
        |> ListThat.appendNotEmpty
            (ListThat.fromCons 1 [ 2 ])
        |> ListThat.append
            (ListThat.fromCons 3 [ 4, 5 ])
    --> ListThat.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped [`ListThat`](#ListThat) is already known as non-empty
or if both can be empty.

-}
appendNotEmpty :
    ListThat (Isnt empty_) element
    -> ListThat canBeEmptyOrNot_ element
    -> ListThat isntEmpty_ element
appendNotEmpty nonEmptyToAppend =
    \list ->
        case list of
            NothingThat _ ->
                nonEmptyToAppend |> MaybeThat.branchableType

            JustThat ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a [`ListThat`](#ListThat) to the end of a [`ListThat`](#ListThat).

    ListThat.fromCons 1 [ 2 ]
        |> ListThat.append
            (ListThat.fromCons 3 [ 4 ])
    --> ListThat.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNotEmpty`](#appendNotEmpty) if the piped [`ListThat`](#ListThat) is already known as non-empty
or if both can be empty.

-}
append :
    ListThat appendedCanBeEmptyOrNot_ element
    -> ListThat canBeEmptyOrNot element
    -> ListThat canBeEmptyOrNot element
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( NothingThat is, NothingThat _ ) ->
                NothingThat is

            ( NothingThat _, JustThat nonEmptyToAppend ) ->
                fromUnConsed nonEmptyToAppend

            ( JustThat ( head_, tail_ ), _ ) ->
                fromCons head_ (tail_ ++ toList toAppend)


{-| Glue together a bunch of [`ListThat`](#ListThat).

    ListThat.fromCons
        (ListThat.fromCons 0 [ 1 ])
        [ ListThat.fromCons 10 [ 11 ]
        , ListThat.empty
        , ListThat.fromCons 20 [ 21, 22 ]
        ]
        |> ListThat.concat
    --> ListThat.fromCons 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty [`ListThat`](#ListThat), there must be a non-empty first list.

-}
concat :
    MaybeThat
        canBeEmptyOrNot
        ( ListThat canBeEmptyOrNot element
        , List (ListThat canTailBeEmptyOrNot_ element)
        )
    -> ListThat canBeEmptyOrNot element
concat listOfLists =
    case listOfLists of
        NothingThat canBeNothing ->
            NothingThat canBeNothing

        JustThat ( JustThat ( head_, firstListTail ), afterFirstList ) ->
            fromCons head_
                (firstListTail
                    ++ (afterFirstList |> List.concatMap toList)
                )

        JustThat ( NothingThat canBeNothing, lists ) ->
            case lists |> List.concatMap toList of
                [] ->
                    NothingThat canBeNothing

                head_ :: tail__ ->
                    fromCons head_ tail__



--


{-| Keep elements that satisfy a test.

    ListThat.fromCons 1 [ 2, 5, -3, 10 ]
        |> ListThat.when (\x -> x < 5)
    --> ListThat.fromCons 1 [ 2, -3 ]
    --: ListThat (CanBe empty_) number_

-}
when :
    (element -> Bool)
    -> ListThat canBeEmpty_ element
    -> ListThat (CanBe empty_) element
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all `just` values and drop all [`nothing`](MaybeThat#nothing)s.

    import MaybeThat exposing (just, nothing)

    ListThat.fromCons nothing [ nothing ]
        |> ListThat.whenJust
    --> ListThat.empty

    ListThat.fromCons (just 1) [ nothing, just 3 ]
        |> ListThat.whenJust
    --> ListThat.fromCons 1 [ 3 ]

As you can see, if only the head is [`just`](MaybeThat#just) a value, the result is non-empty.

-}
whenJust :
    MaybeThat
        canBeEmptyOrNot
        ( MaybeThat canBeEmptyOrNot headValue
        , List
            (MaybeThat canBeNothingOrNotTailElement_ tailElementValue)
        )
    ->
        MaybeThat
            canBeEmptyOrNot
            ( headValue, List tailElementValue )
whenJust maybes =
    case maybes of
        NothingThat isPossible ->
            NothingThat isPossible

        JustThat ( head_, tail_ ) ->
            case head_ of
                NothingThat isPossible ->
                    NothingThat isPossible

                JustThat headValue ->
                    fromCons headValue
                        (tail_ |> List.filterMap MaybeThat.toMaybe)



--


{-| Apply a function to every element.

    ListThat.fromCons 1 [ 4, 9 ]
        |> ListThat.map negate
    --> ListThat.fromCons -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> ListThat (Can possiblyOrNever Be empty_) aElement
    -> ListThat (Can possiblyOrNever Be mappedEmpty_) bElement
map changeElement =
    MaybeThat.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Combine 2 [`ListThat`](#ListThat)s with a given function.
If one list is longer, its extra elements are dropped.

    ListThat.map2 (+)
        (ListThat.fromCons 1 [ 2, 3 ])
        (ListThat.fromCons 4 [ 5, 6, 7 ])
    --> ListThat.fromCons 5 [ 7, 9 ]

    ListThat.map2 Tuple.pair
        (ListThat.fromCons 1 [ 2, 3 ])
        ListThat.empty
    --> ListThat.empty

For `ListWithHeadType head ... tailElement` where `head` and `tailElement` have a different type,
there's [`map2HeadsAndTails`](#map2HeadsAndTails).

-}
map2 :
    (aElement -> bElement -> combinedElement)
    -> ListThat (Can possiblyOrNever Be aEmpty_) aElement
    -> ListThat (Can possiblyOrNever Be bEmpty_) bElement
    -> ListThat (Can possiblyOrNever Be combinedEmpty_) combinedElement
map2 combineAB aList bList =
    map2HeadsAndTails combineAB combineAB aList bList


{-| Combine the head and tail elements of 2 [`ListThat`](#ListThat)s using given functions.
If one list is longer, its extra elements are dropped.

    ListThat.map2HeadsAndTails Tuple.pair (+)
        (ListThat.fromCons "hey" [ 0, 1 ])
        (ListThat.fromCons "there" [ 1, 6, 7 ])
    --> ListThat.fromCons ( "hey", "there" ) [ 1, 7 ]

    ListThat.map2HeadsAndTails Tuple.pair (+)
        (ListThat.fromCons 1 [ 2, 3 ])
        ListThat.empty
    --> ListThat.empty

For matching `head` and `tailElement` types, there's [`map2`](#map2).

-}
map2HeadsAndTails :
    (aHead -> bHead -> combinedHead)
    -> (aTailElement -> bTailElement -> combinedTailElement)
    -> MaybeThat (Can possiblyOrNever Be aEmpty_) ( aHead, List aTailElement )
    -> MaybeThat (Can possiblyOrNever Be bEmpty_) ( bHead, List bTailElement )
    ->
        MaybeThat
            (Can possiblyOrNever Be combinedEmpty_)
            ( combinedHead, List combinedTailElement )
map2HeadsAndTails combineHeads combineTailElements aList bList =
    MaybeThat.map2
        (\( aHead, aTail ) ( bHead, bTail ) ->
            ( combineHeads aHead bHead
            , List.map2 combineTailElements aTail bTail
            )
        )
        aList
        bList


{-| Apply a function to every element of its tail.

    ListThat.fromCons 1 [ 4, 9 ]
        |> ListThat.mapTail negate
    --> ListThat.fromCons 1 [ -4, -9 ]

-}
mapTail :
    (tailElement -> mappedTailElement)
    -> MaybeThat (Can possiblyOrNever Be empty_) ( head, List tailElement )
    -> MaybeThat (Can possiblyOrNever Be mappedEmpty_) ( head, List mappedTailElement )
mapTail changeTailElement =
    MaybeThat.map
        (Tuple.mapSecond (List.map changeTailElement))


{-| Apply a function to the head only.

    ListThat.fromCons 1 [ 4, 9 ]
        |> ListThat.mapHead negate
    --> ListThat.fromCons -1 [ 4, 9 ]

-}
mapHead :
    (head -> mappedHead)
    -> MaybeThat (Can possiblyOrNever Be empty_) ( head, tail )
    -> MaybeThat (Can possiblyOrNever Be mappedEmpty_) ( mappedHead, tail )
mapHead changeHead =
    MaybeThat.map (Tuple.mapFirst changeHead)


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    ListThat.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListThat.foldFrom "" LastToFirst String.cons
    --> "live"

    ListThat.fromCons 'l' [ 'i', 'v', 'e' ]
        |> ListThat.foldFrom "" FirstToLast String.cons
    --> "evil"

-}
foldFrom :
    acc
    -> LinearDirection
    -> (element -> acc -> acc)
    -> ListThat emptyOrNot_ element
    -> acc
foldFrom initial direction reduce =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the [`ListThat`](#ListThat).

    import LinearDirection exposing (LinearDirection(..))

    ListThat.fromCons 234 [ 345, 543 ]
        |> ListThat.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (tailElement -> acc -> acc)
    -> MaybeThat (Isnt empty_) ( acc, List tailElement )
    -> acc
fold direction reduce notEmpty =
    let
        ( head_, tail_ ) =
            notEmpty |> unCons
    in
    List.fold direction reduce head_ tail_


{-| Convert the [`ListThat`](#ListThat) to a `List`.

    ListThat.fromCons 1 [ 7 ]
        |> ListThat.toList
    --> [ 1, 7 ]

-}
toList : ListThat canBeEmptyOrNot_ element -> List element
toList =
    \list ->
        case list of
            JustThat ( head_, tail_ ) ->
                head_ :: tail_

            NothingThat _ ->
                []


{-| Convert to a non-empty list tuple `( head, tail List )`.

Equivalent to [`MaybeThat.value`](MaybeThat#value).

    ListThat.fromCons "hi" [ "there", "👋" ]
        |> ListThat.unCons
    --> ( "hi", [ "there", "👋" ] )

-}
unCons : MaybeThat (Isnt empty_) ( head, tail ) -> ( head, tail )
unCons notEmpty =
    notEmpty |> MaybeThat.value
