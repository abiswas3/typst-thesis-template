#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import cosmos.clouds: *
#import "../commands.typ": *

= Prelims and Problem Statement <hhh:sec:prelims>

== General Notation

We describe sets with calligraphic font #Hierarchy.
For a probability distribution $D$, we denote with $#highlight($x$) arrow.l #h(0.1em) D$ the event of sampling $x$ according to $D$.
We #highlight[highlight] random variables and samples to distinguish them from constants, as shown above.
For a randomized algorithm $A$, the notation $A(X\; rv(z), rv(w))$ means that $A$ is run on input $X$ with random values $rv(z)$ and $rv(w)$.
If an argument is written without highlighting, as in $A(X\; z, rv(w))$, that value is fixed.
For example, $A(X\; arrow(w), rv(arrow(v)))$ conditions on the fixed value $arrow(w)$ and leaves only $rv(arrow(v))$ random.
We write $[n]$ to denote the set ${1, dots, n}$. For any event $E$, we denote with $overline(E)$, the complement of the event.

For a vector $arrow(z) = (z_i)_(i in cal(I))$ indexed by a set $cal(I)$ and an ordered subset $cal(J) = (j_1, dots, j_m) subset.eq cal(I)$, the _restriction_ of $arrow(z)$ to $cal(J)$ is
$
  arrow(z)_(cal(J)) := (z_(j_1), dots, z_(j_m)).
$
When an algorithm $A$ has vector-valued output, we write $A(X; rv(arrow(w)), rv(arrow(v)))_(cal(J))$ for that output restricted to $cal(J)$.

Next, we first review the necessary tools from differential privacy and its basic properties, and then formalise the idea of a hierarchical domain.

== Differential Privacy Definitions 

#definition(title: [Neighbouring Datasets])[
Let $X$ and $X'$ be a multi sets of elements picked from some (possibly hierarchical) domain $cal(H)$.
$X$ and $X'$ are said to be neighbouring, (denoted as $X tilde X'$), if they differ by one element only, i.e., $X' = X union {x'}$, or vice-versa.
] <hhh:def:neighbouring>

#definition(title: [Differential Privacy (DP)])[
Fix some function $f$ that maps a set of elements from a hierarchical domain $cal(H)$ to some range $cal(Y)$.
Fix $n in bb(N)$. Let $X in cal(H)^n$ and $X' in cal(H)^(n+1)$ denote _any_ pair of neighbouring datasets.
For $epsilon > 0$ and $delta = sans("negl")(n)$, where $sans("negl")(dot)$ is a negligible function in $n$, we say a random algorithm $sans(M)$ computes $f$ with $(epsilon, delta)$-differential privacy _if and only if_ for _all_ $cal(A) subset.eq cal(Y)$,

$ exp(-epsilon) (Prob(rv(sans(M)(X', f)) in cal(A)) - delta) <= Prob(rv(sans(M)(X, f)) in cal(A)) <= exp(epsilon) Prob(rv(sans(M)(X', f)) in cal(A)) + delta $
] <hhh:def:dp>

The special case of $(epsilon, delta)$-DP with $delta=0$ is referred to as pure DP, whereas $delta>0$ is known as approximate DP.
A standard approach to obtain DP is to add noise proportional to the global sensitivity of the function being evaluated.

#definition(title: [Global Sensitivity])[
Given any function $f$ that maps a set of elements from a hierarchical domain $cal(H)$ to $bb(R)$, we define the global sensitivity $Delta_G (f)$ of $f$ as
$ Delta_G (f) := max_((X\, thin X')) norm(f(X) - f(X'))_1, $
where the maximum is taken over _any_ pair of neighbouring datasets $X, X'$.
] <hhh:def:global_sensitivity>

It is well known that the global sensitivity of a counting query, such as the queries defined in @hhh:def:absolute_count and @hhh:def:cond_count is 1.
The following facts about differential privacy can be found in any introductory textbook on differential privacy @dwork2014algorithmic.

#theorem(title: [Laplace Histograms ])[
Let $f$ be a function that maps elements from some domain to a subset of $bb(R)^d$, that has global sensitivity $Delta_G$.
Then the Laplace mechanism $sans(M)$ defined as $sans(M)(X) = f(X) + (Y_1, dots, Y_d)$ where each $Y_1, dots, Y_d arrow.l sans("Laplace")(Delta_G slash epsilon)$ is $epsilon$-DP.
] <hhh:thm:laplace_hist>

#theorem(title: [Basic Composition ])[
Let $sans(M)_1$ and $sans(M)_2$ be a $(epsilon_1, delta_1)$-DP and $(epsilon_2, delta_2)$-DP algorithm respectively. $sans(M)(X) = (sans(M)_1 (X), sans(M)_2 (X))$ is $((epsilon_1 + epsilon_2), (delta_1 + delta_2))$-DP.
] <hhh:thm:basic_composition>

