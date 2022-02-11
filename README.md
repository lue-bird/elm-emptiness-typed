> one type for emptiable and safe non-empty

# [emptiness-typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

There are many types that promise non-emptiness. One example: [MartinSStewart's NonemptyString](https://dark.elm.dmy.fr/packages/MartinSStewart/elm-nonempty-string/latest/).

The cool thing is that `fromInt`, `fromChar`, etc. keep the compile-time promise of being non-empty, so `head`, `tail`, etc. are guaranteed to succeed and you don't have to carry `Maybe`s throughout your program.

How about **operations that work on non-empty and emptiable** strings?
```elm
toUpper : StringThat canOrCantBeEmpty -> StringThat canOrCantBeEmpty
length : StringThat canOrCantBeEmpty_ -> Int
...
```
or ones that can **pass** the **(im)possibility of a state** from one data structure to the other?
```elm
toCharList : StringThat canOrCantBeEmpty -> ListThat canOrCantBeEmpty
```

All this good stuff is very much possible 🔥

Let's experiment and see how where we end up:

```elm
type StringThatCanBeEmpty yesOrNever
    = StringEmpty yesOrNever
    | StringNotEmpty Char String

fromChar : Char -> StringThatCanBeEmpty Never
fromChar onlyChar =
    StringNotEmpty onlyChar ""

head : StringThatCanBeEmpty Never -> Char
head string =
    case string of
        StringEmpty canBeEmpty ->
            canBeEmpty |> never --! neat
        
        StringNotEmpty headChar _ ->
            headChar

head (char 'E') --> 'E'
head (StringEmpty ()) --> error
```

→ The type `StringThatCanBeEmpty Never` limits arguments to just `StringNotEmpty`.

To avoid the somewhat unintuitive type argument `StringThatCanBeEmpty ()/Never`, let's try

```elm
type StringThat canOrCantBeEmpty

type alias IsntEmpty =
    Never

fromChar : Char -> StringThatCanBeEmpty Never
```

Not a good idea: `Html NotEmpty`

Next roll:

```elm
type IsntEmpty
    = NotEmpty Never

type CanBeEmpty
    = CanBeEmpty

StringThat.empty
--: StringThat CanBeEmpty

StringThat.head
--: StringThat IsntEmpty -> Char
```

👌 – almost there!

Now let's create `toCharList` that carries the emptiness-information over:

```elm
toCharList : StringThat ?? -> ListThat ?? Char
```

It seems like we need

```elm
type CanBeEmpty possiblyOrNever
    = CanBeEmpty possiblyOrNever

type alias IsntEmpty =
    CanBeEmpty Never

StringThat.empty
--: StringThat (CanBeEmpty ())

toCharList :
    StringThat (CanBeEmpty possiblyOrNever)
    -> ListThat (... possiblyOrNever) Char
```

[`Can ... Be ...`](MaybeThat#Can) is just a cleaner and more powerful version of this.
It uses a simple type tag to make values distinct:

```elm
type Empty
    = Empty Never

fromCons : a -> List a -> ListThat (Isnt Empty) a
```
or
```elm
type Hole
    = Hole Never

only : a -> ListWithFocusThat (Isnt Hole) a
```
(`Never` ensures that _no value can be created_ → phantom-type-only)

Also, what needed to be written as

```elm
emptyString : StringThat (CanBeEmpty ())
emptyString =
    StringEmpty (CanBeEmpty ())
```

becomes simply

```elm
emptyString : StringThat (CanBe empty_)
emptyString =
    StringEmpty (Can () Be)
```

Now the fun part:

```elm
toCharList :
    StringThat (Can possiblyOrNever Be emptyString_) a
    -> ListThat (Can possiblyOrNever Be emptyList_) a
toCharList string =
    case string of
        StringEmpty (CanBe possiblyOrNever) ->
            NothingThat
                --↓ carries over the `possiblyOrNever` type,
                --↓ while allowing a new tag
                (CanBe possiblyOrNever)

        StringNotEmpty headChar tailString ->
            ListThat.fromCons headChar (tailString |> String.toList)
```

> the type information gets carried over, so
>
>     StringThat.(Isnt Empty) -> ListThat.(Isnt Empty)
>     CanBe emptyString_ () -> CanBe emptyList_ ()

`MaybeThat` is just a convenience layer for an optional-able value
where a [`CanBe`](MaybeThat#CanBe) value is attached to its nothing variant.

```elm
type alias StringThat emptyOrNot =
    MaybeThat emptyOrNot ( Char, String )

MaybeThat.map StringThat.head
--: StringThat (CanBe empty_ possiblyOrNever)
--: -> MaybeThat (CanBe nothing_ possiblyOrNever) Char
```

A `StringThat` acts like a type-safe `Maybe NonEmptyString`!

Let's create some data structures!

## [`ListThat`](ListThat)

Handle cases where a list `Isnt Empty` or `CanBe Empty` in one go.

`Isnt Empty` allows safe `Maybe`-free [`head`](ListThat#head), [`tail`](ListThat#tail), [`fold`](ListThat#fold) (useful for finding the maximum, etc. some call it "fold1"), ...

```elm
import ListThat

ListThat.empty         -- ListThat (CanBe Empty) a_
    |> ListThat.appendNotEmpty
        (ListThat.fromCons 1 [ 2, 3 ])
                       -- ListThat isntEmpty Int
    |> ListThat.cons 5 -- ListThat isntEmpty Int
    |> ListThat.unCons
--> ( 5, [ 1, 2, 3 ] )
```

Notice how
```elm
type alias ListThat canItBeEmpty a =
    MaybeThat canItBeEmpty ( a, List a )
```

## [`ListWithFocusThat`](ListWithFocusThat)

A list zipper that can also focus before and after every element.

```elm
import ListWithFocusThat

ListWithFocusThat.empty           -- ListWithFocusThat (CanBe hole_) a_
    |> ListWithFocusThat.plug 5   -- ListWithFocusThat isntHole_ Int
    |> ListWithFocusThat.append [ 1, 2, 3 ]
                                  -- ListWithFocusThat isntHole_ Int
    |> ListWithFocusThat.nextHole -- ListWithFocusThat (CanBe hole_) Int
    |> ListWithFocusThat.toList
--> [ 5, 1, 2, 3 ]
```

→ [zwilias's holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest) with [a type-safe implementation using `MaybeThat` and other minor tweaks](https://github.com/lue-bird/elm-emptiness-typed/blob/master/changes.md).

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements.
