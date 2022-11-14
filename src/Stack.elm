module Stack exposing
    ( Stacked(..)
    , only, topBelow, fromTopBelow, fromList, fromString
    , top
    , length
    , onTopLay, topRemove
    , reverse
    , fills
    , onTopGlue, onTopStack, onTopStackAdapt
    , flatten
    , map, and
    , foldFrom, foldOnto, fold, sum
    , toTopBelow, toList, toString
    )

{-| 📚 An **emptiable or non-empty** structure where
[`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) are `O(n)`

@docs Stacked


## create

[`Emptiable.empty`](Emptiable#empty) to create an `Empty Possibly` stack

@docs only, topBelow, fromTopBelow, fromList, fromString


## scan

@docs top
@docs length

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

@docs map, and
@docs foldFrom, foldOnto, fold, sum
@docs toTopBelow, toList, toString

-}

import Emptiable exposing (Emptiable(..), empty, fill, fillAnd, fillMapFlat, filled)
import Linear exposing (Direction(..))
import List.Linear
import Possibly exposing (Possibly)


{-| The representation of a non-empty stack on the `Filled` case.
[`top`](#top), [`topRemove`](#topRemove), [`onTopLay`](#onTopLay) are `O(n)`


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
                Filled (Stack.TopBelow ( top_, below )) ->
                    top_ :: below

                Empty _ ->
                    []

    [ "hi", "there" ] -- comes in as an argument
        |> Stack.fromList
        |> fillMap (filled >> top)
    --: Emptiable String Possibly

-}
type Stacked element
    = TopBelow ( element, List element )


{-| A stack with just 1 single element

    import Emptiable
    import Stack exposing (onTopLay)

    Stack.only ":)"
    --> Emptiable.empty |> onTopLay ":)"

-}
only : element -> Emptiable (Stacked element) never_
only onlyElement =
    topBelow onlyElement []


{-| A stack from a top element and a `List` of elements below
-}
topBelow :
    element
    -> List element
    -> Emptiable (Stacked element) never_
topBelow topElement belowTopElements =
    TopBelow ( topElement, belowTopElements ) |> filled


{-| Take a tuple `( top, List belowElement )`
from another source like [turboMaCk/non-empty-list-alias](https://dark.elm.dmy.fr/packages/turboMaCk/non-empty-list-alias/latest/List-NonEmpty#NonEmpty)
and convert it to an `Emptiable (StackTopBelow top belowElement) never_`

Use [`topBelow`](#topBelow) if you don't already have a tuple to convert from

-}
fromTopBelow :
    ( element, List element )
    -> Emptiable (Stacked element) never_
fromTopBelow =
    \topBelowTuple ->
        topBelow
            (topBelowTuple |> Tuple.first)
            (topBelowTuple |> Tuple.second)


{-| Convert a `List element` to a `Empty Possibly (Stacked element)`.
The `List`s `head` becomes [`top`](#top), its `tail` is glued below

    import Possibly exposing (Possibly)
    import Emptiable
    import Stack exposing (topBelow)

    [] |> Stack.fromList
    --> Emptiable.empty

    [ "hello", "emptiness" ] |> Stack.fromList
    --> topBelow "hello" [ "emptiness" ]
    --: Empty Possibly (Stacked String)

When constructing from known elements, always prefer

    import Stack exposing (topBelow)

    topBelow "hello" [ "emptiness" ]

-}
fromList : List element -> Emptiable (Stacked element) Possibly
fromList =
    \list ->
        case list of
            [] ->
                empty

            listTop :: listBelowTop ->
                topBelow listTop listBelowTop


{-| Convert to an `Emptiable (Stacked Char) Possibly`.
The `String`s head becomes [`top`](#top), its tail is glued below

    import Possibly exposing (Possibly)
    import Emptiable
    import Stack exposing (topBelow)

    "" |> Stack.fromText
    --> Emptiable.empty

    "hello" |> Stack.fromText
    --> topBelow 'h' [ 'e', 'l', 'l', 'o' ]
    --: Emptiable (Stacked Char) Possibly

When constructing from known elements, always prefer

    import Stack exposing (topBelow)

    onTopLay 'h' ("ello" |> Stack.fromText)

-}
fromString : String -> Emptiable (Stacked Char) Possibly
fromString =
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
top : Emptiable (Stacked element) Never -> element
top =
    \stackFilled ->
        let
            (TopBelow ( topElement, _ )) =
                stackFilled |> fill
        in
        topElement


{-| How many element there are

    import Stack exposing (onTopLay)

    Stack.only 3
        |> onTopLay 2
        |> Stack.length
    --> 2

`O(n)` like `List.length`

-}
length :
    Emptiable (Stacked element_) possiblyOrNever_
    -> Int
length =
    \stack ->
        case stack of
            Empty _ ->
                0

            Filled (TopBelow ( _, belowTop_ )) ->
                1 + (belowTop_ |> List.length)



--


{-| Add an element to the front

    import Emptiable
    import Stack exposing (topBelow, onTopLay)

    topBelow 2 [ 3 ] |> onTopLay 1
    --> topBelow 1 [ 2, 3 ]

    Emptiable.empty |> onTopLay 1
    --> Stack.only 1

-}
onTopLay :
    element
    -> Emptiable (Stacked element) possiblyOrNever_
    -> Emptiable (Stacked element) never_
onTopLay toPutOnTopOfAllOtherElements =
    \stack ->
        topBelow toPutOnTopOfAllOtherElements (stack |> toList)


{-| Everything after the first value

    import Stack exposing (topBelow, onTopLay, onTopStack, topRemove)

    Stack.only 2
        |> onTopLay 3
        |> onTopStack (topBelow 1 [ 0 ])
        |> topRemove
    --> topBelow 0 [ 3, 2 ]
    --: Emptiable (Stacked number_) Possibly

-}
topRemove :
    Emptiable (Stacked element) Never
    -> Emptiable (Stacked element) Possibly
topRemove =
    \stackFilled ->
        let
            (TopBelow ( _, belowTop )) =
                stackFilled |> Emptiable.fill
        in
        belowTop |> fromList


{-| Flip the order of the elements

    import Stack exposing (topBelow)

    topBelow "l" [ "i", "v", "e" ]
        |> Stack.reverse
    --> topBelow "e" [ "v", "i", "l" ]

-}
reverse :
    Emptiable (Stacked element) possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
reverse =
    \stack ->
        stack
            |> fillMapFlat
                (\(TopBelow ( top_, belowTop )) ->
                    case top_ :: belowTop |> List.reverse of
                        bottom :: upAboveBottom ->
                            topBelow bottom upAboveBottom

                        -- shouldn't happen
                        [] ->
                            only top_
                )


{-| Glue the elements of a `... Empty possiblyOrNever`/`Never` [`Stack`](#Stacked)
to the [`top`](#top) of this [`Stack`](Stack)

    import Emptiable
    import Stack exposing (topBelow, onTopStack, onTopStackAdapt)

    Emptiable.empty
        |> onTopStackAdapt (topBelow 1 [ 2 ])
        |> onTopStack (topBelow -2 [ -1, 0 ])
    --> topBelow -2 [ -1, 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever` type of the argument

-}
onTopStackAdapt :
    Emptiable (Stacked element) possiblyOrNever
    ->
        (Emptiable (Stacked element) possiblyOrNeverIn_
         -> Emptiable (Stacked element) possiblyOrNever
        )
onTopStackAdapt stackToPutAbove =
    \stack ->
        stackOnTopAndAdaptTypeOf
            (\( possiblyOrNever, _ ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


{-| Glue the elements of a stack to the end of the stack

    import Stack exposing (topBelow, onTopStack)

    topBelow 1 [ 2 ]
        |> onTopStack (topBelow -1 [ 0 ])
    --> topBelow -1 [ 0, 1, 2 ]

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the `possiblyOrNever` type of the argument

-}
onTopStack :
    Emptiable (Stacked element) possiblyOrNeverAppended_
    ->
        (Emptiable (Stacked element) possiblyOrNever
         -> Emptiable (Stacked element) possiblyOrNever
        )
onTopStack stackToPutAbove =
    \stack ->
        stackOnTopAndAdaptTypeOf
            (\( _, possiblyOrNever ) -> possiblyOrNever)
            ( stackToPutAbove, stack )


stackOnTopAndAdaptTypeOf :
    (( possiblyOrNeverOnTop, possiblyOrNever ) -> possiblyOrNeverTakenOn)
    ->
        ( Emptiable (Stacked element) possiblyOrNeverOnTop
        , Emptiable (Stacked element) possiblyOrNever
        )
    -> Emptiable (Stacked element) possiblyOrNeverTakenOn
stackOnTopAndAdaptTypeOf takeOnType stacksDown =
    case stacksDown of
        ( Empty possiblyOrNeverOnTop, Empty possiblyOrNever ) ->
            Empty (takeOnType ( possiblyOrNeverOnTop, possiblyOrNever ))

        ( Empty _, Filled stackFilled ) ->
            stackFilled |> filled

        ( Filled (TopBelow ( top_, belowTop_ )), stackToPutBelow ) ->
            topBelow
                top_
                (belowTop_ ++ (stackToPutBelow |> toList))


{-| Put the elements of a `List` on [`top`](#top)

    import Stack exposing (topBelow, onTopStack)

    topBelow 1 [ 2 ]
        |> Stack.onTopGlue [ -1, 0 ]
    --> topBelow -1 [ 0, 1, 2 ]

`onTopGlue` only when the piped stack food is already `... Never`.
Glue a stack on top with

  - [`onTopStack`](#onTopStack) takes on the `possiblyOrNever` type of the piped food
  - [`onTopStackAdapt`](#onTopStackAdapt) takes on the **`possiblyOrNever` type of the argument**

-}
onTopGlue :
    List element
    ->
        (Emptiable (Stacked element) possiblyOrNever
         -> Emptiable (Stacked element) possiblyOrNever
        )
onTopGlue stackToPutOnTop =
    onTopStack (stackToPutOnTop |> fromList)


{-| Glue together a bunch of stacks

    import Emptiable
    import Stack exposing (topBelow)

    topBelow
        (topBelow 0 [ 1 ])
        [ topBelow 10 [ 11 ]
        , Emptiable.empty
        , topBelow 20 [ 21, 22 ]
        ]
        |> Stack.flatten
    --> topBelow 0 [ 1, 10, 11, 20, 21, 22 ]

For this to return a non-empty stack, all stacks must be non-empty

-}
flatten :
    Emptiable
        (Stacked
            (Emptiable (Stacked element) possiblyOrNever)
        )
        possiblyOrNever
    -> Emptiable (Stacked element) possiblyOrNever
flatten stackOfStacks =
    stackOfStacks
        |> Emptiable.fillMapFlat
            (\(TopBelow ( topList, belowTopLists )) ->
                belowTopLists
                    |> List.concatMap toList
                    |> fromList
                    |> onTopStackAdapt topList
            )



--


{-| Keep all [`filled`](Emptiable#filled) elements
and drop all [`empty`](Emptiable#empty) elements

    import Emptiable exposing (filled)
    import Stack exposing (topBelow)

    topBelow Emptiable.empty [ Emptiable.empty ]
        |> Stack.fills
    --> Emptiable.empty

    topBelow (filled 1) [ Emptiable.empty, filled 3 ]
        |> Stack.fills
    --> topBelow 1 [ 3 ]

As you can see, if only the top is [`fill`](Emptiable#fill) a value, the result is non-empty

-}
fills :
    Emptiable
        (Stacked
            (Emptiable element possiblyOrNever)
        )
        possiblyOrNever
    ->
        Emptiable
            (Stacked element)
            possiblyOrNever
fills =
    \stackOfHands ->
        stackOfHands
            |> Emptiable.fillMapFlat
                (\(TopBelow ( top_, belowTop_ )) ->
                    top_
                        |> Emptiable.fillMapFlat
                            (\topElement ->
                                topBelow topElement
                                    (belowTop_ |> List.filterMap Emptiable.toMaybe)
                            )
                )



--


{-| Change every element based on its current value and `{ index }`

    import Stack exposing (topBelow)

    topBelow 1 [ 4, 9 ]
        |> Stack.map (\_ -> negate)
    --> topBelow -1 [ -4, -9 ]

    topBelow 1 [ 2, 3, 4 ]
        |> Stack.map (\{ index } n -> index * n)
    --> topBelow 0 [ 2, 6, 12 ]

-}
map :
    ({ index : Int } -> element -> elementMapped)
    ->
        (Emptiable (Stacked element) possiblyOrNever
         -> Emptiable (Stacked elementMapped) possiblyOrNever
        )
map changeElement =
    \stack ->
        stack
            |> Emptiable.fillMapFlat
                (\(TopBelow ( topElement, belowTop )) ->
                    topBelow
                        (topElement |> changeElement { index = 0 })
                        (belowTop
                            |> List.indexedMap
                                (\indexBelow ->
                                    changeElement
                                        { index = 1 + indexBelow }
                                )
                        )
                )


{-| Combine its elements with elements of a given stack at the same location.
If one stack is longer, the extra elements are dropped

    import Stack exposing (topBelow)

    topBelow "alice" [ "bob", "chuck" ]
        |> Stack.and (topBelow 2 [ 5, 7, 8 ])
    --> topBelow ( "alice", 2 ) [ ( "bob", 5 ), ( "chuck", 7 ) ]

    topBelow 4 [ 5, 6 ]
        |> Stack.and (topBelow 1 [ 2, 3 ])
        |> Stack.map (\_ ( n0, n1 ) -> n0 + n1)
    --> topBelow 5 [ 7, 9 ]

-}
and :
    Emptiable (Stacked anotherElement) possiblyOrNever
    ->
        (Emptiable (Stacked element) possiblyOrNever
         -> Emptiable (Stacked ( element, anotherElement )) possiblyOrNever
        )
and anotherStack =
    \stack ->
        stack
            |> fillAnd anotherStack
            |> fillMapFlat
                (\( TopBelow ( topElement, belowTop ), TopBelow ( anotherTop, anotherBelowTop ) ) ->
                    topBelow
                        ( topElement, anotherTop )
                        (List.map2 Tuple.pair belowTop anotherBelowTop)
                )


{-| Reduce in a [direction](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)

    import Linear exposing (Direction(..))
    import Stack exposing (topBelow)

    topBelow 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" Down String.cons
    --> "live"

    topBelow 'l' [ 'i', 'v', 'e' ]
        |> Stack.foldFrom "" Up String.cons
    --> "evil"

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

-}
foldFrom :
    accumulationValue
    -> Linear.Direction
    -> (element -> accumulationValue -> accumulationValue)
    ->
        (Emptiable (Stacked element) possiblyOrNever_
         -> accumulationValue
        )
foldFrom initialAccumulationValue direction reduce =
    \stack ->
        stack
            |> toList
            |> List.Linear.foldFrom
                initialAccumulationValue
                direction
                reduce


{-| Fold, starting from one end as the initial accumulation value,
then reducing what's accumulated in a given [`Direction`](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)

    import Linear exposing (Direction(..))
    import Stack exposing (topBelow)

    topBelow 234 [ 345, 543 ]
        |> Stack.fold Up max
    --> 543

Limited by the fact that the accumulated value must be of the same type as an element?
→ [`Stack.foldOnto`](#foldOnto)

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

-}
fold :
    Linear.Direction
    -> (element -> (element -> element))
    ->
        (Emptiable (Stacked element) Never
         -> element
        )
fold direction reduce =
    \stack ->
        stack
            |> foldOnto identity direction reduce


{-| Fold, starting from one end element transformed to the initial accumulation value,
then reducing what's accumulated in a given [`Direction`](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)

    import Linear exposing (Direction(..))
    import Stack exposing (topBelow)

    topBelow 234 [ 345, 543 ]
        |> Stack.foldOnto SetFilled.only Up SetFilled.insert

A simpler version is

    Stack.fold =
        Stack.foldOnto identity

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

-}
foldOnto :
    (element -> accumulated)
    -> Linear.Direction
    -> (element -> (accumulated -> accumulated))
    ->
        (Emptiable (Stacked element) Never
         -> accumulated
        )
foldOnto initialEndToAccumulator direction reduce =
    -- doesn't use a native implementation for performance reasons
    -- or maybe I'm just lazy. Decide for yourself :)
    \stackFilled ->
        stackFilled
            |> toList
            |> List.Linear.foldFrom
                Emptiable.empty
                direction
                (\element soFar ->
                    (case soFar of
                        Empty _ ->
                            element |> initialEndToAccumulator

                        Filled reducedSoFar ->
                            reducedSoFar |> reduce element
                    )
                        |> Emptiable.filled
                )
            |> -- impossible
               Emptiable.fillElseOnEmpty
                (\_ -> stackFilled |> top |> initialEndToAccumulator)


{-| ∑ Total every element number

    import Emptiable

    topBelow 1 [ 2, 3 ] |> Stack.sum
    --> 6

    topBelow 1 (List.repeat 5 1) |> Stack.sum
    --> 6

    Emptiable.empty |> Stack.sum
    --> 0

-}
sum : Emptiable (Stacked number) possiblyOrNever_ -> number
sum =
    foldFrom 0 Up (\current soFar -> soFar + current)


{-| Convert to a `List`

    import Stack exposing (topBelow)

    topBelow 1 [ 7 ] |> Stack.toList
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
            Filled (TopBelow ( top_, belowTop_ )) ->
                top_ :: belowTop_

            Empty _ ->
                []


{-| Convert to a `String`

    import Stack exposing (topBelow)

    topBelow 'H' [ 'i' ] |> Stack.toString
    --> "Hi"

Don't try to use this prematurely.
Keeping type information as long as possible is always a win

-}
toString : Emptiable (Stacked Char) possiblyOrNever_ -> String
toString =
    \stack ->
        stack |> toList |> String.fromList


{-| Convert to a non-empty list tuple `( top, List belowElement )`
to be used by another library

    import Stack exposing (topBelow, toTopBelow)

    topBelow "hi" [ "there", "👋" ]
        |> toTopBelow
    --> ( "hi", [ "there", "👋" ] )

Don't use [`toTopBelow`](#toTopBelow) to destructure a stack.
Instead: [`Stack.top`](Stack#top), [`Stack.topRemove`](#topRemove)

-}
toTopBelow :
    Emptiable (Stacked element) Never
    -> ( element, List element )
toTopBelow =
    \filledStack ->
        let
            (TopBelow topBelowTuple) =
                filledStack |> fill
        in
        topBelowTuple