#theorem(title: [Post Processing])[
Let $sans(A)_1$ be an $(epsilon, delta)$-DP algorithm and $sans(A)_2$ be a (possibly randomised) post-processing algorithm.
Then the algorithm $sans(A)(x) = sans(A)_2 (sans(A)_1 (x))$ is still an $(epsilon, delta)$-DP algorithm.
] <hhh:thm:post_process>

== Hierarchies

Formally, a hierarchical domain is a set $cal(U)$ associated with a partial order ($succ$).
In streaming literature @mitzenmacher2012hierarchical @cormode2003finding, this partial order is often represented by a function called $sans("Generalise"): cal(U) -> cal(U)$ which maps elements of the universe to other elements in the universe#footnote[$sans("Generalise")$ encodes partial order binary relation $R: cal(U) times cal(U) -> {0,1}$, such that $R(x,p)=1 <==> p = sans("Generalise")(x)$].
In this work, it suffices to think of a hierarchical domain as the set of elements that has one to one mapping with the nodes of a rooted tree with finite arity#footnote[The HHH literature also considers multi-dimensional hierarchies, where the universe is represented by nodes of a lattice rather than a rooted tree. However, in this work, we focus on single dimensional hierarchies which can be represented by a tree.].
For any element $x in cal(U)$, $sans("Generalise")(x)$ refers to the parent or prefix of $x$.
We say an element $*$ is _fully generalised_ or the root of the tree if $sans("Generalise")(*) = *$.
We say an element $e$ is _fully specified_ if there exists no $s in cal(U)$ such that $e = sans("Generalise")(s)$ ($e$ is a leaf node of the rooted tree representing the hierarchy).
We denote by $sans("Generalise")^((k)) (x)$ as the ancestor of $x$ that is $k$ steps away in the tree representation (element obtained by applying $sans("Generalise")$ $k$ times on $x$).
The pair $(cal(U), sans("Generalise"))$ defines a hierarchical domain $cal(H)$.
The height $h$ of the hierarchy represents the maximum number of times _any_ fully specified element must be generalised to get a fully generalised element (or more simply, the height of the tree representing the hierarchy).
As a concrete example of a single-dimensional hierarchy, one can imagine $cal(U)$ to be the set of prefixes of $h$-bit strings.
When $h = 4$, this universe has 16 fully specified elements: $0000, 0001, dots, 1111$. The prefix $000*$ is a generalisation of $0000$ and $0001$.
We use notation $x succ p$ (read as $p$ is reachable from $x$) if there exists a $k in bb(N)$ such that $p = sans("Generalise")^((k)) (x)$, and $x succ.eq p$ if $p = sans("Generalise")^((k))(x) thick or thick x = p$.
For any $p in cal(H)$, $Successors(p) := {q in cal(H) : GeneraliseMap(q, p)}$ denotes the strict successors of $p$, and $Parent(p) := {q in cal(H) : GeneraliseMapEq(p, q)}$ the ancestors of $p$ (including $p$ itself).

Henceforth, we assume that any dataset $X$ is a multiset of fully specified elements from some hierarchical universe $cal(H)$ of height $h$.

#definition(title: [Unconditional Count or Absolute Frequency])[
Given a dataset $X$, the unconditional frequency of any element $p in cal(H)$, denoted by $f_X (p)$, is the number of elements in $X$ that generalise to $p$. Writing $bb(1)[dot]$ for the indicator function,
$ f_X (p) = sum_(e in X) bb(1)[e succ.eq p]. $
] <hhh:def:absolute_count>

In @hhh:fig:why_hhh, the unconditional counts of each node are written next to each node in the tree for the figure on the right.

#definition(title: [Residual Count / Conditional Frequencies])[
Given a dataset $X$, and a set $cal(S) subset.eq cal(H)$, we say $x cancel(succ) cal(S)$ if there does not exist $q in cal(S)$ such that $x succ.eq q$.
We define the conditional or residual count $Residual(p, cal(S))$ of a prefix $p$ with respect to $cal(S)$ as the sum of all fully specified elements who do not have a parent already in $cal(S)$.
$ Residual(p, cal(S)) := sum_(e in X and #h(0.2em) e succ.eq p and #h(0.2em) e cancel(succ) cal(S)) f_X (e). $
] <hhh:def:cond_count>

We will use $ResidualXPrime(p) := sum_(e in X and #h(0.2em) e succ.eq p and #h(0.2em) e cancel(succ) cal(S)) f_X' (e)$ to denote the residual count when using $X'= X union {x'}$ as the input dataset.
In the left tree in @hhh:fig:why_hhh, the set $cal(S)$ is shown by nodes in teal, and the conditional count with respect to $cal(S)$ is written by each node.

#definition(title: [Level Of A Node / Prefix])[
The level of a prefix $p in cal(H)$ is the (minimum) number of applications of $sans("Generalise")$ to reach $*$ i.e. $sans("Level")(p) = k <==> * = sans("Generalise")^((k))(p)$.
] <hhh:def:level>

