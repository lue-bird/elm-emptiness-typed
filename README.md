> one type for emptiable and safe non-empty

# [emptiness typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

**_🗨️ Read about [allowable state](https://package.elm-lang.org/packages/lue-bird/elm-allowable-state/latest/) first _**

[`Hand`](Hand) `. . .  Never |` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) `Empty`
is a convenience layer for an emptiable-able value:

```elm
import Hand exposing (Hand, Empty, filled, fill, fillMap)

type TextFilled
    = TextFilled Char String

first : Hand TextFilled Never Empty -> Char
first =
    fill >> \(TextFilled firstChar _) -> firstChar

fillMap (filled >> first)
--: Hand TextFilled possiblyOrNever Empty
--: -> Hand Char possiblyOrNever Empty
```

→ `Hand TextFilled Never|Possibly Empty` is like a type-safe `Maybe TextFilled` 🌿

## [`Stack`](Stack)

Handle lists that are [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) or `Never` [`Empty`](Hand#Empty) in one go.

`Never Empty` allows safe `Maybe`-free [`top`](Stack#top), [`removeTop`](Stack#removeTop), [`fold`](Stack#fold) (useful for finding the maximum, etc. some call it "fold1"), ...

```elm
import Hand exposing (Hand, Empty)
import Stack exposing (Stacked, topDown, stackOnTop, layOnTop, toTopDown)

Stack.only 0
    |> stackOnTop (topDown 1 [ 2, 3 ])
        --: Hand (Stacked number_) never_ Empty
    |> layOnTop 5
        --: Hand (Stacked number_) never_ Empty
    |> toTopDown
--> ( 5, [ 1, 2, 3, 0 ] )
```

## [`Scroll`](Scroll)

Items rolled up on both sides of a focus
→ good fit for dynamic choice selection: tabs, playlist, ...

`Scroll` can even focus a gap `Before` and `After` every item.


```elm
import Hand exposing (filled)
import Stack exposing (topDown)
import Scroll exposing (Scroll, FocusedOnGap, Side(..), focusGap, focusAlter)

Scroll.empty
        --: Scroll item_ Possibly FocusedOnGap
    |> focusAlter (\_ -> filled -1)
        --: Scroll number_ never_ FocusedOnGap
    |> Scroll.sideAlter After (\_ -> topDown 1 [ 2, 3 ])
        --: Scroll number_ never_ FocusedOnGap
    |> focusGap After
        --: Scroll number_ Possibly FocusedOnGap
    |> focusAlter (\_ -> filled 0)
        --: Scroll number_ never_ FocusedOnGap
    |> Scroll.toList
--> [ -1, 0, 1, 2, 3 ]
```

The idea is pretty similar to [zwilias/elm-holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest).
[`Scroll` is just safer and has a nicer API (operations taking the side as an argument, ...)](https://github.com/lue-bird/elm-emptiness-typed/blob/master/changes.md).

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements.
