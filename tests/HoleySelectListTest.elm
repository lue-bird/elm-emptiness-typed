module HoleySelectListTest exposing (emptyTest, nextTest, previousTest, singletonTest, zipperTest)

import Expect
import HoleySelectList exposing (HoleySelectList, Item)
import Test exposing (Test, describe, test)


emptyTest : Test
emptyTest =
    test "empty creates a HoleySelectList for an empty list"
        (\_ ->
            HoleySelectList.empty
                |> HoleySelectList.toList
                |> Expect.equal []
        )


singletonTest : Test
singletonTest =
    test "only creates a HoleySelectList with a single element"
        (\_ ->
            HoleySelectList.only 3
                |> HoleySelectList.toList
                |> Expect.equal [ 3 ]
        )


zipperTest : Test
zipperTest =
    let
        holeySelectList : HoleySelectList Item Int
        holeySelectList =
            HoleySelectList.currentAndAfter 1 [ 2, 3, 4, 5 ]
    in
    describe "currentAndAfter"
        [ test "currentAndAfter creates a HoleySelectList."
            (\_ ->
                holeySelectList
                    |> HoleySelectList.toList
                    |> Expect.equal [ 1, 2, 3, 4, 5 ]
            )
        , test "nothing before it"
            (\_ ->
                holeySelectList
                    |> HoleySelectList.before
                    |> Expect.equal []
            )
        , test "the current thing is the first thing"
            (\_ ->
                holeySelectList
                    |> HoleySelectList.current
                    |> Expect.equal 1
            )
        , test "the current thing is followed by the rest of the things"
            (\_ ->
                holeySelectList
                    |> HoleySelectList.after
                    |> Expect.equal [ 2, 3, 4, 5 ]
            )
        ]



-- Navigation


nextTest : Test
nextTest =
    let
        holeySelectList : HoleySelectList Item Int
        holeySelectList =
            HoleySelectList.currentAndAfter 1 [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                HoleySelectList.next holeySelectList
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                HoleySelectList.nextHole holeySelectList
                    |> HoleySelectList.next
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
            )
        , test "next on last gives nothing"
            (\_ ->
                HoleySelectList.last holeySelectList
                    |> HoleySelectList.next
                    |> Expect.equal Nothing
            )
        , test "repeating `next` eventually results in `Nothing`"
            (\_ ->
                List.foldl Maybe.andThen
                    (Just holeySelectList)
                    (List.repeat 4 HoleySelectList.next)
                    |> Expect.equal Nothing
            )
        ]


previousTest : Test
previousTest =
    let
        holeySelectList : HoleySelectList Item Int
        holeySelectList =
            HoleySelectList.currentAndAfter 1 [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives nothing initially"
            (\_ ->
                HoleySelectList.previous holeySelectList
                    |> Expect.equal Nothing
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                HoleySelectList.last holeySelectList
                    |> HoleySelectList.previous
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                HoleySelectList.afterLast holeySelectList
                    |> HoleySelectList.previous
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 3)
            )
        ]
