module MaybeIs exposing
    ( CanBe(..), MaybeIs(..)
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
        MaybeIs.CanBe { empty : () } Never

    type alias Emptiable =
        MaybeIs.CanBe { empty : () } ()

    empty : ListIs Emptiable a_

    cons : ListIs emptyOrNot_ a -> a -> ListIs notEmpty_ a

    head : ListIs NotEmpty a -> a

This is exactly how [`ListIs`](ListIs) is implemented.


## types

@docs CanBe, MaybeIs


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value, andThen, withFallback


## type-level

@docs branchableType

-}


{-| Like `Maybe` with type level information about whether it exists. See [`CanBe`](#CanBe).
-}
type MaybeIs justOrNothing a
    = IsNothing justOrNothing
    | IsJust a


{-| `CanBe` is just a cleaner version of this.
It has a simple type tag to make `Never` values distinct:

    type alias NotEmpty =
        CanBe { empty : () } Never

    type alias Item =
        CanBe { hole : () } Never

_Remember to update the tag after renaming an alias._

Now the fun part:

    joinParts :
        HoleyFocusList (CanBe hole_ yesOrNever) a
        -> ListIs (CanBe empty_ yesOrNever) a
    joinParts ... =
        case ( before, focus, after ) of
            ( [], StringEmpty (CanBe yesOrNever), [] ) ->
                IsNothing
                    --↓ carries over the `yesOrNever` type,
                    --↓ while allowing a new tag
                    (CanBe yesOrNever)

            ... -> ...

> the type information gets carried over, so
>
>     HoleyFocusList.Item -> ListIs.NotEmpty
>     CanBe hole_ () -> CanBe empty_ ()

Read more in the readme!

-}
type CanBe stateTag neverOrValue
    = CanBe neverOrValue


{-| Nothing here.
-}
nothing : MaybeIs (CanBe possibleStateTag_ ()) a_
nothing =
    IsNothing (CanBe ())


{-| A `MaybeIs` that certainly exists.

    MaybeIs.just "you" |> MaybeIs.value
    --> "you"

-}
just : value -> MaybeIs just_ value
just value_ =
    IsJust value_


{-| Convert a `Maybe` to a `MaybeIs`.
-}
fromMaybe : Maybe a -> MaybeIs (CanBe possibleStateTag_ ()) a
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


{-| Safely extracts the `value` from a `MaybeIs (CanBe nothingTag_ Never) value`.

    import MaybeIs exposing (just, MaybeIs)

    just (just (just "you"))
        |> MaybeIs.value
        |> MaybeIs.value
        |> MaybeIs.value
    --> "you"

    head : MaybeIs (CanBe empty_ Never) ( a, List a ) -> a
    head =
        MaybeIs.value >> Tuple.first

See [`CanBe`](#CanBe) and [`ListIs`](ListIs).

-}
value : MaybeIs (CanBe impossibleStateTag_ Never) value -> value
value definitelyJust =
    definitelyJust |> withFallback never


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
    (unitOrNever -> value)
    -> MaybeIs (CanBe stateTag_ unitOrNever) value
    -> value
withFallback lazyFallback =
    \maybe ->
        case maybe of
            IsJust val ->
                val

            IsNothing (CanBe unitOrNever) ->
                lazyFallback unitOrNever


{-| Transform the value in the `MaybeIs` using a given function:

    import MaybeIs exposing (just, nothing)

    MaybeIs.map abs (just -3) --> just 3
    MaybeIs.map abs nothing --> nothing

-}
map :
    (a -> b)
    -> MaybeIs (CanBe nothingTag_ yesOrNever) a
    -> MaybeIs (CanBe mappedNothingTag_ yesOrNever) b
map change =
    \maybe ->
        case maybe of
            IsJust val ->
                change val |> IsJust

            IsNothing (CanBe yesOrNever) ->
                IsNothing (CanBe yesOrNever)


{-| If all the arguments exist, combine them using a given function.

    import MaybeIs exposing (just, nothing)

    MaybeIs.map2 (+) (just 3) (just 4) --> just 7
    MaybeIs.map2 (+) (just 3) nothing --> nothing
    MaybeIs.map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (a -> b -> combined)
    -> MaybeIs (CanBe aNothingTag_ yesOrNever) a
    -> MaybeIs (CanBe bNothingTag_ yesOrNever) b
    -> MaybeIs (CanBe combinedNothingTag_ yesOrNever) combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( IsJust a, IsJust b ) ->
            combine a b |> IsJust

        ( IsNothing (CanBe yesOrNever), _ ) ->
            IsNothing (CanBe yesOrNever)

        ( _, IsNothing (CanBe yesOrNever) ) ->
            IsNothing (CanBe yesOrNever)


{-| Chain together many computations that may fail.

    maybeString
        |> MaybeIs.andThen parse
        |> MaybeIs.andThen extraValidation

    parse : String -> MaybeIs CanBe Parsed
    extraValidation : Parsed -> MaybeIs CanBe Validated

-}
andThen :
    (a -> MaybeIs (CanBe thenNothingTag yesOrNever) b)
    -> MaybeIs (CanBe nothingTag_ yesOrNever) a
    -> MaybeIs (CanBe thenNothingTag yesOrNever) b
andThen tryIfSuccess =
    \maybe ->
        case maybe of
            IsJust val ->
                tryIfSuccess val

            IsNothing (CanBe yesOrNever) ->
                IsNothing (CanBe yesOrNever)



--


{-| When using `CanBe ... Never` for an argument:

    theShorter :
        ListIs (CanBe { empty : () } Never) a
        -> ListIs emptyOrNot a
        -> ListIs emptyOrNot a
    theShorter aList bList =
        if ListIs.length bList > ListIs.length aList then
            bList

        else
            --↓ `NotEmpty` but we need `emptyOrNot`
            aList

to make both branches return `emptyOrNot`, we could use

    aList |> ListType.unCons |> ListType.fromTuple

also known as: necessary code that nobody will understand.

    aList |> MaybeIs.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType :
    MaybeIs (CanBe impossibleStateTag_ Never) a
    -> MaybeIs just_ a
branchableType =
    value >> just
