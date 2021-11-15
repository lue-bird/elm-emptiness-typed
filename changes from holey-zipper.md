## changes from holey-zipper

- added module `MaybeTyped`

- renamed module `List.Holey.Zipper` to `HoleySelectList`
    - switched to type-safe implementation using `MaybeTyped`
        - removed type `Hole`
        - added type `HoleOrItem`
    - renamed type `Zipper` to `HoleySelectList`
    - renamed type `Full` to `Item`
    - renamed `zipper` to `currentAndAfter`
    - renamed `singleton` to `only`

- added module `ListTyped`
