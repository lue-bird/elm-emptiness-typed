module Stack exposing
    ( Stacked, StackTopBelow(..)
    , only, topDown, fromTopDown, fromList
    , top, length
    , layOnTop, removeTop
    , reverse
    , when, whenFilled
    , glueOnTop, stackOnTop, stackOnTopTyped
    , flatten
    , map, mapTop, mapBelowTop
    , foldFrom, fold
    , toList, toTopDown
    )

{-| An **emptiable or non-empty** data structure where [`top`](#top), [`removeTop`](#removeTop), [`layOnTop`](#layOnTop) [`mapTop`](#mapTop) are `O(n)`.

@docs Stacked, StackTopBelow


## create

[`Hand.empty`](Hand#empty) to create an `Empty Possibly` stack.

@docs only, topDown, fromTopDown, fromList


## scan

@docs top, length

[`removeTop`](#removeTop) brings out everything below the [`top`](#top).


## alter

@docs layOnTop, removeTop
@docs reverse


### filter

@docs when, whenFilled


### glue

@docs glueOnTop, stackOnTop, stackOnTopTyped
@docs flatten


## transform

@docs map, mapTop, mapBelowTop
@docs foldFrom, fold
@docs toList, toTopDown

-}

import Hand exposing (Empty, Hand(..), empty, fillMapFlat, filled)
import LinearDirection exposing (LinearDirection)
import List.Linear
import Possibly exposing (Possibly)


{-| A non-empty representation of a stack. [`top`](#top), [`removeTop`](#removeTop), [`layOnTop`](#layOnTop) [`mapTop`](#mapTop) are `O(n)`


#### in arguments

[`Hand`](Hand) `(StackFilled ...) Never Empty` → `stack` is non-empty:

    top : Hand (Stacked element) Never -> element


#### in results

[`Hand`](Hand) `(StackFilled ...)`[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `Empty` → stack could be empty

    fromList : List element -> Hand (Stacked element) Possibly Empty

We can treat it like any [`Hand`](Hand):

    import Hand exposing (Hand(..), Empty, filled, fillMap)
    import Possibly exposing (Possibly)
    import Stack exposing (Stacked, top, layOnTop)

    Hand.empty |> layOnTop "cherry" -- works

    toList : Empty possiblyOrNever_ (Stacked element) -> List element
    toList =
        \stack ->
            case stack of
                Filled (Stack.TopDown top_ down) ->
                    top_ :: down

                Empty _ ->
                    []

    [ "hi", "there" ] -- comes in as an argument
        |> Stack.fromList
        |> fillMap (filled >> top)
    --: Hand String Possibly Empty

Most operations also allow a different type for the top element → see [`StackTopBelow`](#StackTopBelow)

-}
type alias Stacked element =
    StackTopBelow element element


{-| [`Stacked`](#Stacked) with a different type for the top element:

    top : Hand (StackTopBelow top belowTopElement_) Never Empty -> top

it's the result of:

  - [`only`](#only)
  - [`topDown`](#topDown)
  - [`fromTopDown`](#fromTopDown)
  - [`layOnTop`](#layOnTop)
  - [`mapTop`](#mapTop)

-}
type StackTopBelow topElement belowTopElement
    = TopDown topElement (List belowTopElement)


{-| A stack with just 1 single element.

    import Hand
    import Stack exposing (layOnTop)

    Stack.only ":)"
    --> Hand.empty |> layOnTop ":)"

-}
only : top -> Hand (StackTopBelow top belowTopElement_) never_ Empty
only onlyElement =
    topDown onlyElement []


{-| A stack from a top element and a `List` of elements below going down.
-}
topDown :
    top
    -> List belowElement
    -> Hand (StackTopBelow top belowElement) never_ Empty
topDown top_ belowTop_ =
    TopDown top_ belowTop_ |> filled


{-| Convert from a tuple `( top, List belowElement )`.

Use [`topDown`](#topDown) if you don't already have a tuple to convert from
(for example coming from [turboMaCk/non-empty-list-alias](https://dark.elm.dmy.fr/packages/turboMaCk/non-empty-list-alias/latest/List-NonEmpty#NonEmpty))

-}
fromTopDown :
    ( top, List belowElement )
    -> Hand (StackTopBelow top belowElement) never_ Empty
fromTopDown =
    \( topElement, down ) ->
        topDown topElement down


{-| Convert a `List element` to a `Empty Possibly (Stacked element)`.
The `List`s `head` becomes [`top`](#top), its `tail` is shoved down below.

    import Possibly exposing (Possibly)
    import Hand
    import Stack exposing (topDown)

    [] |> Stack.fromList
    --> Hand.empty

    [ "hello", "emptiness" ] |> Stack.fromList
    --> topDown "hello" [ "emptiness" ]
    --: Empty Possibly (Stacked String)

When constructing from known elements, always prefer

    import Stack exposing (topDown)

    topDown "hello" [ "emptiness" ]

-}
fromList : List element -> Hand (Stacked element) Possibly Empty
fromList =
    \list ->
        case list of
            [] ->
                empty

            top_ :: belowTop_ ->
                topDown top_ belowTop_



--


{-| The first value.

    import Stack exposing (top, layOnTop)

    Stack.only 3
        |> layOnTop 2
        |> top
    --> 2

-}
top : Hand (StackTopBelow top belowTop_) Never Empty -> top
top =
    \stackFilled ->
        let
            (TopDown topElement _) =
                stackFilled |> Hand.fill
        in
        topElement


{-| How many element there are.

    import Stack exposing (layOnTop)

    Stack.only 3
        |> layOnTop 2
        |> Stack.length
    --> 2

-}
length :
    Hand (StackTopBelow top_ belowElement_) possiblyOrNever_ Empty
    -> Int
length =
    \stack ->
        case stack of
            Empty _ ->
                0

            Filled (TopDown _ belowTop_) ->
                1 + List.length belowTop_



--


{-| Add an element to the front.

    import Hand
    import Stack exposing (topDown, layOnTop)

    topDown 2 [ 3 ] |> layOnTop 1
    --> topDown 1 [ 2, 3 ]

    Hand.empty |> layOnTop 1
    --> Stack.only 1

-}
layOnTop :
    newTop
    -> Hand (Stacked belowElement) possiblyOrNever_ Empty
    -> Hand (StackTopBelow newTop belowElement) never_ Empty
layOnTop toPutOnTopOfAllOtherElements =
    \stack ->
        topDown toPutOnTopOfAllOtherElements (stack |> toList)


{-| Everything after the first value.

    import Stack exposing (topDown, layOnTop, stackOnTop, removeTop)

    Stack.only 2
        |> layOnTop 3
        |> stackOnTop (topDown 1 [ 0 ])
        |> removeTop
    --> topDown 0 [ 3, 2 ]
    --: Hand (Stacked number_) Possibly Empty

-}
removeTop :
    Hand (StackTopBelow top_ belowElement) Never Empty
    -> Hand (Stacked belowElement) Possibly Empty
removeTop =
    \stackFilled ->
        let
            (TopDown _ down) =
                stackFilled |> Hand.fill
        in
        down |> fromList


{-| Flip the order of the elements.

    import Stack exposing (topDown)

    topDown "l" [ "i", "v", "e" ]
        |> Stack.reverse
    --> topDown "e" [ "v", "i", "l" ]

-}
reverse :
    Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
reverse =
    \stack ->
        stack
            |> fillMapFlat
                (\(TopDown top_ down) ->
                    case (top_ :: down) |> List.reverse of
                        bottom :: upAboveBottom ->
                            topDown bottom upAboveBottom

                        -- doesnt happen
                        [] ->
                            topDown top_ []
                )


{-| Glue the elements of a `... Empty possiblyOrNever`/`Never` [`Stack`](#Stacked) to the [`top`](#top) of this [`Stack`](Stack).

    import Hand
    import Stack exposing (topDown, stackOnTop, stackOnTopTyped)

    Hand.empty
        |> stackOnTopTyped (topDown 1 [ 2 ])
        |> stackOnTop (topDown -2 [ -1, 0 ])
    --> topDown -2 [ -1, 0, 1, 2 ]

  - [`stackOnTop`](#stackOnTop) takes on the `possiblyOrNever Empty` type of the piped food
  - [`stackOnTopTyped`](#stackOnTopTyped) takes on the `possiblyOrNever Empty` type of the argument

-}
stackOnTopTyped :
    Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNeverIn_ Empty
    -> Hand (Stacked element) possiblyOrNever Empty
stackOnTopTyped stackToPutAbove =
    \stack ->
        stackOnTopAndTakeOnType
            (\( possiblyOrNever, _ ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


{-| Glue the elements of a stack to the end of the stack.

    import Stack exposing (topDown, stackOnTop)

    topDown 1 [ 2 ]
        |> stackOnTop (topDown -1 [ 0 ])
    --> topDown -1 [ 0, 1, 2 ]

  - [`stackOnTop`](#stackOnTop) takes on the `possiblyOrNever Empty` type of the piped food
  - [`stackOnTopTyped`](#stackOnTopTyped) takes on the `possiblyOrNever Empty` type of the argument

-}
stackOnTop :
    Hand (Stacked element) possiblyOrNeverAppended_ Empty
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
stackOnTop stackToPutAbove =
    \stack ->
        stackOnTopAndTakeOnType
            (\( _, possiblyOrNever ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


stackOnTopAndTakeOnType :
    (( possiblyOrNeverOnTop, possiblyOrNever ) -> possiblyOrNeverTakenOn)
    ->
        ( Hand (StackTopBelow topElement topElement) possiblyOrNeverOnTop Empty
        , Hand (Stacked topElement) possiblyOrNever Empty
        )
    -> Hand (Stacked topElement) possiblyOrNeverTakenOn Empty
stackOnTopAndTakeOnType takeOnType stacksDown =
    case stacksDown of
        ( Empty possiblyOrNeverOnTop, Empty possiblyOrNever ) ->
            Empty (takeOnType ( possiblyOrNeverOnTop, possiblyOrNever ))

        ( Empty _, Filled stackFilled ) ->
            stackFilled |> filled

        ( Filled (TopDown top_ belowTop_), stackToPutBelow ) ->
            topDown
                top_
                (belowTop_ ++ (stackToPutBelow |> toList))


{-| Put the elements of a `List` on [`top`](#top).

    import Stack exposing (topDown, stackOnTop)

    topDown 1 [ 2 ]
        |> Stack.glueOnTop [ -1, 0 ]
    --> topDown -1 [ 0, 1, 2 ]

`glueOnTop` only when the piped stack food is already `... Never Empty`.
Glue a stack on top with

  - [`stackOnTop`](#stackOnTop) takes on the `possiblyOrNever Empty` type of the piped food
  - [`stackOnTopTyped`](#stackOnTopTyped) takes on the **`possiblyOrNever Empty` type of the argument**

-}
glueOnTop :
    List element
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
glueOnTop stackToPutOnTop =
    stackOnTop (stackToPutOnTop |> fromList)


{-| Glue together a bunch of stacks.

    import Hand
    import Stack exposing (topDown)

    topDown
        (topDown 0 [ 1 ])
        [ topDown 10 [ 11 ]
        , Hand.empty
        , topDown 20 [ 21, 22 ]
        ]
        |> Stack.flatten
    --> topDown 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty stack, there must be a non-empty [`top`](#top) stack.

-}
flatten :
    Hand
        (StackTopBelow
            (Hand (Stacked element) possiblyOrNever Empty)
            (Hand (Stacked element) belowTopListsPossiblyOrNever_ Empty)
        )
        possiblyOrNever
        Empty
    -> Hand (Stacked element) possiblyOrNever Empty
flatten stackOfStacks =
    stackOfStacks
        |> Hand.fillMapFlat
            (\(TopDown topList belowTopLists) ->
                belowTopLists
                    |> List.concatMap toList
                    |> fromList
                    |> stackOnTopTyped topList
            )



--


{-| Keep elements that satisfy a test.

    import Stack exposing (topDown)

    topDown 1 [ 2, 5, -3, 10 ]
        |> Stack.when (\x -> x < 5)
    --> topDown 1 [ 2, -3 ]
    --: Empty Possibly (Stacked number_)

-}
when :
    (element -> Bool)
    -> Hand (Stacked element) possiblyOrNever_ Empty
    -> Hand (Stacked element) Possibly Empty
when isGood =
    \stack ->
        stack
            |> toList
            |> List.filter isGood
            |> fromList


{-| Keep all [`filled`](Hand#filled) values and drop all [`empty`](Hand#empty) elements.

    import Hand exposing (filled)
    import Stack exposing (topDown)

    topDown Hand.empty [ Hand.empty ]
        |> Stack.whenFilled
    --> Hand.empty

    topDown (filled 1) [ Hand.empty, filled 3 ]
        |> Stack.whenFilled
    --> topDown 1 [ 3 ]

As you can see, if only the top is [`fill`](Hand#fill) a value, the result is non-empty.

-}
whenFilled :
    Hand
        (StackTopBelow
            (Hand topContent possiblyOrNever Empty)
            (Hand belowElementContent belowPossiblyOrNever_ Empty)
        )
        possiblyOrNever
        Empty
    ->
        Hand
            (StackTopBelow topContent belowElementContent)
            possiblyOrNever
            Empty
whenFilled =
    \stackOfHands ->
        stackOfHands
            |> Hand.fillMapFlat
                (\(TopDown top_ belowTop_) ->
                    top_
                        |> Hand.fillMapFlat
                            (\topElement ->
                                topDown topElement
                                    (belowTop_ |> List.filterMap Hand.toMaybe)
                            )
                )



--


{-| Apply a function to every element.

    import Stack exposing (topDown)

    topDown 1 [ 4, 9 ]
        |> Stack.map negate
    --> topDown -1 [ -4, -9 ]

-}
map :
    (aElement -> bElement)
    -> Hand (Stacked aElement) possiblyOrNever Empty
    -> Hand (Stacked bElement) possiblyOrNever Empty
map changeElement =
    \stack ->
        stack
            |> Hand.fillMapFlat
                (\(TopDown topElement down) ->
                    topDown
                        (topElement |> changeElement)
                        (down |> List.map changeElement)
                )


{-| Apply a function to every element of its removeTop.

    import Stack exposing (topDown, mapBelowTop)

    topDown 1 [ 4, 9 ]
        |> mapBelowTop negate
    --> topDown 1 [ -4, -9 ]

-}
mapBelowTop :
    (belowElement -> belowElementMapped)
    ->
        Hand
            (StackTopBelow top belowElement)
            possiblyOrNever
            Empty
    ->
        Hand
            (StackTopBelow top belowElementMapped)
            possiblyOrNever
            Empty
mapBelowTop changeTailElement =
    Hand.fillMapFlat
        (\(TopDown top_ down_) ->
            topDown top_ (down_ |> List.map changeTailElement)
        )


{-| Change the [`top`](#top) element based on its current value.
Its type is allowed to change.

    import Stack exposing (topDown, mapTop)

    topDown 1 [ 4, 9 ]
        |> mapTop negate
    --> topDown -1 [ 4, 9 ]

-}
mapTop :
    (top -> topMapped)
    -> Hand (StackTopBelow top belowElement) possiblyOrNever Empty
    -> Hand (StackTopBelow topMapped belowElement) possiblyOrNever Empty
mapTop changeTop =
    Hand.fillMapFlat
        (\(TopDown top_ down_) ->
            topDown (top_ |> changeTop) down_
        )


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import LinearDirection exposing (LinearDirection(..))
    import Stack exposing (topDown)

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" LastToFirst String.cons
    --> "live"

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" FirstToLast String.cons
    --> "evil"

-}
foldFrom :
    accumulationValue
    -> LinearDirection
    -> (element -> accumulationValue -> accumulationValue)
    -> Hand (Stacked element) possiblyOrNever_ Empty
    -> accumulationValue
foldFrom initialAccumulationValue direction reduce =
    toList
        >> List.Linear.foldFrom initialAccumulationValue direction reduce


{-| A fold in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
where the initial result is the [`top`](#top).

    import LinearDirection exposing (LinearDirection(..))
    import Stack exposing (topDown)

    topDown 234 [ 345, 543 ]
        |> Stack.fold FirstToLast max
    --> 543

-}
fold :
    LinearDirection
    -> (belowTopElement -> top -> top)
    -> Hand (StackTopBelow top belowTopElement) Never Empty
    -> top
fold direction reduce =
    \stackFilled ->
        let
            (TopDown top_ belowTop_) =
                stackFilled |> Hand.fill
        in
        List.Linear.foldFrom top_ direction reduce belowTop_


{-| Convert it to a `List`.

    import Stack exposing (topDown)

    topDown 1 [ 7 ] |> Stack.toList
    --> [ 1, 7 ]

Don't try to use this prematurely.
Keeping type information as long as possible is always a win.

-}
toList :
    Hand (Stacked element) possiblyOrNever_ Empty
    -> List element
toList =
    \stack ->
        case stack of
            Filled (TopDown top_ belowTop_) ->
                top_ :: belowTop_

            Empty _ ->
                []


{-| Convert to a non-empty list tuple `( top, List belowElement )`.

Currently equivalent to [`fill`](Hand#fill).

    import Stack exposing (topDown, toTopDown)

    topDown "hi" [ "there", "👋" ]
        |> toTopDown
    --> ( "hi", [ "there", "👋" ] )

-}
toTopDown :
    Hand (StackTopBelow top belowElement) Never Empty
    -> ( top, List belowElement )
toTopDown =
    \filledStack ->
        let
            (TopDown top_ below_) =
                filledStack |> Hand.fill
        in
        ( top_, below_ )
