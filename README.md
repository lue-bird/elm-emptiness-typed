# elm-emptiness-typed

Deal with emptiness in a way that doesn't make life hard.

## `Lis`

Handle `Emptiable` and `NotEmpty` lists at once.

```elm
import Lis

Lis.empty         -- Lis Emptiable a_
    |> Lis.appendNonEmpty
        (Lis.fromCons 1 [ 2, 3 ])
                        -- Lis notEmpty_ Int
    |> Lis.cons 5 -- Lis notEmpty_ Int
    |> Lis.toTuple
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

## `Mayb`

`Maybe` + type information: does it exist?

This is the building block for all the data structures in this package.
