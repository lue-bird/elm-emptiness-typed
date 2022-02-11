module MaybeThat exposing
    ( Can(..), Be(..), CanBe, Isnt
    , MaybeThat(..), Nothing
    , just, nothing, fromMaybe
    , map, map2, toMaybe, value, andThen, withFallback
    , branchableType
    )

{-| `Maybe` with the ability to know at the type level whether it exists.

    import MaybeThat exposing (just)

    [ just 1, just 7 ]
        --: List (MaybeThat just_ number_)
        |> List.map MaybeThat.value
    --> [ 1, 7 ]

[`MaybeThat`](#MaybeThat) alone will probably not proof any useful,
but we can build cool type-safe data structures with it:

    type alias ListThat emptyOrNot a =
        MaybeThat emptyOrNot ( a, List a )

    empty : ListThat (CanBe empty_) a_

    cons : ListThat canBeEmptyOrNot_ a -> a -> ListThat isntEmpty_ a

    head : ListThat (Isnt empty_) a -> a

This is exactly how [`ListThat`](ListThat) is implemented.


## types

@docs Can, Be, CanBe, Isnt
@docs MaybeThat, Nothing


## create

@docs just, nothing, fromMaybe


## transform

@docs map, map2, toMaybe, value, andThen, withFallback


## type-level

@docs branchableType

-}


{-| Like `Maybe` with type level information about whether it exists. See [`CanBe`](#CanBe).
-}
type MaybeThat justOrNothing a
    = NothingThat justOrNothing
    | JustThat a


{-| Type tag:

Require [`just`](#just) as an argument:

    head : ListThat (Isnt Empty) element -> element

Store a [`MaybeThat`](#MaybeThat) somewhere:

    type alias Model =
        WithoutConstructorFunction
            { selected : MaybeThat (CanBe Nothing) TreePath
            }

    type alias WithoutConstructorFunction record =
        record

where `WithoutConstructorFunction` stops the compiler from creating a positional constructor function for `Model`.

-}
type Nothing
    = Nothing Never


{-| `CanBe` is just a cleaner version of this.
It has a simple type tag to make `Never` values distinct:

    type Empty
        = Empty

    fromCons : a -> List a -> ListThat (Isnt Empty)

    type Hole
        = Hole

    only : a -> ListWithFocusThat (Isnt Hole)

Now the fun part:

    toCharList :
        StringIs (CanBe emptyString_ possiblyOrNever) a
        -> ListThat (CanBe emptyList_ possiblyOrNever) a
    toCharList string =
        case string of
            StringEmpty (CanBe possiblyOrNever) ->
                NothingThat
                    --↓ carries over the `possiblyOrNever` type,
                    --↓ while allowing a new tag
                    (CanBe possiblyOrNever)

            String (Isnt Empty) headChar tailString ->
                ListThat.fromCons headChar (tailString |> String.toList)

> the type information gets carried over, so
>
>     ListWithFocusThat.Item -> Not ListThat.Empty
>     CanBe hole_ -> CanBe empty_

Read more in the [readme](https://dark.elm.dmy.fr/packages/lue-bird/elm-emptiness-typed/latest/)!

-}
type Can possiblyOrNever be stateTag
    = Can possiblyOrNever Be


{-| Just a word in the type and value [`Can`](#Can):

    type alias CanBe state =
        Can () Be state

    type alias Isnt state =
        Can Never Be state

    StringEmpty (Can possiblyOrNever Be) ->
        NothingThat
            --↓ carries over the `possiblyOrNever` type,
            --↓ while allowing a new tag
            (Can possiblyOrNever Be)

-}
type Be
    = Be


{-| The empty state is possible.

    fromMaybe : Maybe value -> MaybeThat (CanBe possibleState_) value

    fromList : List element -> ListThat (CanBe empty_) element

-}
type alias CanBe possibleStateTag =
    Can () Be possibleStateTag


{-| The empty state isn't possible.

    value : MaybeThat (Isnt nothing_) value -> value

    unCons : ListThat (Isnt empty_) element -> ( element, List element )

-}
type alias Isnt impossibleStateTag =
    Can Never Be impossibleStateTag


{-| The gap is empty.
-}
nothing : MaybeThat (CanBe possibleState_) a_
nothing =
    NothingThat (Can () Be)


{-| A [`MaybeThat`](#MaybeThat) that certainly exists.

    MaybeThat.just "you" |> MaybeThat.value
    --> "you"

-}
just : value -> MaybeThat isJust_ value
just value_ =
    JustThat value_


{-| Convert a `Maybe` to a [`MaybeThat`](#MaybeThat).
-}
fromMaybe : Maybe value -> MaybeThat (CanBe possibleState_) value
fromMaybe coreMaybe =
    case coreMaybe of
        Just val ->
            just val

        Maybe.Nothing ->
            nothing



--


{-| Convert a [`MaybeThat`](#MaybeThat) to a `Maybe`.
-}
toMaybe : MaybeThat isJustOrNothing_ value -> Maybe value
toMaybe =
    \maybe ->
        case maybe of
            JustThat val ->
                Just val

            NothingThat _ ->
                Maybe.Nothing


{-| Safely extracts the `value` from a `MaybeThat (CanBe nothingTag_ Never) value`.

    import MaybeThat exposing (just, MaybeThat)

    just (just (just "you"))
        |> MaybeThat.value
        |> MaybeThat.value
        |> MaybeThat.value
    --> "you"

    head : MaybeThat (CanBe empty_ Never) ( a, List a ) -> a
    head =
        MaybeThat.value >> Tuple.first

See [`CanBe`](#CanBe) and [`ListThat`](ListThat).

-}
value : MaybeThat (Isnt impossibleState_) value -> value
value definitelyJust =
    definitelyJust |> withFallback never


{-| Lazily use a fallback value if the `MaybeThat` is [`nothing`](#nothing).

    import Dict

    Dict.empty
        |> Dict.get "Tom"
        |> MaybeThat.fromMaybe
        |> MaybeThat.withFallback (\() -> "unknown")
    --> "unknown"

Hint: `MaybeThat.withFallback never` is equivalent to `MaybeThat.value`.

-}
withFallback :
    (unitOrNever -> value)
    -> MaybeThat (Can unitOrNever Be state_) value
    -> value
withFallback lazyFallback =
    \maybe ->
        case maybe of
            JustThat val ->
                val

            NothingThat (Can unitOrNever Be) ->
                lazyFallback unitOrNever


{-| Transform the value in the `MaybeThat` using a given function:

    import MaybeThat exposing (just, nothing)

    MaybeThat.map abs (just -3) --> just 3
    MaybeThat.map abs nothing --> nothing

-}
map :
    (value -> mappedValue)
    -> MaybeThat (Can possiblyOrNever Be nothing_) value
    -> MaybeThat (Can possiblyOrNever Be mappedNothing_) mappedValue
map change =
    \maybe ->
        case maybe of
            JustThat val ->
                change val |> JustThat

            NothingThat (Can possiblyOrNever Be) ->
                NothingThat (Can possiblyOrNever Be)


{-| If all the arguments exist, combine them using a given function.

    import MaybeThat exposing (just, nothing)

    MaybeThat.map2 (+) (just 3) (just 4) --> just 7
    MaybeThat.map2 (+) (just 3) nothing --> nothing
    MaybeThat.map2 (+) nothing (just 4) --> nothing

-}
map2 :
    (aValue -> bValue -> combinedValue)
    -> MaybeThat (Can possiblyOrNever Be aNothing_) aValue
    -> MaybeThat (Can possiblyOrNever Be bNothing_) bValue
    -> MaybeThat (Can possiblyOrNever Be combinedNothing_) combinedValue
map2 combine aMaybe bMaybe =
    case ( aMaybe, bMaybe ) of
        ( JustThat a, JustThat b ) ->
            combine a b |> JustThat

        ( NothingThat (Can possiblyOrNever Be), _ ) ->
            NothingThat (Can possiblyOrNever Be)

        ( _, NothingThat (Can possiblyOrNever Be) ) ->
            NothingThat (Can possiblyOrNever Be)


{-| Chain together many computations that may fail.

    maybeString
        |> MaybeThat.andThen parse
        |> MaybeThat.andThen extraValidation

    parse : String -> MaybeThat CanBe Parsed
    extraValidation : Parsed -> MaybeThat CanBe Validated

-}
andThen :
    (value -> MaybeThat (Can possiblyOrNever Be thenNothing) thenValue)
    -> MaybeThat (Can possiblyOrNever Be nothing_) value
    -> MaybeThat (Can possiblyOrNever Be thenNothing) thenValue
andThen tryIfSuccess =
    \maybe ->
        case maybe of
            JustThat val ->
                tryIfSuccess val

            NothingThat (Can possiblyOrNever Be) ->
                NothingThat (Can possiblyOrNever Be)



--


{-| When using `Isnt ...` on an argument:

    theShorter :
        ListThat (Isnt Empty) a
        -> ListThat isEmptyOrNot a
        -> ListThat isEmptyOrNot a
    theShorter aList bList =
        if ListThat.length bList > ListThat.length aList then
            bList

        else
            --↓ `Isnt Empty` but we need `emptyOrNot`
            aList

to make both branches return `emptyOrNot`, we could use

    aList |> ListType.unCons |> ListType.fromUnConsed

also known as: necessary code that nobody will understand.

    aList |> MaybeThat.branchableType

is a bit better.

💙 Found a better name? → open an issue.

-}
branchableType :
    MaybeThat (Isnt nothing_) a
    -> MaybeThat isJust_ a
branchableType =
    value >> just
