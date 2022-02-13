module ListIs exposing
    ( ListIs
    , only, fromCons, fromUnConsed, fromList
    , head, tail, length
    , cons
    , append, appendNotEmpty, concat
    , when, whenFilled
    , map, mapHead, mapTail, foldFrom, fold, toList, unCons
    , map2, map2HeadsAndTails
    )

{-| An **emptiable or non-empty** list

@docs ListIs


## create

Note: [`Fillable.empty`](Fillable#empty) can be used as an empty [`ListIs`](#ListIs)

@docs only, fromCons, fromUnConsed, fromList


## scan

@docs head, tail, length


## modify

@docs cons


## glue

@docs append, appendNotEmpty, concat


### filter

@docs when, whenFilled


## transform

@docs map, mapHead, mapTail, foldFrom, fold, toList, unCons
@docs map2, map2HeadsAndTails

-}

import Fillable exposing (Emptiable, Filled, Is(..), empty, filled)
import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List


{-| An **emptiable or non-empty** list, making it more convenient than [any `NonEmpty`](https://dark.elm.dmy.fr/?q=non%20empty).


#### in arguments

[`Filled`](Fillable#Filled) → non-empty list:

    head : ListIs Filled element -> element


#### in results

[`Emptiable`](Fillable#Emptiable) → list could be empty

    fromList : List element -> ListIs EMptiable element


#### in types

---

Because

    type alias ListIs emptiableOrFilled element =
        Fillable.Is emptiableOrFilled ( element, List element )

we can treat it like any [`Fillable.Is`](Fillable#Is):

    import Fillable exposing (filled, Emptiable)

    Fillable.empty : ListIs Emptiable element_ -- fine

    [ "hi", "there" ] -- comes in as an argument
        |> ListIs.fromList
        |> Fillable.map (filled >> ListIs.head)
    --: Is Emptiable String

    toList : ListIs emptiableOrFilled_ element -> List element
    toList list =
        case list of
            Filled ( head_, tail_ ) ->
                head_ :: tail_

            Empty _ ->
                []

Most operations also allow different types for head and tail elements:

    head : Fillable.Filled ( head, tail_ ) -> head

it's also the result of:

  - [`only`](#only)
  - [`fromCons`](#fromCons)
  - [`fromUnConsed`](#fromUnConsed)
  - [`cons`](#cons)
  - [`mapHead`](#mapHead)
  - [`map2HeadsAndTails`](#map2HeadsAndTails)

-}
type alias ListIs emptiableOrFilled element =
    Is emptiableOrFilled ( element, List element )


{-| A [`ListIs`](#ListIs) with just 1 element.

    ListIs.only ":)"
    --> Fillable.empty |> ListIs.cons ":)"

-}
only : head -> Is filled_ ( head, List tailElement_ )
only onlyElement =
    fromCons onlyElement []


{-| Convert from a non-empty structure tuple `( head, tail )`.

Equivalent to `Fillable.just`.

-}
fromUnConsed :
    ( head, tail )
    -> Is filled_ ( head, tail )
fromUnConsed headAndTailTuple =
    filled headAndTailTuple


{-| A non-empty structure from its head and tail.
-}
fromCons :
    head
    -> tail
    -> Is filled_ ( head, tail )
fromCons head_ tail_ =
    fromUnConsed ( head_, tail_ )


{-| Convert a `List a` to a \`ListIs Emptiable

    [] |> ListIs.fromList
    --> Fillable.empty

    [ "hello", "emptiness" ] |> ListIs.fromList
    --> ListIs.fromCons "hello" [ "emptiness" ]
    --: ListIs Emptiable

When constructing from known elements, always prefer

    ListIs.fromCons "hello" [ "emptiness" ]

-}
fromList : List element -> ListIs Emptiable element
fromList list =
    case list of
        [] ->
            empty

        head_ :: tail_ ->
            fromCons head_ tail_



--


{-| The first value.

    ListIs.only 3
        |> ListIs.cons 2
        |> ListIs.head
    --> 2

-}
head : Is Filled ( head, tail_ ) -> head
head notEmpty =
    notEmpty |> unCons |> Tuple.first


{-| Everything after the first value.

    ListIs.only 2
        |> ListIs.cons 3
        |> ListIs.append (ListIs.fromCons 1 [ 0 ])
        |> ListIs.tail
    --> [ 2, 1, 0 ]

-}
tail : Is Filled ( head_, tail ) -> tail
tail notEmpty =
    notEmpty |> unCons |> Tuple.second


{-| How many element there are.

    ListIs.only 3
        |> ListIs.cons 2
        |> ListIs.length
    --> 2

-}
length : Is emptyOrNot_ ( head_, List tailElement_ ) -> Int
length =
    \list ->
        case list of
            Filled ( _, tail_ ) ->
                1 + List.length tail_

            Empty _ ->
                0



--


{-| Add an element to the front.

    ListIs.fromCons 2 [ 3 ] |> ListIs.cons 1
    --> ListIs.fromCons 1 [ 2, 3 ]

Fillable.empty |> ListIs.cons 1
--> ListIs.only 1

-}
cons :
    newHead
    -> ListIs emptyOrNot_ tailElement
    -> Is filled_ ( newHead, List tailElement )
cons toPutBeforeAllOtherElements =
    fromCons toPutBeforeAllOtherElements << toList


{-| Glue the elements of a non-empty [`ListIs`](#ListIs) to the end of a [`ListIs`](#ListIs).

Fillable.empty
|> ListIs.appendNotEmpty
(ListIs.fromCons 1 [ 2 ])
|> ListIs.append
(ListIs.fromCons 3 [ 4, 5 ])
--> ListIs.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped [`ListIs`](#ListIs) is already known as non-empty
or if both can be empty.

-}
appendNotEmpty :
    ListIs Filled element
    -> ListIs emptiableOrFilled_ element
    -> ListIs filled_ element
appendNotEmpty nonEmptyToAppend =
    \list ->
        case list of
            Empty _ ->
                nonEmptyToAppend |> Fillable.branchableType

            Filled ( head_, tail_ ) ->
                fromCons head_ (tail_ ++ toList nonEmptyToAppend)


{-| Glue the elements of a [`ListIs`](#ListIs) to the end of a [`ListIs`](#ListIs).

    ListIs.fromCons 1 [ 2 ]
        |> ListIs.append
            (ListIs.fromCons 3 [ 4 ])
    --> ListIs.fromCons 1 [ 2, 3, 4 ]

Prefer this over [`appendNotEmpty`](#appendNotEmpty) if the piped [`ListIs`](#ListIs) is already known as non-empty
or if both can be empty.

-}
append :
    ListIs appendedCanBeEmptyOrNot_ element
    -> ListIs emptiableOrFilled element
    -> ListIs emptiableOrFilled element
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( Empty is, Empty _ ) ->
                Empty is

            ( Empty _, Filled nonEmptyToAppend ) ->
                fromUnConsed nonEmptyToAppend

            ( Filled ( head_, tail_ ), _ ) ->
                fromCons head_ (tail_ ++ toList toAppend)


{-| Glue together a bunch of [`ListIs`](#ListIs).

    ListIs.fromCons
        (ListIs.fromCons 0 [ 1 ])
        [ ListIs.fromCons 10 [ 11 ]
        , Fillable.empty
        , ListIs.fromCons 20 [ 21, 22 ]
        ]
        |> ListIs.concat
    --> ListIs.fromCons 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty [`ListIs`](#ListIs), there must be a non-empty first list.

-}
concat :
    Is
        emptiableOrFilled
        ( ListIs emptiableOrFilled element
        , List (ListIs emptiableOrFilledTailLists_ element)
        )
    -> ListIs emptiableOrFilled element
concat listOfLists =
    case listOfLists of
        Empty canBeNothing ->
            Empty canBeNothing

        Filled ( Filled ( head_, firstListTail ), afterFirstList ) ->
            fromCons head_
                (firstListTail
                    ++ (afterFirstList |> List.concatMap toList)
                )

        Filled ( Empty canBeNothing, lists ) ->
            case lists |> List.concatMap toList of
                [] ->
                    Empty canBeNothing

                head_ :: tail__ ->
                    fromCons head_ tail__



--


{-| Keep elements that satisfy a test.

    ListIs.fromCons 1 [ 2, 5, -3, 10 ]
        |> ListIs.when (\x -> x < 5)
    --> ListIs.fromCons 1 [ 2, -3 ]
    --: ListIs Emptiable

-}
when :
    (element -> Bool)
    -> ListIs emptiableOrFilled_ element
    -> ListIs Emptiable element
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all [`filled`](Fillable#filled) values and drop all [`empty`](Fillable#empty) elements.

    import Fillable exposing (just, nothing)

    ListIs.fromCons nothing [ nothing ]
        |> ListIs.whenFilled
    --> Fillable.empty

    ListIs.fromCons (just 1) [ nothing, just 3 ]
        |> ListIs.whenFilled
    --> ListIs.fromCons 1 [ 3 ]

As you can see, if only the head is [`filling`](Fillable#filling) a value, the result is non-empty.

-}
whenFilled :
    Is
        emptiableOrFilled
        ( Is emptiableOrFilled headValue
        , List
            (Is canBeNothingOrNotTailElement_ tailElementValue)
        )
    ->
        Is
            emptiableOrFilled
            ( headValue, List tailElementValue )
whenFilled maybes =
    case maybes of
        Empty isPossible ->
            Empty isPossible

        Filled ( head_, tail_ ) ->
            case head_ of
                Empty isPossible ->
                    Empty isPossible

                Filled headValue ->
                    fromCons headValue
                        (tail_ |> List.filterMap Fillable.toMaybe)



--


{-| Apply a function to every element.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.map negate
    --> ListIs.fromCons -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> ListIs emptiableOrFilled aElement
    -> ListIs emptiableOrFilled bElement
map changeElement =
    Fillable.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Combine 2 [`ListIs`](#ListIs)s with a given function.
If one list is longer, its extra elements are dropped.

    ListIs.map2 (+)
        (ListIs.fromCons 1 [ 2, 3 ])
        (ListIs.fromCons 4 [ 5, 6, 7 ])
    --> ListIs.fromCons 5 [ 7, 9 ]

    ListIs.map2 Tuple.pair
        (ListIs.fromCons 1 [ 2, 3 ])
       Fillable.empty
    --> Fillable.empty

For `ListWithHeadType head ... tailElement` where `head` and `tailElement` have a different type,
there's [`map2HeadsAndTails`](#map2HeadsAndTails).

-}
map2 :
    (aElement -> bElement -> combinedElement)
    -> ListIs emptiableOrFilled aElement
    -> ListIs emptiableOrFilled bElement
    -> ListIs emptiableOrFilled combinedElement
map2 combineAB aList bList =
    map2HeadsAndTails combineAB combineAB aList bList


{-| Combine the head and tail elements of 2 [`ListIs`](#ListIs)s using given functions.
If one list is longer, its extra elements are dropped.

    ListIs.map2HeadsAndTails Tuple.pair (+)
        (ListIs.fromCons "hey" [ 0, 1 ])
        (ListIs.fromCons "there" [ 1, 6, 7 ])
    --> ListIs.fromCons ( "hey", "there" ) [ 1, 7 ]

    ListIs.map2HeadsAndTails Tuple.pair (+)
        (ListIs.fromCons 1 [ 2, 3 ])
       Fillable.empty
    --> Fillable.empty

For matching `head` and `tailElement` types, there's [`map2`](#map2).

-}
map2HeadsAndTails :
    (aHead -> bHead -> combinedHead)
    -> (aTailElement -> bTailElement -> combinedTailElement)
    -> Is emptiableOrFilled ( aHead, List aTailElement )
    -> Is emptiableOrFilled ( bHead, List bTailElement )
    -> Is emptiableOrFilled ( combinedHead, List combinedTailElement )
map2HeadsAndTails combineHeads combineTailElements aList bList =
    Fillable.map2
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
    ->
        Is
            emptiableOrFilled
            ( head, List tailElement )
    ->
        Is
            emptiableOrFilled
            ( head, List mappedTailElement )
mapTail changeTailElement =
    Fillable.map
        (Tuple.mapSecond (List.map changeTailElement))


{-| Apply a function to the head only.

    ListIs.fromCons 1 [ 4, 9 ]
        |> ListIs.mapHead negate
    --> ListIs.fromCons -1 [ 4, 9 ]

-}
mapHead :
    (head -> mappedHead)
    -> Is emptiableOrFilled ( head, tail )
    -> Is emptiableOrFilled ( mappedHead, tail )
mapHead changeHead =
    Fillable.map (Tuple.mapFirst changeHead)


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

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
    -> (element -> acc -> acc)
    -> ListIs emptyOrNot_ element
    -> acc
foldFrom initial direction reduce =
    toList
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the [`ListIs`](#ListIs).

    import LinearDirection exposing (LinearDirection(..))

    ListIs.fromCons 234 [ 345, 543 ]
        |> ListIs.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (tailElement -> acc -> acc)
    -> Is Filled ( acc, List tailElement )
    -> acc
fold direction reduce notEmpty =
    let
        ( head_, tail_ ) =
            notEmpty |> unCons
    in
    List.fold direction reduce head_ tail_


{-| Convert the [`ListIs`](#ListIs) to a `List`.

    ListIs.fromCons 1 [ 7 ]
        |> ListIs.toList
    --> [ 1, 7 ]

-}
toList : ListIs emptiableOrFilled_ element -> List element
toList =
    \list ->
        case list of
            Filled ( head_, tail_ ) ->
                head_ :: tail_

            Empty _ ->
                []


{-| Convert to a non-empty tuple `( head, tail )`.

Currently equivalent to [`filling`](Fillable#filling).

    ListIs.fromCons "hi" [ "there", "👋" ]
        |> ListIs.unCons
    --> ( "hi", [ "there", "👋" ] )

-}
unCons : Is Filled ( head, tail ) -> ( head, tail )
unCons notEmpty =
    notEmpty |> Fillable.filling
