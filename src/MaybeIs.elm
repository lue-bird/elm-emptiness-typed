module MaybeIs exposing
    ( MaybeIs(..), Just, Nothingable, CanBeNothing(..)
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value, andThen, withFallback
    , branchableType
    )

{-| `Maybe` with the ability to know at the type level whether it exists.

    import MaybeIs exposing (just)

    [ just 1, just 7 ]
        --: List (MaybeIs just_ number_)
        |> List.map MaybeIs.value
    --> [ 1, 7 ]

`MaybeIs` alone will probably not proof any useful,
but we can build cool type-safe data structures with it:

    type alias ListIs emptyOrNot a =
        MaybeIs emptyOrNot ( a, List a )

    type alias NotEmpty =
        MaybeIs.Just { notEmpty : () }

    type alias Emptiable =
        MaybeIs.Nothingable { emptiable : () }

    empty : ListIs Emptiable a_

    cons : ListIs emptyOrNot_ a -> a -> ListIs notEmpty_ a

    head : ListIs NotEmpty a -> a

This is exactly how [`ListIs`](ListIs) is implemented.


## types

@docs MaybeIs, Just, Nothingable, CanBeNothing


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value, andThen, withFallback


## type-level

@docs branchableType

-}


{-| Like `Maybe` with type level information about whether it exists.

See [`Just`](#Just) and [`Nothingable`](#Nothingable).

-}
type MaybeIs justOrNothing a
    = IsNothing justOrNothing
    | IsJust a


{-| The value attached to a `IsNothing`:

  - [`Just`](#Just): that value is `Never`
  - [`Nothingable`](#Nothingable): that value is `()`

It also has a simple type tag to make `MaybeIs` values distinct:

    type alias NotEmpty =
        MaybeIs.Just { notEmpty : () }

    type alias ItemFocussed =
        MaybeIs.Just { itemFocussed : () }

Remember to update the tag after renaming an alias.

-}
type CanBeNothing valueIfNothing tag
    = CanBeNothing valueIfNothing


{-| `MaybeIs (Nothingable tag)`: The value could exist, could also not exist.

See [`CanBeNothing`](#CanBeNothing).

-}
type alias Nothingable tag =
    CanBeNothing () tag


{-| Only allow `MaybeIs`s that certainly exist as arguments.

    import MaybeIs exposing (Just, MaybeIs)

    head : MaybeIs (Just tag_) ( a, List a ) -> a
    head =
        MaybeIs.value >> Tuple.first

See [`CanBeNothing`](#CanBeNothing) and [`ListIs`](ListIs).

-}
type alias Just tag =
    CanBeNothing Never tag


{-| Nothing here.
-}
nothing : MaybeIs (Nothingable tag_) a_
nothing =
    IsNothing (CanBeNothing ())


{-| A `MaybeIs` that certainly exists.

    MaybeIs.just "you" |> MaybeIs.value
    --> "you"

-}
just : value -> MaybeIs just_ value
just value_ =
    IsJust value_


{-| Convert a `Maybe` to a `MaybeIs`.
-}
fromMaybe : Maybe a -> MaybeIs (Nothingable tag_) a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            just val

        Nothing ->
            nothing



--


{-| Convert a `MaybeIs` to a `Maybe`.
-}
toMaybe : MaybeIs justOrNothing_ a -> Maybe a
toMaybe =
    \maybe ->
        case maybe of
            IsJust val ->
                Just val

            IsNothing _ ->
                Nothing


{-| Safely extracts the `value` from a `MaybeIs Just value`.

    import MaybeIs exposing (just)

    just (just (just "you"))
        |> MaybeIs.value
        |> MaybeIs.value
        |> MaybeIs.value
    --> "you"

-}
value : MaybeIs (Just tag_) value -> value
value definitelyJust =
    case definitelyJust of
        IsJust val ->
            val

        IsNothing (CanBeNothing canBeNothing) ->
            never canBeNothing


{-| Lazily use a fallback value if the `MaybeIs` is [`nothing`](#nothing).

    import Dict

    Dict.empty
        |> Dict.get "Tom"
        |> MaybeIs.fromMaybe
        |> MaybeIs.withFallback (\() -> "unknown")
    --> "unknown"

Hint: `MaybeIs.withFallback never` is equivalent to `MaybeIs.value`.

-}
withFallback :
    (canBeNothing -> value)
    -> MaybeIs (CanBeNothing canBeNothing tag_) value
    -> value
withFallback lazyFallback =
    \maybe ->
        case maybe of
            IsJust val ->
                val

            IsNothing (CanBeNothing canBeNothing) ->
                lazyFallback canBeNothing


{-| Transform the value in the `MaybeIs` using a given function:

    import MaybeIs exposing (just, nothing)

    MaybeIs.map abs (just -3) --> just 3
    MaybeIs.map abs nothing --> nothing

-}
map : (a -> b) -> MaybeIs justOrNothing a -> MaybeIs justOrNothing b
map change =
    \maybe ->
        case maybe of
            IsJust val ->
                change val |> IsJust

            IsNothing canBeNothing ->
                IsNothing canBeNothing


{-| If all the arguments exist, combine them using a given function.

    import MaybeIs exposing (just, nothing)

    MaybeIs.map2 (+) (just 3) (just 4) --> just 7
    MaybeIs.map2 (+) (just 3) nothing --> nothing
    MaybeIs.map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (a -> b -> combined)
    -> MaybeIs justOrNothing a
    -> MaybeIs justOrNothing b
    -> MaybeIs justOrNothing combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( IsJust a, IsJust b ) ->
            combine a b |> IsJust

        ( IsNothing canBeNothing, _ ) ->
            IsNothing canBeNothing

        ( _, IsNothing canBeNothing ) ->
            IsNothing canBeNothing


{-| Chain together many computations that may fail.

    maybeString
        |> MaybeIs.andThen parse
        |> MaybeIs.andThen extraValidation

    parse : String -> MaybeIs Nothingable Parsed
    extraValidation : Parsed -> MaybeIs Nothingable Validated

-}
andThen :
    (a -> MaybeIs justOrNothing b)
    -> MaybeIs justOrNothing a
    -> MaybeIs justOrNothing b
andThen tryIfSuccess =
    \maybe ->
        case maybe of
            IsJust val ->
                tryIfSuccess val

            IsNothing canBeNothing ->
                IsNothing canBeNothing



--


{-| When using `Just`/`NotEmpty`/... for an argument:

    theShorter :
        ListIs NotEmpty a
        -> ListIs emptyOrNot a
        -> ListIs emptyOrNot a
    theShorter aList bList =
        if ListIs.length bList > ListIs.length aList then
            bList

        else
            --↓ `NotEmpty` but we need `emptyOrNot`
            aList

to make both branches return `emptyOrNot`, we could use

    else
        aList |> ListType.toTuple |> ListType.fromTuple

also known as: necessary code that nobody will understand.

    else
        aList |> MaybeIs.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType : MaybeIs (Just tag_) a -> MaybeIs just_ a
branchableType =
    value >> just
