module Fillable exposing
    ( Empty(..)
    , empty, filled, fromMaybe
    , map, map2, andThen
    , filling, toFillingOrIfEmpty, toMaybe
    , adaptType
    )

{-| An option-able value.


#### in arguments

    import Fillable exposing (Empty)
    import Stack exposing (StackFilled)

    filling : Empty Never filling -> filling

    top : Empty Never (StackFilled element) -> element


#### in type declarations

    import Fillable exposing (Empty)
    import Stack exposing (StackFilled)

    type alias Model =
        WithoutConstructorFunction
            { searchKeyWords : Empty Never (StackFilled String)
            }

    type alias WithoutConstructorFunction record =
        record

where `WithoutConstructorFunction` stops the compiler from creating a positional constructor function for `Model`.

@docs Empty


## create

@docs empty, filled, fromMaybe


## transform

@docs map, map2, andThen
@docs filling, toFillingOrIfEmpty, toMaybe


## type-level

@docs adaptType

-}

import Possibly exposing (Possibly(..))


{-| Like `Maybe`, but able to know at type-level whether `Empty` is possible.

    import Fillable exposing (Empty, filled)

    [ filled 1, filled 7 ]
        --: List (Empty never_ number_)
        |> List.map filling
    --> [ 1, 7 ]

[`Fillable.Empty`](#Empty) alone probably won't be that useful,
but it can make data structures type-safely non-emptiable:

    import Fillable exposing (filling)

    top : Empty Never (StackFilled element) -> element

    Fillable.map Dict.NonEmpty.head
    --: Empty possiblyOrNever (NonEmptyDict comparable v)
    --: -> Empty possiblyOrNever ( comparable, v ) possiblyOrNever

Go take a look at all the data structures in this package.

-}
type Empty possiblyOrNever filling
    = Empty possiblyOrNever
    | Filled filling


{-| Insert joke about life here.

    empty
        |> Fillable.map (\x -> x / 0)
    --> empty

-}
empty : Empty Possibly filling_
empty =
    Empty Possible


{-| A [`Fillable.Empty`](#Empty) that certainly exists, allowing type-safe extraction.

    import Fillable exposing (filled, filling)

    filled "Bami" |> filling
    --> "Bami"

-}
filled : filling -> Empty never_ filling
filled fillingValue =
    Filled fillingValue


{-| Convert a `Maybe` to a [`Fillable.Empty`](#Empty).
-}
fromMaybe : Maybe value -> Empty Possibly value
fromMaybe coreMaybe =
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
toMaybe : Empty possiblyOrNever_ filling -> Maybe filling
toMaybe =
    \fillable ->
        case fillable of
            Filled fillingValue ->
                Maybe.Just fillingValue

            Empty _ ->
                Maybe.Nothing


{-| Safely extracts the value from an `Empty Never`.

    import Fillable exposing (Empty, filled, filling)

    filled (filled (filled "Bami"))
        |> filling
        |> filling
        |> filling
    --> "Bami"

    first : Empty Never ( first, others_ ) -> first
    first =
        filling >> Tuple.first

-}
filling : Empty Never filling -> filling
filling filledFillable =
    filledFillable |> toFillingOrIfEmpty never


{-| Lazily use a fallback value if the [`Fillable.Empty`](#Empty) [`empty`](#empty).

    import Possibly exposing (Possibly(..))
    import Fillable exposing (toFillingOrIfEmpty)
    import Dict

    Dict.empty
        |> Dict.get "Hannah"
        |> Fillable.fromMaybe
        |> toFillingOrIfEmpty (\_ -> "unknown")
    --> "unknown"

    filling =
        toFillingOrIfEmpty never

-}
toFillingOrIfEmpty :
    (possiblyOrNever -> filling)
    -> Empty possiblyOrNever filling
    -> filling
toFillingOrIfEmpty lazyFallback =
    \fillable ->
        case fillable of
            Filled fillingValue ->
                fillingValue

            Empty possiblyOrNever ->
                lazyFallback possiblyOrNever


{-| Change the possibly `Filled` value based on its current value:

    import Fillable exposing (filled)

    filled -3 |> Fillable.map abs
    --> filled 3

    Fillable.empty |> Fillable.map abs
    --> Fillable.empty

-}
map :
    (filling -> fillingMapped)
    -> Empty possiblyOrNever filling
    -> Empty possiblyOrNever fillingMapped
map change =
    \fillable ->
        case fillable of
            Filled fillingValue ->
                fillingValue |> change |> Filled

            Empty emptiableOrFilled ->
                Empty emptiableOrFilled


{-| If all the arguments exist, combine them using a given function.

    import Fillable exposing (filled, empty)

    Fillable.map2 (+) (filled 3) (filled 4) --> filled 7
    Fillable.map2 (+) (filled 3) empty --> empty
    Fillable.map2 (+) empty (filled 4) --> empty

-}
map2 :
    (aFilling -> bFilling -> fillingCombined)
    -> Empty possiblyOrNever aFilling
    -> Empty possiblyOrNever bFilling
    -> Empty possiblyOrNever fillingCombined
map2 combine aFillable bFillable =
    case ( aFillable, bFillable ) of
        ( Filled a, Filled b ) ->
            combine a b |> Filled

        ( Empty possiblyOrNever, _ ) ->
            Empty possiblyOrNever

        ( _, Empty possiblyOrNever ) ->
            Empty possiblyOrNever


{-| Chain together operations that may return [`empty`](#empty).

If the argument [`Fillable.Empty`](#Empty) `Never` [`Empty`](Fillable#Empty),
a given function takes its [`filling`](#filling)
and returns a new possibly [`empty`](#empty) value.

Some call it `flatMap`.

    emptiableString
        |> Fillable.andThen parse
        |> Fillable.andThen extraValidation

    parse : ( Char, String ) -> Empty Possibly Parsed
    extraValidation : Parsed -> Empty Possibly Parsed

-}
andThen :
    (filling -> Empty possiblyOrNever fillingThen)
    -> Empty possiblyOrNever filling
    -> Empty possiblyOrNever fillingThen
andThen tryIfFilled =
    \fillable ->
        case fillable of
            Filled val ->
                tryIfFilled val

            Empty possiblyOrNever ->
                Empty possiblyOrNever



--


{-| Change the `possiblyOrNever` type.


#### Returning a type declaration value or argument that is `Empty Possibly`

An `Empty possiblyOrNever` can't be used as `Empty Possibly`

    import Fillable exposing (Empty)
    import Possibly exposing (Possibly)
    import Stack exposing (StackFilled)

    type alias Log =
        Empty Possibly (StackFilled String)

    fromStack : Empty possiblyOrNever_ (StackFilled String) -> Log
    fromStack stackFilled =
        stackFilled
            --: `possiblyOrNever_` but we need `Possibly`
            |> Fillable.adaptType (always Possible)


#### An argument or a type declaration value is `Empty Never`

The `Empty Never` can't be unified with `Possibly` or a type variable

    import Fillable exposing (Empty)
    import Stack exposing (StackFilled)

    theShorter :
        Empty Never (StackFilled element)
        -> Empty possiblyOrNever (StackFilled element)
        -> Empty possiblyOrNever (StackFilled element)
    theShorter aStack bStack =
        if Stack.length bStack > Stack.length aStack then
            bStack

        else
            --: `Never` but we need `possiblyOrNever`
            aStack

to make both branches return `possiblyOrNever`, use

    aStack |> Fillable.adaptType never

-}
adaptType :
    (possiblyOrNever -> possiblyOrNeverAdapted)
    -> Empty possiblyOrNever filling
    -> Empty possiblyOrNeverAdapted filling
adaptType neverOrAlwaysPossible fillableFilled =
    case fillableFilled of
        Empty possiblyOrNever ->
            Empty (possiblyOrNever |> neverOrAlwaysPossible)

        Filled filling_ ->
            filling_ |> Filled
