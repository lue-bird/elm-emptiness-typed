module MaybeTyped exposing
    ( MaybeTyped(..), Just, MaybeNothing, CanBeNothing(..)
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

    type alias ListTyped isEmpty a =
        MaybeTyped isEmpty ( a, List a )

    type alias NotEmpty =
        MaybeTyped.Just { notEmpty : () }

    type alias EmptyOrNot =
        MaybeTyped.MaybeNothing { emptyOrNot : () }

    empty : ListTyped EmptyOrNot a_

    cons : ListTyped emptyOrNot_ a -> a -> ListTyped notEmpty_ a

    head : ListTyped NotEmpty a -> a

This is exactly how [`ListTyped`] is implemented.


## types

@docs MaybeTyped, Just, MaybeNothing, CanBeNothing


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


{-| A value for when the `MaybeTyped` is `NothingTyped`.

It has a simple type tag to make `MaybeTyped` values distinct:

    type alias NotEmpty =
        MaybeTyped.Just { notEmpty : () }

    type alias ItemFocussed =
        MaybeTyped.Just { itemFocussed () }

-}
type CanBeNothing valueIfNothing tag
    = CanBeNothing valueIfNothing


{-| `Maybe (MaybeNothing tag) a`: The value could exist, could also not exist.

See [`CanBeNothing`](#CanBeNothing).

-}
type alias MaybeNothing tag =
    CanBeNothing () tag


{-| Only allow `MaybeTyped`s that certainly exist as arguments.

    import MaybeTyped exposing (Just, MaybeTyped)

    head : MaybeTyped (Just tag) ( a, List a ) -> a
    head maybe =
        maybe |> MaybeTyped.value |> Tuple.first

See [`CanBeNothing`](#CanBeNothing) and [`ListTyped`](ListTyped).

-}
type alias Just tag =
    CanBeNothing Never tag


{-| Nothing here.
-}
nothing : MaybeTyped (MaybeNothing tag_) a_
nothing =
    NothingTyped (CanBeNothing ())


{-| A `MaybeTyped` that certainly exists.
-}
just : a -> MaybeTyped just_ a
just value_ =
    JustTyped value_


{-| Convert a `Maybe` to a `MaybeTyped`.
-}
fromMaybe : Maybe a -> MaybeTyped (MaybeNothing tag_) a
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


{-| Safely extracts the value from every `MaybeTyped Just a`.
-}
value : MaybeTyped (Just tag_) a -> a
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
withFallback : (canBeNothing -> a) -> MaybeTyped (CanBeNothing canBeNothing tag_) a -> a
withFallback lazyFallback =
    \maybe ->
        case maybe of
            JustTyped val ->
                val

            NothingTyped (CanBeNothing canBeNothing) ->
                lazyFallback canBeNothing


{-| Transform the value in the `MaybeTyped` using a given function:

    map abs (just -3) --> just 3

    map abs nothing --> nothing

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

    map2 (+) (just 3) (just 4) --> just 7

    map2 (+) (just 3) nothing --> nothing

    map2 (+) nothing (just 4) --> nothing

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

    parse : String -> MaybeTyped MaybeNothing Parsed
    extraValidation : Parsed -> MaybeTyped MaybeNothing Validated

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
        ListTyped NotEmpty a
        -> ListTyped emptyOrNot a
        -> ListTyped emptyOrNot a
    theShorter aList bList =
        if ListTyped.length bList > ListTyped.length aList then
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
