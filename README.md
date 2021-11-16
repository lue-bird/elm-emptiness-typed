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

## `HoleySelectList`

A list zipper that can also focus before and after every item.

```elm
import HoleySelectList

HoleySelectList.empty           -- HoleySelectList ItemOrHole a_
    |> HoleySelectList.plug 5   -- HoleySelectList item_ Int
    |> HoleySelectList.append
        [ 1, 2, 3 ]             -- HoleySelectList item_ Int
    |> HoleySelectList.nextHole -- HoleySelectList ItemOrHole Int
    |> HoleySelectList.toList   -- List Int
--> [ 5, 1, 2, 3 ]
```

## `MaybeTyped`

`Maybe` + type information: does it exist?

This is the building block for all the data structures in this package.
