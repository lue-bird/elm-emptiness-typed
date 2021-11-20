# changelog

#### 2.0.2

- changed and corrected readme

#### 2.0.1

- doc correction for `ListIs.unCons`

## 2.0.0

- changed `MaybeIs.CanBeNothing yesOrNever tag` type to `CanBe tag yesOrNever`
- removed `MaybeIs.Just` & `.Nothingable` in favor of `CanBe`
- removed `ListIs.Emptiable` in favor of `CanBe empty_ ()`
- removed `HoleyFocusList.ItemOrHole` in favor of `CanBe hole_ ()`
- changed `ListIs.fold dir red init` to `.foldFrom init dir red`
- renamed variant variant `MaybeIs.CanBeNothing` to `CanBe`
- renamed `ListIs.foldWith` to `.fold`
- renamed `ListIs.toTuple` to `.unCons`
- renamed `ListIs.fromTuple` to `.fromUnConsed`
- added extended summary in readme (`CanBe` explanation etc.)


## 1.0.0: changes from [holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest)

- renamed module `List.Holey.Zipper` to `HoleyFocusList`
- switched to implementation using `MaybeIs`
        - → type-safety
        - [makes unifying types possible](https://github.com/zwilias/elm-holey-zipper/issues/2)
    - removed type `Hole`
    - changed type `Full` to `Item` as `CanBe { hole : () } Never`
- removed `zipper`
- renamed type `Zipper` and its module to `HoleyFocusList`
- renamed `singleton` to `only`
- added `squeezeInBefore`
- added `squeezeInAfter`
- added `joinParts`
