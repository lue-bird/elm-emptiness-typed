module ListWithFocusThatTest exposing (tests)

import Expect
import ListThat
import ListWithFocusThat exposing (ListWithFocusThat)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "ListWithFocusThat"
        [ describe "create" [ emptyTest, onlyTest, appendTest ]
        , describe "navigate" [ nextTest, previousTest ]
        ]



-- create


emptyTest : Test
emptyTest =
    test "empty creates a ListWithFocusThat for an empty list"
        (\_ ->
            ListWithFocusThat.empty
                |> ListWithFocusThat.joinParts
                |> Expect.equal ListThat.empty
        )


onlyTest : Test
onlyTest =
    test "only creates a ListWithFocusThat with a single element"
        (\_ ->
            ListWithFocusThat.only 3
                |> ListWithFocusThat.joinParts
                |> Expect.equal (ListThat.only 3)
        )



-- modify


appendTest : Test
appendTest =
    let
        listWithFocusThat : ListWithFocusThat isntHole_ Int
        listWithFocusThat =
            ListWithFocusThat.only 1
                |> ListWithFocusThat.append [ 2, 3, 4, 5 ]
    in
    describe "append"
        [ test "correct order"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.joinParts
                    |> Expect.equal (ListThat.fromCons 1 [ 2, 3, 4, 5 ])
            )
        ]



-- navigate


nextTest : Test
nextTest =
    let
        listWithFocusThat : ListWithFocusThat isntHole_ Int
        listWithFocusThat =
            ListWithFocusThat.only 1
                |> ListWithFocusThat.append [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.next
                    |> Maybe.map ListWithFocusThat.current
                    |> Expect.equal (Just 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.nextHole
                    |> ListWithFocusThat.next
                    |> Maybe.map ListWithFocusThat.current
                    |> Expect.equal (Just 2)
            )
        , test "next on last gives nothing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.last
                    |> ListWithFocusThat.next
                    |> Expect.equal Nothing
            )
        , test "repeating `next` eventually results in `Nothing`"
            (\_ ->
                List.foldl Maybe.andThen
                    (Just listWithFocusThat)
                    (List.repeat 4 ListWithFocusThat.next)
                    |> Expect.equal Nothing
            )
        ]


previousTest : Test
previousTest =
    let
        listWithFocusThat : ListWithFocusThat isntHole_ Int
        listWithFocusThat =
            ListWithFocusThat.only 1
                |> ListWithFocusThat.append [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives nothing initially"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.previous
                    |> Expect.equal Nothing
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.last
                    |> ListWithFocusThat.previous
                    |> Maybe.map ListWithFocusThat.current
                    |> Expect.equal (Just 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocusThat.afterLast
                    |> ListWithFocusThat.previous
                    |> Maybe.map ListWithFocusThat.current
                    |> Expect.equal (Just 3)
            )
        ]
