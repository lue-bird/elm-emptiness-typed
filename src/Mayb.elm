module Mayb exposing
    ( Mayb(..), Just, Nothingable, CanBeNothing(..)
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value, andThen, withFallback
    , branchableType
    )

{-| `Maybe` with the ability to know at the type level whether it exists.

    import Mayb exposing (just)

    [ just 1, just 7 ]
        -- : List (Mayb just_ number_)
        |> List.map Mayb.value
    --> [ 1, 7 ]

I don't think `Mayb` will proof any useful just by itself,
but we can build cool type-safe data structures with it:

    type alias Lis emptyOrNot a =
        Mayb emptyOrNot ( a, List a )

    type alias NotEmpty =
        Mayb.Just { notEmpty : () }

    type alias Emptiable =
        Mayb.Nothingable { emptiable : () }

    empty : Lis Emptiable a_

    cons : Lis emptyOrNot_ a -> a -> Lis notEmpty_ a

    head : Lis NotEmpty a -> a

This is exactly how [`Lis`] is implemented.


## types

@docs Mayb, Just, Nothingable, CanBeNothing


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value, andThen, withFallback


## type-level

@docs branchableType

-}


{-| `Maybe` with the ability to know at the type level whether it exists.
-}
type Mayb justOrNothing a
    = Nothin justOrNothing
    | Jus a


{-| The value attached to a `Nothin`:

  - [`Just`](#Just): that value is `Never`
  - [`Nothingable`](#Nothingable): that value is `()`

It also has a simple type tag to make `Mayb` values distinct:

    type alias NotEmpty =
        Mayb.Just { notEmpty : () }

    type alias ItemFocussed =
        Mayb.Just { itemFocussed : () }

-}
type CanBeNothing valueIfNothing tag
    = CanBeNothing valueIfNothing


{-| `Maybe (Nothingable tag) a`: The value could exist, could also not exist.

See [`CanBeNothing`](#CanBeNothing).

-}
type alias Nothingable tag =
    CanBeNothing () tag


{-| Only allow `Mayb`s that certainly exist as arguments.

    import Mayb exposing (Just, Mayb)

    head : Mayb (Just tag_) ( a, List a ) -> a
    head maybe =
        maybe |> Mayb.value |> Tuple.first

See [`CanBeNothing`](#CanBeNothing) and [`Lis`](Lis).

-}
type alias Just tag =
    CanBeNothing Never tag


{-| Nothing here.
-}
nothing : Mayb (Nothingable tag_) a_
nothing =
    Nothin (CanBeNothing ())


{-| A `Mayb` that certainly exists.

    Mayb.just "you" |> Mayb.value
    --> "you"

-}
just : value -> Mayb just_ value
just value_ =
    Jus value_


{-| Convert a `Maybe` to a `Mayb`.
-}
fromMaybe : Maybe a -> Mayb (Nothingable tag_) a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            just val

        Nothing ->
            nothing



--


{-| Convert a `Mayb` to a `Maybe`.
-}
toMaybe : Mayb justOrNothing_ a -> Maybe a
toMaybe =
    \maybe ->
        case maybe of
            Jus val ->
                Just val

            Nothin _ ->
                Nothing


{-| Safely extracts the `value` from a `Mayb Just value`.

    import Mayb exposing (just)

    just (just (just "you"))
        |> Mayb.value
        |> Mayb.value
        |> Mayb.value
    --> "you"

-}
value : Mayb (Just tag_) value -> value
value definitelyJust =
    case definitelyJust of
        Jus val ->
            val

        Nothin (CanBeNothing canBeNothing) ->
            never canBeNothing


{-| Lazily use a fallback value if the `Mayb` is [`nothing`](#nothing).

    Dict.empty
        |> Dict.get "Tom"
        |> Mayb.fromMaybe
        |> Mayb.withFallback (\() -> "unknown")
    --> "unknown"

Hint: `Mayb.withFallback never` is equivalent to `Mayb.value`.

-}
withFallback :
    (canBeNothing -> value)
    -> Mayb (CanBeNothing canBeNothing tag_) value
    -> value
withFallback lazyFallback =
    \maybe ->
        case maybe of
            Jus val ->
                val

            Nothin (CanBeNothing canBeNothing) ->
                lazyFallback canBeNothing


{-| Transform the value in the `Mayb` using a given function:

    import Mayb exposing (just, nothing)

    Mayb.map abs (just -3) --> just 3
    Mayb.map abs nothing --> nothing

-}
map : (a -> b) -> Mayb justOrNothing a -> Mayb justOrNothing b
map change =
    \maybe ->
        case maybe of
            Jus val ->
                change val |> Jus

            Nothin canBeNothing ->
                Nothin canBeNothing


{-| If all the arguments exist, combine them using a given function.

    import Mayb exposing (just, nothing)

    Mayb.map2 (+) (just 3) (just 4) --> just 7
    Mayb.map2 (+) (just 3) nothing --> nothing
    Mayb.map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (a -> b -> combined)
    -> Mayb justOrNothing a
    -> Mayb justOrNothing b
    -> Mayb justOrNothing combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( Jus a, Jus b ) ->
            combine a b |> Jus

        ( Nothin canBeNothing, _ ) ->
            Nothin canBeNothing

        ( _, Nothin canBeNothing ) ->
            Nothin canBeNothing


{-| Chain together many computations that may fail.

    maybeString
        |> Mayb.andThen parse
        |> Mayb.andThen extraValidation

    parse : String -> Mayb Nothingable Parsed
    extraValidation : Parsed -> Mayb Nothingable Validated

-}
andThen :
    (a -> Mayb justOrNothing b)
    -> Mayb justOrNothing a
    -> Mayb justOrNothing b
andThen tryIfSuccess =
    \maybe ->
        case maybe of
            Jus val ->
                tryIfSuccess val

            Nothin canBeNothing ->
                Nothin canBeNothing



--


{-| When using `(Just ...)` for an argument:

    theShorter :
        Lis NotEmpty a
        -> Lis emptyOrNot a
        -> Lis emptyOrNot a
    theShorter aList bList =
        if Lis.length bList > Lis.length aList then
            bList

        else
            -- ↓ `NotEmpty` but we need `emptyOrNot`
            aList

to make both branches return `emptyOrNot`, we could use

    else
        aList |> ListType.toTuple |> ListType.fromTuple

also known as: necessary code that nobody will understand.

    else
        aList |> Mayb.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType : Mayb (Just tag_) a -> Mayb just_ a
branchableType =
    value >> just
