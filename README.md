> one type for emptiable and safe non-empty

# [emptiness typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

**_🗨️ Read about [allowable state](https://package.elm-lang.org/packages/lue-bird/elm-allowable-state/latest/) first _**

[`Fillable.Empty`](Fillable#Empty) is a convenience layer for an optional-able value
where a type argument that's either `Never` or [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly)
is attached to its [`Empty`](Fillable#Empty) variant.

Defining
```elm
import Fillable exposing (Empty, filled, filling)

type alias TextFilled =
    ( Char, String )

first : Empty Never TextFilled -> Char
first =
    filling >> \( headChar, _ ) -> headChar

Fillable.map (filled >> first)
--: Text possiblyOrNever 
--: -> Empty possiblyOrNever Char
```

`Empty ... TextFilled` acts like a type-safe `Maybe NonEmptyString` 🌿

## [`Stack`](Stack)

Handle lists that are [`Empty`](Fillable#Empty) [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) or `Never` in one go.

[`Empty`](Fillable#Empty) `Never` <some stack type> allows safe `Maybe`-free [`top`](Stack#top), [`removeTop`](Stack#removeTop), [`fold`](Stack#fold) (useful for finding the maximum, etc. some call it "fold1"), ...

```elm
import Fillable exposing (Empty)
import Stack exposing (StackFilled, topAndBelow, stackMoreTypedOnTop, addOnTop, toTopAndBelow)

Fillable.empty
    |> stackMoreTypedOnTop
        (topAndBelow 1 [ 2, 3 ])
                  -- Empty never_ (StackFilled number_)
    |> addOnTop 5 -- Empty never_ (StackFilled number_)
    |> toTopAndBelow
--> ( 5, [ 1, 2, 3 ] )
```

## [`FocusList`](FocusList)

A list zipper that can also focus before and after every element.

```elm
import FocusList exposing (ListFocusingHole)

FocusList.empty           -- ListFocusingHole Possibly item_
    |> FocusList.plug 5   -- ListFocusingHole never_ number_
    |> FocusList.append [ 1, 2, 3 ]
                          -- ListFocusingHole never_ number_
    |> FocusList.nextHole -- ListFocusingHole Possibly number_
    |> FocusList.toList
--> [ 5, 1, 2, 3 ]
```

= [zwilias/elm-holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest) with [a type-safe implementation using [`Fillable.Empty`](Fillable#Empty) and other tweaks](https://github.com/lue-bird/elm-emptiness-typed/blob/master/changes.md).

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements.
