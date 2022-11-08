module Stack.Test exposing (expectEqualStack, stackFilledFuzz, stackFuzz, tests)

import Emptiable exposing (Emptiable)
import Expect
import Fuzz exposing (Fuzzer)
import Possibly exposing (Possibly)
import Stack exposing (Stacked, top, topDown, topRemove)
import Test exposing (Test, describe)


tests : Test
tests =
    describe "Stack"
        [ describe "alter" [ reverseTest ]
        , Test.fuzz
            (Fuzz.list Fuzz.int)
            "fromList |> toList = identity"
            (\list ->
                list
                    |> Stack.fromList
                    |> Stack.toList
                    |> Expect.equalLists list
            )
        , Test.fuzz
            (Fuzz.pair Fuzz.int (Fuzz.list Fuzz.int))
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
            (stackFilledFuzz Fuzz.int)
            "topDown: top=head topRemove=tail"
            (\stackFilled ->
                stackFilled
                    |> Expect.equal
                        (topDown (stackFilled |> top)
                            (stackFilled |> topRemove |> Stack.toList)
                        )
            )
        ]


reverseTest : Test
reverseTest =
    describe "reverse"
        [ Test.fuzz
            (stackFuzz Fuzz.int)
            "(reverse >> toList) = (toList >> reverse)"
            (\stack ->
                stack
                    |> Stack.reverse
                    |> Stack.toList
                    |> Expect.equalLists
                        (stack
                            |> Stack.toList
                            |> List.reverse
                        )
            )
        , Test.fuzz
            (stackFuzz Fuzz.int)
            "(reverse >> reverse) = identity"
            (\stack ->
                stack
                    |> Stack.reverse
                    |> Stack.reverse
                    |> expectEqualStack stack
            )
        ]



-- common


expectEqualStack :
    Emptiable (Stacked element) possiblyOrNeverExpected_
    -> Emptiable (Stacked element) possiblyOrNeverActual_
    -> Expect.Expectation
expectEqualStack expectedStack =
    \actualStack ->
        (actualStack |> Stack.toList)
            |> Expect.equalLists
                (expectedStack |> Stack.toList)


stackFilledFuzz :
    Fuzzer element
    -> Fuzzer (Emptiable (Stacked element) never_)
stackFilledFuzz elementFuzz =
    Fuzz.constant topDown
        |> Fuzz.andMap elementFuzz
        |> Fuzz.andMap (Fuzz.list elementFuzz)


stackFuzz :
    Fuzzer element
    -> Fuzzer (Emptiable (Stacked element) Possibly)
stackFuzz elementFuzz =
    Fuzz.list elementFuzz
        |> Fuzz.map Stack.fromList
