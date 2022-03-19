module Stack.Test exposing (expectEqualStack, fuzzStackFilled, tests)

import Expect
import Fuzz exposing (Fuzzer)
import Hand exposing (Empty, Hand)
import Stack exposing (Stacked, removeTop, top, topDown)
import Test exposing (Test, describe)


tests : Test
tests =
    describe "Stack"
        [ Test.fuzz
            (Fuzz.list Fuzz.int)
            "fromList |> toList = identity"
            (\list ->
                list
                    |> Stack.fromList
                    |> Stack.toList
                    |> Expect.equalLists list
            )
        , Test.fuzz
            (Fuzz.tuple ( Fuzz.int, Fuzz.list Fuzz.int ))
            "topDown = fromList"
            (\( head, tail ) ->
                Stack.topDown head tail
                    |> Stack.toList
                    |> Expect.equalLists
                        ((head :: tail)
                            |> Stack.fromList
                            |> Stack.toList
                        )
            )
        , Test.fuzz
            (fuzzStackFilled Fuzz.int)
            "topDown: top=head removeTop=tail"
            (\stackFilled ->
                stackFilled
                    |> Expect.equal
                        (topDown (stackFilled |> top)
                            (stackFilled |> removeTop |> Stack.toList)
                        )
            )
        ]



-- common


expectEqualStack :
    Hand (Stacked element) possiblyOrNeverExpected_ Empty
    -> Hand (Stacked element) possiblyOrNeverActual_ Empty
    -> Expect.Expectation
expectEqualStack expectedStack =
    \actualStack ->
        (actualStack |> Stack.toList)
            |> Expect.equalLists
                (expectedStack |> Stack.toList)


fuzzStackFilled :
    Fuzzer element
    -> Fuzzer (Hand (Stacked element) never_ Empty)
fuzzStackFilled elementFuzz =
    Fuzz.constant topDown
        |> Fuzz.andMap elementFuzz
        |> Fuzz.andMap (Fuzz.list elementFuzz)
