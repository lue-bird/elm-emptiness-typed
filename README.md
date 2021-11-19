Deal with emptiness in a way that doesn't make life hard:

# [emptiness-typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

How about this: A string type that allows the **same operations for non-empty and emptiable** values:

```elm
toUpper : String emptyOrNot -> String emptyOrNot
```
or even allow **passing** the **(im)possibility of a state** from one data structure to another?
```elm
toCharList : String emptyOrNot -> List emptyOrNot -- crazy!
length : String emptyOrNot -> Int
...
```

Turns out this is very much possible!

```elm
type String emptyOrNot
    = StringEmpty emptyOrNot
    | StringNotEmpty Char String

char : Char -> StringIs notEmpty_
char onlyChar =
    StringNotEmpty onlyChar ""

head : StringIs Never -> Char
head string =
    case string of
        StringEmpty empty ->
            never empty --! neat
        
        StringNotEmpty headChar _ ->
            headChar
```

the type `StringIs Never` limits arguments to just `StringNotEmpty`.

to make the name more descriptive, we could define

```elm
type alias NotEmpty =
    Never

type alias Emptiable =
    ()
```

not a good idea:

```elm
Html NotEmpty
```

next try:

```elm
type alias NotEmpty =
    { canBeEmpty : Never }
```

almost there!

`StringIs ()` would then refer to an emptiable. Nice!

Now let's create `toCharList` that carries the emptiness-information over:

```elm
toCharList : StringIs WAIT -> ListIs HOW_CAN_I_DO_THIS Char
```

seems like we need

```elm
type alias Emptiable = { canBeEmpty : () }
type alias NotEmpty = { canBeEmpty : Never }

toCharList :
    StringIs { canBeEmpty : unitOrNever }
    -> ListIs { ... : unitOrNever } Char
```

`CanBe` is just a cleaner version of this.
It has a simple type tag to make `Never` values distinct:

```elm
type alias NotEmpty =
    CanBe { empty : () } Never

type alias Item =
    CanBe { hole : () } Never
```

_Remember to update the tag after renaming an alias._

Also, what needed to be written as

```elm
type alias Emptiable =
    { canBeEmpty : () }

emptyString : StringIs Emptiable
emptyString =
    StringEmpty { canBeEmpty = () }
```

becomes simply

```elm
emptyString : StringIs (CanBe empty_ ())
emptyString =
    StringEmpty (CanBe ())
```

Now the fun part:

```elm
joinParts :
    HoleyFocusList (CanBe hole_ yesOrNever) a
    -> ListIs (CanBe empty_ yesOrNever) a
joinParts ... =
    case ( before, focus, after ) of
        ( [], StringEmpty (CanBe yesOrNever), [] ) ->
            IsNothing
                --↓ carries over the `yesOrNever` type,
                --↓ while allowing a new tag
                (CanBe yesOrNever)

        ... -> ...
```

> the type information gets carried over, so
>
>     HoleyFocusList.Item -> ListIs.NotEmpty
>     CanBe hole_ () -> CanBe empty_ ()

`MaybeIs` is just a convenience layer for an optional-able value
where a [`CanBe`](#CanBe) value is attached to its nothing variant.

```elm
type alias StringIs emptyOrNot =
    MaybeIs emptyOrNot ( Char, String )

MaybeIs.map StringIs.head
--: StringIs (CanBe empty_ yesOrNever)
--: -> MaybeIs (CanBe nothing_ yesOrNever) Char
```

A `StringIs` acts like a type-safe `Maybe NonEmptyString`!

Let's create some data structures!

## `ListIs`

Handle `Emptiable` and `NotEmpty` lists at once.

```elm
MaybeIs emptyOrNot ( a, List b )
```

is

```elm
ListIs emptyOrNot a
```

more correctly, it's a

```elm
ListWithHeadType a emptyOrNot b
```

`ListIs NotEmpty` then allow Maybe-free type-safe [`head`](ListIs#head), [`tail`](ListIs#tail) and [`fold`](ListIs#fold) (useful for finding the maximum, some call it "fold1"), etc.

```elm
import ListIs

ListIs.empty         -- ListIs Emptiable a_
    |> ListIs.appendNotEmpty
        (ListIs.fromCons 1 [ 2, 3 ])
                     -- ListIs notEmpty_ Int
    |> ListIs.cons 5 -- ListIs notEmpty_ Int
    |> ListIs.unCons
--> ( 5, [ 1, 2, 3 ] )
```

## `HoleyFocusList`

A list zipper that can also focus before and after every item.

```elm
import HoleyFocusList

HoleyFocusList.empty           -- HoleyFocusList (CanBe hole_ ()) a_
    |> HoleyFocusList.plug 5   -- HoleyFocusList item_ Int
    |> HoleyFocusList.append [ 1, 2, 3 ]
                               -- HoleyFocusList item_ Int
    |> HoleyFocusList.nextHole -- HoleyFocusList (CanBe hole_ ()) Int
    |> HoleyFocusList.toList
--> [ 5, 1, 2, 3 ]
```

→ [zwilias's holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest) with [a type-safe implementation using `MaybeIs` and other minor tweaks](https://github.com/lue-bird/elm-emptiness-typed/blob/master/changes.md).

## suggestions?
→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)
