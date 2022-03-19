module N exposing (Bound(..), Zero)

import Possibly exposing (Possibly(..))


type alias N0 =
    Bound Never Possibly Zero


type alias Add1 n =
    Bound n Never Zero


type alias N1 =
    Add1 N0


type Bound successor possiblyOrNever zeroTag
    = Z possiblyOrNever
    | S successor


type NumberAny
    = Nat (Bound NumberAny Possibly Zero)


type N range
    = N range Int


type alias In min max =
    ArgIn min max NoDifference


type ArgIn min max differences
    = Min min differences


type alias Min min =
    In min NoMax


type NoDifference
    = NoDifference


type Is difference0 difference1
    = Differences difference0 difference1


type From n to sum
    = Difference
        { add : n -> sum
        , sub : sum -> n
        }


type To
    = To Never


type NoMax
    = NoMax Never


type Zero
    = ZeroTag Never


difference0 : From a To a
difference0 =
    Difference
        { add = identity
        , sub = identity
        }


difference1 : From n To (Add1 n)
difference1 =
    Difference
        { add = S
        , sub = sub1
        }


sub1 : Add1 n -> n
sub1 =
    \n ->
        case n of
            Z possible ->
                never possible

            S lower ->
                lower


n0 : N (ArgIn N0 max_ (Is (From n0 To n0) (From n1 To n1)))
n0 =
    let
        differences0 =
            Differences difference0 difference0
    in
    N (Min (Z Possible) differences0) 0


n1 : N (ArgIn N1 max_ (Is (From n0 To (Add1 n0)) (From n1 To (Add1 n1))))
n1 =
    let
        differences1 =
            Differences difference1 difference1
    in
    N (Min (S (Z Possible)) differences1) 0


toInt : N range_ -> Int
toInt =
    \(N _ int) -> int


min : N (ArgIn min max_ is_) -> min
min =
    \(N (Min minimum _) _) -> minimum


differences : N (ArgIn min_ max_ differences) -> differences
differences =
    \(N (Min _ differences_) _) -> differences_


add :
    N
        (ArgIn
            minAdded_
            maxAdded_
            (Is (From min To minSum) (From max To maxSum))
        )
    -> N (ArgIn min max is_)
    -> N (In minSum maxSum)
add added =
    \n ->
        N
            (let
                (Differences (Difference min_) _) =
                    differences added
             in
             Min (min_.add (min n)) NoDifference
            )
            (toInt n + toInt added)


sub :
    N
        (ArgIn
            minSubtracted_
            maxSubtracted_
            (Is (From minDifference To min) (From maxDifference To max))
        )
    -> N (ArgIn min max is_)
    -> N (In minDifference maxDifference)
sub subtracted =
    \n ->
        N
            (let
                (Differences (Difference min_) _) =
                    differences subtracted
             in
             Min (min_.sub (min n)) NoDifference
            )
            (toInt n + toInt subtracted)
