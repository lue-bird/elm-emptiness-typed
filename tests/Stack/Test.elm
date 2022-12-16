module Stack.Test exposing (tests)

import Emptiable exposing (Emptiable)
import Expect
import Fuzz
import Stack exposing (Stacked, removeTop, top, topBelow)
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
            "topBelow = fromList"
            (\( head, tail ) ->
                Stack.topBelow head tail
                    |> Stack.toList
                    |> Expect.equalLists
                        ((head :: tail)
                            |> Stack.fromList
                            |> Stack.toList
                        )
            )
        , Test.fuzz
            (Stack.filledFuzz Fuzz.int)
            "topBelow: top=head removeTop=tail"
            (\stackFilled ->
                stackFilled
                    |> Expect.equal
                        (topBelow (stackFilled |> top)
                            (stackFilled |> removeTop |> Stack.toList)
                        )
            )
        ]


reverseTest : Test
reverseTest =
    describe "reverse"
        [ Test.fuzz
            (Stack.fuzz Fuzz.int)
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
            (Stack.fuzz Fuzz.int)
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
