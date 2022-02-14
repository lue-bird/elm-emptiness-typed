module ListWithFocusTest exposing (tests)

import Expect
import Fillable exposing (filled)
import ListIs
import ListWithFocus exposing (ListWhereFocusIs)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "ListWithFocus"
        [ describe "create" [ emptyTest, onlyTest, appendTest ]
        , describe "navigate" [ nextTest, previousTest ]
        ]



-- create


emptyTest : Test
emptyTest =
    test "empty creates a ListWithFocus for an empty list"
        (\_ ->
            ListWithFocus.empty
                |> ListWithFocus.toListIs
                |> Expect.equal Fillable.empty
        )


onlyTest : Test
onlyTest =
    test "only creates a ListWithFocus with a single element"
        (\_ ->
            ListWithFocus.only 3
                |> ListWithFocus.toListIs
                |> Expect.equal (ListIs.only 3)
        )



-- modify


appendTest : Test
appendTest =
    let
        listWithFocusThat : ListWhereFocusIs filled_ Int
        listWithFocusThat =
            ListWithFocus.only 1
                |> ListWithFocus.append [ 2, 3, 4, 5 ]
    in
    describe "append"
        [ test "correct order"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.toListIs
                    |> Expect.equal (ListIs.fromCons 1 [ 2, 3, 4, 5 ])
            )
        ]



-- navigate


nextTest : Test
nextTest =
    let
        listWithFocusThat : ListWhereFocusIs filled_ Int
        listWithFocusThat =
            ListWithFocus.only 1
                |> ListWithFocus.append [ 2, 3 ]
    in
    describe "next"
        [ test "next gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.next
                    |> Fillable.map ListWithFocus.current
                    |> Expect.equal (filled 2)
            )
        , test "next on the next hole gives the next thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.nextHole
                    |> ListWithFocus.next
                    |> Fillable.map ListWithFocus.current
                    |> Expect.equal (filled 2)
            )
        , test "next on last gives empty"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.last
                    |> ListWithFocus.next
                    |> Expect.equal Fillable.empty
            )
        , test "repeating `next` eventually results in empty"
            (\_ ->
                List.foldl Fillable.andThen
                    (filled listWithFocusThat)
                    (List.repeat 4 ListWithFocus.next)
                    |> Expect.equal Fillable.empty
            )
        ]


previousTest : Test
previousTest =
    let
        listWithFocusThat : ListWhereFocusIs filled_ Int
        listWithFocusThat =
            ListWithFocus.only 1
                |> ListWithFocus.append [ 2, 3 ]
    in
    describe "previous"
        [ test "previous gives empty initially"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.previous
                    |> Expect.equal Fillable.empty
            )
        , test "previous on the last thing gives the thing before that"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.last
                    |> ListWithFocus.previous
                    |> Fillable.map ListWithFocus.current
                    |> Expect.equal (filled 2)
            )
        , test "previous after the last hole gives the last thing"
            (\_ ->
                listWithFocusThat
                    |> ListWithFocus.afterLast
                    |> ListWithFocus.previous
                    |> Fillable.map ListWithFocus.current
                    |> Expect.equal (filled 3)
            )
        ]
