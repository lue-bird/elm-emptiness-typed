module Stack exposing
    ( Stacked(..)
    , one, topBelow
    , fromTopBelow, fromList, fromString
    , fuzz, filledFuzz
    , top
    , length
    , onTopLay, removeTop, topAlter
    , reverse
    , fills
    , attach, attachAdapt
    , flatten
    , map, and
    , foldFrom, foldFromOne, fold, sum
    , toTopBelow, toList, toString
    )

{-| 📚 An **emptiable or non-empty** structure where
[`top`](#top), [`removeTop`](#removeTop), [`onTopLay`](#onTopLay) are `O(n)`

@docs Stacked


## create

[`Emptiable.empty`](Emptiable#empty) to create an `Empty Possibly` stack

@docs one, topBelow
@docs fromTopBelow, fromList, fromString
@docs fuzz, filledFuzz


## scan

@docs top
@docs length

[`removeTop`](#removeTop) brings out everything below the [`top`](#top)


## alter

@docs onTopLay, removeTop, topAlter
@docs reverse


### filter

@docs fills


### attaching

@docs attach, attachAdapt
@docs flatten


## transform

@docs map, and
@docs foldFrom, foldFromOne, fold, sum
@docs toTopBelow, toList, toString

-}

import Emptiable exposing (Emptiable(..), empty, fill, filled)
import Fuzz exposing (Fuzzer)
import Linear exposing (Direction(..))
import List.Linear
import Possibly exposing (Possibly)


{-| The representation of a non-empty stack on the `Filled` case.
[`top`](#top), [`removeTop`](#removeTop), [`onTopLay`](#onTopLay) are `O(n)`


#### in arguments

[`Emptiable`](Emptiable) `(StackFilled ...) Never` → `stack` is non-empty:

    top : Emptiable (Stacked element) Never -> element


#### in results

[`Emptiable`](Emptiable) `(StackFilled ...)`[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `Empty` → stack could be empty

    fromList : List element -> Emptiable (Stacked element) Possibly

We can treat it like any [`Emptiable`](Emptiable):

    import Emptiable exposing (Emptiable(..), filled, map)
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
        |> map (filled >> top)
    --: Emptiable String Possibly

-}
type Stacked element
    = TopBelow ( element, List element )


{-| A stack with just 1 single element

    import Emptiable
    import Stack exposing (onTopLay)

    Stack.one ":)"
    --> Emptiable.empty |> onTopLay ":)"

-}
one : element -> Emptiable (Stacked element) never_
one onlyElement =
    topBelow onlyElement []


{-| A stack from a top element and a `List` of elements below

    Stack.topBelow ":)" [ "wait", "a", "moment" ]
    --> Stack.topBelow "wait" [ "a", "moment" ]
    -->     |> onTopLay ":)"

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
The `List`s `head` becomes [`top`](#top), its `tail` is attachd below

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
The `String`s head becomes [`top`](#top), its tail is attachd below

    import Possibly exposing (Possibly)
    import Emptiable
    import Stack exposing (topBelow)

    "" |> Stack.fromString
    --> Emptiable.empty

    "hello" |> Stack.fromString
    --> topBelow 'h' [ 'e', 'l', 'l', 'o' ]
    --: Emptiable (Stacked Char) Possibly

When constructing from known elements, always prefer

    import Stack exposing (topBelow)

    onTopLay 'h' ("ello" |> Stack.fromString)

-}
fromString : String -> Emptiable (Stacked Char) Possibly
fromString =
    \string ->
        string |> String.toList |> fromList


{-| `Emptiable Stacked Never` [`Fuzzer`](https://dark.elm.dmy.fr/packages/elm-explorations/test/latest/Fuzz#Fuzzer).
Generates stacks of varying length <= 32

    import Stack exposing (topBelow)
    import Fuzz

    Stack.filledFuzz (Fuzz.intRange 0 9)
        |> Fuzz.examples 3
    --> [ topBelow 4 [ 2, 2, 5, 3, 8, 9, 4, 1, 0, 6, 6, 4, 7, 2, 6, 5 ]
    --> , topBelow 3 [ 4, 4, 5, 1, 7, 4, 2, 5, 6, 9, 7, 0, 1, 4, 1, 3, 2, 9, 6, 9, 0, 8, 3, 3, 3, 1, 5, 4, 9, 5, 2, 8 ]
    --> , topBelow 5 [ 4, 9, 8, 9 ]
    --> ]

-}
filledFuzz :
    Fuzzer element
    -> Fuzzer (Emptiable (Stacked element) never_)
filledFuzz elementFuzz =
    Fuzz.constant topBelow
        |> Fuzz.andMap elementFuzz
        |> Fuzz.andMap (Fuzz.list elementFuzz)


{-| `Emptiable (Stacked ...) Possibly` [`Fuzzer`](https://dark.elm.dmy.fr/packages/elm-explorations/test/latest/Fuzz#Fuzzer).
Generates stacks of varying length <= 32

    import Stack exposing (topBelow)
    import Fuzz

    Stack.fuzz (Fuzz.intRange 0 9)
        |> Fuzz.examples 3
    --> [ topBelow 2 [ 2, 5, 3, 8, 9, 4, 1, 0, 6, 6, 4, 7, 2, 6, 5 ]
    --> , topBelow 8 [ 8, 0, 9, 8, 1, 0, 4, 1, 4, 6, 3, 4 ]
    --> , topBelow 9 [ 7, 1, 5, 8, 2, 8, 3, 7, 4, 7 ]
    --> ]
    --: List (Emptiable (Stacked Int) Possibly)

-}
fuzz :
    Fuzzer element
    -> Fuzzer (Emptiable (Stacked element) Possibly)
fuzz elementFuzz =
    Fuzz.list elementFuzz
        |> Fuzz.map fromList



--


{-| The first value

    import Stack exposing (top, onTopLay)

    Stack.one 3
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

    Stack.one 3
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
    --> Stack.one 1

-}
onTopLay :
    element
    -> Emptiable (Stacked element) possiblyOrNever_
    -> Emptiable (Stacked element) never_
onTopLay toPutOnTopOfAllOtherElements =
    \stack ->
        topBelow toPutOnTopOfAllOtherElements (stack |> toList)


{-| Everything after the [first element](#top)

    import Stack exposing (topBelow)
    import Linear exposing (Direction(..))

    Stack.one 2
        |> Stack.onTopLay 3
        |> Stack.attach Down (topBelow 1 [ 0 ])
        |> Stack.removeTop
    --> topBelow 0 [ 3, 2 ]
    --: Emptiable (Stacked number_) Possibly

-}
removeTop :
    Emptiable (Stacked element) Never
    -> Emptiable (Stacked element) Possibly
removeTop =
    \stackFilled ->
        let
            (TopBelow ( _, belowTop )) =
                stackFilled |> Emptiable.fill
        in
        belowTop |> fromList


{-| Change the [first element](#top) based on its current value

    import Stack

    Stack.topBelow "Helpy IQ 4000 – the amazing vacuum cleaner"
        [ "faster and more thorough than ever seen before!" ]
        |> Stack.topAlter (\firstLine -> "Introducing: " ++ firstLine)
    --> Stack.topBelow "Introducing: Helpy IQ 4000 – the amazing vacuum cleaner" [ "faster and more thorough than ever seen before!" ]

-}
topAlter : (element -> element) -> Emptiable (Stacked element) possiblyOrNever -> Emptiable (Stacked element) possiblyOrNever
topAlter topChange =
    \stack ->
        stack
            |> Emptiable.map
                (\(TopBelow ( stackTop, stackBelow )) ->
                    TopBelow ( stackTop |> topChange, stackBelow )
                )


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
            |> Emptiable.mapFlat
                (\(TopBelow ( top_, belowTop )) ->
                    case top_ :: belowTop |> List.reverse of
                        bottom :: upAboveBottom ->
                            topBelow bottom upAboveBottom

                        -- shouldn't happen
                        [] ->
                            one top_
                )


{-| Glue the elements of a given stack to the end
in a given [direction](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/)
of the stack

    import Linear exposing (Direction(..))
    import Stack exposing (topBelow)

    topBelow 1 [ 2 ]
        |> Stack.attach Down (topBelow -1 [ 0 ])
    --> topBelow -1 [ 0, 1, 2 ]

    topBelow 1 [ 2 ]
        |> Stack.attach Down ([ -1, 0 ] |> Stack.fromList)
    --> topBelow -1 [ 0, 1, 2 ]

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

Compared to [`attachAdapt`](#attachAdapt)

  - [`attach`](#attach) takes on the `possiblyOrNever` type of the incoming attachment Stack
  - [`attachAdapt`](#attachAdapt) takes on the `possiblyOrNever` type of the argument

-}
attach :
    Linear.Direction
    -> Emptiable (Stacked element) attachmentPossiblyOrNever_
    ->
        (Emptiable (Stacked element) possiblyOrNever
         -> Emptiable (Stacked element) possiblyOrNever
        )
attach direction stackAttachment =
    \stack ->
        stackGlueAdaptFrom direction
            (\( _, possiblyOrNever ) -> possiblyOrNever)
            ( stackAttachment, stack )


{-| Glue the elements of a given stack
to the end in a given [direction](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/)
of the stack, taking on the emptiness knowledge of the given stack

    import Linear exposing (Direction(..))
    import Emptiable
    import Stack exposing (topBelow)

    Emptiable.empty
        |> Stack.attachAdapt Down (topBelow 1 [ 2 ])
        |>  Stack.attachAdapt Down (topBelow -2 [ -1, 0 ])
    --> topBelow -2 [ -1, 0, 1, 2 ]

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

Compared to [`attach`](#attach)

  - [`attach`](#attach) takes on the `possiblyOrNever` type of the incoming attachment Stack
  - [`attachAdapt`](#attachAdapt) takes on the `possiblyOrNever` type of the argument

-}
attachAdapt :
    Linear.Direction
    -> Emptiable (Stacked element) possiblyOrNever
    ->
        (Emptiable (Stacked element) possiblyOrNeverIn_
         -> Emptiable (Stacked element) possiblyOrNever
        )
attachAdapt direction stackToGlue =
    \stack ->
        stackGlueAdaptFrom direction
            (\( possiblyOrNever, _ ) -> possiblyOrNever)
            ( stackToGlue, stack )


stackGlueAdaptFrom :
    Linear.Direction
    -> (( possiblyOrNeverOnTop, possiblyOrNever ) -> possiblyOrNeverTakenOn)
    ->
        ( Emptiable (Stacked element) possiblyOrNeverOnTop
        , Emptiable (Stacked element) possiblyOrNever
        )
    -> Emptiable (Stacked element) possiblyOrNeverTakenOn
stackGlueAdaptFrom direction takeOnType stacksDown =
    case direction of
        Down ->
            case stacksDown of
                ( Empty possiblyOrNeverOnTop, Empty possiblyOrNever ) ->
                    Empty (takeOnType ( possiblyOrNeverOnTop, possiblyOrNever ))

                ( Empty _, Filled stackFilled ) ->
                    stackFilled |> filled

                ( Filled (TopBelow ( top_, belowTop_ )), stackToPutBelow ) ->
                    topBelow
                        top_
                        (belowTop_ ++ (stackToPutBelow |> toList))

        Up ->
            case stacksDown of
                ( Empty possiblyOrNeverOnTop, Empty possiblyOrNever ) ->
                    Empty (takeOnType ( possiblyOrNeverOnTop, possiblyOrNever ))

                ( Filled stackFilled, Empty _ ) ->
                    stackFilled |> filled

                ( stackToPutBelow, Filled (TopBelow ( top_, belowTop_ )) ) ->
                    topBelow
                        top_
                        (belowTop_ ++ (stackToPutBelow |> toList))


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

For this to return a filled stack, all stacks must be filled

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
        |> Emptiable.mapFlat
            (\(TopBelow ( topList, belowTopLists )) ->
                belowTopLists
                    |> List.concatMap toList
                    |> fromList
                    |> attachAdapt Down topList
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
            |> Emptiable.mapFlat
                (\(TopBelow ( top_, belowTop_ )) ->
                    top_
                        |> Emptiable.mapFlat
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
            |> Emptiable.mapFlat
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
            |> Emptiable.and anotherStack
            |> Emptiable.mapFlat
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

To fold into a different non-empty structure → [`Stack.foldFromOne`](#foldFromOne)

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
            |> foldFromOne identity direction reduce


{-| Fold, starting from one end element transformed to the initial accumulation value,
then reducing what's accumulated in a given [`Direction`](https://package.elm-lang.org/packages/lue-bird/elm-linear-direction/latest/)

Usually used to convert to a different non-empty structure

    -- module SetFilled exposing (SetFilled, fromStack, insert, one)

    import Linear exposing (Direction(..))
    import Emptiable exposing (Emptiable)
    import Stack exposing (topBelow)
    import Set exposing (Set)

    fromStack : Emptiable (Stacked comparable) Never -> SetFilled comparable
    fromStack =
        Stack.foldFromOne one Up insert

    type alias SetFilled comparable =
        { anElement : comparable
        , otherElements : Set comparable
        }

    one : comparable -> SetFilled comparable
    one onlyElement =
        { anElement = onlyElement, otherElements = Set.empty }

    insert : comparable -> (SetFilled comparable -> SetFilled comparable)
    insert toInsert =
        \setFilled ->
            if toInsert == setFilled.anElement then
                setFilled
            else
                -- new element
                { setFilled
                    | otherElements =
                        setFilled.otherElements |> Set.insert toInsert
                }

    topBelow 3 [ 4, 5, 4, 3 ]
        |> fromStack
    --> { anElement = 3, otherElements = Set.fromList [ 5, 4 ] }

(Know there's is something better than `SetFilled`: [`KeySet`](https://dark.elm.dmy.fr/packages/lue-bird/elm-keysset/latest/KeySet))

[`fold`](#fold) is a simple version that folds directly from the start element:

    Stack.fold =
        Stack.foldFromOne identity

Be aware:

  - `Down` = indexes decreasing, not: from the [`top`](#top) lower
  - `Up` = indexes increasing, not: from the bottom up

-}
foldFromOne :
    (element -> accumulated)
    -> Linear.Direction
    -> (element -> (accumulated -> accumulated))
    ->
        (Emptiable (Stacked element) Never
         -> accumulated
        )
foldFromOne initialEndToAccumulator direction reduce =
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
Instead: [`Stack.top`](Stack#top), [`Stack.removeTop`](#removeTop)

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
