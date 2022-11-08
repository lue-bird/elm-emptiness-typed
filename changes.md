# changes log

#### 7.0.2

  - `linear-direction` → >= 8.0.0

#### 7.0.1

  - documentation `Scroll` argument order correct

## 7.0.0

  - `Scroll.sideAlter ( dir, change )` → `sideAlter dir change`
  - `linear-direction` version → 7.0.0
  - `Stack.indexLast` remove

## 6.0.0

  - `Hand` → `Emptiable`
      - `type Hand filling possiblyOrNever Empty`
        →
        `type Emptiable filling possiblyOrNever`
          - less lines
          - more intuitive
          - no ambiguous `exposing (Empty)`
  - `Stack`
      - `toString` → `toText`
      - `fromString` → `fromText`
      - `sum` corrected
        ```elm
        : Emptiable (Stacked number) Never -> number
        ```
        →
        ```elm
        : Emptiable (Stacked number) possiblyOrNever_ -> number
        ```
      - `fold` changed
        ```elm
        (belowElement -> top -> top)
        -> Hand (StackTopBelow top belowElement) Never Empty
        -> top
        ```
        →
        ```elm
        Linear.DirectionLinear
        -> (element -> element -> element)
        -> Emptiable (Stacked element) Never
        -> element
        ```
      - `foldFrom` made curry-able
        ```elm
        ( accumulationValue
        , DirectionLinear
        , element -> accumulationValue -> accumulationValue
        )
        -> Hand (Stacked element) possiblyOrNever_ Empty
        -> accumulationValue
        ```
        →
        ```elm
        accumulationValue
        -> DirectionLinear
        -> (element -> accumulationValue -> accumulationValue)
        -> Emptiable (Stacked element) possiblyOrNever_
        -> accumulationValue
        ```
  - `Scroll`
      - `type Scroll`
        `type Scroll item neverOrPossibly FocusGap`
        →
        `type Scroll item FocusGap neverOrPossibly`
      - `fold` made curry-able
        ```elm
        ( DirectionLinear, item -> item -> item )
        -> Scroll item Never FocusGap
        -> item
        ```
        →
        ```elm
        DirectionLinear
        -> (item -> item -> item)
        -> Scroll item FocusGap Never
        -> item
        ```
      - `foldFrom` made curry-able
        ```elm
        ( accumulationValue
        , DirectionLinear
        , item -> accumulationValue -> accumulationValue
        )
        -> Scroll item Never FocusGap
        -> accumulationValue
        ```
        →
        ```elm
        accumulationValue
        -> DirectionLinear
        -> (item -> accumulationValue -> accumulationValue)
        -> Scroll item FocusGap Never
        -> accumulationValue
        ```

### 5.2.0

  - `Stack`
      - `sum` add

### 5.1.0

  - `Stack`
      - `fromString` add
      - `toString` add

#### 5.0.1

  - section "`Scroll` alternatives" `mapIndexed`, `mapOver` → `map (Location -> ...)` missing

