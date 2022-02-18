module FocusListTest exposing (tests)

import Expect
import Fillable exposing (filled)
import FocusList exposing (ListFocusingHole)
import Stack exposing (topAndBelow)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "FocusList"
        [ describe "create" [ emptyTest, onlyTest, appendTest ]
        , describe "navigate" [ nextTest, previousTest ]
        ]



-- create


emptyTest : Test
emptyTest =
    test "empty creates a FocusList for an empty list"
        (\_ ->
            FocusList.empty
                |> FocusList.toStack
                |> Expect.equal Fillable.empty
        )


onlyTest : Test
onlyTest =
    test "only creates a FocusList with a single element"
        (\_ ->
            FocusList.only 3
                |> FocusList.toStack
                |> Expect.equal (Stack.only 3)
        )



-- modify


appendTest : Test
appendTest =
    let
        listWithFocusThat : ListFocusingHole never_ Int
        listWithFocusThat =
            FocusList.only 1
                |> FocusList.append [ 2, 3, 4, 5 ]
    in
    describe "append"
        [ test "correct order"
            (\_ ->
                listWithFocusThat
                    |> FocusList.toStack
                    |> Expect.equal
                        (topAndBelow 1 [ 2, 3, 4, 5 ])
            )
        ]



-- navigate


nextTest : Test
nextTest =
    let
        listWithFocusThat : ListFocusingHole never_ Int
        listWithFocusThat =
            FocusList.only 1
                |> FocusList.append [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> FocusList.next
                    |> Fillable.map FocusList.current
                    |> Expect.equal (filled 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> FocusList.nextHole
                    |> FocusList.next
                    |> Fillable.map FocusList.current
                    |> Expect.equal (filled 2)
            )
        , test "next on last gives empty"
            (\_ ->
                listWithFocusThat
                    |> FocusList.last
                    |> FocusList.next
                    |> Expect.equal Fillable.empty
            )
        , test "repeating `next` eventually results in empty"
            (\_ ->
                List.foldl Fillable.andThen
                    (filled listWithFocusThat)
                    (List.repeat 4 FocusList.next)
                    |> Expect.equal Fillable.empty
            )
        ]


previousTest : Test
previousTest =
    let
        listWithFocusThat : ListFocusingHole never_ Int
        listWithFocusThat =
            FocusList.only 1
                |> FocusList.append [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives empty initially"
            (\_ ->
                listWithFocusThat
                    |> FocusList.previous
                    |> Expect.equal Fillable.empty
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                listWithFocusThat
                    |> FocusList.last
                    |> FocusList.previous
                    |> Fillable.map FocusList.current
                    |> Expect.equal (filled 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                listWithFocusThat
                    |> FocusList.afterLast
                    |> FocusList.previous
                    |> Fillable.map FocusList.current
                    |> Expect.equal (filled 3)
            )
        ]
