module HoleySelectListTest exposing (emptyTest, nextTest, previousTest, singletonTest, zipperTest)

import Expect
import HoleyFocusList exposing (HoleyFocusList, Item)
import Test exposing (Test, describe, test)


emptyTest : Test
emptyTest =
    test "empty creates a HoleyFocusList for an empty list"
        (\_ ->
            HoleyFocusList.empty
                |> HoleyFocusList.toList
                |> Expect.equal []
        )


singletonTest : Test
singletonTest =
    test "only creates a HoleyFocusList with a single element"
        (\_ ->
            HoleyFocusList.only 3
                |> HoleyFocusList.toList
                |> Expect.equal [ 3 ]
        )


zipperTest : Test
zipperTest =
    let
        holeySelectList : HoleyFocusList Item Int
        holeySelectList =
            HoleyFocusList.currentAndAfter 1 [ 2, 3, 4, 5 ]
    in
    describe "currentAndAfter"
        [ test "currentAndAfter creates a HoleyFocusList."
            (\_ ->
                holeySelectList
                    |> HoleyFocusList.toList
                    |> Expect.equal [ 1, 2, 3, 4, 5 ]
            )
        , test "nothing before it"
            (\_ ->
                holeySelectList
                    |> HoleyFocusList.before
                    |> Expect.equal []
            )
        , test "the current thing is the first thing"
            (\_ ->
                holeySelectList
                    |> HoleyFocusList.current
                    |> Expect.equal 1
            )
        , test "the current thing is followed by the rest of the things"
            (\_ ->
                holeySelectList
                    |> HoleyFocusList.after
                    |> Expect.equal [ 2, 3, 4, 5 ]
            )
        ]



-- Navigation


nextTest : Test
nextTest =
    let
        holeySelectList : HoleyFocusList Item Int
        holeySelectList =
            HoleyFocusList.currentAndAfter 1 [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                HoleyFocusList.next holeySelectList
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                HoleyFocusList.nextHole holeySelectList
                    |> HoleyFocusList.next
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on last gives nothing"
            (\_ ->
                HoleyFocusList.last holeySelectList
                    |> HoleyFocusList.next
                    |> Expect.equal Nothing
            )
        , test "repeating `next` eventually results in `Nothing`"
            (\_ ->
                List.foldl Maybe.andThen
                    (Just holeySelectList)
                    (List.repeat 4 HoleyFocusList.next)
                    |> Expect.equal Nothing
            )
        ]


previousTest : Test
previousTest =
    let
        holeySelectList : HoleyFocusList Item Int
        holeySelectList =
            HoleyFocusList.currentAndAfter 1 [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives nothing initially"
            (\_ ->
                HoleyFocusList.previous holeySelectList
                    |> Expect.equal Nothing
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                HoleyFocusList.last holeySelectList
                    |> HoleyFocusList.previous
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                HoleyFocusList.afterLast holeySelectList
                    |> HoleyFocusList.previous
                    |> Maybe.map HoleyFocusList.current
                    |> Expect.equal (Just 3)
            )
        ]
