## 5.0.0 plans

  - rename `Fillable` module to `Hand`
      - rename `Empty possiblyOrNever content` to `Hand content possiblyOrNever Empty`
      - rename `filling` to `content`
      - rename `toFillingOrIfEmpty` to `contentOrIfEmpty`
      - rename `andThen` to `mapFlat`
      - rename `adaptType` to `adaptTypeEmpty`
      - add `flatten`
      - add `supply`
      - add `supplyFlat`
  - in `Stack`
      - replace `StackWithTop`/`StackFilled` type with
        ```elm
        type alias Stacked element =
            StackTopBelow element element

        type StackTopBelow top belowElement
            = TopDown top (List belowElement)
        ```
      - rename `topAndBelow` to `topDown`
      - rename `fromTopAndBelow` to `fromTopDown`
      - rename `toTopAndBelow` to `toTopDown`
  - rename `FocusList` module to `Slider`
      - replace `ListFocusingHole possibleOrNever item` with
        ```elm
        type alias Slider item possiblyOrNever focusedOnHoleTag =
            = BeforeFocusAfter
                (Hand (StackFilled item) Possibly Empty)
                (Hand item possiblyOrNever focusedOnHoleTag)
                (Hand (StackFilled item) Possibly Empty)
        
        type FocusedOnHole
            = FocusedOnHoleTag Never
        ```
      - add
        ```elm
        type Arm
            = Before
            | After
        ```
      - replace `previous`/`next` with
        ```elm
        focusItem :
            Arm
            -> Slider item possiblyOrNever_ FocusedOnHole
            -> Hand (Slider item Never FocusedOnHole) Possibly Empty
        ```
      - replace `previousHole`/`nextHole` with
        ```elm
        focusHole :
            Arm
            -> Slider item Never FocusedOnHole
            -> Slider item Possibly FocusedOnHole
        ```
      - replace `findForward isFound`/`findBackward isFound` with
        ```elm
        focusWhere :
            Arm
            -> (item -> Bool)
            -> Slider item possiblyOrNever_ FocusedOnHole
            -> Hand (Slider item Never FocusedOnHole) Possibly Empty
        ```
      - replace `alterCurrent` with `alterFocusItem`
      - replace `remove`, `plug` with
        ```elm
        replaceFocus :
            Hand item possiblyOrNeverAltered
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item possiblyOrNeverAltered FocusedOnHole
        ```
      - rename `current` to `itemFocus`
      - replace `first`/`last` with
        ```elm
        focusEnd :
            Arm
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item possiblyOrNever FocusedOnHole
        ```
      - replace `beforeFirst`/`afterLast` with
        ```elm
        focusBeyondEnd :
            Arm
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item Possibly FocusedOnHole
        ```
      - rename `focusingItem` to `withItemFocus`
      - replace `before`/`after` with `arm Arm`
      - replace `alterBefore`/`alterAfter` with
        ```elm
        alterArm :
            Arm
            ->
                (Hand (StackFilled item) Possibly Empty
                 -> Hand (StackFilled item) possiblyOrNeverArm_ Empty
                )
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item possiblyOrNeverAltered FocusedOnHole
        ```
      - replace `insertAfter item`/`insertBefore item` with `insert arm item`
      - replace `squeezeInBefore list`/`squeezeInAfter List` with `squeezeIn arm list`
      - replace `squeezeStackInBefore stack`/`squeezeStackInAfter stack` with `squeezeInStack arm`
      - rename `mapParts` to `mapBeforeFocusAfter`
      - rename `adaptHoleType` to `adaptFocusedOnHoleType`
      - add
        ```elm
        alterFocus :
            (Hand item possiblyOrNever Empty
             -> Hand item possiblyOrNeverAltered Empty
            )
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item possiblyOrNeverAltered FocusedOnHole
        ```
      - add
        ```elm
        replaceArm :
            Arm
            -> Hand (StackFilled item) possiblyOrNeverStack_ Empty
            -> Slider item possiblyOrNever FocusedOnHole
            -> Slider item possiblyOrNever FocusedOnHole
        ```
      - add `reverse`

# changelog

#### 4.1.0

  - added `Fillable.ifFilled`

## 4.0.0

  - add [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) dependency
    to improve understandability of types

  - replaced `MaybeIs` module with `Fillable`
      - with
        ```elm
        type Empty possiblyOrNever content
            = Empty possiblyOrNever
            | Filled content
        ```
      - renamed `just` to `filled`
      - renamed `nothing` to `empty`
      - renamed `value` to `content`
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
