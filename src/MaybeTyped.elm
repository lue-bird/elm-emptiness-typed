module MaybeTyped exposing
    ( MaybeTyped, MaybeEmpty, NotEmpty
    , fromMaybe
    , map, map2, toMaybe, value
    )

{-|


## types

@docs MaybeTyped, MaybeEmpty, NotEmpty


## create

@docs fromMaybe, existing, empty


## transform

@docs map, map2, toMaybe, value

-}


type MaybeTyped isEmpty a
    = Empty isEmpty
    | Existing a


type alias MaybeEmpty =
    { empty : () }


type alias NotEmpty =
    { empty : Never }


fromMaybe : Maybe a -> MaybeTyped MaybeEmpty a
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            Existing val

        Nothing ->
            Empty { empty = () }


toMaybe : MaybeTyped empty a -> Maybe a
toMaybe maybe =
    case maybe of
        Existing val ->
            Just val

        Empty _ ->
            Nothing


value : MaybeTyped { kind | empty : Never } a -> a
value maybe =
    case maybe of
        Existing val ->
            val

        Empty { empty } ->
            never empty


map : (a -> b) -> MaybeTyped empty a -> MaybeTyped empty b
map change maybe =
    case maybe of
        Existing val ->
            change val |> Existing

        Empty empty ->
            Empty empty


map2 :
    (a -> b -> combined)
    -> MaybeTyped empty a
    -> MaybeTyped empty b
    -> MaybeTyped empty combined
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( Existing a, Existing b ) ->
            combine a b |> Existing

        ( Empty empty, _ ) ->
            Empty empty

        ( _, Empty empty ) ->
            Empty empty
