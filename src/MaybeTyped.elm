module MaybeTyped exposing
    ( MaybeTyped, MaybeEmpty, NotEmpty
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value
    )

{-|


## types

@docs MaybeTyped, MaybeEmpty, NotEmpty


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value

-}


type MaybeTyped isEmpty a
    = NothingTyped isEmpty
    | JustTyped a


type alias MaybeEmpty =
    { empty : () }


type alias NotEmpty =
    { empty : Never }


nothing : MaybeTyped MaybeEmpty a
nothing =
    NothingTyped { empty = () }


just : a -> MaybeTyped notEmpty a
just value_ =
    JustTyped value_


fromMaybe : Maybe a -> MaybeTyped MaybeEmpty a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            JustTyped val

        Nothing ->
            NothingTyped { empty = () }


toMaybe : MaybeTyped empty a -> Maybe a
toMaybe maybe =
    case maybe of
        JustTyped val ->
            Just val

        NothingTyped _ ->
            Nothing


value : MaybeTyped { kind | empty : Never } a -> a
value maybe =
    case maybe of
        JustTyped val ->
            val

        NothingTyped { empty } ->
            never empty


map : (a -> b) -> MaybeTyped empty a -> MaybeTyped empty b
map change maybe =
    case maybe of
        JustTyped val ->
            change val |> JustTyped

        NothingTyped empty ->
            NothingTyped empty


map2 :
    (a -> b -> combined)
    -> MaybeTyped empty a
    -> MaybeTyped empty b
    -> MaybeTyped empty combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( JustTyped a, JustTyped b ) ->
            combine a b |> JustTyped

        ( NothingTyped empty, _ ) ->
            NothingTyped empty

        ( _, NothingTyped empty ) ->
            NothingTyped empty