## 5.0.0

  - renamed `module Fillable` to `Hand`
      - replaced `type Empty possiblyOrNever fill` with
        ```elm
        type Hand fill possiblyOrNever emptyTag = ..as before..

        type Empty
            = EmptyTag Never
        ```
      - renamed `filling` to `fill`
      - renamed `toFillingOrIfEmpty` to `fillElseOnEmpty`
      - renamed `map` to `fillMap`
      - removed `map2` in favor of `fillAnd` pipeline style
      - removed `ifFilled`
      - renamed `andThen` to `fillMapFlat`
      - renamed `adaptType` to `emptyAdapt`
      - added `flatten`
  - in `module Stack`
      - replaced `StackWithTop`, `StackFilled` type with
        ```elm
        type alias Stacked element =
            StackTopBelow element element

        type StackTopBelow top belowElement
            = TopDown top (List belowElement)
        ```
      - removed `map2`
      - removed `map2TopAndDown`
      - changed `map (item -> ...)`
        to `map ({ index : Int } -> item -> ...)`
      - renamed `mapTop` to `topMap`
      - renamed `mapBelowTop (item -> ...)`
        to `belowTopMap ({ index : Int } -> item -> ...)`
      - renamed `removeTop` to `topRemove`
      - removed `splitTop` in favor of `top`, `topRemove`
      - renamed `topAndBelow` to `topDown`
      - renamed `fromTopAndBelow` to `fromTopDown`
      - renamed `toTopAndBelow` to `toTopDown`
      - renamed `addOnTop` to `onTopLay`
      - renamed `concat` to `flatten`
      - renamed `whenFilled` to `fills`
      - removed `when` in favor of `fills`
      - renamed `stackOnTop` to `onTopStack`
      - renamed `stackOnTopTyped` to `onTopStackAdapt`
      - changed `foldFrom base direction reduce`
        to `foldFrom ( base, direction, reduce )`
      - corrected
        ```elm
        fold :
            LinearDirection
            -> (belowTopElement -> top -> top)
            -> Empty Never (StackWithTop top belowTopElement)
            -> top
        ```
        to
        ```elm
        fold :
            (belowElement -> top -> top)
            -> Hand (StackTopBelow top belowElement) Never Empty
            -> top
        ```
      - added `onTopGlue`
  - renamed `module FocusList` to `Scroll`
      - replaced `ListFocusingGap possibleOrNever item` with
        ```elm
        type alias Scroll item possiblyOrNever focusedOnGapTag =
            = BeforeFocusAfter
                (Hand (StackFilled item) Possibly Empty)
                (Hand item possiblyOrNever focusedOnGapTag)
                (Hand (StackFilled item) Possibly Empty)
        
        type FocusGap
            = FocusGapTag Never
        ```
      - added
        ```elm
        type Location
            = AtFocus
            | AtSide DirectionLinear Int
        ```
      - replaced `previous`/`next` with
        ```elm
        to :
            Location
            -> Scroll item possiblyOrNever_ FocusGap
            -> Hand (Scroll item Never FocusGap) Possibly Empty
        ```
      - replaced `previousGap`/`nextGap` with
        ```elm
        toGap :
            DirectionLinear
            -> Scroll item Never FocusGap
            -> Scroll item Possibly FocusGap
        ```
      - replaced `findForward isFound`/`findBackward isFound` with
        ```elm
        toWhere :
            ( DirectionLinear, item -> Bool )
            -> Scroll item possiblyOrNever_ FocusGap
            -> Hand (Scroll item Never FocusGap) Possibly Empty
        ```
      - removed `removed`
        in favor of `focusAlter (\_ -> Hand.empty)`
      - removed `alterCurrent focusItemAlter`
        in favor of `focusAlter (Hand.fillMap focusItemAlter)`
      - removed `plug focusItemNew`
        in favor of `focusAlter (focusItemNew |> Hand.filled)`
      - renamed `current` to `focusItem`
      - replaced `first`/`last` with
        ```elm
        toEnd :
            DirectionLinear
            -> Scroll item possiblyOrNever FocusGap
            -> Scroll item possiblyOrNever FocusGap
        ```
      - replaced `beforeFirst`/`afterLast` with
        ```elm
        toEndGap :
            DirectionLinear
            -> Scroll item possiblyOrNever FocusGap
            -> Scroll item Possibly FocusGap
        ```
      - renamed `focusingItem` to `focusItemTry`
      - replaced `before`/`after` with `side DirectionLinear`
      - replaced `alterBefore`/`alterAfter` with
        ```elm
        sideAlter :
            ( DirectionLinear
            , Hand (StackFilled item) Possibly Empty
              -> Hand (StackFilled item) possiblyOrNeverSide_
            )
            -> Scroll item possiblyOrNever FocusGap
            -> Scroll item possiblyOrNeverAltered FocusGap
        ```
      - removed `insertAfter item`/`insertBefore item` 
        in favor of `sideAlter ( direction, Stack.onTopLay item )`
      - removed `squeezeInBefore List`/`squeezeInAfter List` in favor of `sideAlter (Stack.onTopGlue List)`
      - removed `squeezeStackInBefore stack`/`squeezeStackInAfter stack`
        in favor of `sideAlter ( DirectionLinear, Stack.onTopStack stack )`
      - removed `prepend/append/prependStack/appendStack`
        in favor of `sideAlter ( DirectionLinear, \side -> stack |> Stack.onTopStack/-Glue side )`
      - replaced
        ```elm
        mapParts
          { before : item ...
          , current : item ...
          , after : item ...
          }
        ```
        with
        ```elm
        focusSidesMap
            { side : DirectionLinear -> ... Stacked item ...
            , focus : Hand item ...
            }
        ```
      - renamed `adaptHoleType` to `focusGapAdapt`
      - changed `sideAlter (item ...)` to `sideAlter (... Stacked item ...)`
      - changed `map (item -> ...)` to `map (Location -> item -> ...)`
      - added
        ```elm
        focusAlter :
            (Hand item possiblyOrNever Empty
             -> Hand item possiblyOrNeverAltered Empty
            )
            -> Scroll item possiblyOrNever FocusGap
            -> Scroll item possiblyOrNeverAltered FocusGap
        ```
      - added `sideOpposite`
      - added `nearest : DirectionLinear -> Location`
      - added `length`
      - added `toWhere`
      - added `focusDrag`
      - added `mirror`
      - added `fold`
      - added `foldFrom`

#### 4.1.0

  - added `Fillable.ifFilled`

## 4.0.0

  - added [`Possibly`](https://dark.elm.dmy.fr/packages/lue-bird/elm-allowable-state/latest/Possibly) dependency
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
