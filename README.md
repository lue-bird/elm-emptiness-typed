# elm-emptiness-typed

## `ListTyped`

One way to construct and transform `MaybeEmpty` and `NotEmpty` lists.

```elm
import ListTyped

ListTyped.empty           -- ListTyped MaybeEmpty a
    |> ListTyped.cons 5   -- ListTyped notEmpty Int
    |> ListTyped.append
        (ListTyped.fromList [ 1, 2, 3 ])
                          -- ListTyped notEmpty Int
    |> ListTyped.toTuple
--> ( 5, [ 1, 2, 3 ] )
```

## `HoleySelectList`

Like a list zipper, but with more holes in it.

The basic idea is a zipper that can represent an empty list, can focus before 
and after every item, and doesn't make life hard.

```elm
import HoleySelectList

HoleySelectList.empty           -- HoleySelectList Hole a
    |> HoleySelectList.plug 5   -- HoleySelectList full Int
    |> HoleySelectList.append
        [ 1, 2, 3 ]             -- HoleySelectList full Int
    |> HoleySelectList.nextHole -- HoleySelectList Hole Int
    |> HoleySelectList.toList   -- List Int
--> [ 5, 1, 2, 3 ]
```

---

Made with love and released under BSD-3.
