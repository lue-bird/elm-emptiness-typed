module StackIs exposing
    ( StackIs
    , only, topAndDown, topDown
    , top, downBelowTop, length
    , layOnTop
    , shoveDownBelow, shoveDownBelowNotEmpty, concat
    , when, whenJust
    , map, alterTop, alterBelowTop, foldFrom, fold, toTopDown, toTopAndDown
    , map2
    )

{-|

@docs StackIs


## create

@docs only, topAndDown, topDown


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

import Fillable exposing (Emptiable, Filled, Is(..), empty, filled)
import LinearDirection exposing (LinearDirection)
import List.LinearDirection as List


{-| Describes an emptiable or non-empty stack, making it more convenient than any `Nonempty`.


#### in arguments

    top : StackIs Filled element -> element


#### in return values

    where :
        (element -> Bool)
        -> StackIs emptiableOrFilled_ element
        -> StackIs Emptiable element


#### in types

    type alias Model =
        WithoutConstructorFunction
            { clipboard : StackIs Filled String
            , history : StackIs Emptiable Msg
            }

where

    type alias WithoutConstructorFunction record =
        record

stops the compiler from creating a positional constructor function for `Model`.

---

Because

    type alias StackIs emptiableOrFilled element =
        Is
            emptiableOrFilled
            { top : element, down : List element }

we can treat it like a normal [`Fillable.Is`](Fillable#Is):

    import Fillable exposing (Is(..), filled)

    Fillable.empty
        |> ListIs.toList
    --> []

    [ "hi", "there" ]
        |> StackIs.topDown
        |> Fillable.map (filled >> StackIs.top)
    --: Is Emptiable String

    toTopDown : StackIs emptiableOrFilled_ element -> List element
    toTopDown stack =
        case stack of
            Filled parts ->
                parts.top :: parts.downBelowTop

            Empty _ ->
                []

-}
type alias StackIs emptiableOrFilled element =
    Is
        emptiableOrFilled
        { top : element, downBelowTop : List element }


{-| A [`StackIs`](#StackIs) with just 1 element.

    StackIs.only ":)"
    --> StackIs.empty |> StackIs.layOnTop ":)"

-}
only : element -> StackIs filled_ element
only onlyElement =
    topAndDown onlyElement []


{-| A non-empty [`StackIs`](#StackIs) from its top followed by elements below.

    import StackIs exposing (topAndDown, toTopAndDown)

    topAndDown "hi" [ "there", "👋" ]
        |> toTopAndDown
    --> ( "hi", [ "there", "👋" ] )

-}
topAndDown :
    element
    -> List element
    -> StackIs filled_ element
topAndDown head_ tail_ =
    filled { top = head_, downBelowTop = tail_ }


{-| Convert a `List` to a \`StackIs Emptiable

    [] |> StackIs.topDown
    --> StackIs.empty

    [ "hello", "emptiness" ] |> StackIs.topDown
    --> StackIs.topAndDown "hello" [ "emptiness" ]
    --: StackIs Emptiable

When constructing from known elements, always prefer

    StackIs.topAndDown "hello" [ "emptiness" ]

-}
topDown : List element -> StackIs Emptiable element
topDown list_ =
    case list_ of
        [] ->
            empty

        head_ :: tail_ ->
            topAndDown head_ tail_



--


{-| The first value in the [`StackIs`](#StackIs).

    StackIs.only 3
        |> StackIs.layOnTop 2
        |> StackIs.top
    --> 2

-}
top : StackIs Filled element -> element
top notEmpty =
    notEmpty |> Fillable.filling |> .top


{-| Everything after the first value.

    StackIs.only 2
        |> StackIs.layOnTop 3
        |> StackIs.shoveDownBelow (StackIs.topAndDown 1 [ 0 ])
        |> StackIs.downBelowTop
    --> [ 2, 1, 0 ]

-}
downBelowTop : StackIs Filled element -> List element
downBelowTop notEmptyList =
    notEmptyList |> Fillable.filling |> .downBelowTop


{-| How many element there are.

    StackIs.only 3
        |> StackIs.layOnTop 2
        |> StackIs.length
    --> 2

-}
length : Is emptyOrNot_ ( head_, List tailElement_ ) -> Int
length =
    \stack ->
        case stack of
            Filled ( _, tail_ ) ->
                1 + List.length tail_

            Empty _ ->
                0



--


{-| Add an element above the current [`top`](#top).

    StackIs.topAndDown 2 [ 3 ] |> StackIs.layOnTop 1
    --> StackIs.topAndDown 1 [ 2, 3 ]

    StackIs.empty |> StackIs.layOnTop 1
    --> StackIs.only 1

-}
layOnTop :
    element
    -> StackIs emptyOrNot_ element
    -> StackIs filled_ element
layOnTop toPutBeforeAllOtherElements =
    topAndDown toPutBeforeAllOtherElements << toTopDown


{-| Glue the elements of a non-empty [`StackIs`](#StackIs) below a [`StackIs`](#StackIs).

    StackIs.empty
        |> StackIs.shoveDownBelowNotEmpty
            (StackIs.topAndDown 1 [ 2 ])
        |> StackIs.shoveDownBelow
            (StackIs.topAndDown 3 [ 4, 5 ])
    --> StackIs.topAndDown 1 [ 2, 3, 4, 5 ]

Prefer [`shoveDownBelow`](#shoveDownBelow) if the piped [`StackIs`](#StackIs) is already known as non-empty
or if both can be empty.

-}
shoveDownBelowNotEmpty :
    StackIs Filled element
    -> StackIs emptiableOrFilled_ element
    -> StackIs filled_ element
shoveDownBelowNotEmpty nonEmptyToAppend =
    \stack ->
        case stack of
            Empty _ ->
                nonEmptyToAppend |> Fillable.branchableType

            Filled parts ->
                topAndDown
                    parts.top
                    (parts.downBelowTop
                        ++ (nonEmptyToAppend |> toTopDown)
                    )


{-| Glue the elements of a [`StackIs`](#StackIs) below a [`StackIs`](#StackIs).

    StackIs.topAndDown 1 [ 2 ]
        |> StackIs.shoveDownBelow
            (StackIs.topAndDown 3 [ 4 ])
    --> StackIs.topAndDown 1 [ 2, 3, 4 ]

Prefer this over [`shoveDownBelowNotEmpty`](#shoveDownBelowNotEmpty) if the piped [`StackIs`](#StackIs) is already known as non-empty
or if both can be empty.

-}
shoveDownBelow :
    StackIs appendedCanBeEmptyOrNot_ element
    -> StackIs emptiableOrFilled element
    -> StackIs emptiableOrFilled element
shoveDownBelow toAppend =
    \stack ->
        case ( stack, toAppend ) of
            ( Empty is, Empty _ ) ->
                Empty is

            ( Empty _, Filled nonEmptyToAppend ) ->
                filled nonEmptyToAppend

            ( Filled parts, _ ) ->
                topAndDown
                    parts.top
                    (parts.downBelowTop ++ toTopDown toAppend)


{-| Glue together a bunch of [`StackIs`](#StackIs)s.

    StackIs.topAndDown
        (StackIs.topAndDown 0 [ 1 ])
        [ StackIs.topAndDown 10 [ 11 ]
        , StackIs.empty
        , StackIs.topAndDown 20 [ 21, 22 ]
        ]
        |> StackIs.concat
    --> StackIs.topAndDown 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty [`StackIs`](#StackIs), there must be a non-empty amount of non-empty stacks.

-}
concat :
    StackIs
        emptiableOrFilled
        (StackIs emptiableOrFilled element)
    -> StackIs emptiableOrFilled element
concat stackOfStacks =
    case stackOfStacks of
        Empty canBeNothing ->
            Empty canBeNothing

        Filled stacks ->
            case stacks.top of
                Empty canBeNothing ->
                    Empty canBeNothing

                Filled topStack ->
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

    StackIs.topAndDown 1 [ 2, 5, -3, 10 ]
        |> StackIs.when (\x -> x < 5)
    --> StackIs.topAndDown 1 [ 2, -3 ]
    --: StackIs Emptiable number_

-}
when :
    (element -> Bool)
    -> StackIs emptiableOrFilled_ element
    -> StackIs Emptiable element
when isGood =
    topDown << List.filter isGood << toTopDown


{-| Keep all [`filled`](Fillable#filled) and drop all [`empty`](Fillable#empty) elements.

    import Fillable exposing (just, nothing)

    StackIs.topAndDown nothing [ nothing ]
        |> StackIs.whenJust
    --> StackIs.empty

    StackIs.topAndDown (just 1) [ nothing, just 3 ]
        |> StackIs.whenJust
    --> StackIs.topAndDown 1 [ 3 ]

As you can see, if only the top is [`filling`](Fillable#filling) a value, the result is non-empty.

-}
whenJust :
    StackIs
        emptiableOrFilled
        (Is emptiableOrFilled element)
    -> StackIs emptiableOrFilled element
whenJust maybes =
    case maybes of
        Empty emptiableOrFilled ->
            Empty emptiableOrFilled

        Filled parts ->
            case parts.top of
                Empty emptiableOrFilled ->
                    Empty emptiableOrFilled

                Filled top_ ->
                    topAndDown
                        top_
                        (parts.downBelowTop
                            |> List.filterMap Fillable.toMaybe
                        )



--


{-| Apply a function to every element.

    StackIs.topAndDown 1 [ 4, 9 ]
        |> StackIs.map negate
    --> StackIs.topAndDown -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> StackIs emptiableOrFilled aElement
    -> StackIs emptiableOrFilled bElement
map changeElement =
    Fillable.andThen
        (\parts ->
            topAndDown
                (parts.top |> changeElement)
                (parts.downBelowTop |> List.map changeElement)
        )


{-| Combine 2 [`StackIs`](#StackIs)s with a given function.
If one stack is longer, its extra elements are dropped.

    StackIs.map2 (+)
        (StackIs.topAndDown 1 [ 2, 3 ])
        (StackIs.topAndDown 4 [ 5, 6, 7 ])
    --> StackIs.topAndDown 5 [ 7, 9 ]

    StackIs.map2 Tuple.pair
        (StackIs.topAndDown 1 [ 2, 3 ])
        StackIs.empty
    --> StackIs.empty

-}
map2 :
    (aElement -> bElement -> combinedElement)
    -> StackIs emptiableOrFilled aElement
    -> StackIs emptiableOrFilled bElement
    -> StackIs emptiableOrFilled combinedElement
map2 combineAB aStack bStack =
    Fillable.map2
        (\a b ->
            { top = combineAB a.top b.top
            , downBelowTop =
                List.map2 combineAB a.downBelowTop b.downBelowTop
            }
        )
        aStack
        bStack


{-| Apply a function to every element of its downBelowTop.

    StackIs.topAndDown 1 [ 4, 9 ]
        |> StackIs.alterBelowTop negate
    --> StackIs.topAndDown 1 [ -4, -9 ]

-}
alterBelowTop :
    (tailElement -> mappedTailElement)
    -> Is emptiableOrFilled ( top, List tailElement )
    -> Is emptiableOrFilled ( top, List mappedTailElement )
alterBelowTop changeTailElement =
    Fillable.map
        (Tuple.mapSecond (List.map changeTailElement))


{-| Apply a function to the top only.

    StackIs.topAndDown 1 [ 4, 9 ]
        |> StackIs.alterTop negate
    --> StackIs.topAndDown -1 [ 4, 9 ]

-}
alterTop :
    (element -> element)
    -> StackIs emptiableOrFilled element
    -> StackIs emptiableOrFilled element
alterTop changeHead =
    Fillable.map
        (\stack -> { stack | top = stack.top |> changeHead })


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))

    StackIs.topAndDown 'l' [ 'i', 'v', 'e' ]
        |> StackIs.foldFrom "" LastToFirst String.append
    --> "live"

    StackIs.topAndDown 'l' [ 'i', 'v', 'e' ]
        |> StackIs.foldFrom "" FirstToLast String.append
    --> "evil"

-}
foldFrom :
    acc
    -> LinearDirection
    -> (element -> acc -> acc)
    -> StackIs emptyOrNot_ element
    -> acc
foldFrom initial direction reduce =
    toTopDown
        >> List.fold direction reduce initial


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the first value in the [`StackIs`](#StackIs).

    import LinearDirection exposing (LinearDirection(..))

    StackIs.topAndDown 234 [ 345, 543 ]
        |> StackIs.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (element -> element -> element)
    -> StackIs Filled element
    -> element
fold direction reduce notEmpty =
    let
        parts =
            notEmpty |> Fillable.filling
    in
    List.fold direction reduce parts.top parts.downBelowTop


{-| Convert the [`StackIs`](#StackIs) to a `List`.

    StackIs.topAndDown 1 [ 7 ]
        |> StackIs.toTopDown
    --> [ 1, 7 ]

-}
toTopDown : StackIs emptiableOrFilled_ element -> List element
toTopDown =
    \stack ->
        case stack of
            Filled parts ->
                parts.top :: parts.downBelowTop

            Empty _ ->
                []


{-| Convert to a non-empty list tuple `( top, down List )`.

    StackIs.topAndDown "hi" [ "there", "👋" ]
        |> StackIs.toTopAndDown
    --> ( "hi", [ "there", "👋" ] )

-}
toTopAndDown :
    StackIs Filled element
    -> ( element, List element )
toTopAndDown notEmpty =
    let
        parts =
            notEmpty |> Fillable.filling
    in
    ( parts.top, parts.downBelowTop )
