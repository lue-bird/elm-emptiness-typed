module MaybeTyped exposing
    ( MaybeTyped(..), Just, Nothingable, CanBeNothing(..)
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value, andThen, withFallback
    , branchableType
    )

{-| `Maybe` with the ability to know at the type level whether it exists.

    import MaybeTyped exposing (just)

    [ just 1, just 7 ]
        -- : List (MaybeTyped notEmpty number)
        |> List.map MaybeTyped.value
    --> [ 1, 7 ]

I don't think `MaybeTyped` will proof any useful just by itself,
but we can build cool type-safe data structures with it:

    type alias Lis isEmpty a =
        MaybeTyped isEmpty ( a, List a )

    type alias NotEmpty =
        MaybeTyped.Just { notEmpty : () }

    type alias Emptiable =
        MaybeTyped.Nothingable { emptyOrNot : () }

    empty : Lis Emptiable a_

    cons : Lis emptyOrNot_ a -> a -> Lis notEmpty_ a

    head : Lis NotEmpty a -> a

This is exactly how [`Lis`] is implemented.


## types

@docs MaybeTyped, Just, Nothingable, CanBeNothing


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value, andThen, withFallback


## type-level

@docs branchableType

-}


{-| `Maybe` with the ability to know at the type level whether it exists.
-}
type MaybeTyped justOrNothing a
    = NothingTyped justOrNothing
    | JustTyped a


{-| The value attached to a `NothingTyped`:

  - [`Just`](#Just): that value is `Never`
  - [`Nothingable`](#Nothingable): that value is `()`

It also has a simple type tag to make `MaybeTyped` values distinct:

    type alias NotEmpty =
        MaybeTyped.Just { notEmpty : () }

    type alias ItemFocussed =
        MaybeTyped.Just { itemFocussed : () }

-}
type CanBeNothing valueIfNothing tag
    = CanBeNothing valueIfNothing


{-| `Maybe (Nothingable tag) a`: The value could exist, could also not exist.

See [`CanBeNothing`](#CanBeNothing).

-}
type alias Nothingable tag =
    CanBeNothing () tag


{-| Only allow `MaybeTyped`s that certainly exist as arguments.

    import MaybeTyped exposing (Just, MaybeTyped)

    head : MaybeTyped (Just tag_) ( a, List a ) -> a
    head maybe =
        maybe |> MaybeTyped.value |> Tuple.first

See [`CanBeNothing`](#CanBeNothing) and [`Lis`](Lis).

-}
type alias Just tag =
    CanBeNothing Never tag


{-| Nothing here.
-}
nothing : MaybeTyped (Nothingable tag_) a_
nothing =
    NothingTyped (CanBeNothing ())


{-| A `MaybeTyped` that certainly exists.
-}
just : value -> MaybeTyped just_ value
just value_ =
    JustTyped value_


{-| Convert a `Maybe` to a `MaybeTyped`.
-}
fromMaybe : Maybe a -> MaybeTyped (Nothingable tag_) a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            just val

        Nothing ->
            nothing



--


{-| Convert a `MaybeTyped` to a `Maybe`.
-}
toMaybe : MaybeTyped justOrNothing_ a -> Maybe a
toMaybe =
    \maybe ->
        case maybe of
            JustTyped val ->
                Just val

            NothingTyped _ ->
                Nothing


{-| Safely extracts the `value` from a `MaybeTyped Just value`.

    import MaybeTyped exposing (just)

    just (just (just "you"))
        |> MaybeTyped.value
        |> MaybeTyped.value
        |> MaybeTyped.value
    --> "you"

-}
value : MaybeTyped (Just tag_) value -> value
value definitelyJust =
    case definitelyJust of
        JustTyped val ->
            val

        NothingTyped (CanBeNothing canBeNothing) ->
            never canBeNothing


{-| Lazily use a fallback value if the `MaybeTyped` is [`nothing`](#nothing).

    Dict.empty
        |> Dict.get "Tom"
        |> MaybeTyped.fromMaybe
        |> MaybeTyped.withFallback (\() -> "unknown")
    --> "unknown"

Hint: `MaybeTyped.withFallback never` is equivalent to `MaybeTyped.value`.

-}
withFallback :
    (canBeNothing -> value)
    -> MaybeTyped (CanBeNothing canBeNothing tag_) value
    -> value
withFallback lazyFallback =
    \maybe ->
        case maybe of
            JustTyped val ->
                val

            NothingTyped (CanBeNothing canBeNothing) ->
                lazyFallback canBeNothing


{-| Transform the value in the `MaybeTyped` using a given function:

    import MaybeTyped exposing (just, nothing)

    MaybeTyped.map abs (just -3) --> just 3
    MaybeTyped.map abs nothing --> nothing

-}
map : (a -> b) -> MaybeTyped justOrNothing a -> MaybeTyped justOrNothing b
map change =
    \maybe ->
        case maybe of
            JustTyped val ->
                change val |> JustTyped

            NothingTyped canBeNothing ->
                NothingTyped canBeNothing


{-| If all the arguments exist, combine them using a given function.

    import MaybeTyped exposing (just, nothing)

    MaybeTyped.map2 (+) (just 3) (just 4) --> just 7
    MaybeTyped.map2 (+) (just 3) nothing --> nothing
    MaybeTyped.map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (a -> b -> combined)
    -> MaybeTyped justOrNothing a
    -> MaybeTyped justOrNothing b
    -> MaybeTyped justOrNothing combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( JustTyped a, JustTyped b ) ->
            combine a b |> JustTyped

        ( NothingTyped canBeNothing, _ ) ->
            NothingTyped canBeNothing

        ( _, NothingTyped canBeNothing ) ->
            NothingTyped canBeNothing


{-| Chain together many computations that may fail.

    maybeString
        |> MaybeTyped.andThen parse
        |> MaybeTyped.andThen extraValidation

    parse : String -> MaybeTyped Nothingable Parsed
    extraValidation : Parsed -> MaybeTyped Nothingable Validated

-}
andThen :
    (a -> MaybeTyped justOrNothing b)
    -> MaybeTyped justOrNothing a
    -> MaybeTyped justOrNothing b
andThen tryIfSuccess =
    \maybe ->
        case maybe of
            JustTyped val ->
                tryIfSuccess val

            NothingTyped canBeNothing ->
                NothingTyped canBeNothing



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
            -- ↓ is `NotEmpty` but we need `emptyOrNot`
            aList

to make both branches return `emptyOrNot`, we could use

    else
        aList |> ListType.toTuple |> ListType.fromTuple

also known as: necessary code that nobody will understand.

    else
        aList |> MaybeTyped.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType : MaybeTyped (Just tag_) a -> MaybeTyped just_ a
branchableType =
    value >> just
