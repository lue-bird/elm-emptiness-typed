> one type for emptiable and safe non-empty

# [emptiness typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

**_🧩 Read about [allowable state](https://package.elm-lang.org/packages/lue-bird/elm-allowable-state/latest/) first_**

## [📦 `Emptiable`](Emptiable) `.....  Never |` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly)

A `Maybe` value that can be made non-empty depending on what we know – an "emptiable-able" value

```elm
import Emptiable exposing (Emptiable, filled, fill)

type alias TextFilled =
    { first : Char, afterFirst : String }

first : Emptiable TextFilled Never -> Char
first =
    fill >> .first

maybeFirst :
    Emptiable TextFilled possiblyOrNever
    -> Emptiable Char possiblyOrNever
maybeFirst =
    Emptiable.map (filled >> first)
```

## [📚 `Stack`](Stack)

Handle lists that are
[`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly)
or `Never` [`Emptiable`](Emptiable#Emptiable)
in one go

`Emptiable ... Never` allows safe `Maybe`-free
[`top`](Stack#top), [`removeTop`](Stack#removeTop),
[`fold`](Stack#fold) (for finding the maximum etc.; some call it "fold1"), ...

That's more useful than you might think.

```elm
import Linear exposing (Direction(..))
import Emptiable exposing (Emptiable)
import Stack exposing (Stacked)

Emptiable.empty
    --: Emptiable (Stacked element_) Possibly
    |> Stack.onTopLay 0
    --: Emptiable (Stacked number_) never_
    |> Stack.attach Down (Stack.topBelow 1 [ 2, 3 ])
    --: Emptiable (Stacked number_) never_
    |> Stack.toTopBelow
--> ( 1, [ 2, 3, 0 ] )
```

## where `emptiness-typed` is already being used

- [🗃️ `elm-keysSet`](https://dark.elm.dmy.fr/packages/lue-bird/elm-keysset/latest/)
- [📜 `elm-scroll`](https://dark.elm.dmy.fr/packages/lue-bird/elm-scroll/latest/)

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like length type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements
