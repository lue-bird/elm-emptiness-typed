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

{-| 📚 An **emptiable or non-empty** structure where
[`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) [`topMap`](#topMap)
are `O(n)`

@docs Stacked, StackTopBelow


## create

[`Emptiable.empty`](Emptiable#empty) to create an `Empty Possibly` stack

@docs only, topDown, fromTopDown, fromList, fromText


## scan

@docs top
@docs length, indexLast

[`topRemove`](#topRemove) brings out everything below the [`top`](#top)


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

import Emptiable exposing (Emptiable(..), empty, fill, fillAnd, fillMapFlat, filled)
import Linear exposing (Direction(..))
import List.Linear
import Possibly exposing (Possibly)


{-| The representation of a non-empty stack on the `Filled` case.
[`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) [`topMap`](#topMap) are `O(n)`


#### in arguments

[`Emptiable`](Emptiable) `(StackFilled ...) Never` → `stack` is non-empty:

    top : Emptiable (Stacked element) Never -> element


#### in results

[`Emptiable`](Emptiable) `(StackFilled ...)`[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `Empty` → stack could be empty

    fromList : List element -> Emptiable (Stacked element) Possibly

We can treat it like any [`Emptiable`](Emptiable):

    import Emptiable exposing (Emptiable(..), filled, fillMap)
    import Possibly exposing (Possibly)
    import Stack exposing (Stacked, top, onTopLay)

    Emptiable.empty |> onTopLay "cherry" -- works

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
    --: Emptiable String Possibly

Most operations also allow a different type for the top element → see [`StackTopBelow`](#StackTopBelow)

-}
type alias Stacked element =
    StackTopBelow element element


{-| [`Stacked`](#Stacked) with a different type for the top element:

    top : Emptiable (StackTopBelow top belowTopElement_) Never -> top

it's the result of:

  - [`only`](#only)
  - [`topDown`](#topDown)
  - [`fromTopDown`](#fromTopDown)
  - [`onTopLay`](#onTopLay)
  - [`topMap`](#topMap)

-}
type StackTopBelow topElement belowTopElement
    = TopDown topElement (List belowTopElement)


{-| A stack with just 1 single element

    import Emptiable
    import Stack exposing (onTopLay)

    Stack.only ":)"
    --> Emptiable.empty |> onTopLay ":)"

-}
only : top -> Emptiable (StackTopBelow top belowTopElement_) never_
only onlyElement =
    topDown onlyElement []


{-| A stack from a top element and a `List` of elements below going down.
-}
topDown :
    top
    -> List belowElement
    -> Emptiable (StackTopBelow top belowElement) never_
topDown top_ belowTop_ =
    TopDown top_ belowTop_ |> filled


{-| Take a tuple `( top, List belowElement )`
from another source like [turboMaCk/non-empty-list-alias](https://dark.elm.dmy.fr/packages/turboMaCk/non-empty-list-alias/latest/List-NonEmpty#NonEmpty)
and convert it to an `Emptiable (StackTopBelow top belowElement) never_`

Use [`topDown`](#topDown) if you don't already have a tuple to convert from

-}
fromTopDown :
    ( top, List belowElement )
    -> Emptiable (StackTopBelow top belowElement) never_
fromTopDown =
    \( topElement, down ) ->
        topDown topElement down


{-| Convert a `List element` to a `Empty Possibly (Stacked element)`.
The `List`s `head` becomes [`top`](#top), its `tail` is shoved down below

    import Possibly exposing (Possibly)
    import Emptiable
    import Stack exposing (topDown)

    [] |> Stack.fromList
    --> Emptiable.empty

    [ "hello", "emptiness" ] |> Stack.fromList
    --> topDown "hello" [ "emptiness" ]
    --: Empty Possibly (Stacked String)

When constructing from known elements, always prefer

    import Stack exposing (topDown)

    topDown "hello" [ "emptiness" ]

-}
fromList : List element -> Emptiable (Stacked element) Possibly
fromList =
    \list ->
        case list of
            [] ->
                empty

            top_ :: belowTop_ ->
                topDown top_ belowTop_


{-| Convert a `String` to a `Emptiable (Stacked Char) Possibly`.
The `String`s head becomes [`top`](#top), its tail is shoved down below

    import Possibly exposing (Possibly)
    import Emptiable
    import Stack exposing (topDown)

    "" |> Stack.fromText
    --> Emptiable.empty

    "hello" |> Stack.fromText
    --> topDown 'h' [ 'e', 'l', 'l', 'o' ]
    --: Emptiable (Stacked Char) Possibly

When constructing from known elements, always prefer

    import Stack exposing (topDown)

    onTopLay 'h' ("ello" |> Stack.fromText)

-}
fromText : String -> Emptiable (Stacked Char) Possibly
fromText =
    \string ->
        string |> String.toList |> fromList



--


{-| The first value

    import Stack exposing (top, onTopLay)

    Stack.only 3
        |> onTopLay 2
        |> top
    --> 2

-}
top : Emptiable (StackTopBelow top belowTop_) Never -> top
top =
    \stackFilled ->
        let
            (TopDown topElement _) =
                stackFilled |> Emptiable.fill
        in
        topElement


{-| How many element there are

    import Stack exposing (onTopLay)

    Stack.only 3
        |> onTopLay 2
        |> Stack.length
    --> 2

-}
length :
    Emptiable (StackTopBelow top_ belowElement_) possiblyOrNever_
    -> Int
length =
    \stack ->
        case stack of
            Empty _ ->
                0

            Filled stacked ->
                1 + (stacked |> filled |> indexLast)


{-| The position of the element at the bottom

    import Stack exposing (onTopLay)

    Stack.only 3
        |> onTopLay 2
        |> Stack.indexLast
    --> 1

-}
indexLast :
    Emptiable (StackTopBelow top_ belowElement_) Never
    -> Int
indexLast =
    \stack ->
        case stack of
            Empty _ ->
                0

            Filled (TopDown _ belowTop_) ->
                belowTop_ |> List.length



--


{-| Add an element to the front

    import Emptiable
    import Stack exposing (topDown, onTopLay)

    topDown 2 [ 3 ] |> onTopLay 1
    --> topDown 1 [ 2, 3 ]

    Emptiable.empty |> onTopLay 1
    --> Stack.only 1

-}
onTopLay :
    newTop
    -> Emptiable (Stacked belowElement) possiblyOrNever_
    -> Emptiable (StackTopBelow newTop belowElement) never_
onTopLay toPutOnTopOfAllOtherElements =
    \stack ->
        topDown toPutOnTopOfAllOtherElements (stack |> toList)


{-| Everything after the first value

    import Stack exposing (topDown, onTopLay, onTopStack, topRemove)

    Stack.only 2
        |> onTopLay 3
        |> onTopStack (topDown 1 [ 0 ])
        |> topRemove
    --> topDown 0 [ 3, 2 ]
    --: Emptiable (Stacked number_) Possibly

-}
topRemove :
    Emptiable (StackTopBelow top_ belowElement) Never
    -> Emptiable (Stacked belowElement) Possibly
topRemove =
    \stackFilled ->
        let
            (TopDown _ down) =
                stackFilled |> Emptiable.fill
        in
        down |> fromList


{-| Flip the order of the elements

    import Stack exposing (topDown)

    topDown "l" [ "i", "v", "e" ]
        |> Stack.reverse
    --> topDown "e" [ "v", "i", "l" ]

-}
reverse :
    Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
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


{-| Glue the elements of a `... Empty possiblyOrNever`/`Never` [`Stack`](#Stacked)
to the [`top`](#top) of this [`Stack`](Stack)

    import Emptiable
    import Stack exposing (topDown, onTopStack, onTopStackAdapt)

    Emptiable.empty
        |> onTopStackAdapt (topDown 1 [ 2 ])
        |> onTopStack (topDown -2 [ -1, 0 ])
    --> topDown -2 [ -1, 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever` type of the argument

-}
onTopStackAdapt :
    Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNeverIn_
    -> Emptiable (Stacked element) possiblyOrNever
onTopStackAdapt stackToPutAbove =
    \stack ->
        stackOnTopAndAdaptTypeOf
            (\( possiblyOrNever, _ ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


{-| Glue the elements of a stack to the end of the stack

    import Stack exposing (topDown, onTopStack)

    topDown 1 [ 2 ]
        |> onTopStack (topDown -1 [ 0 ])
    --> topDown -1 [ 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever` type of the argument

-}
onTopStack :
    Emptiable (Stacked element) possiblyOrNeverAppended_
    -> Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
onTopStack stackToPutAbove =
    \stack ->
        stackOnTopAndAdaptTypeOf
            (\( _, possiblyOrNever ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


stackOnTopAndAdaptTypeOf :
    (( possiblyOrNeverOnTop, possiblyOrNever ) -> possiblyOrNeverTakenOn)
    ->
        ( Emptiable (StackTopBelow topElement topElement) possiblyOrNeverOnTop
        , Emptiable (Stacked topElement) possiblyOrNever
        )
    -> Emptiable (Stacked topElement) possiblyOrNeverTakenOn
stackOnTopAndAdaptTypeOf takeOnType stacksDown =
    case stacksDown of
        ( Empty possiblyOrNeverOnTop, Empty possiblyOrNever ) ->
            Empty (takeOnType ( possiblyOrNeverOnTop, possiblyOrNever ))

        ( Empty _, Filled stackFilled ) ->
            stackFilled |> filled

        ( Filled (TopDown top_ belowTop_), stackToPutBelow ) ->
            topDown
                top_
                (belowTop_ ++ (stackToPutBelow |> toList))


{-| Put the elements of a `List` on [`top`](#top)

    import Stack exposing (topDown, onTopStack)

    topDown 1 [ 2 ]
        |> Stack.onTopGlue [ -1, 0 ]
    --> topDown -1 [ 0, 1, 2 ]

`onTopGlue` only when the piped stack food is already `... Never`.
Glue a stack on top with

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the **`possiblyOrNever` type of the argument**

-}
onTopGlue :
    List element
    -> Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
onTopGlue stackToPutOnTop =
    onTopStack (stackToPutOnTop |> fromList)


{-| Glue together a bunch of stacks

    import Emptiable
    import Stack exposing (topDown)

    topDown
        (topDown 0 [ 1 ])
        [ topDown 10 [ 11 ]
        , Emptiable.empty
        , topDown 20 [ 21, 22 ]
        ]
        |> Stack.flatten
    --> topDown 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty stack, there must be a non-empty [`top`](#top) stack

-}
flatten :
    Emptiable
        (StackTopBelow
            (Emptiable (Stacked element) possiblyOrNever)
            (Emptiable (Stacked element) belowTopListsPossiblyOrNever_)
        )
        possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
flatten stackOfStacks =
    stackOfStacks
        |> Emptiable.fillMapFlat
            (\(TopDown topList belowTopLists) ->
                belowTopLists
                    |> List.concatMap toList
                    |> fromList
                    |> onTopStackAdapt topList
            )



--


{-| Keep all [`filled`](Emptiable#filled) elements
and drop all [`empty`](Emptiable#empty) elements

    import Emptiable exposing (filled)
    import Stack exposing (topDown)

    topDown Emptiable.empty [ Emptiable.empty ]
        |> Stack.fills
    --> Emptiable.empty

    topDown (filled 1) [ Emptiable.empty, filled 3 ]
        |> Stack.fills
    --> topDown 1 [ 3 ]

As you can see, if only the top is [`fill`](Emptiable#fill) a value, the result is non-empty

-}
fills :
    Emptiable
        (StackTopBelow
            (Emptiable topContent possiblyOrNever)
            (Emptiable belowElementContent belowPossiblyOrNever_)
        )
        possiblyOrNever
    ->
        Emptiable
            (StackTopBelow topContent belowElementContent)
            possiblyOrNever
fills =
    \stackOfHands ->
        stackOfHands
            |> Emptiable.fillMapFlat
                (\(TopDown top_ belowTop_) ->
                    top_
                        |> Emptiable.fillMapFlat
                            (\topElement ->
                                topDown topElement
                                    (belowTop_ |> List.filterMap Emptiable.toMaybe)
                            )
                )



--


{-| Change every element based on its current value and `{ index }`

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
    -> Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked elementMapped) possiblyOrNever
map changeElement =
    \stack ->
        stack
            |> Emptiable.fillMapFlat
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
If one stack is longer, the extra elements are dropped

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
    Emptiable (Stacked anotherElement) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked ( element, anotherElement )) possiblyOrNever
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
Their type is allowed to change

    import Stack exposing (topDown, belowTopMap)

    topDown 1 [ 4, 9 ]
        |> belowTopMap (\_ -> negate)
    --> topDown 1 [ -4, -9 ]

-}
belowTopMap :
    ({ index : Int } -> belowElement -> belowElementMapped)
    ->
        Emptiable
            (StackTopBelow top belowElement)
            possiblyOrNever
    ->
        Emptiable
            (StackTopBelow top belowElementMapped)
            possiblyOrNever
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
Its type is allowed to change

    import Stack exposing (topDown, topMap)

    topDown 1 [ 4, 9 ] |> topMap negate
    --> topDown -1 [ 4, 9 ]

-}
topMap :
    (top -> topMapped)
    -> Emptiable (StackTopBelow top belowElement) possiblyOrNever
    -> Emptiable (StackTopBelow topMapped belowElement) possiblyOrNever
topMap changeTop =
    Emptiable.fillMapFlat
        (\(TopDown top_ down_) ->
            topDown (top_ |> changeTop) down_
        )


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)

    import Linear exposing (Direction(..))
    import Stack exposing (topDown)

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" Down String.cons
    --> "live"

    topDown 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" Up String.cons
    --> "evil"

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) down
  - `Up` = indexes increasing, not: from the bottom up

-}
foldFrom :
    accumulationValue
    -> Linear.Direction
    -> (element -> accumulationValue -> accumulationValue)
    -> Emptiable (Stacked element) possiblyOrNever_
    -> accumulationValue
foldFrom initialAccumulationValue direction reduce =
    \stack ->
        stack
            |> toList
            |> List.Linear.foldFrom
                initialAccumulationValue
                direction
                reduce


{-| Fold from the [`top`](#top) as the initial accumulation value

    import Linear exposing (Direction(..))
    import Stack exposing (topDown)

    topDown 234 [ 345, 543 ]
        |> Stack.fold Up max
    --> 543

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) down
  - `Up` = indexes increasing, not: from the bottom up

-}
fold :
    Linear.Direction
    -> (element -> element -> element)
    -> Emptiable (Stacked element) Never
    -> element
fold direction reduce =
    -- doesn't use a native implementation for performance reasons
    \stackFilled ->
        stackFilled
            |> toList
            |> List.Linear.foldFrom
                Nothing
                direction
                (\element soFar ->
                    (case soFar of
                        Nothing ->
                            element

                        Just reducedSoFar ->
                            reducedSoFar |> reduce element
                    )
                        |> Just
                )
            |> -- impossible
               Maybe.withDefault (stackFilled |> top)


{-| ∑ Total every element number

    import Emptiable

    topDown 1 [ 2, 3 ] |> Stack.sum
    --> 6

    topDown 1 (List.repeat 5 1) |> Stack.sum
    --> 6

    Emptiable.empty |> Stack.sum
    --> 0

-}
sum : Emptiable (Stacked number) possiblyOrNever_ -> number
sum =
    foldFrom 0 Up (\current soFar -> soFar + current)


{-| Convert to a `List`

    import Stack exposing (topDown)

    topDown 1 [ 7 ] |> Stack.toList
    --> [ 1, 7 ]

Don't try to use this prematurely.
Keeping type information as long as possible is always a win

-}
toList :
    Emptiable (Stacked element) possiblyOrNever_
    -> List element
toList =
    \stack ->
        case stack of
            Filled (TopDown top_ belowTop_) ->
                top_ :: belowTop_

            Empty _ ->
                []


{-| Convert to a `String`

    import Stack exposing (topDown)

    topDown 'H' [ 'i' ] |> Stack.toText
    --> "Hi"

Don't try to use this prematurely.
Keeping type information as long as possible is always a win

-}
toText : Emptiable (Stacked Char) possiblyOrNever_ -> String
toText =
    \stack ->
        stack |> toList |> String.fromList


{-| Convert to a non-empty list tuple `( top, List belowElement )`
to be used by another library

    import Stack exposing (topDown, toTopDown)

    topDown "hi" [ "there", "👋" ]
        |> toTopDown
    --> ( "hi", [ "there", "👋" ] )

Don't use [`toTopDown`](#toTopDown) to destructure a stack.
Instead: [`Stack.top`](Stack#top), [`Stack.topRemove`](#topRemove)

-}
toTopDown :
    Emptiable (StackTopBelow top belowElement) Never
    -> ( top, List belowElement )
toTopDown =
    \filledStack ->
        let
            (TopDown top_ below_) =
                filledStack |> fill
        in
        ( top_, below_ )
