module Emptiable exposing
    ( Emptiable(..)
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

    import Stack exposing (Stacked)

    fill : Emptiable fill Never -> fill

    top : Emptiable (Stacked element) Never -> element


#### in type declarations

    import Emptiable exposing (Emptiable)
    import Stack exposing (Stacked)

    type alias Model =
        WithoutConstructorFunction
            { searchKeyWords : Emptiable (Stacked String) Never
            }

where [`RecordWithoutConstructorFunction`](https://dark.elm.dmy.fr/packages/lue-bird/elm-no-record-type-alias-constructor-function/latest/)
stops the compiler from creating a constructor function for `Model`.

@docs Emptiable


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


{-| Like `Maybe`, but able to know at type-level whether `Empty` is a possibility.

    import Emptiable exposing (Emptiable, filled, fill)

    [ filled 1, filled 7 ]
        --: List (Emptiable number_ never_)
        |> List.map fill
    --> [ 1, 7 ]

[`Emptiable`](#Emptiable) by itself probably won't be that useful,
but it can make data structures type-safely non-emptiable:

    import Emptiable exposing (fillMap)

    top : Emptiable (Stacked element) Never -> element

    fillMap Dict.NonEmpty.head
    --: Emptiable (NonEmptyDict comparable v) possiblyOrNever
    --: -> Emptiable ( comparable, v ) possiblyOrNever

Go take a look at all the data structures in this package.

-}
type Emptiable fill possiblyOrNever
    = Empty possiblyOrNever
    | Filled fill


{-| Insert joke about life here.

    Emptiable.empty
        |> Emptiable.fillMap (\x -> x / 0)
    --> Emptiable.empty

-}
empty : Emptiable filling_ Possibly
empty =
    Empty Possible


{-| [`Emptiable`](#Emptiable) that certainly exists, allowing type-safe extraction.

    import Emptiable exposing (filled, fill)

    filled "Bami" |> fill
    --> "Bami"

-}
filled : fill -> Emptiable fill never_
filled =
    \fillContent -> Filled fillContent


{-| Convert a `Maybe` to an [`Emptiable`](#Emptiable) `Possibly`.

To _create_ new [`Emptiable`](#Emptiable)s, use [`filled`](#filled) and [`empty`](#empty) instead!

-}
fromMaybe : Maybe value -> Emptiable value Possibly
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
toMaybe : Emptiable fill possiblyOrNever_ -> Maybe fill
toMaybe =
    \hand ->
        case hand of
            Filled fillContent ->
                Maybe.Just fillContent

            Empty _ ->
                Maybe.Nothing


{-| Safely extract the [`filled`](#filled) content from a `Emptiable fill Never`.

    import Emptiable exposing (filled)

    filled (filled (filled "Bami"))
        |> Emptiable.fill
        |> Emptiable.fill
        |> Emptiable.fill
    --> "Bami"

    first : Empty ( first, others_ ) Never -> first
    first =
        Emptiable.fill >> Tuple.first

-}
fill : Emptiable fill Never -> fill
fill =
    \handFilled ->
        handFilled |> fillElseOnEmpty never


{-| Lazily use a fallback value if the [`Emptiable`](#Emptiable) is [`empty`](#empty).

    import Possibly exposing (Possibly(..))
    import Emptiable exposing (Emptiable(..), fillElseOnEmpty)
    import Dict

    Dict.empty
        |> Dict.get "Hannah"
        |> Emptiable.fromMaybe
        |> fillElseOnEmpty (\_ -> "unknown")
    --> "unknown"

    fill =
        fillElseOnEmpty never

    fatten =
        fillElseOnEmpty

-}
fillElseOnEmpty :
    (possiblyOrNever -> fill)
    -> Emptiable fill possiblyOrNever
    -> fill
fillElseOnEmpty fallbackWhenEmpty =
    \hand ->
        case hand of
            Filled fill_ ->
                fill_

            Empty possiblyOrNever ->
                possiblyOrNever |> fallbackWhenEmpty


{-| If the [`Emptiable`](#Emptiable) is [`filled`](#filled), change it based on its current [`fill`](#fill):

    import Emptiable exposing (filled, fillMap)

    filled -3 |> fillMap abs
    --> filled 3

    Emptiable.empty |> fillMap abs
    --> Emptiable.empty

-}
fillMap :
    (fill -> fillMapped)
    -> Emptiable fill possiblyOrNever
    -> Emptiable fillMapped possiblyOrNever
fillMap change =
    \hand ->
        case hand of
            Filled fillingValue ->
                fillingValue |> change |> Filled

            Empty emptiableOrFilled ->
                Empty emptiableOrFilled


{-| Chain together operations that may return [`empty`](#empty).
It's like calling [`fillMap`](#fillMap)`|>`[`flatten`](#flatten):

If the argument is `Never` empty,
a given function takes its [`fill`](#fill)
and returns a new possibly [`empty`](#empty) value.

Some call it
[`andThen`](https://package.elm-lang.org/packages/elm/core/latest/Maybe#andThen)
or [`flatMap`](https://package.elm-lang.org/packages/ccapndave/elm-flat-map/1.2.0/Maybe-FlatMap#flatMap).

    import Emptiable exposing (Emptiable, fillMapFlat)

    emptiableString
        |> fillMapFlat parse
        |> fillMapFlat extraValidation

    parse : ( Char, String ) -> Emptiable Parsed Possibly
    extraValidation : Parsed -> Emptiable Parsed Possibly

For any number of arguments:
[`fillAnd`](#fillAnd)`... |> ... |>`[`fillMapFlat`](#fillMapFlat):

    import Emptiable exposing (filled, fillMapFlat, fillAnd)

    (filled 3)
        |> fillAnd (filled 4)
        |> fillAnd (filled 5)
        |> fillMapFlat
            (\( ( a, b ), c ) -> filled ( a, b, c ))
    --> filled ( 3, 4, 5 )

-}
fillMapFlat :
    (fill -> Emptiable fillIfBothFilled possiblyOrNever)
    -> Emptiable fill possiblyOrNever
    -> Emptiable fillIfBothFilled possiblyOrNever
fillMapFlat tryIfFilled =
    \hand ->
        hand
            |> fillMap tryIfFilled
            |> flatten


{-| In a nestable [`Emptiable`](#Emptiable):
Only keep it [`filled`](#filled) if the inner [`Emptiable`](#Emptiable) is [`filled`](#filled).

Some call it [`join`](https://package.elm-lang.org/packages/elm-community/maybe-extra/latest/Maybe-Extra#join).

    import Emptiable exposing (filled)

    filled (filled 1) |> Emptiable.flatten
    --> filled 1

    filled Emptiable.empty |> Emptiable.flatten
    --> Emptiable.empty

    Emptiable.empty |> Emptiable.flatten
    --> Emptiable.empty

-}
flatten :
    Emptiable (Emptiable fill possiblyOrNever) possiblyOrNever
    -> Emptiable fill possiblyOrNever
flatten =
    \hand ->
        hand |> fillElseOnEmpty Empty


{-| If the incoming food and the given argument are
[`filled`](#filled), give a [`filled`](#filled) tuple of both [`fill`](#fill)s back.

If any is [`empty`](#empty), give a [`Emptiable.empty`](#empty) back.

[`fillAnd`](#fillAnd) comes in handy when **multiple arguments** need to be [`filled`](#filled):

    import Emptiable exposing (filled, fillMap, fillAnd)

    filled 3
        |> fillAnd (filled 4)
        |> fillAnd (filled 5)
        |> fillMap (\( ( a0, a1 ), a2 ) -> a0^a1 - a2^2)
    --> filled 56

-}
fillAnd :
    Emptiable anotherFill possiblyOrNever
    -> Emptiable fill possiblyOrNever
    -> Emptiable ( fill, anotherFill ) possiblyOrNever
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

    import Emptiable
    import Possibly exposing (Possibly)
    import Stack exposing (Stacked)

    type alias Log =
        Empty Possibly (Stacked String)

    fromStack : Emptiable (Stacked String) possiblyOrNever_ -> Log
    fromStack stackFilled =
        stackFilled
            --: `possiblyOrNever_` but we need `Possibly`
            |> Emptiable.emptyAdapt (always Possible)


#### An argument or a type declaration value is `Never`

The `Never` can't be unified with `Possibly` or a type variable

    import Emptiable
    import Stack exposing (Stacked)

    theShorter :
        Emptiable (Stacked element) Never
        -> Emptiable (Stacked element) possiblyOrNever
        -> Emptiable (Stacked element) possiblyOrNever
    theShorter aStack bStack =
        if Stack.length bStack > Stack.length aStack then
            bStack

        else
            aStack
                --: `Never` but we need `possiblyOrNever`
                |> Emptiable.emptyAdapt never

makes both branches return `possiblyOrNever`.

-}
emptyAdapt :
    (possiblyOrNever -> adaptedPossiblyOrNever)
    -> Emptiable fill possiblyOrNever
    -> Emptiable fill adaptedPossiblyOrNever
emptyAdapt neverOrAlwaysPossible =
    \handFilled ->
        case handFilled of
            Empty possiblyOrNever ->
                Empty (possiblyOrNever |> neverOrAlwaysPossible)

            Filled fillContent ->
                Filled fillContent
