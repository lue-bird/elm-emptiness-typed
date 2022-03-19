# changelog

## 5.0.0

  - renamed `Fillable` module to `Hand`
      - replaced `Empty possiblyOrNever fill` with
        ```elm
        type Hand fill possiblyOrNever emptyTag = ..as before..

        type Empty
            = EmptyTag Never
        ```
      - renamed `filling` to `fill`
      - renamed `toFillingOrIfEmpty` to `fillOrWhereEmpty`
      - renamed `map` to `fillMap`
      - removed `map2` in favor of `feedFill` pipeline style
      - removed `ifFilled` in favor of `alterFill`
      - renamed `andThen` to `fillMapFlat`
      - renamed `adaptType` to `adaptTypeEmpty`
      - added `flatten`
      - added `feedFill`
      - added `alterFill`
  - in `Stack`
      - replaced `StackWithTop`/`StackFilled` type with
        ```elm
        type alias Stacked element =
            StackTopBelow element element

        type StackTopBelow top belowElement
            = TopDown top (List belowElement)
        ```
      - removed `map2`
      - removed `map2TopAndDown`
      - removed `splitTop` in favor of `top`, `removeTop`
      - renamed `topAndBelow` to `topDown`
      - renamed `fromTopAndBelow` to `fromTopDown`
      - renamed `toTopAndBelow` to `toTopDown`
      - renamed `addOnTop` to `layOnTop`
      - renamed `concat` to `flatten`
      - added `glueOnTop`
  - renamed `FocusList` module to `Scroll`
      - replaced `ListFocusingGap possibleOrNever item` with
        ```elm
        type alias Scroll item possiblyOrNever focusedOnGapTag =
            = BeforeFocusAfter
                (Hand (StackFilled item) Possibly Empty)
                (Hand item possiblyOrNever focusedOnGapTag)
                (Hand (StackFilled item) Possibly Empty)
        
        type FocusedOnGap
            = FocusedOnGapTag Never
        ```
      - added
        ```elm
        type Side
            = Before
            | After
        ```
      - renamed `adaptGapType` to `adaptTypeFocusedOnGap`
      - replaced `previous`/`next` with
        ```elm
        focusItem :
            Side
            -> Scroll item possiblyOrNever_ FocusedOnGap
            -> Hand (Scroll item Never FocusedOnGap) Possibly Empty
        ```
      - replaced `previousGap`/`nextGap` with
        ```elm
        focusGap :
            Side
            -> Scroll item Never FocusedOnGap
            -> Scroll item Possibly FocusedOnGap
        ```
      - replaced `findForward isFound`/`findBackward isFound` with
        ```elm
        focusWhere :
            Side
            -> (item -> Bool)
            -> Scroll item possiblyOrNever_ FocusedOnGap
            -> Hand (Scroll item Never FocusedOnGap) Possibly Empty
        ```
      - renamed `removed` to `focusRemove`
      - removed `alterCurrent` in favor of `focusAlter`
      - removed `plug` in favor of `focusAlter`
      - renamed `current` to `focusedItem`
      - replaced `first`/`last` with
        ```elm
        focusItemEnd :
            Side
            -> Scroll item possiblyOrNever FocusedOnGap
            -> Scroll item possiblyOrNever FocusedOnGap
        ```
      - replaced `beforeFirst`/`afterLast` with
        ```elm
        focusGapBeyondEnd :
            Side
            -> Scroll item possiblyOrNever FocusedOnGap
            -> Scroll item Possibly FocusedOnGap
        ```
      - renamed `focusingItem` to `focusedOnItem`
      - replaced `before`/`after` with `side Side`
      - replaced `alterBefore`/`alterAfter` with
        ```elm
        alterSide :
            Side
            ->
                (Hand (StackFilled item) Possibly Empty
                 -> Hand (StackFilled item) possiblyOrNeverSide_ Empty
                )
            -> Scroll item possiblyOrNever FocusedOnGap
            -> Scroll item possiblyOrNeverAltered FocusedOnGap
        ```
      - replaced `insertAfter item`/`insertBefore item` with `insert side item`
      - removed `squeezeInBefore List`/`squeezeInAfter List` in favor of `alterSide (Stack.glueOnTop List)`
      - removed `squeezeStackInBefore stack`/`squeezeStackInAfter stack` in favor of `alterSide (Stack.stackOnTop stack)`
      - replaced `prepend/append` with `glueToEnd side`
      - replaced `prependStack/appendStack` with `stackToEnd side`
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
            { before : ... Stacked item ...
            , focus : Hand item ...
            , after : ... Stacked item ...
            }
        ```
      - renamed `adaptHoleType` to `adaptTypeFocusedOnGap`
      - change `sideAlter (item ...)` to `sideAlter (... Stacked item ...)`
      - added
        ```elm
        alterFocus :
            (Hand item possiblyOrNever Empty
             -> Hand item possiblyOrNeverAltered Empty
            )
            -> Scroll item possiblyOrNever FocusedOnGap
            -> Scroll item possiblyOrNeverAltered FocusedOnGap
        ```
      - added `focusDrag`
      - added `mirror`
      - added `sideOpposite`

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
