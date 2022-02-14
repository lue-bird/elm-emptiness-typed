module Fillable exposing
    ( Emptiable, Filled, PossiblyEmpty(..)
    , Is(..)
    , empty, filled, fromMaybe
    , map, map2, andThen
    , filling, toFillingWithEmpty, toMaybe
    , branchableType
    )

{-| `Maybe` with the ability to know at the type level whether `Empty` is possible.

    import Fillable exposing (Is, filled)

    [ filled 1, filled 7 ]
        --: List (Is filled_ number_)
        |> List.map filling
    --> [ 1, 7 ]

[`Is`](#Is) alone probably won't be that useful,
but we can build type-safe data structures with it:

    type alias ListIs emptiableOrFilled element =
        Is emptiableOrFilled ( element, List element )

is exactly how [`ListIs`](ListIs) is implemented, allowing you to treat [`ListIs`](ListIs) just like any [`Fillable.Is`](#Is).

    import Fillable exposing (filling)

    head : Is Filled ( head, tail_ ) -> head
    head =
        filling >> Tuple.first



    Fillable.map (filled >> head)
    --: Is emptiableOrFilled ( head, tail_ )
    --: -> Is emptiableOrFilled head


## types

@docs Emptiable, Filled, PossiblyEmpty
@docs Is


## create

@docs empty, filled, fromMaybe


## transform

@docs map, map2, andThen
@docs filling, toFillingWithEmpty, toMaybe


## type-level

@docs branchableType

-}


{-| Like `Maybe` with type level information about whether `Empty` is possible.
See [`PossiblyEmpty`](Fillable#PossiblyEmpty), [`Emptiable`](Fillable#Emptiable), [`Filled`](Fillable#Filled).

[`Is`](#Is) alone probably won't be that useful,
but we can build type-safe data structures with it.
Go take a look at all the data structures in this package.

-}
type Is emptiableOrFilled filling
    = Empty emptiableOrFilled
    | Filled filling


{-| In short:

  - [`Emptiable`](#Emptiable), [`Filled`](#Filled) are defined in terms of `PossiblyEmpty ()/Never`

        empty : Is Emptiable filling_

        head : ListIs Filled element -> element

  - `...Is emptiableOrFilled -> ...Is emptiableOrFilled` can carry over non-emptiness-information

        toCharList :
            StringIs emptiableOrFilled
            -> ListIs emptiableOrFilled Char
        toCharList string =
            case string of
                StringEmpty emptiableOrFilled ->
                    ListEmpty emptiableOrFilled

                StringNotEmpty headChar tailString ->
                    ListIs.fromCons headChar (tailString |> String.toList)


#### [`Filled`](#Filled) in arguments

    head : ListIs Filled element -> element


#### [`Emptiable`](#Emptiable) in results

    fromList : List element -> ListIs Emptiable element


#### in type declarations

    type alias Model =
        WithoutConstructorFunction
            { selected : Is Emptiable
            , searchKeyWords : ListIs Filled String
            , planets : ListIs Emptiable Planet
            }

    type alias WithoutConstructorFunction record =
        record

where `WithoutConstructorFunction` stops the compiler from creating a positional constructor function for `Model`.

If you still have questions, check out the [readme](https://dark.elm.dmy.fr/packages/lue-bird/elm-emptiness-typed/latest/).

-}
type PossiblyEmpty unitOrNever
    = Possible unitOrNever


{-| The empty state is possible.


#### in results

    fromMaybe : Maybe value -> Is Emptiable value

    fromList : List element -> ListIs Emptiable element


#### `Emptiable` in type declarations

    type alias Model =
        WithoutConstructorFunction
            { selected : Is Emptiable
            , planets : ListIs Emptiable Planet
            }

    type alias WithoutConstructorFunction record =
        record

where `WithoutConstructorFunction` stops the compiler from creating a positional constructor function for `Model`.

-}
type alias Emptiable =
    PossiblyEmpty ()


{-| The empty state isn't possible.


#### in arguments

    filling : Is Filled filling -> filling

    unCons : ListIs Filled element -> ( element, List element )

    head : ListIs Filled element -> element


#### `Filled` in type declarations

    type alias Model =
        WithoutConstructorFunction
            { searchKeyWords : ListIs Filled String
            }

    type alias WithoutConstructorFunction record =
        record

where `WithoutConstructorFunction` stops the compiler from creating a positional constructor function for `Model`.

-}
type alias Filled =
    PossiblyEmpty Never


{-| Insert joke about life here.

    empty
        |> Fillable.map (\x -> x / 0)
    --> empty

-}
empty : Is Emptiable filled_
empty =
    Empty (Possible ())


{-| A [`Fillable.Is`](#Is) that certainly exists, allowing type-safe extraction.

    import Fillable exposing (filled, filling)

    filled "Bami" |> filling
    --> "Bami"

-}
filled : filling -> Is filled_ filling
filled fillingValue =
    Filled fillingValue


{-| Convert a `Maybe` to a [`Fillable.Is`](#Is).
-}
fromMaybe : Maybe value -> Is Emptiable value
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
toMaybe : Is canBeFilledOrNot_ filling -> Maybe filling
toMaybe =
    \maybe ->
        case maybe of
            Filled val ->
                Maybe.Just val

            Empty _ ->
                Maybe.Nothing


{-| Safely extracts the `filling` from an `Is Filled filling`.

    import Fillable exposing (filled, filling, Is)

    filled (filled (filled "Bami"))
        |> filling
        |> filling
        |> filling
    --> "Bami"

    head : Is Filled ( head, tail ) -> head
    head =
        filling >> Tuple.first

See [`Filled`](#Filled) and [`ListIs`](ListIs).

-}
filling : Is Filled value -> value
filling definitelyFilled =
    definitelyFilled |> toFillingWithEmpty never


{-| Lazily use a fallback value if the [`Fillable.Is`](#Is) [`empty`](#empty).

    import Dict

    Dict.empty
        |> Dict.get "Hannah"
        |> Fillable.fromMaybe
        |> Fillable.toFillingWithEmpty (\() -> "unknown")
    --> "unknown"

    value =
        toFillingWithEmpty never

-}
toFillingWithEmpty :
    (unitOrNever -> value)
    -> Is (PossiblyEmpty unitOrNever) value
    -> value
toFillingWithEmpty lazyFallback =
    \maybe ->
        case maybe of
            Filled val ->
                val

            Empty (Possible possibleOrNever) ->
                lazyFallback possibleOrNever


{-| Transform the value in the \`Fillable. using a given function:

    import Fillable exposing (filled)

    filled -3 |> Fillable.map abs
    --> filled 3

    Fillable.empty
        |> Fillable.map abs
    --> Fillable.empty

-}
map :
    (filling -> mappedFilling)
    -> Is emptiableOrFilled filling
    -> Is emptiableOrFilled mappedFilling
map change =
    \maybe ->
        case maybe of
            Filled val ->
                val |> change |> Filled

            Empty emptiableOrFilled ->
                Empty emptiableOrFilled


{-| If all the arguments exist, combine them using a given function.

    import Fillable exposing (filled, empty)

    Fillable.map2 (+) (filled 3) (filled 4) --> filled 7
    Fillable.map2 (+) (filled 3) empty --> empty
    Fillable.map2 (+) empty (filled 4) --> empty

-}
map2 :
    (aValue -> bValue -> combinedValue)
    -> Is emptiableOrFilled aValue
    -> Is emptiableOrFilled bValue
    -> Is emptiableOrFilled combinedValue
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( Filled a, Filled b ) ->
            combine a b |> Filled

        ( Empty emptiableOrFilled, _ ) ->
            Empty emptiableOrFilled

        ( _, Empty emptiableOrFilled ) ->
            Empty emptiableOrFilled


{-| Chain together operations that may return [`empty`](#empty).

If the argument [`Is`](#Is) [`Filled`](#Filled),
a given function takes its [`filling`](#filling)
and returns a new possibly [`empty`](#empty) value.

    emptiableString
        |> Fillable.andThen parse
        |> Fillable.andThen extraValidation

    parse : ( Char, String ) -> Is Emptiable Parsed
    extraValidation : Parsed -> Is Emptiable Parsed

-}
andThen :
    (value -> Is emptiableOrFilled thenValue)
    -> Is emptiableOrFilled value
    -> Is emptiableOrFilled thenValue
andThen tryIfFilled =
    \maybe ->
        case maybe of
            Filled val ->
                tryIfFilled val

            Empty emptiableOrFilled ->
                Empty emptiableOrFilled



--


{-| When using `Is Filled ...`

    theShorter :
        ListIs Filled a
        -> ListIs isEmptyOrNot a
        -> ListIs isEmptyOrNot a
    theShorter aList bList =
        if ListIs.length bList > ListIs.length aList then
            bList

        else
            --↓ `Filled` but we need `emptiableOrFilled`
            aList

to make both branches return `emptiableOrFilled`, we could use

    aList |> filling |> filled

also known as: necessary code that nobody will understand.

    aList |> Fillable.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType :
    Is Filled filled
    -> Is filled_ filled
branchableType =
    \filledFillable ->
        filledFillable |> filling |> filled
