module Scroll.Test exposing (tests)

import Emptiable exposing (fillMapFlat, filled)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Linear exposing (Direction(..))
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
            "items exist on the Linear.Direction"
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
            "no items on the Linear.Direction"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.to
                        (side |> Linear.opposite |> Scroll.nearest)
                    |> Expect.equal Emptiable.empty
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(Scroll.toEndGap Linear.Direction >> Scroll.to (Linear.Direction |> Linear.opposite)) == Scroll.toEnd Linear.Direction`"
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
            "`(Scroll.toGap Linear.Direction >> Scroll.to Linear.Direction) == Scroll.to Linear.Direction`"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.toGap side
                    |> Scroll.to (side |> Scroll.nearest)
                    |> Expect.equal
                        (scroll |> Scroll.to (side |> Scroll.nearest))
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(Scroll.toEnd Linear.Direction >> Scroll.to Linear.Direction) == Emptiable.empty`"
            (\{ scroll, side } ->
                scroll
                    |> Scroll.toEnd side
                    |> Scroll.to (side |> Scroll.nearest)
                    |> Expect.equal Emptiable.empty
            )
        , Test.fuzz
            (sideAndScrollFuzz scrollFocusSideFuzz)
            "repeating `Scroll.to (Linear.Direction |> Scroll.nearest)` length times results in empty"
            (\{ scroll, side } ->
                Scroll.to (side |> Scroll.nearest)
                    |> List.repeat
                        (1 + (scroll |> Scroll.side side |> Stack.length))
                    |> List.foldl fillMapFlat (scroll |> filled)
                    |> Expect.equal Emptiable.empty
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
                    |> Expect.equal Emptiable.empty
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
    Scroll item FocusGap possiblyOrNever
    -> Scroll item FocusGap possiblyOrNever
    -> Expectation
expectEqualScroll expectedScroll =
    \actualScroll ->
        actualScroll
            |> Expect.equal expectedScroll


sideFuzz : Fuzzer Linear.Direction
sideFuzz =
    Fuzz.oneOf
        [ Down |> Fuzz.constant
        , Up |> Fuzz.constant
        ]


scrollFuzz : Fuzzer item -> Fuzzer (Scroll item FocusGap Possibly)
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
