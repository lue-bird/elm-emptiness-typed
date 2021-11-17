module HoleyFocusListTest exposing (tests)

import Expect
import HoleyFocusList exposing (HoleyFocusList, Item)
import Lis
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "HoleyFocusList"
        [ describe "create" [ emptyTest, onlyTest, appendTest ]
        , describe "navigate" [ nextTest, previousTest ]
        ]



-- create


emptyTest : Test
emptyTest =
    test "empty creates a HoleyFocusList for an empty list"
        (\_ ->
            HoleyFocusList.empty
                |> HoleyFocusList.joinParts
                |> Expect.equal Lis.empty
        )


onlyTest : Test
onlyTest =
    test "only creates a HoleyFocusList with a single element"
        (\_ ->
            HoleyFocusList.only 3
                |> HoleyFocusList.joinParts
                |> Expect.equal (Lis.only 3)
        )



-- modify


appendTest : Test
appendTest =
    let
        holeyFocusList : HoleyFocusList Item Int
        holeyFocusList =
            HoleyFocusList.only 1
                |> HoleyFocusList.append [ 2, 3, 4, 5 ]
    in
    describe "append"
        [ test "correct order"
            (\_ ->
                holeyFocusList
                    |> HoleyFocusList.joinParts
                    |> Expect.equal (Lis.fromCons 1 [ 2, 3, 4, 5 ])
            )
        ]



-- navigate


nextTest : Test
nextTest =
    let
        holeyFocusList : HoleyFocusList Item Int
        holeyFocusList =
            HoleyFocusList.only 1
                |> HoleyFocusList.append [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                HoleyFocusList.next holeyFocusList
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                HoleyFocusList.nextHole holeyFocusList
                    |> HoleyFocusList.next
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on last gives nothing"
            (\_ ->
                HoleyFocusList.last holeyFocusList
                    |> HoleyFocusList.next
                    |> Expect.equal Nothing
            )
        , test "repeating `next` eventually results in `Nothing`"
            (\_ ->
                List.foldl Maybe.andThen
                    (Just holeyFocusList)
                    (List.repeat 4 HoleyFocusList.next)
                    |> Expect.equal Nothing
            )
        ]


previousTest : Test
previousTest =
    let
        holeyFocusList : HoleyFocusList Item Int
        holeyFocusList =
            HoleyFocusList.only 1
                |> HoleyFocusList.append [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives nothing initially"
            (\_ ->
                HoleyFocusList.previous holeyFocusList
                    |> Expect.equal Nothing
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                HoleyFocusList.last holeyFocusList
                    |> HoleyFocusList.previous
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                HoleyFocusList.afterLast holeyFocusList
                    |> HoleyFocusList.previous
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 3)
            )
        ]
