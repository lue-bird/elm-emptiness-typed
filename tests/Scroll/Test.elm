module Scroll.Test exposing (tests)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Hand exposing (fillMapFlat, filled)
import Linear exposing (DirectionLinear(..))
import Possibly exposing (Possibly)
import Scroll exposing (FocusGap, Scroll)
import Stack exposing (top, topRemove)
import Stack.Test exposing (expectEqualStack, stackFilledFuzz, stackFuzz)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Scroll"
        [ describe "alter" [ glueToEndTest, mirrorTest ]
        , describe "navigate" [ focusItemTest ]
        , describe "transform" [ toStackTest ]
        ]



-- alter


mirrorTest : Test
mirrorTest =
    describe "mirror"
        [ Test.fuzz
            (scrollFuzz Fuzz.int)
            "(mirror >> mirror) = identity"
            (\scroll ->
                scroll
                    |> Scroll.mirror
                    |> Scroll.mirror
                    |> expectEqualScroll scroll
            )
        ]


glueToEndTest : Test
glueToEndTest =
    describe "sideAlter"
        [ describe "replace"
            [ Test.fuzz
                (stackFilledFuzz Fuzz.int)
                "Down"
                (\stack ->
                    Scroll.only (stack |> top)
                        |> Scroll.sideAlter
                            ( Down, \_ -> stack |> topRemove )
                        |> Scroll.toStack
                        |> expectEqualStack (stack |> Stack.reverse)
                )
            , Test.fuzz
                (stackFilledFuzz Fuzz.int)
                "Up"
                (\stack ->
                    Scroll.only (stack |> top)
                        |> Scroll.sideAlter
                            ( Up, \_ -> stack |> topRemove )
                        |> Scroll.toStack
                        |> expectEqualStack stack
                )
            ]
        ]



-- navigate focus


focusItemTest : Test
focusItemTest =
    let
        scrollFocusSideFuzz =
            Fuzz.constant
                (\focus_ sideStack side ->
                    Scroll.only focus_
                        |> Scroll.sideAlter
                            ( side, \_ -> sideStack )
                )
                |> Fuzz.andMap Fuzz.int
                |> Fuzz.andMap (stackFilledFuzz Fuzz.int)

        sideAndScrollFuzz scrollFuzz_ =
            Fuzz.constant
                (\side scroll ->
                    { side = side
                    , scroll = scroll side
                    }
                )
                |> Fuzz.andMap sideFuzz
                |> Fuzz.andMap scrollFuzz_
    in
    describe "Scroll.to"
        [ Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "items exist on the DirectionLinear"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.to (side |> Scroll.nearest)
                    |> fillMapFlat (Scroll.side side)
                    |> Expect.equal
                        (scroll
                            |> Scroll.side side
                            |> fillMapFlat (Stack.topRemove << filled)
                        )
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "no items on the DirectionLinear"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.to
                        (side |> Linear.opposite |> Scroll.nearest)
                    |> Expect.equal Hand.empty
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(Scroll.toEndGap DirectionLinear >> Scroll.to (DirectionLinear |> Linear.opposite)) == Scroll.toEnd DirectionLinear`"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.toEndGap side
                    |> Scroll.to
                        (side |> Linear.opposite |> Scroll.nearest)
                    |> Expect.equal
                        (scroll |> Scroll.toEnd side |> filled)
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(Scroll.toGap DirectionLinear >> Scroll.to DirectionLinear) == Scroll.to DirectionLinear`"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.toGap side
                    |> Scroll.to (side |> Scroll.nearest)
                    |> Expect.equal
                        (scroll |> Scroll.to (side |> Scroll.nearest))
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(Scroll.toEnd DirectionLinear >> Scroll.to DirectionLinear) == Hand.empty`"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.toEnd side
                    |> Scroll.to (side |> Scroll.nearest)
                    |> Expect.equal Hand.empty
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "repeating `Scroll.to (DirectionLinear |> Scroll.nearest)` length times results in empty"
            (\{ scroll, side } ->
                Scroll.to (side |> Scroll.nearest)
                    |> List.repeat
                        (1 + (scroll |> Scroll.side side |> Stack.length))
                    |> List.foldl fillMapFlat (scroll |> filled)
                    |> Expect.equal Hand.empty
            )
        ]



-- transform


toStackTest : Test
toStackTest =
    describe "toStack"
        [ test "empty"
            (\_ ->
                Scroll.empty
                    |> Scroll.toStack
                    |> Expect.equal Hand.empty
            )
        , test "only"
            (\_ ->
                Scroll.only 3
                    |> Scroll.toStack
                    |> Expect.equal (Stack.only 3)
            )
        ]



-- common


expectEqualScroll :
    Scroll item possiblyOrNever FocusGap
    -> Scroll item possiblyOrNever FocusGap
    -> Expectation
expectEqualScroll expectedScroll =
    \actualScroll ->
        actualScroll
            |> Expect.equal expectedScroll


sideFuzz : Fuzzer DirectionLinear
sideFuzz =
    Fuzz.oneOf
        [ Down |> Fuzz.constant
        , Up |> Fuzz.constant
        ]


scrollFuzz : Fuzzer item -> Fuzzer (Scroll item Possibly FocusGap)
scrollFuzz itemFuzz =
    Fuzz.constant
        (\before focusOnly after ->
            focusOnly
                |> Scroll.sideAlter
                    ( Down, \_ -> before )
                |> Scroll.sideAlter
                    ( Up, \_ -> after )
        )
        |> Fuzz.andMap (stackFuzz itemFuzz)
        |> Fuzz.andMap
            (Fuzz.oneOf
                [ Scroll.empty |> Fuzz.constant
                , itemFuzz |> Fuzz.map Scroll.only
                ]
            )
        |> Fuzz.andMap (stackFuzz itemFuzz)
