# elm-emptiness-typed

Deal with emptiness in a way that doesn't make life hard.

## `ListIs`

Handle `Emptiable` and `NotEmpty` lists at once.

```elm
import ListIs

ListIs.empty         -- ListIs Emptiable a_
    |> ListIs.appendNonEmpty
        (ListIs.fromCons 1 [ 2, 3 ])
                     -- ListIs notEmpty_ Int
    |> ListIs.cons 5 -- ListIs notEmpty_ Int
    |> ListIs.toTuple
--> ( 5, [ 1, 2, 3 ] )
```

## `HoleyFocusList`

A list zipper that can also focus before and after every item.

```elm
import HoleyFocusList

HoleyFocusList.empty           -- HoleyFocusList HoleOrItem a_
    |> HoleyFocusList.plug 5   -- HoleyFocusList item_ Int
    |> HoleyFocusList.append [ 1, 2, 3 ]
                               -- HoleyFocusList item_ Int
    |> HoleyFocusList.nextHole -- HoleyFocusList HoleOrItem Int
    |> HoleyFocusList.toList
--> [ 5, 1, 2, 3 ]
```

## `MaybeIs`

`Maybe` + type information: does it exist?

This is the building block for all the data structures in this package.