For example, let $cal(H)$ be the set of 4-bit bistrings.
If we generalise $011*$ three times we get to $*$, so the level of the prefix is 3.
The fully specified elements or leaf elements are at level $h = 4$ and $*$ is at level 0.
With these definitions in place, we can formally define the concept of a heavy hitter and a hierarchical heavy hitter.

#definition(title: [Exact Heavy Hitters])[
For dataset $X$ and threshold $tau in bb(R)$, we say prefix $p$ is a heavy hitter (HH) if $f_X (p) > tau$.
The set of heavy hitters of $X$ is $cal(H H) = {e in X : f_X (e) >= tau}$.
] <hhh:def:exact_HHH>

#definition(title: [Exact Hierarchical Heavy Hitters])[
The set of exact hierarchical heavy hitters is defined inductively. Let $X$ denote a dataset drawn from a hierarchy of height $h$, then \
+ $cal(H H H)_h$ denotes the exact heavy hitters in $X$.
+ For any prefix $p$ at level $0 <= l < h$, let $F_(cal(H H H)_(l+1)) (p)$ be the residual count (Defn. @hhh:def:cond_count) of $p$ given $cal(H H H)_(l+1)$. Then $cal(H H H)_l$ is defined as $cal(H H H)_(l+1) union {p in sans("Level")(l) : F_(cal(H H H)_(l+1))(p) >= tau}$.
+ $cal(H H H)_0$ is the set of _exact_ hierarchical heavy hitters of $X$.
] <hhh:def:hhh>

@hhh:fig:why_hhh illustrates this difference between heavy hitters and hierarchical heavy hitters.

=== Approximate Hierarchical Heavy Hitters

In this paper, the function $f$ that our algorithm $sans(M)$ computes is the hierarchical heavy hitters of a dataset $X$.
By definition, differential privacy restricts us from outputting exact answers or using a deterministic algorithm to compute approximate values.
As the output _must_ be random, we can no longer output exact counts of the hierarchical heavy hitter problem.
Thus, keeping in line with the definitions introduced in @mitzenmacher2012hierarchical @cormode2003finding we define the task of _approximate heavy hitters_, where the estimates are within some approximation error $Delta$ with high confidence.
As we now have noise in the system, we relax the threshold by $Delta$ units, where $Delta$ allows the error to grow larger for larger values (i.e., relative error).
Clearly the smaller the value of $Delta$, the closer we are to the definition of exact hierarchical heavy hitters.
The coverage constraint says we want to be conservative and not miss out on potential heavy hitters due to DP noise i.e., prevent false negatives#footnote[We constrain on false negatives instead of false positives to stay aligned with the definitions in prior works. Our results still hold if we constrain on false positives.].
Our goal is to come up with a theoretical bound on the error, and show that the error is small enough for practical use cases.

#definition(title: [Private Approximate Hierarchical Heavy Hitters])[
Let $sans(M)$ denote an algorithm that receives as input a multi set $X$ of $n$ fully specified elements from some hierarchical domain $cal(H)$. Fix a public threshold $tau in bb(R)$, a confidence parameter $eta in (0,1)$, privacy parameters $epsilon in (0, log n)$ and $delta = sans("negl")(n)$.
We say the algorithm $sans(M)$ correctly finds approximate private hierarchical heavy hitters with relative error $(tau, Delta)$ if it outputs $cal(S) subset cal(H)$ and approximate counts $tilde(f)_X (p)$ such that:

+ *Privacy*: $sans(M)$ is $(epsilon, delta)$-DP.
+ *Simultaneous Relative Error*: With probability $1 - eta$ we have $max_(p in cal(H)) abs((f_X (p) - tilde(f)_X (p)) / f_X (p)) <= Delta / tau$.
+ *Coverage*: For _any_ prefix $p in.not cal(S)$, $Residual(p, cal(S)) <= tau - Delta$ with probability $1 - eta$, with $Residual(p, cal(S))$ as defined in @hhh:def:cond_count.
] <hhh:problem:one>

We want to show that in the non-streaming setting, the relative error $Delta$ of our algorithm does not grow linearly with the the height of the hierarchy#footnote[As we want to bound the worst case simultaneous relative error for _any_ element in the hierarchy, logarithmic dependence on height is unavoidable (via the union bound).], and is independent of the number of heavy hitters in the hierarchy (as discussed in the introduction above).
In the streaming setting we will have to deal with error due to privacy and lack of space.
Thus, the streaming version of our problem is the exact same problem with limited space.

#definition(title: [Streaming Private HHH])[
The streaming problem is to solve @hhh:problem:one with a constant amount of space $kappa = O(1)$.
] <hhh:problem:streaming>

Of course, to prevent the problem from being degenerate, we will assume that the amount of space available is significantly smaller than the size of the stream $n$ or the size of the universe $|cal(H)|$.
