## changes from holey-zipper

- added module `MaybeIs`

- renamed module `List.Holey.Zipper` to `HoleyFocusList`
    - switched to type-safe implementation using `MaybeIs`
        - removed type `Hole`
        - added type `HoleOrItem`
    - removed `zipper`
    - renamed type `Zipper` and its module to `HoleyFocusList`
    - renamed type `Full` to `Item`
    - renamed `singleton` to `only`
    - added `squeezeInBefore`
    - added `squeezeInAfter`
    - added `joinParts`

- added module `ListIs`
