# elm-emptiness-typed

Deal with emptiness in a way that doesn't make life hard.

## `ListTyped`

Handle `MaybeEmpty` and `NotEmpty` lists at once.

```elm
import ListTyped

ListTyped.empty         -- ListTyped MaybeEmpty a_
    |> ListTyped.appendNonEmpty
        (ListTyped.fromCons 1 [ 2, 3 ])
                        -- ListTyped notEmpty_ Int
    |> ListTyped.cons 5 -- ListTyped notEmpty_ Int
    |> ListTyped.toTuple
--> ( 5, [ 1, 2, 3 ] )
```

## `HoleyFocusList`

A list zipper that can also focus before and after every item.

```elm
import HoleyFocusList

HoleyFocusList.empty           -- HoleyFocusList ItemOrHole a_
    |> HoleyFocusList.plug 5   -- HoleyFocusList item_ Int
    |> HoleyFocusList.append [ 1, 2, 3 ]
                               -- HoleyFocusList item_ Int
    |> HoleyFocusList.nextHole -- HoleyFocusList ItemOrHole Int
    |> HoleyFocusList.toList
--> [ 5, 1, 2, 3 ]
```

## `MaybeTyped`

`Maybe` + type information: does it exist?

This is the building block for all the data structures in this package.
