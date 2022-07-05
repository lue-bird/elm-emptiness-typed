module Stack exposing
    ( Stacked, StackTopBelow(..)
    , only, topDown, fromTopDown, fromList, fromText
    , top
    , length, indexLast
    , onTopLay, topRemove
    , reverse
    , fills
    , onTopGlue, onTopStack, onTopStackAdapt
    , flatten
    , map, and, topMap, belowTopMap
    , foldFrom, fold, sum
    , toTopDown, toList, toText
    )

{-| An **emptiable or non-empty** data structure where [`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) [`topMap`](#topMap) are `O(n)`.

@docs Stacked, StackTopBelow


## create

[`Hand.empty`](Hand#empty) to create an `Empty Possibly` stack.

@docs only, topDown, fromTopDown, fromList, fromText


## scan

@docs top
@docs length, indexLast

[`topRemove`](#topRemove) brings out everything below the [`top`](#top).


## alter

@docs onTopLay, topRemove
@docs reverse


### filter

@docs fills


### glue

@docs onTopGlue, onTopStack, onTopStackAdapt
@docs flatten


## transform

@docs map, and, topMap, belowTopMap
@docs foldFrom, fold, sum
@docs toTopDown, toList, toText

-}

import Hand exposing (Empty, Hand(..), empty, fill, fillAnd, fillMapFlat, filled)
import Linear exposing (DirectionLinear(..))
import List.Linear
import Possibly exposing (Possibly)


{-| A non-empty representation of a stack. [`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) [`topMap`](#topMap) are `O(n)`


#### in arguments

[`Hand`](Hand) `(StackFilled ...) Never Empty` → `stack` is non-empty:

    top : Hand (Stacked element) Never -> element


#### in results

[`Hand`](Hand) `(StackFilled ...)`[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `Empty` → stack could be empty

    fromList : List element -> Hand (Stacked element) Possibly Empty

We can treat it like any [`Hand`](Hand):

    import Hand exposing (Hand(..), Empty, filled, fillMap)
    import Possibly exposing (Possibly)
    import Stack exposing (Stacked, top, onTopLay)

    Hand.empty |> onTopLay "cherry" -- works

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
  - [`onTopLay`](#onTopLay)
  - [`topMap`](#topMap)

-}
type StackTopBelow topElement belowTopElement
    = TopDown topElement (List belowTopElement)


{-| A stack with just 1 single element.

    import Hand
    import Stack exposing (onTopLay)

    Stack.only ":)"
    --> Hand.empty |> onTopLay ":)"

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


{-| Convert a `String` to a `Hand (Stacked Char) Possibly Empty`.
The `String`s head becomes [`top`](#top), its tail is shoved down below.

    import Possibly exposing (Possibly)
    import Hand
    import Stack exposing (topDown)

    "" |> Stack.fromText
    --> Hand.empty

    "hello" |> Stack.fromText
    --> topDown 'h' [ 'e', 'l', 'l', 'o' ]
    --: Hand (Stacked Char) Possibly Empty

When constructing from known elements, always prefer

    import Stack exposing (topDown)

    onTopLay 'h' ("ello" |> Stack.fromText)

-}
fromText : String -> Hand (Stacked Char) Possibly Empty
fromText =
    \string ->
        string |> String.toList |> fromList



--


{-| The first value.

    import Stack exposing (top, onTopLay)

    Stack.only 3
        |> onTopLay 2
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

    import Stack exposing (onTopLay)

    Stack.only 3
        |> onTopLay 2
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

            Filled stacked ->
                1 + (stacked |> filled |> indexLast)


{-| The position of the element at the bottom.

    import Stack exposing (onTopLay)

    Stack.only 3
        |> onTopLay 2
        |> Stack.indexLast
    --> 1

-}
indexLast :
    Hand (StackTopBelow top_ belowElement_) Never Empty
    -> Int
indexLast =
    \stack ->
        case stack of
            Empty _ ->
                0

            Filled (TopDown _ belowTop_) ->
                belowTop_ |> List.length



--


{-| Add an element to the front.

    import Hand
    import Stack exposing (topDown, onTopLay)

    topDown 2 [ 3 ] |> onTopLay 1
    --> topDown 1 [ 2, 3 ]

    Hand.empty |> onTopLay 1
    --> Stack.only 1

-}
onTopLay :
    newTop
    -> Hand (Stacked belowElement) possiblyOrNever_ Empty
    -> Hand (StackTopBelow newTop belowElement) never_ Empty
onTopLay toPutOnTopOfAllOtherElements =
    \stack ->
        topDown toPutOnTopOfAllOtherElements (stack |> toList)


{-| Everything after the first value.

    import Stack exposing (topDown, onTopLay, onTopStack, topRemove)

    Stack.only 2
        |> onTopLay 3
        |> onTopStack (topDown 1 [ 0 ])
        |> topRemove
    --> topDown 0 [ 3, 2 ]
    --: Hand (Stacked number_) Possibly Empty

-}
topRemove :
    Hand (StackTopBelow top_ belowElement) Never Empty
    -> Hand (Stacked belowElement) Possibly Empty
topRemove =
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
    import Stack exposing (topDown, onTopStack, onTopStackAdapt)

    Hand.empty
        |> onTopStackAdapt (topDown 1 [ 2 ])
        |> onTopStack (topDown -2 [ -1, 0 ])
    --> topDown -2 [ -1, 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever Empty` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever Empty` type of the argument

-}
onTopStackAdapt :
    Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNeverIn_ Empty
    -> Hand (Stacked element) possiblyOrNever Empty
onTopStackAdapt stackToPutAbove =
    \stack ->
        stackOnTopAndTakeOnType
            (\( possiblyOrNever, _ ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


{-| Glue the elements of a stack to the end of the stack.

    import Stack exposing (topDown, onTopStack)

    topDown 1 [ 2 ]
        |> onTopStack (topDown -1 [ 0 ])
    --> topDown -1 [ 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever Empty` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever Empty` type of the argument

-}
onTopStack :
    Hand (Stacked element) possiblyOrNeverAppended_ Empty
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
onTopStack stackToPutAbove =
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

    import Stack exposing (topDown, onTopStack)

    topDown 1 [ 2 ]
        |> Stack.onTopGlue [ -1, 0 ]
    --> topDown -1 [ 0, 1, 2 ]

`onTopGlue` only when the piped stack food is already `... Never Empty`.
Glue a stack on top with

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever Empty` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the **`possiblyOrNever Empty` type of the argument**

-}
onTopGlue :
    List element
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
onTopGlue stackToPutOnTop =
    onTopStack (stackToPutOnTop |> fromList)


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
                    |> onTopStackAdapt topList
            )



--


{-| Keep all [`filled`](Hand#filled) elements
and drop all [`empty`](Hand#empty) elements.

    import Hand exposing (filled)
    import Stack exposing (topDown)

    topDown Hand.empty [ Hand.empty ]
        |> Stack.fills
    --> Hand.empty

    topDown (filled 1) [ Hand.empty, filled 3 ]
        |> Stack.fills
    --> topDown 1 [ 3 ]

As you can see, if only the top is [`fill`](Hand#fill) a value, the result is non-empty.

-}
fills :
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
fills =
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


{-| Change every element based on its current value and `{ index }`.

    import Stack exposing (topDown)

    topDown 1 [ 4, 9 ]
        |> Stack.map (\_ -> negate)
    --> topDown -1 [ -4, -9 ]

    topDown 1 [ 2, 3, 4 ]
        |> Stack.map (\{ index } n -> index * n)
    --> topDown 0 [ 2, 6, 12 ]

-}
map :
    ({ index : Int } -> element -> elementMapped)
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked elementMapped) possiblyOrNever Empty
map changeElement =
    \stack ->
        stack
            |> Hand.fillMapFlat
                (\(TopDown topElement down) ->
                    topDown
                        (topElement |> changeElement { index = 0 })
                        (down
                            |> List.indexedMap
                                (\indexBelow ->
                                    changeElement
                                        { index = 1 + indexBelow }
                                )
                        )
                )


{-| Combine its elements with elements of a given stack at the same location.
If one stack is longer, the extra elements are dropped.

    import Stack exposing (topDown)

    topDown "alice" [ "bob", "chuck" ]
        |> Stack.and (topDown 2 [ 5, 7, 8 ])
    --> topDown ( "alice", 2 ) [ ( "bob", 5 ), ( "chuck", 7 ) ]

    topDown 4 [ 5, 6 ]
        |> Stack.and (topDown 1 [ 2, 3 ])
        |> Stack.map (\_ ( n0, n1 ) -> n0 + n1)
    --> topDown 5 [ 7, 9 ]

-}
and :
    Hand (Stacked anotherElement) possiblyOrNever Empty
    -> Hand (Stacked element) possiblyOrNever Empty
    -> Hand (Stacked ( element, anotherElement )) possiblyOrNever Empty
and anotherStack =
    \stack ->
        stack
            |> fillAnd anotherStack
            |> fillMapFlat
                (\( TopDown topElement down, TopDown anotherTop anotherDown ) ->
                    topDown
                        ( topElement, anotherTop )
                        (List.map2 Tuple.pair down anotherDown)
                )


{-| Change every element below its [`top`](#top)
based on their `{ index }` in the whole stack and their current value.
Their type is allowed to change.

    import Stack exposing (topDown, belowTopMap)

    topDown 1 [ 4, 9 ]
        |> belowTopMap (\_ -> negate)
    --> topDown 1 [ -4, -9 ]

-}
belowTopMap :
    ({ index : Int } -> belowElement -> belowElementMapped)
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
belowTopMap changeTailElement =
    fillMapFlat
        (\(TopDown top_ down_) ->
            topDown
                top_
                (down_
                    |> List.indexedMap
                        (\index ->
                            changeTailElement { index = index }
                        )
                )
        )


{-| Change the [`top`](#top) element based on its current value.
Its type is allowed to change.

    import Stack exposing (topDown, topMap)

    topDown 1 [ 4, 9 ]
        |> topMap negate
    --> topDown -1 [ 4, 9 ]

-}
topMap :
    (top -> topMapped)
    -> Hand (StackTopBelow top belowElement) possiblyOrNever Empty
    -> Hand (StackTopBelow topMapped belowElement) possiblyOrNever Empty
topMap changeTop =
    Hand.fillMapFlat
        (\(TopDown top_ down_) ->
            topDown (top_ |> changeTop) down_
        )


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/).

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom ( "", Down, String.cons )
    --> "live"

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom ( "", Up, String.cons )
    --> "evil"

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) down
  - `Up` = indexes increasing, not: from the bottom up

-}
foldFrom :
    ( accumulationValue
    , DirectionLinear
    , element -> accumulationValue -> accumulationValue
    )
    -> Hand (Stacked element) possiblyOrNever_ Empty
    -> accumulationValue
foldFrom ( initialAccumulationValue, direction, reduce ) =
    \stack ->
        stack
            |> toList
            |> List.Linear.foldFrom
                ( initialAccumulationValue
                , direction
                , reduce
                )


{-| Fold from the [`top`](#top) as the initial accumulation value.

    import Linear exposing (DirectionLinear(..))
    import Stack exposing (topDown)

    topDown 234 [ 345, 543 ]
        |> Stack.fold max
    --> 543

`fold` doesn't take a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)
as an argument because at the time of writing, the best implementation would include a [`Stack.reverse`](#reverse).

-}
fold :
    (belowElement -> top -> top)
    -> Hand (StackTopBelow top belowElement) Never Empty
    -> top
fold reduce =
    \stackFilled ->
        let
            (TopDown top_ belowTop_) =
                stackFilled |> fill
        in
        List.Linear.foldFrom ( top_, Up, reduce ) belowTop_


{-| ∑ Total each element number.

    topDown 1 [ 2, 3 ] |> Stack.sum
    --> 6
    topDown 1 (List.repeat 5 1) |> Stack.sum
    --> 6
    Stack.sum Hand.empty
    --> 0

-}
sum : Hand (Stacked number) Never Empty -> number
sum =
    foldFrom ( 0, Up, \current soFar -> soFar + current )


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


{-| Convert it to a `String`.

    import Stack exposing (topDown)

    topDown 'H' [ 'i' ] |> Stack.toText
    --> "Hi"

Don't try to use this prematurely.
Keeping type information as long as possible is always a win.

-}
toText : Hand (Stacked Char) possiblyOrNever_ Empty -> String
toText =
    \stack ->
        stack |> toList |> String.fromList


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
