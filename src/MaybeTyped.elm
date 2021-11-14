module MaybeTyped exposing
    ( MaybeTyped(..), Exists, MaybeNothing
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value
    )

{-| `Maybe` with the ability to know at the type level whether it exists.

    import MaybeTyped exposing (just)

    [ just 1, just 7 ]
        |> List.map MaybeTyped.value
    --> [ 1, 7 ]

    type alias ListTyped isEmpty a =
        MaybeTyped isEmpty ( a, List a )

    empty : ListTyped MaybeTyped.MaybeNothing a
    cons : ListTyped isHeadEmpty a -> a -> ListTyped headExists a
    head : ListTyped MaybeTyped.Exists a a -> a


## types

@docs MaybeTyped, Exists, MaybeNothing


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value

-}


{-| `Maybe` with the ability to know at the type level whether it exists.
-}
type MaybeTyped isEmpty a
    = NothingTyped isEmpty
    | JustTyped a


{-| `Maybe MaybeNothing a`: The value could exist, could also not exist.
-}
type alias MaybeNothing =
    { empty : () }


{-| In

    import MaybeTyped exposing (MaybeTyped, Exists)

    f : MaybeTyped Exists a -> a
    f maybe =
        |> MaybeTyped.value

only `MaybeTyped`s that certainly exist can be used as arguments.

-}
type alias Exists =
    { empty : Never }


{-| Empty.
-}
nothing : MaybeTyped MaybeNothing a
nothing =
    NothingTyped { empty = () }


{-| A `MaybeTyped` that certainly exists.
-}
just : a -> MaybeTyped notEmpty a
just value_ =
    JustTyped value_


{-| Convert a `Maybe` to a `MaybeTyped`.
-}
fromMaybe : Maybe a -> MaybeTyped MaybeNothing a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            JustTyped val

        Nothing ->
            NothingTyped { empty = () }


{-| Convert a `MaybeTyped` to a `Maybe`.
-}
toMaybe : MaybeTyped empty a -> Maybe a
toMaybe maybe =
    case maybe of
        JustTyped val ->
            Just val

        NothingTyped _ ->
            Nothing


{-| Safely extracts the value from every `MaybeTyped Exists a`.
-}
value : MaybeTyped { kind | empty : Never } a -> a
value maybe =
    case maybe of
        JustTyped val ->
            val

        NothingTyped { empty } ->
            never empty


{-| Transform the value in the `MaybeTyped` using a given function:

    map abs (just -3) --> just 3

    map abs nothing --> nothing

-}
map : (a -> b) -> MaybeTyped isEmpty a -> MaybeTyped isEmpty b
map change maybe =
    case maybe of
        JustTyped val ->
            change val |> JustTyped

        NothingTyped empty ->
            NothingTyped empty


{-| If all the arguments exist, combine them using a given function.

    map2 (+) (just 3) (just 4) --> just 7

    map2 (+) (just 3) nothing --> nothing

    map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (a -> b -> combined)
    -> MaybeTyped isEmpty a
    -> MaybeTyped isEmpty b
    -> MaybeTyped isEmpty combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( JustTyped a, JustTyped b ) ->
            combine a b |> JustTyped

        ( NothingTyped empty, _ ) ->
            NothingTyped empty

        ( _, NothingTyped empty ) ->
            NothingTyped empty


{-| Chain together many computations that may fail.

    maybeString
        |> MaybeTyped.andThen parse
        |> MaybeTyped.andThen extraValidation

    parse : String -> MaybeTyped MaybeNothing Parsed
    extraValidation : Parsed -> MaybeTyped MaybeNothing Validated

-}
andThen : (a -> MaybeTyped isEmpty b) -> MaybeTyped isEmpty a -> MaybeTyped isEmpty b
andThen tryIfSuccess maybe =
    case maybe of
        JustTyped val ->
            tryIfSuccess val

        NothingTyped empty ->
            NothingTyped empty
