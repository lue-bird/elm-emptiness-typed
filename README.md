> one type for emptiable and safe non-empty

# [emptiness-typed](https://package.elm-lang.org/packages/lue-bird/elm-emptiness-typed/latest/)

There are many types that promise non-emptiness. One example: [MartinSStewart's `NonemptyString`](https://dark.elm.dmy.fr/packages/MartinSStewart/elm-nonempty-string/latest/).

`fromInt`, `fromChar`, ... promise being non-empty at compile-time

→ `head`, `tail`, ... are guaranteed to succeed.
You don't have to carry `Maybe`s throughout your program. Cool.

How about operations that **work on non-empty and emptiable** strings?
```elm
length : StringIs emptiableOrFilled_ -> Int

toUpper :
    StringIs emptiableOrFilled
    -> StringIs emptiableOrFilled
...
```
or ones that can **pass** the **(im)possibility of a state** from one data structure to the other?
```elm
toCharList :
    StringIs emptiableOrFilled
    -> ListIs emptiableOrFilled
```

All this good stuff is very much possible [🔥](https://youtu.be/3b7U8LePPL0)

Let's experiment and see where we end up.

```elm
type StringIsCanBeEmpty possiblyOrNever
    = StringEmpty possiblyOrNever
    | StringNotEmpty Char String

fromChar : Char -> StringIsCanBeEmpty Never
fromChar onlyChar =
    StringNotEmpty onlyChar ""

head : StringIsCanBeEmpty Never -> Char
head string =
    case string of
        StringEmpty empty ->
            empty |> never --! neat
        
        StringNotEmpty headChar _ ->
            headChar

head (char 'E') --> 'E'
head (StringEmpty ()) --> error
```

→ The type `StringIsCanBeEmpty Never` limits arguments to just `StringNotEmpty`.

Lets make the type `StringIsCanBeEmpty ()/Never` handier:

```elm
type StringIs emptiableOrFilled

type alias Filled =
    Never

type alias CanBeEmpty =
    ()

head : StringIs Filled -> Char
empty : StringIs CanBeEmpty
```

To avoid misuse like `empty : StringIs ()` or `Parser.spaces : Parser CanBeEmpty`,

we'll wrap the type tags up 🌯

```elm
type Filled
    = NotEmpty Never

type CanBeEmpty
    = CanBeEmpty

head : StringIs Filled -> Char
empty : StringIs CanBeEmpty
```

👌

On to implementing ↓ that carries the emptiness-information over:

```elm
toCharList : StringIs ?? -> ListIs ?? Char
```

We need a common wrapper

```elm
type PossiblyEmpty possiblyOrNever
    = Possible possiblyOrNever

type alias Filled =
    PossiblyEmpty Never

type alias Emptiable =
    PossiblyEmpty ()


empty : StringIs Emptiable
empty =
    StringEmpty (Possible ())

head : StringIs Filled
head =
    \string ->
        case string of
            StringEmpty (Possible emptyPossible) ->
                emptyPossible |> never
            
            StringFilled headChar _ ->
                headChar
```

This is **exactly** what this library provides: [`PossiblyEmpty`](Fillable#PossiblyEmpty), [`Emptiable`](Fillable#Emptiable), [`Filled`](Fillable#Filled)

Now the fun part:

```elm
toCharList :
    StringIs emptiableOrFilled
    -> ListIs emptiableOrFilled Char
toCharList string =
    case string of
        StringEmpty emptiableOrFilled ->
            ListEmpty emptiableOrFilled

        StringNotEmpty headChar tailString ->
            ListIs.fromCons headChar (tailString |> String.toList)
```

The type information gets carried over, so
```elm
StringIs Filled -> ListIs Filled
StringIs Emptiable -> ListIs Emptiable
```

[`Fillable.Is`](Fillable#Is) is just a convenience layer for an optional-able value
where [`PossiblyEmpty`](Fillable#PossiblyEmpty) is attached to its [`Empty`](Fillable#Is) variant.

Defining
```elm
import Fillable exposing (Is, Filled, filled, filling)

type alias StringIs emptiableOrFilled =
    Is emptiableOrFilled ( Char, String )

head : StringIs Filled -> Char
head =
    filling >> \( headChar, _ ) -> headChar

Fillable.map (filled >> head) :
--: StringIs emptiableOrFilled
--.: -> Is emptiableOrFilled Char
```

`StringIs` acts like a type-safe `Maybe NonEmptyString` 🪴


Let's create some data structures!

## [`ListIs`](ListIs)

Handle [`Emptiable`](Fillable#Emptiable) & [`Filled`](Fillable#Filled) lists in one go.

[`Filled`](Fillable#Filled) allows safe `Maybe`-free [`head`](ListIs#head), [`tail`](ListIs#tail), [`fold`](ListIs#fold) (useful for finding the maximum, etc. some call it "fold1"), ...

```elm
import ListIs

Fillable.empty         -- ListIs Emptiable a_
    |> ListIs.appendNotEmpty
        (ListIs.fromCons 1 [ 2, 3 ])
                       -- ListIs Filled Int
    |> ListIs.cons 5 -- ListIs Filled Int
    |> ListIs.unCons
--> ( 5, [ 1, 2, 3 ] )
```

Notice how
```elm
type alias ListIs emptiableOrFilled element =
    Fillable.Is emptiableOrFilled ( element, List element )
```

## [`ListWithFocus`](ListWithFocus)

A list zipper that can also focus before and after every element.

```elm
import ListWithFocusThat

ListWithFocus.empty           -- ListWhereFocusIs Emptiable item_
    |> ListWithFocus.plug 5   -- ListWhereFocusIs filled_ number_
    |> ListWithFocus.append [ 1, 2, 3 ]
                              -- ListWereFocusIs filled_ number_
    |> ListWithFocus.nextHole -- ListWereFocusIs Emptiable number_
    |> ListWithFocus.toList
--> [ 5, 1, 2, 3 ]
```

→ [zwilias's holey-zipper](https://package.elm-lang.org/packages/zwilias/elm-holey-zipper/latest) with [a type-safe implementation using [`Fillable.Is`](Fillable#Is) and other minor tweaks](https://github.com/lue-bird/elm-emptiness-typed/blob/master/changes.md).

## suggestions?

→ See [contributing.md](https://github.com/lue-bird/elm-emptiness-typed/blob/master/contributing.md)

## you like type-safety?

[typesafe-array](https://dark.elm.dmy.fr/packages/lue-bird/elm-typesafe-array/latest/) takes it to the extreme.
The possible length range is part of its type, allowing safe access for some elements.
