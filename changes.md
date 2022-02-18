## 5.0.0 plans

  - rename `toFillingOrIfEmpty` to `fillingOrIfEmpty`

### to decide

  - change type of `next`-/`previousHole`
    from
    ```elm
    ListFocusingHole Never item
    -> ListFocusingHole Possibly item
    ```
    to
    ```elm
    ListFocusingHole possiblyOrNever_ item
    -> ListFocusingHole Possibly item
    ```

# changelog

#### 4.1.0

  - added `Fillable.applyIfFilled`

## 4.0.0

  - add [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) dependency
    to improve understandability of types

  - replaced `MaybeIs` module with `Fillable`
      - with
        ```elm
        type Empty possiblyOrNever filling
            = Empty possiblyOrNever
            | Filled filling
        ```
      - renamed `just` to `filled`
      - renamed `nothing` to `empty`
      - renamed `value` to `filling`
      - renamed `withFallback` to `toFillingOrIfEmpty`
      - replaced `branchableType` with `adaptType`
  
  - replaced `ListIs` with `Stack`
      - `Empty Possibly`/`Never ...` with
        ```elm
        type alias StackFilled element =
            StackWithTop element element
        
        type alias StackWithTop top belowElement =
            ( top, List belowElement )
        ```
        
  - renamed `HoleyFocusList` module to `FocusList`
      - renamed `HoleyFocusList` to `ListFocusingHole`
      - removed `Item`, `Hole`
      - renamed `mapBefore` to `alterBefore`
      - renamed `mapCurrent` to `alterCurrent`
      - renamed `mapAfter` to `alterAfter`
    
  - in general
      - replaced `Maybe` results & arguments with `Empty Possibly`
      - in replacement/addition to `List` results & arguments: `Possibly Empty (StackFilled ...)`

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

- doc correction for `Stack.splitTop`

## 2.0.0

- changed `MaybeIs.PossiblyNothing possiblyOrNever tag` type to `Possibly tag possiblyOrNever`
- removed `MaybeIs.Just` & `.Nothingable` in favor of `Possibly`
- removed `Stack.Possibly` in favor of `Possibly empty_ ()`
- removed `HoleyFocusList.ItemOrHole` in favor of `Possibly hole_ ()`
- changed `Stack.fold dir red init` to `.foldFrom init dir red`
- renamed variant variant `MaybeIs.PossiblyNothing` to `Possibly`
- renamed `Stack.foldWith` to `.fold`
- renamed `Stack.toTuple` to `.splitTop`
- renamed `Stack.fromTuple` to `.fromTopAndBelow`
- added extended summary in readme (`Possibly` explanation etc.)


## 1.0.0: changes from [holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest)

- renamed module `List.Holey.Zipper` to `HoleyFocusList`
- switched to implementation using `MaybeIs`
        - → type-safety
        - [makes unifying types possible](https://github.com/zwilias/elm-holey-zipper/issues/2)
    - removed type `Hole`
    - changed type `Full` to `Item` as `Possibly { hole : () } Never`
- removed `zipper`
- renamed type `Zipper` and its module to `HoleyFocusList`
- renamed `singleton` to `only`
- added `squeezeInBefore`
- added `squeezeInAfter`
- added `joinParts`
