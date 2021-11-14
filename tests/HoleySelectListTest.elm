module HoleySelectListTest exposing (emptyTest, nextTest, previousTest, singletonTest, zipperTest)

import Expect
import HoleySelectList exposing (HoleOrItem, HoleySelectList, Item)
import Test exposing (..)


emptyTest : Test
emptyTest =
    test "Empty creates a zipper for an empty list" <|
        \_ ->
            HoleySelectList.empty
                |> HoleySelectList.toList
                |> Expect.equal []


singletonTest : Test
singletonTest =
    test "Singleton creates a HoleySelectList with a single element" <|
        \_ ->
            HoleySelectList.singleton 3
                |> HoleySelectList.toList
                |> Expect.equal [ 3 ]


zipperTest : Test
zipperTest =
    let
        zipper : HoleySelectList Item Int
        zipper =
            HoleySelectList.selecting 1 [ 2, 3, 4, 5 ]
    in
    describe "selecting"
        [ test "selecting creates a HoleySelectList." <|
            \_ ->
                zipper
                    |> HoleySelectList.toList
                    |> Expect.equal [ 1, 2, 3, 4, 5 ]
        , test "nothing before it" <|
            \_ ->
                zipper
                    |> HoleySelectList.before
                    |> Expect.equal []
        , test "the current thing is the first thing" <|
            \_ ->
                zipper
                    |> HoleySelectList.current
                    |> Expect.equal 1
        , test "the current thing is followed by the rest of the things" <|
            \_ ->
                zipper
                    |> HoleySelectList.after
                    |> Expect.equal [ 2, 3, 4, 5 ]
        ]



-- Navigation


nextTest : Test
nextTest =
    let
        zipper : HoleySelectList Item Int
        zipper =
            HoleySelectList.selecting 1 [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing" <|
            \_ ->
                HoleySelectList.next zipper
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
        , test "next on the next hole gives the next thing" <|
            \_ ->
                HoleySelectList.nextHole zipper
                    |> HoleySelectList.next
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
        , test "next on last gives nothing" <|
            \_ ->
                HoleySelectList.last zipper
                    |> HoleySelectList.next
                    |> Expect.equal Nothing
        , test "repeating `next` eventually results in `Nothing`" <|
            \_ ->
                List.foldl Maybe.andThen (Just zipper) (List.repeat 4 HoleySelectList.next)
                    |> Expect.equal Nothing
        ]


previousTest : Test
previousTest =
    let
        zipper : HoleySelectList Item Int
        zipper =
            HoleySelectList.selecting 1 [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives nothing initially" <|
            \_ ->
                HoleySelectList.previous zipper
                    |> Expect.equal Nothing
        , test "previous on the last thing gives the thing before that" <|
            \_ ->
                HoleySelectList.last zipper
                    |> HoleySelectList.previous
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 2)
        , test "previous after the last hole gives the last thing" <|
            \_ ->
                HoleySelectList.afterLast zipper
                    |> HoleySelectList.previous
                    |> Maybe.map HoleySelectList.current
                    |> Expect.equal (Just 3)
        ]
