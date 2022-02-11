### non-plans

  - adding `StackThat`. Currently I can't see additional value not provided by `ListThat`

# changelog

## 4.0.0

  - changed
    ```elm
    type CanBe stateTag yesOrNever
        = CanBe yesOrNever
    ```
    to
    ```elm
    type Can possiblyOrNever be state
        = Can yesOrNever Be
    ```
      - added
        ```elm
        type Be
            = Be
        
        type alias Isnt state =
            Can Never Be state
        
        type alias CanBe state =
            Can () Be state
        ```

  - renamed `MaybeIs` type and module to `MaybeThat`
      - renamed `MaybeIs.IsJust` variant to `.JustThat`
      - renamed `MaybeIs.IsNothing` variant to `.NothingThat`
      - added `type Nothing = Nothing`
  
  - renamed `ListIs` type and module to `ListThat`
      - removed `NotEmpty`
      - added `type Empty = Empty`
      - removed `type alias ListWithHeadType head canItBeEmpty tailElement`
        in favor of the aliased type `MaybeThat canItBeEmpty ( head, List tailElement )`
        
  - renamed `HoleyFocusList` type and module to `ListWithFocusThat`
      - removed `type alias Item`
      - removed `type alias Hole`
      - added `type Hole = Hole`
      - renamed `mapBefore` to `alterBefore`
      - renamed `mapCurrent` to `alterCurrent`
      - renamed `mapAfter` to `alterAfter`

## 3.0.0

- renamed `MaybeIs.IsJust` variant to `.JustIs`
- renamed `MaybeIs.IsNothing` variant to `.NothingIs`

#### 2.0.4

- corrected readme

#### 2.0.3

- added a mini "why you should care about non-empty" section in the readme

#### 2.0.2

- changed and corrected readme

#### 2.0.1

- doc correction for `ListIs.unCons`

## 2.0.0

- changed `MaybeIs.CanBeNothing possiblyOrNever tag` type to `CanBe tag possiblyOrNever`
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
