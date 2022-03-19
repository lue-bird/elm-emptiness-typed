module Scroll.Test exposing (tests)

import Expect
import Fuzz exposing (Fuzzer)
import Hand exposing (fillMapFlat, filled)
import Scroll exposing (Side(..), focusGap, focusGapBeyondEnd, focusItem, focusItemEnd, sideOpposite)
import Stack exposing (removeTop, top)
import Stack.Test exposing (expectEqualStack, fuzzStackFilled)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Scroll"
        [ describe "alter" [ glueToEndTest ]
        , describe "navigate" [ focusItemTest ]
        , describe "transform" [ toStackTest ]
        ]



-- alter


glueToEndTest : Test
glueToEndTest =
    describe "sideAlter"
        [ describe "replace"
            [ Test.fuzz (fuzzStackFilled Fuzz.int)
                "Before"
                (\stack ->
                    Scroll.only (stack |> top)
                        |> Scroll.sideAlter Before (\_ -> stack |> removeTop)
                        |> Scroll.toStack
                        |> expectEqualStack (stack |> Stack.reverse)
                )
            , Test.fuzz (fuzzStackFilled Fuzz.int)
                "After"
                (\stack ->
                    Scroll.only (stack |> top)
                        |> Scroll.sideAlter After
                            (\_ -> stack |> removeTop)
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
                        |> Scroll.sideAlter side (\_ -> sideStack)
                )
                |> Fuzz.andMap Fuzz.int
                |> Fuzz.andMap (fuzzStackFilled Fuzz.int)

        sideAndScrollFuzz scrollFuzz =
            Fuzz.constant
                (\side scroll ->
                    { side = side, scroll = scroll side }
                )
                |> Fuzz.andMap sideFuzz
                |> Fuzz.andMap scrollFuzz
    in
    describe "focusItem"
        [ Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "items exist on the Side"
            (\{ scroll, side } ->
                scroll
                    |> focusItem side
                    |> fillMapFlat (Scroll.side side)
                    |> Expect.equal
                        (scroll
                            |> Scroll.side side
                            |> fillMapFlat (Stack.removeTop << filled)
                        )
            )
        , Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "no items on the Side"
            (\{ scroll, side } ->
                scroll
                    |> focusItem (side |> sideOpposite)
                    |> Expect.equal Hand.empty
            )
        , Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(focusGapBeyondEnd Side >> focusItem (Side |> sideOpposite)) == focusItemEnd Side`"
            (\{ scroll, side } ->
                scroll
                    |> focusGapBeyondEnd side
                    |> focusItem (side |> sideOpposite)
                    |> Expect.equal
                        (scroll |> focusItemEnd side |> filled)
            )
        , Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(focusGap Side >> focusItem Side) == focusItem Side`"
            (\{ scroll, side } ->
                scroll
                    |> focusGap side
                    |> focusItem side
                    |> Expect.equal (scroll |> focusItem side)
            )
        , Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "`(focusItemEnd Side >> focusItem Side) == Hand.empty`"
            (\{ scroll, side } ->
                scroll
                    |> focusItemEnd side
                    |> focusItem side
                    |> Expect.equal Hand.empty
            )
        , Test.fuzz (sideAndScrollFuzz scrollFocusSideFuzz)
            "repeating `focusItem Side` length times results in empty"
            (\{ scroll, side } ->
                focusItem side
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


sideFuzz : Fuzzer Side
sideFuzz =
    Fuzz.oneOf
        [ Before |> Fuzz.constant
        , After |> Fuzz.constant
        ]
