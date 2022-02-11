module StackThat exposing
    ( StackThat, Empty
    , empty, only, topAndDown, topDown
    , top, downBelowTop, length
    , layOnTop
    , shoveDownBelow, shoveDownBelowNotEmpty, concat
    , when, whenJust
    , map, alterTop, alterBelowTop, foldFrom, fold, toTopDown, toTopAndDown
    , map2
    )

{-|


## types

@docs StackThat, Empty


## create

@docs empty, only, topAndDown, topDown


## scan

@docs top, downBelowTop, length


## modify

@docs layOnTop


## glue

@docs shoveDownBelow, shoveDownBelowNotEmpty, concat


### filter

@docs when, whenJust


## transform

@docs map, alterTop, alterBelowTop, foldFrom, fold, toTopDown, toTopAndDown
@docs map2

-}

import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List
import MaybeThat exposing (Be, Can, CanBe, Isnt, MaybeThat(..), just, nothing)


{-| Describes an emptiable or non-empty stack, making it more convenient than any `Nonempty`.

`(`[`Isnt`](MaybeThat#Isnt) [`Empty`](#Empty)`)` can be used to require a non-empty stack as an argument:

    top : StackThat (Isnt Empty) element -> element

[`StackThat`](#StackThat) is equivalent to a [`MaybeThat`](MaybeThat) of a top-down non-empty list

    MaybeThat
        canBeEmptyOrNot
        { top = element, down = List element }

so we can treat it like a normal [`MaybeThat`](MaybeThat):

    import MaybeThat exposing (MaybeThat(..))

    StackThat.empty
    --> MaybeThat.nothing

    [ ... ]
        |> StackThat.topDown
        |> MaybeThat.map StackThat.top
    --: MaybeThat (CanBe nothing_ ()) head_

    toTopDown : StackThat canBeEmptyOrNot_ element -> List element
    toTopDown stack =
        case stack of
            JustThat parts ->
                parts.top :: parts.downBelowTop

            NothingThat _ ->
                []

-}
type alias StackThat canItBeEmpty element =
    MaybeThat
        canItBeEmpty
        { top : element, downBelowTop : List element }


{-| Type tag:

    top : StackThat (Isnt Empty) element -> element

Use it when describing a [`StackThat`](#StackThat) in a `type`/`type alias`:

    type alias Model =
        WithoutConstructorFunction
            { clipboard : StackThat (Isnt Empty) String
            , history : StackThat (CanBe Empty) Msg
            }

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

-}
type Empty
    = Empty Never


{-| A [`StackThat`](#StackThat) without elements.

[`MaybeThat.nothing`](MaybeThat#nothing) will also work.

-}
empty : StackThat (CanBe empty_) element_
empty =
    nothing


{-| A [`StackThat`](#StackThat) with just 1 element.

    StackThat.only ":)"
    --> StackThat.empty |> StackThat.layOnTop ":)"

-}
only : element -> StackThat isntEmpty_ element
only onlyElement =
    topAndDown onlyElement []


{-| A non-empty [`StackThat`](#StackThat) from its top followed by elements below.

    import StackThat exposing (topAndDown, toTopAndDown)

    topAndDown "hi" [ "there", "👋" ]
        |> toTopAndDown
    --> ( "hi", [ "there", "👋" ] )

-}
topAndDown :
    element
    -> List element
    -> StackThat isntEmpty_ element
topAndDown head_ tail_ =
    just { top = head_, downBelowTop = tail_ }


{-| Convert a `List` to a `StackThat (CanBe empty_ ())`.

    [] |> StackThat.topDown
    --> StackThat.empty

    [ "hello", "emptiness" ] |> StackThat.topDown
    --> StackThat.topAndDown "hello" [ "emptiness" ]
    --: StackThat (CanBe empty_ ()) String

When constructing from known elements, always prefer

    StackThat.topAndDown "hello" [ "emptiness" ]

-}
topDown : List element -> StackThat (CanBe empty_) element
topDown list_ =
    case list_ of
        [] ->
            empty

        head_ :: tail_ ->
            topAndDown head_ tail_



--


{-| The first value in the [`StackThat`](#StackThat).

    StackThat.only 3
        |> StackThat.layOnTop 2
        |> StackThat.top
    --> 2

-}
top : StackThat (Isnt empty_) element -> element
top notEmpty =
    notEmpty |> MaybeThat.value |> .top


{-| Everything after the first value.

    StackThat.only 2
        |> StackThat.layOnTop 3
        |> StackThat.shoveDownBelow (StackThat.topAndDown 1 [ 0 ])
        |> StackThat.downBelowTop
    --> [ 2, 1, 0 ]

-}
downBelowTop : StackThat (Isnt empty_) element -> List element
downBelowTop notEmptyList =
    notEmptyList |> MaybeThat.value |> .downBelowTop


{-| How many element there are.

    StackThat.only 3
        |> StackThat.layOnTop 2
        |> StackThat.length
    --> 2

-}
length : MaybeThat emptyOrNot_ ( head_, List tailElement_ ) -> Int
length =
    \stack ->
        case stack of
            JustThat ( _, tail_ ) ->
                1 + List.length tail_

            NothingThat _ ->
                0



--


{-| Add an element above the current [`top`](#top).

    StackThat.topAndDown 2 [ 3 ] |> StackThat.layOnTop 1
    --> StackThat.topAndDown 1 [ 2, 3 ]

    StackThat.empty |> StackThat.layOnTop 1
    --> StackThat.only 1

-}
layOnTop :
    element
    -> StackThat emptyOrNot_ element
    -> StackThat isntEmpty_ element
layOnTop toPutBeforeAllOtherElements =
    topAndDown toPutBeforeAllOtherElements << toTopDown


{-| Glue the elements of a non-empty [`StackThat`](#StackThat) below a [`StackThat`](#StackThat).

    StackThat.empty
        |> StackThat.shoveDownBelowNotEmpty
            (StackThat.topAndDown 1 [ 2 ])
        |> StackThat.shoveDownBelow
            (StackThat.topAndDown 3 [ 4, 5 ])
    --> StackThat.topAndDown 1 [ 2, 3, 4, 5 ]

Prefer [`shoveDownBelow`](#shoveDownBelow) if the piped [`StackThat`](#StackThat) is already known as non-empty
or if both can be empty.

-}
shoveDownBelowNotEmpty :
    StackThat (Isnt empty_) element
    -> StackThat canBeEmptyOrNot_ element
    -> StackThat isntEmpty_ element
shoveDownBelowNotEmpty nonEmptyToAppend =
    \stack ->
        case stack of
            NothingThat _ ->
                nonEmptyToAppend |> MaybeThat.branchableType

            JustThat parts ->
                topAndDown
                    parts.top
                    (parts.downBelowTop
                        ++ (nonEmptyToAppend |> toTopDown)
                    )


{-| Glue the elements of a [`StackThat`](#StackThat) below a [`StackThat`](#StackThat).

    StackThat.topAndDown 1 [ 2 ]
        |> StackThat.shoveDownBelow
            (StackThat.topAndDown 3 [ 4 ])
    --> StackThat.topAndDown 1 [ 2, 3, 4 ]

Prefer this over [`shoveDownBelowNotEmpty`](#shoveDownBelowNotEmpty) if the piped [`StackThat`](#StackThat) is already known as non-empty
or if both can be empty.

-}
shoveDownBelow :
    StackThat appendedCanBeEmptyOrNot_ element
    -> StackThat canBeEmptyOrNot element
    -> StackThat canBeEmptyOrNot element
shoveDownBelow toAppend =
    \stack ->
        case ( stack, toAppend ) of
            ( NothingThat is, NothingThat _ ) ->
                NothingThat is

            ( NothingThat _, JustThat nonEmptyToAppend ) ->
                just nonEmptyToAppend

            ( JustThat parts, _ ) ->
                topAndDown
                    parts.top
                    (parts.downBelowTop ++ toTopDown toAppend)


{-| Glue together a bunch of [`StackThat`](#StackThat)s.

    StackThat.topAndDown
        (StackThat.topAndDown 0 [ 1 ])
        [ StackThat.topAndDown 10 [ 11 ]
        , StackThat.empty
        , StackThat.topAndDown 20 [ 21, 22 ]
        ]
        |> StackThat.concat
    --> StackThat.topAndDown 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty [`StackThat`](#StackThat), there must be a non-empty amount of non-empty stacks.

-}
concat :
    StackThat
        canBeEmptyOrNot
        (StackThat canBeEmptyOrNot element)
    -> StackThat canBeEmptyOrNot element
concat stackOfStacks =
    case stackOfStacks of
        NothingThat canBeNothing ->
            NothingThat canBeNothing

        JustThat stacks ->
            case stacks.top of
                NothingThat canBeNothing ->
                    NothingThat canBeNothing

                JustThat topStack ->
                    topAndDown
                        topStack.top
                        (topStack.downBelowTop
                            ++ (topStack.downBelowTop
                                    ++ (stacks.downBelowTop
                                            |> List.concatMap toTopDown
                                       )
                               )
                        )



--


{-| Keep elements that satisfy a test.

    StackThat.topAndDown 1 [ 2, 5, -3, 10 ]
        |> StackThat.when (\x -> x < 5)
    --> StackThat.topAndDown 1 [ 2, -3 ]
    --: StackThat (CanBe empty_) number_

-}
when :
    (element -> Bool)
    -> StackThat canBeEmpty_ element
    -> StackThat (CanBe filteredEmpty_) element
when isGood =
    topDown << List.filter isGood << toTopDown


{-| Keep all `just` values and drop all [`nothing`](MaybeThat#nothing)s.

    import MaybeThat exposing (just, nothing)

    StackThat.topAndDown nothing [ nothing ]
        |> StackThat.whenJust
    --> StackThat.empty

    StackThat.topAndDown (just 1) [ nothing, just 3 ]
        |> StackThat.whenJust
    --> StackThat.topAndDown 1 [ 3 ]

As you can see, if only the top is [`just`](MaybeThat#just) a value, the result is non-empty.

-}
whenJust :
    StackThat
        canBeEmptyOrNot
        (MaybeThat canBeEmptyOrNot element)
    -> StackThat canBeEmptyOrNot element
whenJust maybes =
    case maybes of
        NothingThat canBeEmptyOrNot ->
            NothingThat canBeEmptyOrNot

        JustThat parts ->
            case parts.top of
                NothingThat canBeEmptyOrNot ->
                    NothingThat canBeEmptyOrNot

                JustThat top_ ->
                    topAndDown
                        top_
                        (parts.downBelowTop
                            |> List.filterMap MaybeThat.toMaybe
                        )



--


{-| Apply a function to every element.

    StackThat.topAndDown 1 [ 4, 9 ]
        |> StackThat.map negate
    --> StackThat.topAndDown -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> StackThat (Can possiblyOrNever Be empty_) aElement
    -> StackThat (Can possiblyOrNever Be mappedEmpty_) bElement
map changeElement =
    MaybeThat.andThen
        (\parts ->
            topAndDown
                (parts.top |> changeElement)
                (parts.downBelowTop |> List.map changeElement)
        )


{-| Combine 2 [`StackThat`](#StackThat)s with a given function.
If one stack is longer, its extra elements are dropped.

    StackThat.map2 (+)
        (StackThat.topAndDown 1 [ 2, 3 ])
        (StackThat.topAndDown 4 [ 5, 6, 7 ])
    --> StackThat.topAndDown 5 [ 7, 9 ]

    StackThat.map2 Tuple.pair
        (StackThat.topAndDown 1 [ 2, 3 ])
        StackThat.empty
    --> StackThat.empty

-}
map2 :
    (aElement -> bElement -> combinedElement)
    -> StackThat (Can possiblyOrNever Be aEmpty_) aElement
    -> StackThat (Can possiblyOrNever Be bEmpty_) bElement
    -> StackThat (Can possiblyOrNever Be combinedEmpty_) combinedElement
map2 combineAB aStack bStack =
    MaybeThat.map2
        (\a b ->
            { top = combineAB a.top b.top
            , downBelowTop =
                List.map2 combineAB a.downBelowTop b.downBelowTop
            }
        )
        aStack
        bStack


{-| Apply a function to every element of its downBelowTop.

    StackThat.topAndDown 1 [ 4, 9 ]
        |> StackThat.alterBelowTop negate
    --> StackThat.topAndDown 1 [ -4, -9 ]

-}
alterBelowTop :
    (tailElement -> mappedTailElement)
    -> MaybeThat (Can possiblyOrNever Be empty_) ( top, List tailElement )
    -> MaybeThat (Can possiblyOrNever Be mappedEmpty_) ( top, List mappedTailElement )
alterBelowTop changeTailElement =
    MaybeThat.map
        (Tuple.mapSecond (List.map changeTailElement))


{-| Apply a function to the top only.

    StackThat.topAndDown 1 [ 4, 9 ]
        |> StackThat.alterTop negate
    --> StackThat.topAndDown -1 [ 4, 9 ]

-}
alterTop :
    (element -> element)
    -> StackThat (Can possiblyOrNever Be empty_) element
    -> StackThat (Can possiblyOrNever Be mappedEmpty_) element
alterTop changeHead =
    MaybeThat.map
        (\stack -> { stack | top = stack.top |> changeHead })


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    StackThat.topAndDown 'l' [ 'i', 'v', 'e' ]
        |> StackThat.foldFrom "" LastToFirst String.layOnTop
    --> "live"

    StackThat.topAndDown 'l' [ 'i', 'v', 'e' ]
        |> StackThat.foldFrom "" FirstToLast String.layOnTop
    --> "evil"

-}
foldFrom :
    acc
    -> LinearDirection
    -> (element -> acc -> acc)
    -> StackThat emptyOrNot_ element
    -> acc
foldFrom initial direction reduce =
    toTopDown
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the [`StackThat`](#StackThat).

    import LinearDirection exposing (LinearDirection(..))

    StackThat.topAndDown 234 [ 345, 543 ]
        |> StackThat.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (element -> element -> element)
    -> StackThat (Isnt empty_) element
    -> element
fold direction reduce notEmpty =
    let
        parts =
            notEmpty |> MaybeThat.value
    in
    List.fold direction reduce parts.top parts.downBelowTop


{-| Convert the [`StackThat`](#StackThat) to a `List`.

    StackThat.topAndDown 1 [ 7 ]
        |> StackThat.toTopDown
    --> [ 1, 7 ]

-}
toTopDown : StackThat canBeEmptyOrNot_ element -> List element
toTopDown =
    \stack ->
        case stack of
            JustThat parts ->
                parts.top :: parts.downBelowTop

            NothingThat _ ->
                []


{-| Convert to a non-empty list tuple `( top, down List )`.

    StackThat.topAndDown "hi" [ "there", "👋" ]
        |> StackThat.toTopAndDown
    --> ( "hi", [ "there", "👋" ] )

-}
toTopAndDown :
    StackThat (Isnt empty_) element
    -> ( element, List element )
toTopAndDown notEmpty =
    let
        parts =
            notEmpty |> MaybeThat.value
    in
    ( parts.top, parts.downBelowTop )
