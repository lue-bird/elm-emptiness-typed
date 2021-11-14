# Holey Zipper

Like a `List` zipper, but with more holes in it.

The basic idea is a zipper that can represent an empty list, can focus before 
and after every item, and doesn't make life hard.

```elm
import HoleySelectList

HoleySelectList.empty           -- HoleySelectList Hole a
    |> HoleySelectList.plug 5   -- HoleySelectList full Int
    |> HoleySelectList.append
        [ 1, 2, 3 ]    -- HoleySelectList full Int
    |> HoleySelectList.nextHole -- HoleySelectList Hole Int
    |> HoleySelectList.toList   -- List Int
--> [ 5, 1, 2, 3 ]
```

So, there's that.

---

Made with love and released under BSD-3.
