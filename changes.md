# changelog

## 2.0.0

- renamed `CanBeNothing` type and variant to `CanBe`

## 1.0.0: changes from [holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest)

- renamed module `List.Holey.Zipper` to `HoleyFocusList`
- switched to implementation using `MaybeIs`
        - → type-safety
        - [makes unifying types possible](https://github.com/zwilias/elm-holey-zipper/issues/2)
    - removed type `Hole`
    - added type `HoleOrItem`
- removed `zipper`
- renamed type `Zipper` and its module to `HoleyFocusList`
- renamed type `Full` to `Item`
- renamed `singleton` to `only`
- added `squeezeInBefore`
- added `squeezeInAfter`
- added `joinParts`
