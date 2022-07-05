> one type for emptiable and safe non-empty

# [emptiness typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

**_🔗 Read about [allowable state](https://package.elm-lang.org/packages/lue-bird/elm-allowable-state/latest/) first _**

## [`Emptiable`](Emptiable) `.....  Never |` [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly)

A `Maybe` value that can be made non-empty depending on what we know – an "emptiable-able" value

```elm
import Emptiable exposing (Emptiable, filled, fill, fillMap)

type TextFilled
    = TextFilled Char String

first : Emptiable TextFilled Never -> Char
first =
    fill >> \(TextFilled firstChar _) -> firstChar

maybeFirst :
    Emptiable TextFilled possiblyOrNever
    -> Emptiable Char possiblyOrNever
maybeFirst =
    fillMap (filled >> first)
```

## [`Stack`](Stack)

Handle lists that are [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) or `Never` [`Emptiable`](Emptiable#Emptiable) in one go.

`Emptiable ... Never` allows safe `Maybe`-free [`top`](Stack#top), [`topRemove`](Stack#topRemove), [`fold`](Stack#fold) (for finding the maximum etc.; some call it "fold1"), ...

```elm
import Emptiable exposing (Emptiable)
import Stack exposing (Stacked, topDown, onTopStack, onTopLay, toTopDown)

Emptiable.empty
        --: Emptiable (Stacked element_) Possibly
    |> onTopLay 0
        --: Emptiable (Stacked number_) never_
    |> onTopStack (topDown 1 [ 2, 3 ])
        --: Emptiable (Stacked number_) never_
    |> toTopDown
--> ( 5, [ 1, 2, 3, 0 ] )
```

## 📜 [`Scroll`](Scroll)

Items rolled up on both sides of a focus

→ good fit for dynamic choice selection: tabs, playlist, ...
[↑ examples](https://github.com/lue-bird/elm-emptiness-typed/tree/master/examples)

`Scroll` can even focus a gap `Down` and `Up` every item.


```elm
import Linear exposing (DirectionLinear(..))
import Emptiable exposing (filled)
import Stack exposing (topDown)
import Scroll exposing (Scroll, FocusGap)

Scroll.empty
        --: Scroll item_ Possibly FocusGap
    |> Scroll.focusAlter (\_ -> -1 |> filled)
        --: Scroll number_ never_ FocusGap
    |> Scroll.sideAlter
        ( Up, \_ -> topDown 1 [ 2, 3 ] )
        --: Scroll number_ never_ FocusGap
    |> Scroll.toGap Up
        --: Scroll number_ Possibly FocusGap
    |> Scroll.focusAlter (\_ -> 0 |> filled)
        --: Scroll number_ never_ FocusGap
    |> Scroll.toStack
--> topDown -1 [ 0, 1, 2, 3 ]
```

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements.

## [`Scroll`](Scroll) alternatives

- [zwilias/elm-holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest).
  unsafe; a bit cluttered; no `map (Location -> ...)`, `focusDrag`, `toNonEmptyList`, `sideAlter` (so no squeezing in multiple items, ...)
- [turboMaCk/non-empty-list-alias: `List.NonEmpty.Zipper`](https://dark.elm.dmy.fr/packages/turboMaCk/non-empty-list-alias/latest/List-NonEmpty-Zipper)
  complete; cluttered (for example `update` & `map`); some unintuitive names
- [miyamoen/select-list](https://dark.elm.dmy.fr/packages/miyamoen/select-list/latest/SelectList)
  complete; a bit cluttered; no `focusWhere`
- [yotamDvir/elm-pivot](https://dark.elm.dmy.fr/packages/yotamDvir/elm-pivot/latest/)
  complete; cluttered; no `map (Location -> ...)`
- [STTR13/ziplist](https://dark.elm.dmy.fr/packages/STTR13/ziplist/latest/)
  navigation works; a bit cluttered; no `map (Location -> ...)`, `sideAlter` (so no squeezing in multiple items, ...)
- [wernerdegroot/listzipper](https://dark.elm.dmy.fr/packages/wernerdegroot/listzipper/latest/List-Zipper)
  navigation works; no `focusDrag`, `map (Location -> ...)`, `toNonEmptyList`
- [alexanderkiel/list-selection](https://dark.elm.dmy.fr/packages/alexanderkiel/list-selection/latest/List-Selection)
  & [NoRedInk/list-selection](https://dark.elm.dmy.fr/packages/NoRedInk/list-selection/latest/List-Selection)
  very incomplete, impossible to extract focused item safely; no navigation, insertion, `side`, ...
- [jjant/elm-comonad-zipper](https://dark.elm.dmy.fr/packages/jjant/elm-comonad-zipper/latest/)
  incomplete; no `focusDrag`, `toNonEmptyList`, `sideAlter` (so no squeezing in multiple items, ...)
- [guid75/ziplist](https://dark.elm.dmy.fr/packages/guid75/ziplist/latest/)
  extremely incomplete
- [arowM/elm-reference: `Reference.List`](https://dark.elm.dmy.fr/packages/arowM/elm-reference/latest/Reference-List)
  only `overList`, sides impossible to access & alter
