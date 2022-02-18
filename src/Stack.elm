module Stack exposing
    ( StackFilled, StackWithTop
    , only, topAndBelow, fromTopAndBelow, fromList
    , top, length
    , addOnTop, removeTop, reverse
    , when, whenFilled
    , stackOnTop, stackTypedOnTop, concat
    , map, mapTop, mapBelowTop, foldFrom, fold, toList, splitTop, toTopAndBelow
    , map2, map2TopAndDown
    )

{-| An **emptiable or non-empty** data structure where [`top`](#top), [`removeTop`](#removeTop), [`addOnTop`](#addOnTop) [`mapTop`](#mapTop) are `O(n)`.

@docs StackFilled, StackWithTop


## create

[`Fillable.empty`](Fillable#empty) to create an `Empty Possibly` stack.

@docs only, topAndBelow, fromTopAndBelow, fromList


## scan

@docs top, length


## modify

@docs addOnTop, removeTop, reverse


### filter

@docs when, whenFilled


## glue

@docs stackOnTop, stackTypedOnTop, concat


## transform

@docs map, mapTop, mapBelowTop, foldFrom, fold, toList, splitTop, toTopAndBelow
@docs map2, map2TopAndDown

-}

import Fillable exposing (Empty(..), empty, filled, filling)
import LinearDirection exposing (LinearDirection)
import List.Linear
import Possibly exposing (Possibly)


{-| An **emptiable or non-empty** data structure where [`top`](#top), [`removeTop`](#removeTop), [`addOnTop`](#addOnTop) [`mapTop`](#mapTop) are `O(n)`


#### in arguments

[`Empty`](Fillable#Empty) `Never` → non-empty stack:

    top : Empty Never (StackFilled element) -> element


#### in results

[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) [`Empty`](Fillable#Empty) → stack could be empty

    fromList : List element -> Empty Possibly (StackFilled element)

We can treat it like any [`Fillable.Empty`](Fillable#Empty):

    import Fillable exposing (filled, Empty(..))
    import Possibly exposing (Possibly)
    import Stack exposing (StackFilled, top)

    Fillable.empty : Stack Possibly element_ -- fine

    [ "hi", "there" ] -- comes in as an argument
        |> Stack.fromList
        |> Fillable.map (filled >> top)
    --: Empty String Possibly

    toList : Empty possiblyOrNever_ (StackFilled element) -> List element
    toList =
        \stack ->
            case stack of
                Filled ( top_, belowTop_ ) ->
                    top_ :: belowTop_

                Empty _ ->
                    []

Most operations also allow a different type for the top element → see [`StackWithTop`](#StackWithTop)

-}
type alias StackFilled element =
    StackWithTop element element


{-| [`StackFilled`](#StackFilled) with a different type for the top element:

    top : Empty Never (StackWithTop top belowTopElement_) -> top

it's the result of:

  - [`only`](#only)
  - [`topAndBelow`](#topAndBelow)
  - [`fromTopAndBelow`](#fromTopAndBelow)
  - [`addOnTop`](#addOnTop)
  - [`mapTop`](#mapTop)
  - [`map2TopAndDown`](#map2TopAndDown)

-}
type alias StackWithTop topElement belowTopElement =
    ( topElement, List belowTopElement )


{-| A stack with just 1 single element.

    import Fillable
    import Stack exposing (addOnTop)

    Stack.only ":)"
    --> Fillable.empty |> addOnTop ":)"

-}
only : top -> Empty never_ (StackWithTop top belowTopElement_)
only onlyElement =
    topAndBelow onlyElement []


{-| Convert from a tuple `( top, List belowElement )`.

Currently equivalent to [`filled`](Fillable#filled).

-}
fromTopAndBelow :
    ( top, List belowElement )
    -> Empty never_ (StackWithTop top belowElement)
fromTopAndBelow topAndTailTuple =
    filled topAndTailTuple


{-| A stack from a top element and a `List` of elements below going down.
-}
topAndBelow :
    top
    -> List belowElement
    -> Empty never_ (StackWithTop top belowElement)
topAndBelow top_ belowTop_ =
    fromTopAndBelow ( top_, belowTop_ )


{-| Convert a `List element` to a `Empty Possibly (StackFilled element)`.
The `List`s `head` becomes [`top`](#top), its `tail` is shoved down below.

    import Possibly exposing (Possibly)
    import Fillable
    import Stack exposing (topAndBelow)

    [] |> Stack.fromList
    --> Fillable.empty

    [ "hello", "emptiness" ] |> Stack.fromList
    --> topAndBelow "hello" [ "emptiness" ]
    --: Empty Possibly (StackFilled String)

When constructing from known elements, always prefer

    import Stack exposing (topAndBelow)

    topAndBelow "hello" [ "emptiness" ]

-}
fromList : List element -> Empty Possibly (StackFilled element)
fromList list =
    case list of
        [] ->
            empty

        top_ :: belowTop_ ->
            topAndBelow top_ belowTop_



--


{-| The first value.

    import Stack exposing (top, addOnTop)

    Stack.only 3
        |> addOnTop 2
        |> top
    --> 2

-}
top : Empty Never (StackWithTop top belowTop_) -> top
top filled =
    filled |> toTopAndBelow |> Tuple.first


{-| How many element there are.

    import Stack exposing (addOnTop)

    Stack.only 3
        |> addOnTop 2
        |> Stack.length
    --> 2

-}
length :
    Empty possiblyOrNever_ (StackWithTop top_ belowElement_)
    -> Int
length =
    \stack ->
        case stack of
            Filled ( _, belowTop_ ) ->
                1 + List.length belowTop_

            Empty _ ->
                0



--


{-| Add an element to the front.

    import Fillable
    import Stack exposing (topAndBelow, addOnTop)

    topAndBelow 2 [ 3 ] |> addOnTop 1
    --> topAndBelow 1 [ 2, 3 ]

    Fillable.empty |> addOnTop 1
    --> Stack.only 1

-}
addOnTop :
    newTop
    -> Empty possiblyOrNever_ (StackFilled belowElement)
    -> Empty never_ (StackWithTop newTop belowElement)
addOnTop toPutBeforeAllOtherElements =
    topAndBelow toPutBeforeAllOtherElements << toList


{-| Everything after the first value.

    import Stack exposing (topAndBelow, addOnTop, stackOnTop, removeTop)

    Stack.only 2
        |> addOnTop 3
        |> stackOnTop (topAndBelow 1 [ 0 ])
        |> removeTop
    --> topAndBelow 0 [ 3, 2 ]
    --: Empty Possibly (StackFilled number_)

-}
removeTop :
    Empty Never (StackWithTop top_ belowElement)
    -> Empty Possibly (StackFilled belowElement)
removeTop stackFilled =
    stackFilled
        |> filling
        |> Tuple.second
        |> fromList


{-| Flip the order of the elements.

    import Stack exposing (topAndBelow)

    topAndBelow "l" [ "i", "v", "e" ]
        |> Stack.reverse
    --> topAndBelow "e" [ "v", "i", "l" ]

-}
reverse :
    Empty possiblyOrNever (StackFilled element)
    -> Empty possiblyOrNever (StackFilled element)
reverse =
    \stack ->
        stack
            |> Fillable.map
                (\( top_, below_ ) ->
                    case (top_ :: below_) |> List.reverse of
                        previousLast :: previousBeforeLastToTop ->
                            ( previousLast, previousBeforeLastToTop )

                        -- doesnt happen
                        [] ->
                            ( top_, [] )
                )


{-| Glue the elements of an `Empty possiblyOrNever`/`Never` [`Stack`](#StackFilled) to the end of a [`Stack`](#StackFilled).

    import Fillable
    import Stack exposing (topAndBelow, stackOnTop, stackTypedOnTop)

    Fillable.empty
        |> stackTypedOnTop
            (topAndBelow 1 [ 2 ])
        |> stackOnTop
            (topAndBelow -2 [ -1, 0 ])
    --> topAndBelow -2 [ -1, 0, 1, 2 ]

Prefer [`stackOnTop`](#stackOnTop) if the piped stack is already known as non-empty
or if both are `Possibly`.

-}
stackTypedOnTop :
    Empty possiblyOrNever (StackWithTop newTop element)
    -> Empty inPossiblyOrNever_ (StackFilled element)
    -> Empty possiblyOrNever (StackWithTop newTop element)
stackTypedOnTop stackFilledToPutOnTop =
    \stack ->
        stackFilledToPutOnTop
            |> Fillable.map
                (\( appendedTop, appendedDown ) ->
                    ( appendedTop, appendedDown ++ (stack |> toList) )
                )


{-| Glue the elements of a stack to the end of another stack.

    import Stack exposing (topAndBelow, stackOnTop)

    topAndBelow 1 [ 2 ]
        |> stackOnTop (topAndBelow -1 [ 0 ])
    --> topAndBelow -1 [ 0, 1, 2 ]

Prefer this over [`stackOnTopFilled`](#stackOnTopFilled) if the piped stack is already known as non-empty
or if both can be empty.

-}
stackOnTop :
    Empty appendedPossiblyOrNever_ (StackFilled element)
    -> Empty possiblyOrNever (StackFilled element)
    -> Empty possiblyOrNever (StackFilled element)
stackOnTop stackToPutOnTop =
    \stack ->
        case ( stackToPutOnTop, stack ) of
            ( Empty _, Empty possiblyOrNever ) ->
                Empty possiblyOrNever

            ( Empty _, Filled stackFilled ) ->
                stackFilled |> fromTopAndBelow

            ( Filled ( top_, belowTop_ ), stackToPutBelow ) ->
                topAndBelow
                    top_
                    (belowTop_ ++ (stackToPutBelow |> toList))


{-| Glue together a bunch of stacks.

    import Fillable
    import Stack exposing (topAndBelow)

    topAndBelow
        (topAndBelow 0 [ 1 ])
        [ topAndBelow 10 [ 11 ]
        , Fillable.empty
        , topAndBelow 20 [ 21, 22 ]
        ]
        |> Stack.concat
    --> topAndBelow 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty stack, there must be a non-empty [`top`](#top) stack.

-}
concat :
    Empty
        possiblyOrNever
        (StackWithTop
            (Empty possiblyOrNever (StackFilled element))
            (Empty belowTopListsPossiblyOrNever_ (StackFilled element))
        )
    -> Empty possiblyOrNever (StackFilled element)
concat stackOfStacks =
    stackOfStacks
        |> Fillable.andThen
            (\( topList, belowTopLists ) ->
                belowTopLists
                    |> List.concatMap toList
                    |> fromList
                    |> stackTypedOnTop topList
            )



--


{-| Keep elements that satisfy a test.

    import Stack exposing (topAndBelow)

    topAndBelow 1 [ 2, 5, -3, 10 ]
        |> Stack.when (\x -> x < 5)
    --> topAndBelow 1 [ 2, -3 ]
    --: Empty Possibly (StackFilled number_)

-}
when :
    (element -> Bool)
    -> Empty possiblyOrNever_ (StackFilled element)
    -> Empty Possibly (StackFilled element)
when isGood =
    fromList << List.filter isGood << toList


{-| Keep all [`filled`](Fillable#filled) values and drop all [`empty`](Fillable#empty) elements.

    import Fillable exposing (filled)
    import Stack exposing (topAndBelow)

    topAndBelow Fillable.empty [ Fillable.empty ]
        |> Stack.whenFilled
    --> Fillable.empty

    topAndBelow (filled 1) [ Fillable.empty, filled 3 ]
        |> Stack.whenFilled
    --> topAndBelow 1 [ 3 ]

As you can see, if only the top is [`filling`](Fillable#filling) a value, the result is non-empty.

-}
whenFilled :
    Empty
        possiblyOrNever
        (StackWithTop
            (Empty possiblyOrNever topValue)
            (Empty possiblyOrNever belowTopElementValue)
        )
    ->
        Empty
            possiblyOrNever
            (StackWithTop topValue belowTopElementValue)
whenFilled maybes =
    maybes
        |> Fillable.andThen
            (\( top_, belowTop_ ) ->
                top_
                    |> Fillable.andThen
                        (\topValue ->
                            topAndBelow topValue
                                (belowTop_ |> List.filterMap Fillable.toMaybe)
                        )
            )



--


{-| Apply a function to every element.

    import Stack exposing (topAndBelow)

    topAndBelow 1 [ 4, 9 ]
        |> Stack.map negate
    --> topAndBelow -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> Empty possiblyOrNever (StackFilled aElement)
    -> Empty possiblyOrNever (StackFilled bElement)
map changeElement =
    Fillable.map
        (Tuple.mapBoth changeElement (List.map changeElement))


{-| Combine every element in 2 stacks with a given function.
If one stack is longer, its extra elements are dropped.

    import Fillable
    import Stack exposing (topAndBelow)

    Stack.map2 (+)
        (topAndBelow 1 [ 2, 3 ])
        (topAndBelow 4 [ 5, 6, 7 ])
    --> topAndBelow 5 [ 7, 9 ]

    Stack.map2 Tuple.pair
        (topAndBelow 1 [ 2, 3 ])
       Fillable.empty
    --> Fillable.empty

For [`StackWithTop top belowTopElement`](#StackWithTop) where `top` and `belowTopElement` have a different type,
there's [`map2TopAndDown`](#map2TopAndDown).

-}
map2 :
    (aElement -> bElement -> combinedElement)
    -> Empty possiblyOrNever (StackFilled aElement)
    -> Empty possiblyOrNever (StackFilled bElement)
    -> Empty possiblyOrNever (StackFilled combinedElement)
map2 combineAB aStack bStack =
    map2TopAndDown combineAB combineAB aStack bStack


{-| Combine the top and below elements of 2 stacks using given functions.
If one stack is longer, its extra elements are dropped.

    import Fillable
    import Stack exposing (topAndBelow, map2TopAndDown)

    map2TopAndDown Tuple.pair (+)
        (topAndBelow "hey" [ 0, 1 ])
        (topAndBelow "there" [ 1, 6, 7 ])
    --> topAndBelow ( "hey", "there" ) [ 1, 7 ]

    map2TopAndDown Tuple.pair (+)
        (topAndBelow 1 [ 2, 3 ])
       Fillable.empty
    --> Fillable.empty

Use [`map2`](#map2) if [`top`](#top) and `belowElement` types match.

-}
map2TopAndDown :
    (aTop -> bTop -> topCombined)
    -> (aBelowElement -> bBelowElement -> belowElementCombined)
    -> Empty possiblyOrNever (StackWithTop aTop aBelowElement)
    -> Empty possiblyOrNever (StackWithTop bTop bBelowElement)
    -> Empty possiblyOrNever (StackWithTop topCombined belowElementCombined)
map2TopAndDown combineHeads combineTailElements aList bList =
    Fillable.map2
        (\( aHead, aTail ) ( bHead, bTail ) ->
            ( combineHeads aHead bHead
            , List.map2 combineTailElements aTail bTail
            )
        )
        aList
        bList


{-| Apply a function to every element of its removeTop.

    import Stack exposing (topAndBelow, mapBelowTop)

    topAndBelow 1 [ 4, 9 ]
        |> mapBelowTop negate
    --> topAndBelow 1 [ -4, -9 ]

-}
mapBelowTop :
    (belowElement -> belowElementMapped)
    ->
        Empty
            possiblyOrNever
            (StackWithTop top belowElement)
    ->
        Empty
            possiblyOrNever
            (StackWithTop top belowElementMapped)
mapBelowTop changeTailElement =
    Fillable.map
        (Tuple.mapSecond (List.map changeTailElement))


{-| Change the [`top`](#top) element based on its current value.
Its type is allowed to change.

    import Stack exposing (topAndBelow, mapTop)

    topAndBelow 1 [ 4, 9 ]
        |> mapTop negate
    --> topAndBelow -1 [ 4, 9 ]

-}
mapTop :
    (top -> topMapped)
    -> Empty possiblyOrNever (StackWithTop top belowElement)
    -> Empty possiblyOrNever (StackWithTop topMapped belowElement)
mapTop changeTop =
    Fillable.map (Tuple.mapFirst changeTop)


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))
    import Stack exposing (topAndBelow)

    topAndBelow 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" LastToFirst String.cons
    --> "live"

    topAndBelow 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" FirstToLast String.cons
    --> "evil"

-}
foldFrom :
    accumulationValue
    -> LinearDirection
    -> (element -> accumulationValue -> accumulationValue)
    -> Empty possiblyOrNever_ (StackFilled element)
    -> accumulationValue
foldFrom initialAccumulationValue direction reduce =
    toList
        >> List.Linear.foldFrom initialAccumulationValue direction reduce


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the [`top`](#top).

    import LinearDirection exposing (LinearDirection(..))
    import Stack exposing (topAndBelow)

    topAndBelow 234 [ 345, 543 ]
        |> Stack.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (belowTopElement -> top -> top)
    -> Empty Never (StackWithTop top belowTopElement)
    -> top
fold direction reduce filledStack =
    let
        ( top_, belowTop_ ) =
            filledStack |> toTopAndBelow
    in
    List.Linear.foldFrom top_ direction reduce belowTop_


{-| Convert it to a `List`.

    import Stack exposing (topAndBelow)

    topAndBelow 1 [ 7 ] |> Stack.toList
    --> [ 1, 7 ]

-}
toList :
    Empty possiblyOrNever_ (StackFilled element)
    -> List element
toList =
    \stack ->
        case stack of
            Filled ( top_, belowTop_ ) ->
                top_ :: belowTop_

            Empty _ ->
                []


{-| Convert to a non-empty list tuple `( top, List belowElement )`.

Currently equivalent to [`filling`](Fillable#filling).

    import Stack exposing (topAndBelow, toTopAndBelow)

    topAndBelow "hi" [ "there", "👋" ]
        |> toTopAndBelow
    --> ( "hi", [ "there", "👋" ] )

-}
toTopAndBelow :
    Empty Never (StackWithTop top belowElement)
    -> ( top, List belowElement )
toTopAndBelow filledStack =
    filledStack |> filling


{-| Convert to a non-empty list tuple `( top, List belowElement )`.

Currently equivalent to [`filling`](Fillable#filling).

    import Stack exposing (StackFilled, topAndBelow, splitTop)

    topAndBelow "hi" [ "there", "👋" ]
        |> splitTop
    --> ( "hi", topAndBelow "there" [ "👋" ] )
    --: ( String, Empty Possibly (StackFilled String) )

-}
splitTop :
    Empty Never (StackWithTop top belowElement)
    -> ( top, Empty Possibly (StackFilled belowElement) )
splitTop filledStack =
    let
        ( topElement, belowList ) =
            filledStack |> filling
    in
    ( topElement, belowList |> fromList )
