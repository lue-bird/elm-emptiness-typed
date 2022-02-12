> one type for emptiable and safe non-empty

# [emptiness-typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

There are many types that promise non-emptiness. One example: [MartinSStewart's NonemptyString](https://dark.elm.dmy.fr/packages/MartinSStewart/elm-nonempty-string/latest/).

The cool thing is that `fromInt`, `fromChar`, etc. keep the compile-time promise of being non-empty, so `head`, `tail`, etc. are guaranteed to succeed and you don't have to carry `Maybe`s throughout your program.

How about **operations that work on non-empty and emptiable** strings?
```elm
length : StringThat canBeEmptyOrNot_ -> Int

toUpper :
    StringThat canBeEmptyOrNot
    -> StringThat canBeEmptyOrNot
...
```
or ones that can **pass** the **(im)possibility of a state** from one data structure to the other?
```elm
toCharList :
    StringThat canBeEmptyOrNot
    -> ListThat canBeEmptyOrNot
```

All this good stuff is very much possible [🔥](https://youtu.be/3b7U8LePPL0)

Let's experiment and see how where we end up:

```elm
type StringThatCanBeEmpty possiblyOrNever
    = StringEmpty possiblyOrNever
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

Lets make the type `StringThatCanBeEmpty ()/Never` handier:

```elm
type StringThat canBeEmptyOrNot

type alias IsntEmpty =
    Never

type alias CanBeEmpty =
    ()

head : StringThat IsntEmpty -> Char
empty : StringThat CanBeEmpty
```

To avoid misuse like `empty : StringThat ()` or `Parser.spaces : Parser CanBeEmpty`,

we'll wrap the type tags up 🌯

```elm
type IsntEmpty
    = NotEmpty Never

type CanBeEmpty
    = CanBeEmpty

head : StringThat IsntEmpty -> Char
empty : StringThat CanBeEmpty
```

👌

On to implementing ↓ that carries the emptiness-information over:

```elm
toCharList : StringThat ?? -> ListThat ?? Char
```

We need a common wrapper

```elm
type CanBeEmpty possiblyOrNever
    = CanBeEmpty possiblyOrNever

type alias IsntEmpty =
    CanBeEmpty Never

type alias CanBeEmpty =
    CanBeEmpty ()

StringThat.empty
--: StringThat CanBeEmpty

toCharList :
    StringThat (CanBeEmpty possiblyOrNever)
    -> ListThat (... possiblyOrNever) Char
```

[`Can ... Be ...`](MaybeThat#Can) is just a clean generic version of this.
It has a type tag to differentiate between different kinds of emptiness:

```elm
type Empty
    = Empty Never

head : ListThat (Isnt Empty) element -> element
```
```elm
type Hole
    = Hole Never

current : ListWithFocusThat (Isnt Hole) element -> element
```
(`Never` ensures that _no value can be created_ → type tag-only)

Also, what needed to be written as

```elm
empty : StringThat CanBeEmpty
empty =
    StringEmpty CanBeEmpty
```

becomes simply

```elm
empty : StringThat (CanBe empty_)
empty =
    StringEmpty (Can () Be)
```

Now the fun part:

```elm
toCharList :
    StringThat (Can possiblyOrNever Be emptyString_) element
    -> ListThat (Can possiblyOrNever Be emptyList_) element
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
>     StringThat (Isnt emptyString_)
>         -> ListThat (Isnt emptyList_)
>
>     StringThat (CanBe emptyString_)
>         -> ListThat (CanBe emptyList_)

`MaybeThat` is just a convenience layer for an optional-able value
where a [`Can ... Be ...`](MaybeThat#Can) value is attached to its nothing variant.

Defining
```elm
type alias StringThat canBeEmptyOrNot =
    MaybeThat canBeEmptyOrNot ( Char, String )

head : StringThatCanBeEmpty Never -> Char
head =
    \string ->
        let
            ( headChar, _ ) =
                string |> MaybeThat.value
        in
        headChar

MaybeThat.map head :
    StringThat (Can possiblyOrNever Be empty_)
    -> MaybeThat (Can possiblyOrNever Be nothing_) Char
```

`StringThat` acts like a type-safe `Maybe NonEmptyString` 🪴

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
