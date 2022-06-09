module Hand exposing
    ( Hand(..), Empty
    , empty, filled, fromMaybe
    , fillMap, fillMapFlat
    , fillAnd
    , flatten
    , fill, fillElseOnEmpty
    , toMaybe
    , emptyAdapt
    )

{-| An emptiable-able value.


#### in arguments

    import Hand exposing (Empty)
    import Stack exposing (Stacked)

    fill : Hand fill Never Empty -> fill

    top : Hand (Stacked element) Never Empty -> element


#### in type declarations

    import Hand exposing (Empty, Hand)
    import Stack exposing (Stacked)

    type alias Model =
        WithoutConstructorFunction
            { searchKeyWords : Hand (Stacked String) Never Empty
            }

where [`RecordWithoutConstructorFunction`](https://dark.elm.dmy.fr/packages/lue-bird/elm-no-record-type-alias-constructor-function/latest/)
stops the compiler from creating a constructor function for `Model`.

@docs Hand, Empty


## create

@docs empty, filled, fromMaybe


## transform

@docs fillMap, fillMapFlat
@docs fillAnd
@docs flatten
@docs fill, fillElseOnEmpty
@docs toMaybe


## type-level

@docs emptyAdapt

-}

import Possibly exposing (Possibly(..))


{-| Like `Maybe`, but able to know at type-level whether [`Empty`](#Empty) is possible.

    import Hand exposing (Hand, Empty, filled, fill)

    [ filled 1, filled 7 ]
        --: List (Hand number_ never_ Empty)
        |> List.map fill
    --> [ 1, 7 ]

[`Hand.Empty`](#Empty) alone probably won't be that useful,
but it can make data structures type-safely non-emptiable:

    import Hand exposing (fillMap)

    top : Hand (Stacked element) Never Empty -> element

    fillMap Dict.NonEmpty.head
    --: Hand (NonEmptyDict comparable v) possiblyOrNever Empty
    --: -> Hand ( comparable, v ) possiblyOrNever Empty

Go take a look at all the data structures in this package.

-}
type Hand fill possiblyOrNever emptyTag
    = Empty possiblyOrNever
    | Filled fill


{-| A word used in the [`Hand`](#Hand) type:

    top : Hand (Stacked element) Never Empty -> element

    when :
        Hand ... possiblyOrNever_ Empty
        -> Hand ... Possibly Empty

-}
type Empty
    = EmptyTag Never


{-| Insert joke about life here.

    Hand.empty
        |> Hand.fillMap (\x -> x / 0)
    --> Hand.empty

-}
empty : Hand filling_ Possibly Empty
empty =
    Empty Possible


{-| A [`Hand.Empty`](#Empty) that certainly exists, allowing type-safe extraction.

    import Hand exposing (filled, fill)

    filled "Bami" |> fill
    --> "Bami"

-}
filled : fill -> Hand fill never_ Empty
filled =
    \fillContent -> Filled fillContent


{-| Convert a `Maybe` to a [`Hand`](#Hand)`Possibly`[`Hand`](#Empty).

To _create_ new [`Hand`](#Hand)s, use [`filled`](#filled) and [`empty`](#empty) instead!

-}
fromMaybe : Maybe value -> Hand value Possibly Empty
fromMaybe =
    \coreMaybe ->
        case coreMaybe of
            Maybe.Just val ->
                filled val

            Maybe.Nothing ->
                empty



--


{-| Convert to a `Maybe`.

Don't try to use this prematurely.
Keeping type information as long as possible is always a win.

-}
toMaybe : Hand fill possiblyOrNever_ Empty -> Maybe fill
toMaybe =
    \hand ->
        case hand of
            Filled fillContent ->
                Maybe.Just fillContent

            Empty _ ->
                Maybe.Nothing


{-| Safely extract the [`filled`](#filled) content from a `Hand fill Never Empty`.

    import Hand exposing (Empty, filled)

    filled (filled (filled "Bami"))
        |> Hand.fill
        |> Hand.fill
        |> Hand.fill
    --> "Bami"

    first : Empty ( first, others_ ) Never Empty -> first
    first =
        Hand.fill >> Tuple.first

-}
fill : Hand fill Never Empty -> fill
fill =
    \handFilled ->
        handFilled |> fillElseOnEmpty never


{-| Lazily use a fallback value if the [`Hand`](#Hand) is [`empty`](#empty).

    import Possibly exposing (Possibly(..))
    import Hand exposing (Hand(..), fillElseOnEmpty)
    import Dict

    Dict.empty
        |> Dict.get "Hannah"
        |> Hand.fromMaybe
        |> fillElseOnEmpty (\_ -> "unknown")
    --> "unknown"

    fill =
        fillElseOnEmpty never

    fatten =
        fillElseOnEmpty Empty

-}
fillElseOnEmpty :
    (possiblyOrNever -> fill)
    -> Hand fill possiblyOrNever Empty
    -> fill
fillElseOnEmpty fallbackWhenEmpty =
    \hand ->
        case hand of
            Filled fill_ ->
                fill_

            Empty possiblyOrNever ->
                possiblyOrNever |> fallbackWhenEmpty


{-| If the [`Hand`](#Hand) is [`filled`](#filled), change it based on its current [`fill`](#fill):

    import Hand exposing (filled, fillMap)

    filled -3 |> fillMap abs
    --> filled 3

    Hand.empty |> fillMap abs
    --> Hand.empty

-}
fillMap :
    (fill -> fillMapped)
    -> Hand fill possiblyOrNever Empty
    -> Hand fillMapped possiblyOrNever Empty
fillMap change =
    \hand ->
        case hand of
            Filled fillingValue ->
                fillingValue |> change |> Filled

            Empty emptiableOrFilled ->
                Empty emptiableOrFilled


{-| Chain together operations that may return [`empty`](#empty).
It's like calling [`fillMap`](#fillMap)`|>`[`flatten`](#flatten):

If the argument [`Hand.Empty`](#Empty) `Never` [`Empty`](Hand#Empty),
a given function takes its [`fill`](#fill)
and returns a new possibly [`empty`](#empty) value.

Some call it
[`andThen`](https://package.elm-lang.org/packages/elm/core/latest/Maybe#andThen)
or [`flatMap`](https://package.elm-lang.org/packages/ccapndave/elm-flat-map/1.2.0/Maybe-FlatMap#flatMap).

    import Hand exposing (Hand, Empty, fillMapFlat)

    emptiableString
        |> fillMapFlat parse
        |> fillMapFlat extraValidation

    parse : ( Char, String ) -> Hand Parsed Possibly Empty
    extraValidation : Parsed -> Hand Parsed Possibly Empty

For any number of arguments:
[`fillAnd`](#fillAnd)`... |> ... |>`[`fillMapFlat`](#fillMapFlat):

    import Hand exposing (filled, fillMapFlat, fillAnd)

    (filled 3)
        |> fillAnd (filled 4)
        |> fillAnd (filled 5)
        |> fillMapFlat
            (\( ( a, b ), c ) -> filled ( a, b, c ))
    --> filled ( 3, 4, 5 )

-}
fillMapFlat :
    (fill -> Hand fillIfBothFilled possiblyOrNever Empty)
    -> Hand fill possiblyOrNever Empty
    -> Hand fillIfBothFilled possiblyOrNever Empty
fillMapFlat tryIfFilled =
    \hand ->
        hand
            |> fillMap tryIfFilled
            |> flatten


{-| In a nestable [`Hand`](#Hand):
Only keep it [`filled`](#filled) if the inner [`Hand`](#Hand) is [`filled`](#filled).

Some call it [`join`](https://package.elm-lang.org/packages/elm-community/maybe-extra/latest/Maybe-Extra#join).

    import Hand exposing (filled)

    filled (filled 1) |> Hand.flatten
    --> filled 1

    filled Hand.empty |> Hand.flatten
    --> Hand.empty

    Hand.empty |> Hand.flatten
    --> Hand.empty

-}
flatten :
    Hand (Hand fill possiblyOrNever Empty) possiblyOrNever Empty
    -> Hand fill possiblyOrNever Empty
flatten =
    \hand ->
        hand |> fillElseOnEmpty Empty


{-| If the incoming food and the given argument are
[`filled`](#filled), give a [`filled`](#filled) tuple of both [`fill`](#fill)s back.

If any is [`empty`](#empty), give a [`Hand.empty`](#empty) back.

[`fillAnd`](#fillAnd) comes in handy when **multiple arguments** need to be [`filled`](#filled):

    import Hand exposing (filled, fillMap, fillAnd)

    filled 3
        |> fillAnd (filled 4)
        |> fillAnd (filled 5)
        |> fillMap (\( ( a0, a1 ), a2 ) -> a0^a1 - a2^2)
    --> filled 56

-}
fillAnd :
    Hand anotherFill possiblyOrNever Empty
    -> Hand fill possiblyOrNever Empty
    -> Hand ( fill, anotherFill ) possiblyOrNever Empty
fillAnd argument =
    \soFar ->
        case ( soFar, argument ) of
            ( Filled soFarFill, Filled argumentFill ) ->
                ( soFarFill, argumentFill ) |> Filled

            ( Empty possible, _ ) ->
                Empty possible

            ( _, Empty possible ) ->
                Empty possible



--


{-| Change the `possiblyOrNever` type.


#### Returning a type declaration value or argument that is `Empty Possibly`

An `Empty possiblyOrNever` can't be used as `Empty Possibly`

    import Hand exposing (Empty)
    import Possibly exposing (Possibly)
    import Stack exposing (Stacked)

    type alias Log =
        Empty Possibly (Stacked String)

    fromStack : Hand (Stacked String) possiblyOrNever_ Empty -> Log
    fromStack stackFilled =
        stackFilled
            --: `possiblyOrNever_` but we need `Possibly`
            |> Hand.emptyAdapt (always Possible)


#### An argument or a type declaration value is `Never Empty`

The `Never Empty` can't be unified with `Possibly Empty` or a type variable

    import Hand exposing (Empty)
    import Stack exposing (Stacked)

    theShorter :
        Hand (Stacked element) Never Empty
        -> Hand (Stacked element) possiblyOrNever Empty
        -> Hand (Stacked element) possiblyOrNever Empty
    theShorter aStack bStack =
        if Stack.length bStack > Stack.length aStack then
            bStack

        else
            aStack
                --: `Never` but we need `possiblyOrNever`
                |> Hand.emptyAdapt never

makes both branches return `possiblyOrNever`.

-}
emptyAdapt :
    (possiblyOrNever -> adaptedPossiblyOrNever)
    -> Hand fill possiblyOrNever Empty
    -> Hand fill adaptedPossiblyOrNever Empty
emptyAdapt neverOrAlwaysPossible =
    \handFilled ->
        case handFilled of
            Empty possiblyOrNever ->
                Empty (possiblyOrNever |> neverOrAlwaysPossible)

            Filled fillContent ->
                Filled fillContent
