#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import "@preview/cetz:0.4.0"
#import cosmos.clouds: *
#import "../commands.typ": *

= Offline Private Hierarchical Heavy Hitters <hhh:sec:private_hhh_no_streaming>

In this section, we tackle the offline version of the problem, with no space constraints.
Before describing the complete protocol and showing how it solves @hhh:problem:one, we provide an intuitive explanation of the techniques used to circumvent the dependence the height of the hierarchy and the number of hierarchical heavy hitters by working through a sequence of attempts.
Let $cal(H)$ denote a hierarchy with height $h$ and let $X$ denote a dataset of $n$ fully specified elements drawn from $cal(H)$.

== Laplace Histograms

Observe that the unconditional frequencies for each prefix of the hierarchy can be estimated by computing $h$ histograms for each level of the hierarchy.
For two neighbouring datasets $X$ and $X'$ that differ by a single input only, there is _exactly_ one node per level for which the unconditional frequency of the nodes differ by one under $X$ and $X'$.
Thus, a first approach to hierarchical heavy hitter estimation is to release $h$ Laplace histograms by adding noise drawn from a Laplace noise distribution with scale $h / Episilon$ to every node in the hierarchy.
By the privacy of the Laplace histograms (@hhh:thm:laplace_hist), each level is $Episilon \/ h$-private.
As any node contributes to at most $h$ counts, by basic composition and the privacy of the Laplace mechanism, the set of realised counts is $(Episilon, 0)$-DP.
Then, one could compute hierarchical heavy hitters via post-processing, which does not affect the privacy of the algorithm (@hhh:thm:post_process).
As we add noise with scale $h / Episilon$ to each node in $cal(H)$, the DP error per node scales linearly in the height of the hierarchy.
Furthermore, if we wanted to upper bound the simultaneous error over all prefixes in the hierarchy, then we need to apply the union bound over all nodes of the hierarchy.
As the number of nodes is exponential in the height of the hierarchy, the relative estimation error scales $sans("poly")(h)$.

== Stability Histograms 

One solution to circumventing such a union bound over all the elements of the universe when the size of the universe is very large is to use stability histograms @bun2019simultaneous @balcer2017differential @thakurta2013differentially instead of Laplace histograms.
For fixed privacy parameters $Episilon in (0, log n)$ and $delta = sans("negl")(n)$, the key intuition behind stability histograms is that if we only released private estimates (using the Laplace mechanism) for nodes with _large enough_ non-zero frequency, the simultaneous error bound improves from $log(Size(cal(H)))$ to $log(n) < log(1 \/ delta)$ (as there are at most $n$ elements in $X$).
This is advantageous when $Size(cal(H)) >> n$ meaning that many nodes have zero frequency.
For such nodes, we incur no error at all (as the algorithm ignores them).

However, this technique cannot achieve pure DP as was possible in the Laplace histogram case.
Observe that if $X'$ contains an element $x'$ that is not present in $X$ (we call such an $x'$ isolated), an adversary can perfectly distinguish between $X$ and $X'$ if the count of this element, albeit noisy, appeared in the output (as when processing $X$, nodes representing generalisations of $x'$ would have frequency 0, and would be ignored).
Nevertheless, since stability histograms only output counts for elements with "large" counts, and as the frequency of such an isolated element $x'$ is 1 (from the definition of neighbouring datasets), we can set the frequency threshold for "large enough" such that with probability at least $1 - delta$ the isolated element will never show up in the final output.
This is sufficient to achieve $(Episilon, delta)$-DP.
Over the whole tree representing the hierarchy, the case where $x'$ distinguishes $X$ and $X'$ can occur at at most $h$ levels of $cal(H)$.
Thus, if we output stability histograms with $delta' = delta \/ h$ at each level then, by basic composition, the final output does not contain any isolated elements with probability at least $1 - delta$.
In this way, stability histograms allow us to circumvent the union bound over all the nodes in $cal(H)$, at the cost of going from pure to approximate DP.
It does not however, circumvent the issue discussed above where the scale of the DP noise is $h / Episilon$.

== DP Counting On Trees 

One approach to resolving this issue is to make repeated use of the Above-Threshold Algorithm by #citet(<dwork2009complexity>).
Given a hierarchy $cal(H)$ then, by definition, there can be at most $c = n / (tau - Delta)$ hierarchical heavy hitters.
Observe that $c$ is a constant that depends only on $tau$ and $Delta$, and is independent of the height of the hierarchy $h$.
When the height of the hierarchy $h$ is large and $c << h$, we would incur lower per-node DP error if the scale of the noise were $c / Episilon$ instead of $h / Episilon$.
#citet(<ghazi2022differentially>) observed this fact and proposed an algorithm that traverses the tree bottom up.
At each level of the tree, their algorithm inspects only one node, the one with maximal unconditional count for that level.
There are at most $h$ such nodes (one per level).
However, even in the worst case, at most $c$ out of $h$ of these nodes can be conditionally heavy.
Thus, we have $h$ counting queries, out of which $c$ are conditionally heavy.
Their solution uses the Sparse Vector Technique (SVT) by composing Above-threshold $h$ times, but they pay only for the $c$ conditionally heavy nodes.
Once $c$ levels have been identified, the algorithm prunes the tree, and restricts it to just the $c$ levels with at least one conditionally heavy node.
Then it estimates the counts of the pruned tree by solving $c$ instances of the private stability histogram estimation problem#footnote[While #citeauthor(<ghazi2022differentially>) do not explicitly refer to stability histograms, their use of bounded truncated Laplace noise is equivalent. In the case of bounded noise, the union bound is affected by the size of the support of the truncated noise distribution, which is upper bounded by $O(1 \/ delta)$. For stability histograms, it is affected by the number of elements which is upper bounded by $1 \/ delta$.] with privacy budget $Episilon \/ c$.
As commented in the introduction, although this is an asymptotic improvement, it is very hard to imagine cases where $c << h$.
Thus, the simple Laplace stability histograms with composition error $h$ would outperform the algorithm by #citet(<ghazi2022differentially>) in almost all feasible situations.

== Our Approach

Our algorithm is based on the following critical observation.
Although it is true that there are at most $c$ conditionally heavy levels in the tree, _only one_ of the conditionally heavy nodes is really influenced by $x'$.
For the remainder of the heavy nodes, there is no difference in the conditional frequencies of $X$ and $X'$.
It is this structure that want to exploit to improve error our guarantees.
In prior work, #citet(<kaplan2021sparse>) show that there are instances where the composition error of the SVT algorithm is suboptimal, even when dealing with a stream of adaptively chosen queries by an unbounded adversary.
Instead, they propose a general algorithm (called Threshold Monitor) where DP error of a query scales linearly by a constant $ O((Episilon (k+1)) / (log 1 \/ delta))$, where $k >= 1$ represents the number of times any data point can contribute to a counting query being heavy.
In this section, we revisit the Threshold monitor algorithm 
under a simplified regime. 
Instead of adaptively chosen arbitrary counting queries, we will have a _pre-determined set of monotonically increasing counting queries_. 
Additionally for us, the structure of our problems corresponds to the case $k=1$, which can simplify the analysis. 
Note that both the SVT algorithm and Threshold monitor are general and accommodate a stream of adaptively chosen counting queries with no structure.
In estimating HHH in the non-streaming setting with central differential privacy, we can pre-select the order of queries to be bottom up (leveraging monotonicity and limited influence of any node), and we do not have to deal with adaptive queries.
Thus, in the case of hierarchical heavy hitter estimation, paying a price of $c \/ Episilon$ of SVT or the larger constants of Threshold Monitor for adaptivity in composition is wasteful#footnote[In the proofs we will pin-point exactly which parts of the general Threshold monitor algorithm we do not need, and instead can use simpler claims which led to improved constants.]
Instead, we can use the idea of threshold monitor, and with more specialised privacy analysis we show that DP noise per node scales $c_0 \/ Episilon$ instead of $c \/ Episilon$, where $c_0$ is truly a constant since it is independent of _both_ the height of the hierarchy and the number of heavy hitters in $cal(H)$, and is smaller than the constants used in threshold monitor.
@hhh:alg:hh shows our non-streaming algorithm.

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Non-Streaming DP-HHH Detection],
  pseudocode-list(booktabs: true, numbered-title: [Non-Streaming DP-HHH Detection])[
    *Input:* Data $X$ of size $n$ over hierarchy $cal(H)$ with height $h$, Privacy parameter $epsilon in (0, log n)$, $delta = sans("negl")(n)$, Threshold $tau > 0$
    + $c_0 := log_(5/4) (1/delta)$
    + $xi:= 2 eta c_0$
    + $eta := epsilon / (log (1/delta))$
    + $Delta := 1/eta log (1/eta) >= 1$
    + *for* $i = h, dots, 1$ *do*
      + $cal(A)_i = {p in cal(H) | sans("Level")(p) = i}$
      + *for* $p in cal(A)_i$ *do*
        + #rv($w_p$) #samples $Laplace(10 Delta)$
        + #rv($v_p$) #samples $Laplace(1 \/ eta)$
        + #rv($overline(v)_p$) $:= min { #rv($v_p$), Delta }$
        + *if* $Residual(p, cal(S)) + #rv($w_p$) + #rv($overline(v)_p$) >= tau$ *then*
          + Output $b_p = top$  
          + Update $cal(S) = cal(S) union {p}$
          + Output $NoisyResidualFrequency(p) = Residual(p, cal(S)) + #rv($Laplace(xi \/ 2)$)$
        + *end if*
      + *end for*
    + *end for*
    + Output $cal(S)$ and ${NoisyResidualFrequency(p)}_(p in cal(S))$.
  ]
) <hhh:alg:hh>
¡
Before stating our theorem statement, we introduce notation used heavily throughout this section.
Observe that once we fix the output of the algorithm to $arrow(b) in {bot, top}^Size(cal(H))$, this fully determines the set of hierarchical heavy hitters $cal(S)$. That is,
$
cal(S):= cal(S)(arrow(b)) =  {p in cal(H) : b_p = top}
$
Under the same output $arrow(b)$, the neighbour $X' = X union {x'}$ induces the same selected set, $cal(S') := cal(S)(arrow(b)) = cal(S)$.


Next observe, that given $arrow(b)$ we can partition $cal(H)$ into 3 sets $OnPath, Unrelated, After$ as shown in @hhh:fig:proof_tree.

#figure(
  image("../assets/proof_tree.png", width: 80%),
  caption: [
]
)<hhh:fig:proof_tree>

Before we can formally define the conditions of membership of the above sets, we need to define the Inflexion operator.

#definition(title: [Inflexion Operator And The Stopped Path])[
Fix a sequence of counting queries $(p_1, dots, p_h)$ ordered from leaf-to-root  and an output vector $arrow(a) in (bot, top)^h$. We define the inflexion operator by
$
  sans("Inflexion")(arrow(a)) := min {i in [h] : a_(p_i) = top}.
$
If no such index exists, set $sans("Inflexion")(arrow(a)) = h + 1$.
We also define the stopped path induced by $arrow(a)$ as
$
  cal(P)(arrow(a)) := (p_1, dots, p_(min {sans("Inflexion")(arrow(a)), h})).
$
] <hhh:def:inflexion-operator>

Although defined for any path, throughout this work the path we focus on is the leaf-to-root path containing $x'$. 
To prevent notation pollution, we use $InflexionLevel(arrow(a)):= sans("Inflexion")(arrow(a))$ as short hand for the inflexion operator.
Let $arrow(a) = (b_(p_1), dots, b_(p_h))$ denote the restriction of $arrow(b)$ to the leaf-to-root path involving $x'$, 

Then 

$
Unrelated &:= {p in cal(H): GeneraliseMapNotEq(x', p)} \
OnPath &:= {p_1, dots, p_(min {sans("Inflexion")(arrow(a)), h})} \
After &:= cal(H) without (OnPath union Unrelated)
$


In @hhh:fig:proof_tree, the set of nodes in $OnPath$ is denoted by red dotted lines, $Unrelated$ are marked with green stripes and $After$ is marked in green solid colour.

#remark[
 We draw the readers attention to a seemingly obvious fact, but one that is easily misunderstood when reading the analysis later  with all the moving parts.
 The location of $InflexionLevel$ is a function of the output stream $arrow(a)$ _only_ .
 The internal randomness of @hhh:alg:hh determines the probability of seeing said output $arrow(a)$, but the location $InflexionLevel$ is determined by the output and the output alone.
]

Now with the above partition defined, we can further classify the nodes in $OnPath$ using the samples $rv(arrow(w))$ drawn by @hhh:alg:hh.

#block(breakable: false)[
#definition(title: [Sets Induced By Random Samples And Output])[
Let $Delta >= 1$ be as defined in @hhh:alg:hh.
Fix any full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$ and path $(p_1, dots, p_h)$ ordered from leaf to root.
Let $arrow(a):= (b_(p_1), dots, b_(p_h)) in (bot, top)^h$ be the restriction of $arrow(b)$ to this path.
Let $cal(P):= cal(P)(arrow(a))$ be the stopped path from @hhh:def:inflexion-operator.
For any vector $arrow(w)=(w_p)_(p in cal(P)) in RR^(Size(cal(P)))$, define the following (overlapping) subsets of $cal(P)$.

$
PStar(arrow(a)) &:= {p in cal(P) : a_p = top}\
far(arrow(w), arrow(a)) &:= {p in cal(P) : a_p = bot and ResidualX(p) + w_p < tau - Delta - 1 }\
almost(arrow(w), arrow(a)) &:= {p in cal(P) : a_p = bot and ResidualX(p) + w_p >= tau - 2 Delta}
$

We also use the following subsets of $almost(arrow(w), arrow(a))$.
$
special(arrow(w), arrow(a)) &:= {p in almost(arrow(w), arrow(a)) : tau - Delta - 1 <= ResidualX(p) + w_p < tau - Delta } \
ualmost(arrow(w), arrow(a)) &:= {p in almost(arrow(w), arrow(a)) : ResidualX(p) + w_p >= tau - Delta}

$
]<hhh:def:almost-top>
]

Once again @hhh:def:almost-top is defined generally for any leaf to root path, but for our analysis it will always be the path containing $x'$.
The nodes from $OnPath$ can be projected onto the real number line as shown on the right in @hhh:fig:proof_tree and that is the picture to think of whenever we write $cal(P)(arrow(a))$ downstream.

// #figure(
//   image("../assets/partition.png", width: 80%),
//   caption: [For any path from leaf to root the above set includes all the nodes the alogorithm declares as $bot$, before outputting the first $top$.
//   Once $arrow(w)$ and $arrow(a)$ fix these node sets, the nodes in $far$ are harmless as $overline(v)$ is never large enough to send these nodes over the threshold.
//   These nodes do not exhause our privacy budget. 
//   The cases we need to worry about are the nodes inside of $almost$, namely $special$ and $ualmost$.
//   However, by @hhh:lemma:bad-event, we will show that these sets can be large with cryptographically negligible probability.
//
//   ],
// ) <hhh:fig:randomness-partition>
//


#remark[As mentioned earlier, $OnPath$ is determined by $arrow(a)$ which is a restriction of the full output $arrow(b)$, to just the leaf-to-root path starting from leaf that contains $x'$. 
Once $OnPath$ is defined the subsequent subsets $far, special, ualmost$ together with the inflexion node $PStar$ partition the stopped path $OnPath$; the first three depend _only_ on the samples $rv(arrow(w))$ (given $arrow(a)$) and _not_ on the samples $rv(arrow(v))$.
]


Intuitively, what we are saying is that although $OnPath$ could have size $h$, only certain nodes will be "dangerous", and contribute to our privacy budget. 
These are the nodes that correspond to queries in $special$ and $ualmost$, as these contain values in the domain of $rv(arrow(v))$ that allow us to distinguish between $X$ and $X'$.
As we have $rv(overline(v)) <= Delta$, if a node belongs to $far$, then no matter if the node contains $x'$ or not, it will always stay below $tau$ i.e., there is no sampled value of $rv(v)$ that can help distinguish $X$ and $X'$.
The nodes in $special union ualmost subset almost$ are the ones that the privacy adversary can take advantage of, and our privacy budget scales linearly with their size.
Thus, we do not want the size of $special$ or $ualmost$ to be large#footnote[We will be loose in our analysis and upper bound the size $almost$ instead which may contain a few nodes that are in $far$ as well. However, we show even $almost$ is very likely to be small, and this keeps our analysis simpler.].
So we define  a good event as 

#block(breakable: false)[
#definition(title: [Good Event For A Fixed Output])[
Let $c_0$ be as defined in @hhh:alg:hh.
Fix any full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$ and path $(p_1, dots, p_h)$ ordered from leaf to root.
Let $arrow(a):= (b_(p_1), dots, b_(p_h)) in (bot, top)^h$ be the restriction of $arrow(b)$ to this path.
Let $cal(P):= cal(P)(arrow(a))$ be the stopped path from @hhh:def:inflexion-operator.
For any vector $arrow(w)=(w_p)_(p in cal(P)) in RR^(Size(cal(P)))$, define the good event
$
  E(arrow(w), arrow(a)) := (Size(almost(arrow(w), arrow(a))) < c_0)
$
where $almost(arrow(w), arrow(a))$ is as defined in @hhh:def:almost-top.
] <hhh:def:good-event-fixed-output>
]

Intuitively, what @hhh:def:good-event-fixed-output is conveying is that, if we run @hhh:alg:hh and get output $arrow(a)$ using samples $rv(arrow(v))$ and $rv(arrow(w))$ then $rv(arrow(w))$ and $arrow(a)$ only put a few queries in $almost$. 
If this event happens with extremely high likelihood, and we can prove privacy under this event, then we can bound the other events to have probability mass at most $delta$.
This is what we do subsequently.
We show that that good events are extremely likely by upper bounding the reward of the following game in @hhh:lemma:counting-game.

#remark[In Appendix A.2 of @kaplan2021sparse they require a more complicated game to accommodate $k>1$ and arbitrary queries. 
As we will show, in our algorithm the order and the nature of the queries are fixed, and $k=1$, so the simpler game (and therefore proof) suffices.
]

#block(breakable: false)[
#lemma(title:[Coin Flipping Game])[Fix $h in NN$. 
Given inputs $gamma in (0, 1/2)$ and $phi in [gamma/4, 1 - gamma]$ define the following distribution $Dist()$ over the domain ${stop, 0, 1}$ where 

$
PProb(rv(z) = 0, rv(z) samples Dist()) &= 1 - gamma - phi \
PProb(rv(z) = 1, rv(z) samples Dist()) &= gamma\
PProb(rv(z) = stop, rv(z) samples Dist()) &= phi \
$


We sample a sequence of random variables $Z_1, Z_2, dots$ i.i.d. from $Dist()$ and stop at the random time
$
  rv(T) := min(h, min{i >= 1 : Z_i = stop}),
$


i.e., as soon as we either observe a $stop$ or reach $h$ samples, whichever comes first.
Let $rv(r) := sum_(i=1)^rv(T) Identity(Z_i = 1)$ be the number of $1$'s observed before we stop.
Then for every integer $c_0 >= 1$,
$
  Prob(rv(r) >= c_0) <= (gamma/(gamma + phi))^(c_0) <= (4/5)^(c_0)  
$
]<hhh:lemma:counting-game>
]
#proof[
  Fix $c_0 >= 1$.
  Set $rho := gamma / (gamma + phi)$, and let $p_(h, c_0)$ be the probability that the game with
  horizon $h$ yields more than $c_0$ ones. 

// #GrahamComment()[It might be slightly more direct to observe that $rho$ is the probability of seeing a 1, conditioned on not seeing a 0.  Since the zeros can be ignored, it follows directly that the desired probability bound is $rho^(c_0)$]
  
  We prove $p_(h, c_0) <= rho^(c_0)$ by induction on $h$.

  *Base ($h = 0$).* No sample is drawn, so $rv(r) = 0$ and $p_(0, c_0) = 0 <= rho^(c_0)$.

  *Step.* Fix $h >= 1$ and assume $p_(h-1, c_0) <= rho^(c_0)$ for all $c_0 >= 1$. Condition on the
  first sample $X_1$; if the game does not stop, the rest is an independent game with horizon
  $h - 1$. With probability $phi$ we draw $bot$ and stop with $rv(r) = 0$; with probability
  $1 - gamma - phi$ we draw $0$ and still need $c_0$ ones; with probability $gamma$ we draw $1$
  and need $c_0 - 1$ more. Hence
  $ p_(h, c_0) = (1 - gamma - phi) p_(h-1, c_0) + gamma p_(h-1, c_0 - 1). $
  Here $p_(h-1, c_0) <= rho^(c_0)$ by hypothesis, and $p_(h-1, c_0 - 1) <= rho^(c_0 - 1)$ as well
  (using the boundary $p_(h-1, 0) = 1 = rho^0$ when $c_0 = 1$). With $(gamma + phi) rho = gamma$,
  $ p_(h, c_0) <= (1 - gamma - phi) rho^(c_0) + gamma rho^(c_0 - 1)
    = rho^(c_0 - 1) ((1 - gamma - phi) rho + gamma) = rho^(c_0). $

  Thus $Prob(rv(r) >= c_0) <= rho^(c_0) = (gamma / (gamma + phi))^(c_0)$, and $phi >= gamma / 4$
  gives $gamma + phi >= (5 gamma) / 4$, hence $rho <= 4 / 5$ and
  $ Prob(rv(r) >= c_0) <= (4 / 5)^(c_0) = exp(-c_0 ln(5 / 4)). $
]

Next, we illustrate with @hhh:fig:game  why the game in @hhh:lemma:counting-game is relevant for privacy analysis. 
As we process nodes $(p_1, dots, p_(InflexionLevel))$ from leaf to root, the game gives us the random variables $Z_1, dots, Z_(InflexionLevel)$.
We treat the allocation of nodes to regions in @hhh:fig:game by $rv(w)$ as fixed, and map the action of the random noise $rv(overline(v))$ to outcomes of the game.  
If $p_i in special union ualmost$ and $rv(overline(v))$ fails to push the noisy count above tau i.e., $a_(p_i) = bot$, then $Z_i = 1$. 
Otherwise, if $a_(p_i)= bot$ and $p_i in far$ then $Z_i = 0$.
Finally, we have $Z_(InflexionNode) = stop$.
What the game is really saying is that it is extremely unlikely we will have many nodes in $almost$ such that $rv(overline(v))$ fails to push at least one of them over the threshold of $tau$.


#figure(
 image("../assets/game.png", width: 50%),
 caption: []
)<hhh:fig:game>

#block(breakable: false)[

#corollary(title: [Good Event Is Extremely Likely])[
Fix privacy parameters $epsilon >0$ and $delta in o(1/n)$, and set $c_0:= log_(5/4) 1/delta$.
Fix a dataset $X$, a full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$, and a leaf-to-root path $(p_1, dots, p_h)$.
Let $arrow(a):= (b_(p_1), dots, b_(p_h))$ and $cal(P):= cal(P)(arrow(a))$ as defined in @hhh:def:inflexion-operator.
$
  PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and 
    not E(rv(arrow(w)), arrow(a))
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta) 
  ) <= delta
$
] <hhh:lemma:bad-event>
]
#proof()[
Fix $p in OnPath$.
Mapping the variables of @hhh:lemma:counting-game, we have $Z=1$ corresponds to the event where $p in almost$. 
$Z=0$ corresponds to a node being in $far without almost$ and $Z = stop$ corresponds to the event that $p = p_(i*)$.
We make use of properties of the Laplace distribution $rv(L) samples Laplace(b)$: (i) the first quartile of $L$ is $-b ln 2$, i.e., $ Prob(L < -b ln 2) = 1/4$ 
(ii) the third and fifth octile of $L$ are $b ln(3/4)$ and $-b ln(3/4)$, respectively.
(iii) the probability of any range of values is maximised by taking the range around the mean, i.e., $max_a Prob(a <= L < a + c) = Prob(-c/2 <= L <= c/2)$. 
A consequence of (ii) and (iii) together is that the maximum probability for a range of length $b$ is less than that of a range of length $-2b ln(3/4) = 0.575b$, i.e., the probability is less than 1/4. 



Let $W = {w in RR : w >= tau - 2Delta - ResidualX(p)}$ and $Laplace(10 Delta)_(|W)$ denote the Laplace distribution re-normalised over the set $W$. 
Similarly, let $rv(v) samples Laplace(1\/eta)_(| v < c)$ denote the conditional distribution obtained by conditioning that the domain of the Laplace distribution is restricted to values less than some $c in RR$.
$
gamma &:= PProb(ResidualX(p) + rv(w) + rv(overline(v)) < tau and ResidualX(p) + rv(w) >= tau - 2Delta , rv(w) samples Laplace(10 Delta), rv(v) samples Laplace(1\/eta) )\ 
// & = PProb(tau - ResidualX(p) - 2Delta <= rv(w) < tau - ResidualX(p) - rv(overline(v)), rv(w)\, rv(v) )\
&= PProb(tau - ResidualX(p) - 2Delta <= rv(w) < tau - ResidualX(p) - rv(overline(v)), rv(w) samples Laplace(10 Delta), rv(v) samples Laplace(1\/eta))\
&<= PProb(rv(v) < -Delta, rv(v) samples Laplace(1\/eta)) + PProb(tau - ResidualX(p) - 2Delta <= rv(w) < tau - ResidualX(p) - rv(overline(v)) | rv(v) > - Delta, rv(w) samples Laplace(10 Delta), rv(v) samples Laplace(1\/eta)_(| v > -Delta ) )\ 
&<= 1/4 + PProb(tau - ResidualX(p) - 2Delta <= rv(w) < tau - ResidualX(p) - v | v = -Delta , rv(w) samples Laplace(10 Delta)) #<hhh:eq:get-rid-v>\ 
&<= 1/4 + PProb(tau - ResidualX(p) - 2Delta <= rv(w) < tau - ResidualX(p) + Delta, rv(w) samples Laplace(10 Delta)) #<hhh:eq:three-delta-pre>\ 
&<= 1/4 + 1/4 = 1/2 #<hhh:eq:three-delta>\
$

In @hhh:eq:get-rid-v, as we are in the business of upper bounds, we can remove the randomness over $v$ by simply observing that after conditioning over $rv(v) > - Delta$, the conditional probability is maximal when we fix $v = - Delta$ (as this maximises the possible interval on which sampled $rv(w)$ can land).
@hhh:eq:three-delta comes from the fact that $w samples Laplace(10 Delta)$ and @hhh:eq:three-delta-pre requires $w$ be in an interval of size $3Delta$, hence easily upper bounded by 1/4.
The bound $PProb(rv(v) < -Delta) <= 1\/4$ used above relies on the first quartile of $Laplace(1\/eta)$: it holds whenever $Delta >= (ln 2)\/eta$, i.e. for $eta$ small enough, which is the case in our regime $eta = epsilon \/ log(1\/delta)$ with $delta$ negligible.


$
phi &:= PProb(ResidualX(p) + rv(w) + rv(overline(v)) >= tau and ResidualX(p) + rv(w) >= tau - 2Delta , rv(w) samples Laplace(10 Delta), rv(v) samples Laplace(1\/eta) )\ 
&= PProb(ResidualX(p) + rv(w) >= tau - 2Delta, rv(w)samples Laplace(10 Delta)) dot PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | rv(w) >= tau - ResidualX(p) - 2Delta ,  rv(v) samples Laplace(1\/eta), rv(w) samples Laplace(10 Delta)_(|W)) #<hhh:eq:condtional>\ 
&>= gamma dot  PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | rv(w) >= tau - ResidualX(p) - 2Delta ,  rv(v) samples Laplace(1\/eta), rv(w) samples Laplace(10 Delta)_(|W))\
&>= gamma dot  PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | p in almost,  rv(v) samples Laplace(1\/eta), rv(w) samples Laplace(10 Delta)_(|W))\
&>= gamma dot  PProb(rv(v) >= -Delta | p in almost, Laplace(1\/eta)) dot  PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | p in almost and rv(v) >= -Delta,  rv(v) samples Laplace(1\/eta)_(|v >= -Delta), rv(w) samples Laplace(10 Delta)_(|W))\
&= gamma dot  PProb(rv(v) >= -Delta , rv(v) samples Laplace(1\/eta)) dot  PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | p in almost and rv(v) >= -Delta,  rv(v) samples Laplace(1\/eta)_(|v >= -Delta), rv(w) samples Laplace(10 Delta)_(|W))\
&>= gamma dot  1/2 dot  PProb(rv(w) >= tau - rv(overline(v)) - ResidualX(p) | p in almost and rv(v) > -Delta,  rv(v) samples Laplace(1\/eta)_(|v > -Delta), rv(w) samples Laplace(10 Delta)_(|W))\
&>= gamma dot  1/2 dot  PProb(rv(w) >= tau + Delta - ResidualX(p) | p in almost and v = -Delta,   rv(w) samples Laplace(10 Delta)_(|W))\
&>= gamma dot 1/2 dot 1/2 = gamma/4
$

The last inequality comes from the following analysis.
The variable $rv(w)$ follows $Laplace(10 Delta)$ _conditioned_ on $rv(w) >= ell$, where $ell := tau - 2 Delta - ResidualX(p)$ is the left endpoint of $W$. Once we fix $rv(v) = -Delta$, the target event is ${rv(w) >= tau + Delta - ResidualX(p)} = {rv(w) >= ell + 3 Delta}$, so the factor equals $Prob(rv(w) >= ell + 3 Delta | rv(w) >= ell)$. As a function of $ell$ this is minimised at $ell >= 0$, where it equals exactly $e^(-3 Delta \/ 10 Delta) = e^(-0.3) approx 0.74 >= 1\/2$; for $ell < 0$ it is only larger. Hence the factor is at least $1\/2$ for every node, irrespective of $ResidualX(p)$.
  
/* #GrahamComment()[
The proof implicitly makes use of knowledge of the quartiles (and octiles) of the Laplace distribution: Line 7.4 relies on the fact that the first quartile of the Laplace dbn is -ln 2 b, so there is $<0.25$ probability that $v < -Delta$.  Similarly we need the result that the amount of probability mass across a range of length $Delta$ is at most $1/4.$ (this can be seen by inspecting the mass between the 3rd octile and the 5th octile)
]
#AriComment()[For the setting of $eta$ and $Delta:= 1/eta log (1/eta)$ this should work out.] */


]

Proving good events are likely is not enough, we also need to show that privacy is preserved under good events.
We do this next. 
#block(breakable: false)[
#lemma(title:[Privacy Conditioned On Good Events])[
Fix privacy parameters $epsilon >0$ and $delta in o(1/n)$, and set $xi := 2 eta c_0$.
Fix neighbouring datasets $X$ and $X':= X union {x'}$.
Fix any full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$ and leaf-to-root path $(p_1, dots, p_h)$ containing $x'$.
Let $arrow(a):= (b_(p_1), dots, b_(p_h))$ and $cal(P):= cal(P)(arrow(a))$.

For every vector $arrow(u)=(u_p)_(p in cal(P)) in RR^(Size(cal(P)))$ satisfying $E(arrow(u), arrow(a))$, define $arrow(u')=(u'_p)_(p in cal(P))$ coordinate-wise by
$
  u'_p :=
  cases(
    u_p - 1 quad "if"  a_p = top,
    u_p quad quad  "  otherwise",
  )
$
Then
$
  PProb(A(X'; arrow(u'), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta))
  <= PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta))
  <= e^xi PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)).
$
]<hhh:lemma:priv-upper-helper>
]
#proof[
As $arrow(u)$ and $arrow(a)$ are fixed, we also get our sets $almost, far, special$ and $ualmost$ as defined in @hhh:def:almost-top.
Observe that 


$
PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) &= PProb(ResidualX(p_(InflexionLevel)) + u_(InflexionLevel) + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta)) #<hhh:equate:revoke> \
&quad dot product_(p in far) PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta)) #<hhh:eq:ind> \
&quad dot product_(p in ualmost union special) PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta))  #<hhh:equate:revoke>\
$

  
The products in @hhh:eq:ind comes from the fact that given $cal(P)$ each output along the path is decided independently of the others.
We will bound each product term individually.\
  
*Upper Bound*: Now as $ResidualXPrime(p_(InflexionLevel)) > ResidualX(p_(InflexionLevel))$ the following is immediately true
$
PProb(ResidualX(p_(InflexionLevel)) + u_(InflexionLevel) + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta)) &<= PProb(ResidualXPrime(p_(InflexionLevel)) + u_(InflexionLevel) + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta))
$

Observe that as $rv(overline(v)_p) <= Delta$, for all $p in far$, 

$
PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta))  = PProb(ResidualXPrime(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta)) = 1
$

For any $p in ualmost$, we have $ResidualX(p) + u_p >= tau - Delta$, so for $PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta)) > 0$ we need
$
rv(v_p) <= tau - (ResidualX(p) + u_p) <= Delta
$
Using that $PProb(rv(v_p) < c, rv(v_p) samples Laplace(1 \/ eta)) <= exp(eta) PProb(rv(v_p) < c - 1, rv(v_p) samples Laplace(1 \/ eta))$ for any $c$ (shifting the threshold by the sensitivity $1$), this gives us

$
PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta)) &=  PProb(rv(v_p) < tau - (ResidualX(p) + u_p)  ,rv(v_p) samples Laplace(1 \/ eta)) \
 &<=  exp(eta) PProb(rv(v_p) < tau - (ResidualX(p) + u_p) - 1  ,rv(v_p) samples Laplace(1 \/ eta)) \
&=  exp(eta) dot  PProb(ResidualXPrime(p) + u_p + rv(v_p) < tau , rv(v_p) samples Laplace(1 \/ eta)) \
&<= exp(eta) dot PProb(ResidualXPrime(p) + u_p + rv(overline(v)_p) < tau , rv(v_p) samples Laplace(1\/eta)) \
&<= exp(2eta) dot PProb(ResidualXPrime(p) + u_p + rv(overline(v)_p) < tau , rv(v_p) samples Laplace(1\/eta))
$

For any $ p in special$, as $eta:= epsilon/ (log (1/delta)) in (0,1)$ (since $delta$ is cryptographically negligible and $epsilon$ is a small real constant)
$
PProb(ResidualX(p) + u_p + rv(overline(v)_p) = bot, rv(v_p) samples Laplace(1\/eta)) &<= 1 \
&<= exp(eta)(1- eta/2) #<hhh:eq:fact>\
&<= exp(eta)PProb(rv(v_p) < Delta, rv(v_p) samples Laplace(1 \/ eta)) #<hhh:eq:tail>\
&<= exp(eta)PProb(ResidualX(p) + u_p + rv(v_p) < tau, rv(v_p) samples Laplace(1 \/ eta)) \
&<= exp(2eta)PProb(ResidualXPrime(p) + u_p + rv(v_p) < tau, rv(v_p) samples Laplace(1 \/ eta)) \
&<= exp(2eta) PProb(ResidualXPrime(p) + u_p + rv(overline(v)_p) < tau, rv(v_p) samples Laplace(1\/eta))
$

#GrahamComment()[In fact, we require $eta in (0,1)$ earlier, else $Delta < 0$ and the process is not well defined.  However, it really ought to be possible to define a procedure that also works for $epsilon > 1$...r]
#AriComment[You mean $eta > 1$, but I get what you mean, here $eta$ is playing the role of $eta$-differential privacy, and we are in the small privacy parameter regime.]

@hhh:eq:fact follows from the fact that for any $eta in (0,1)$, we have $exp(eta)(1-eta/2) > 1$. 
@hhh:eq:tail comes from the fact that $Delta := 1/eta log (1/eta)$, and by tail bounds we have $PProb(rv(v_i) >= Delta, rv(v_i) samples Laplace(1 \/ eta)) <= eta/2$.
We have handled all four types of nodes that appear in @hhh:eq:ind. 
Combining them all 

$
PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) &<= exp(2 eta Size(ualmost union special)) PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) \
&<= exp(2 eta Size(almost)) PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta))  \
&<= exp(2 eta c_0 ) PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) #<hhh:eq:assumption>
$

@hhh:eq:assumption comes from our assumption that $E(arrow(u), arrow(a)) = 1$, and this completes our proof of the upper bound.

*Lower Bound*: The lower bound is noticeably simpler.
For the inflexion node $InflexionNode$ we have,

$
PProb(ResidualXPrime(p_(InflexionLevel)) + u^(')_(InflexionLevel) + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta)) &= PProb(ResidualXPrime(p_(InflexionLevel)) + u_(InflexionLevel) - 1  + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta)) \
&= PProb(ResidualX(p_(InflexionLevel)) + u_(InflexionLevel)   + rv(overline(v)_p_(InflexionLevel)) >= tau, rv(v_p_(InflexionLevel)) samples Laplace(1\/eta))
$

For $p in (far union ualmost union special)$, we have $a_p = bot$ so $u'_p = u_p$, and
$
PProb(ResidualXPrime(p) + u'_p + rv(overline(v)_p) < tau, rv(v_p) samples Laplace(1\/eta)) &= PProb(ResidualX(p) + 1 + u_p + rv(overline(v)_p) < tau, rv(v_p) samples Laplace(1\/eta)) \
&<= PProb(ResidualX(p) + u_p + rv(overline(v)_p) < tau, rv(v_p) samples Laplace(1\/eta))
$

Putting all these together, we can conclude, 
$
 PProb(A(X'; arrow(u'), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta))
  <= PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta))
$
This completes the proof.

]

== Release On $OnPath$ is private <hhh:sec:active-dp>

We have already shown that if restricted to nodes in $OnPath$, and conditioning on good events, we have $xi$-privacy.
Now we remove the conditioning, and prove that the release  is $(xi, delta)$ private, still restricting to nodes in $OnPath$.
Once this is done, the full privacy over the entire output will immediately follow and is given in @hhh:sec:full-dp.

#lemma(title:[Privacy Upper Bound])[
Fix privacy parameters $epsilon >0$ and $delta in o(1/n)$, and set $xi := 2 eta c_0$.
Fix neighbouring datasets $X$ and $X':= X union {x'}$.
Fix any full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$ and leaf-to-root path $(p_1, dots, p_h)$ containing $x'$.
Let $arrow(a):= (b_(p_1), dots, b_(p_h))$ and $cal(P):= cal(P)(arrow(a))$.
$
  PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) 
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) <= exp(xi) PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) 
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  + delta
$

]<hhh:lemma:priv-upper-bound>
#proof()[
  The noise samples on $cal(P)$ are drawn independently of the data, with $rv(arrow(w)) samples Laplace(10 Delta)$ and $rv(arrow(v)) samples Laplace(1\/eta)$ i.i.d. per node.
  For fixed stopped path $cal(P)$ and output $arrow(a)$ we have
  $
  PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P))
   , rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  &= PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  \ 
  & quad + PProb( A(X; rv(arrow(w)), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and 
    not E(rv(arrow(w)), arrow(a))
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) #<hhh:equate:revoke> \
  &<= PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) + delta #<hhh:eq:bad-event> \ 
  $

  @hhh:eq:bad-event comes by applying @hhh:lemma:bad-event.
  Since $E(arrow(w), arrow(a))$ is determined by $arrow(w)$ and the fixed output vector $arrow(a)$, we can expand the good-event term by conditioning only on the $w$-samples:
  $E(arrow(u), arrow(a))$.
  Since $rv(arrow(w))$ is continuous, let $f_(rv(arrow(w)))$ denote the density of $rv(arrow(w)) samples Laplace(10 Delta)^(times.o Size(cal(P)))$. Then
  $
  & PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)), rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) \
  &= integral_(arrow(u) in RR^(Size(cal(P))) : E(arrow(u), arrow(a))) f_(rv(arrow(w)))(arrow(u)) dot PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u) \
  &<= integral_(arrow(u) in RR^(Size(cal(P))) : E(arrow(u), arrow(a))) f_(rv(arrow(w)))(arrow(u)) dot e^xi PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u) \
  &<= e^xi integral_(arrow(u) in RR^(Size(cal(P)))) f_(rv(arrow(w)))(arrow(u)) dot PProb(A(X'; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u) \
  &= e^xi PProb(A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)).
  $
 The first equality conditions on $rv(arrow(w)) = arrow(u)$ (with $rv(arrow(v))$ independent), the second applies @hhh:lemma:priv-upper-helper on $E(arrow(u), arrow(a))$, and the third extends the region to all $arrow(u)$.
]

#lemma(title: [Privacy Lower Bound])[
Fix privacy parameters $epsilon >0$ and $delta in o(1/n)$, and set $xi := 2 eta c_0$.
Fix neighbouring datasets $X$ and $X':= X union {x'}$.
Fix any full output vector $arrow(b) in (bot, top)^(Size(cal(H)))$ and leaf-to-root path $(p_1, dots, p_h)$ containing $x'$.
Let $arrow(a):= (b_(p_1), dots, b_(p_h))$ and $cal(P):= cal(P)(arrow(a))$.
$
   exp(-xi)( PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P))
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  - delta) <= PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P))
   ,
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))
$
]<hhh:lemma:priv-lower-bound>

#proof[
The noise samples on $cal(P)$ are drawn independently of the data, with $rv(arrow(w)) samples Laplace(10 Delta)$ and $rv(arrow(v)) samples Laplace(1\/eta)$ i.i.d. per node.
Let $arrow(u) in RR^(Size(cal(P)))$ be a vector such that $E(arrow(u), arrow(a))$
holds.
Let $arrow(u)' in RR^(Size(cal(P)))$ be as defined in @hhh:lemma:priv-upper-helper where 
$
  u'_p :=
  cases(
    u_p - 1 quad "if"  a_p = top,
    u_p quad quad  "  otherwise",
  )
$

Let $f_(rv(arrow(w)))$ denote the joint density of $rv(arrow(w)) samples Laplace(10 Delta)^(times.o Size(cal(P)))$ and $f_(rv(w_p))$ the density of each coordinate $rv(w_p) samples Laplace(10 Delta)$.
Then,
$
f_(rv(arrow(w)))(arrow(u)) &= f_(rv(w_InflexionNode))(u_InflexionNode) product_(p in far union almost) f_(rv(w_p))(u_p) \
&= f_(rv(w_InflexionNode))(u_InflexionNode) product_(p in far union almost) f_(rv(w_p))(u'_p) \
&>= exp(-1/(10 Delta )) f_(rv(w_InflexionNode))(u'_InflexionNode) product_(p in far union almost) f_(rv(w_p))(u'_p) \
&= exp(-1/(10 Delta )) f_(rv(arrow(w)))(arrow(u)') \
&>= exp(-xi) f_(rv(arrow(w)))(arrow(u)') #<hhh:eq:lower-w>
$
The last inequality is due to $xi = 2 eta c_0 = 2 epsilon\/log(5\/4)$ (as $eta = epsilon\/log(1\/delta)$, $c_0 = log_(5/4)(1\/delta)$). Since $eta = epsilon\/log(1\/delta) <= min(epsilon, 1\/e)$ for $delta in o(1\/n)$, $1\/(10 Delta) = eta\/(10 log(1\/eta)) <= eta\/10 <= epsilon\/10 <= 2 epsilon\/log(5\/4) = xi$.

$
  PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P))
   , rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  &>= PProb( A(X; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  \
&= integral_(arrow(u) in RR^(Size(cal(P))) : E(arrow(u), arrow(a))) f_(rv(arrow(w)))(arrow(u)) dot PProb(A(X; arrow(u), rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u) \
&>= exp(-xi) integral_(arrow(u) in RR^(Size(cal(P))) : E(arrow(u), arrow(a))) f_(rv(arrow(w)))(arrow(u)') dot PProb(A(X'; arrow(u)', rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u) #<hhh:eq:lower-bound-main> \
&= exp(-xi) integral_(arrow(u)' in RR^(Size(cal(P))) : E(arrow(u)', arrow(a))) f_(rv(arrow(w)))(arrow(u)') dot PProb(A(X'; arrow(u)', rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)), rv(arrow(v)) samples Laplace(1\/eta)) dif arrow(u') #<hhh:eq:change-of-vars> \
&= exp(-xi) PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) \
&>= exp(-xi) PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and E(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  #<hhh:equate:revoke>\ 
   &quad quad +exp(-xi)( PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and overline(E)(rv(arrow(w)), arrow(a)),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  - delta) #<hhh:eq:bad-under-prime> \
&= exp(-xi) ( PProb( A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P))
   , rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))  - delta)
$
@hhh:eq:lower-bound-main comes from @hhh:eq:lower-w and the lower bound in  @hhh:lemma:priv-upper-helper.
  @hhh:eq:change-of-vars is justified because $E(arrow(u), arrow(a)) = E(arrow(u)', arrow(a))$: since $arrow(u)$ and $arrow(u)'$ differ only at the inflexion node $InflexionNode$ (never in $almost$, as $a_(InflexionNode) = top$), we have $almost(arrow(u), arrow(a)) = almost(arrow(u)', arrow(a))$, so the translation $arrow(u) |-> arrow(u)'$ maps the region onto itself.
  @hhh:eq:bad-under-prime uses $PProb(A(X'; rv(arrow(w))\, rv(arrow(v)))_(cal(P)) = arrow(a)_(cal(P)) and overline(E)(rv(arrow(w)), arrow(a)), rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) <= delta$. 
  Although $E$ is the $X$-based good event, $ResidualXPrime(p) = ResidualX(p) + 1$ on the path, so every node of $almost$ under $X$ remains in $almost$ under $X'$; hence the bad event $overline(E)$ is only more likely under $X'$, and @hhh:lemma:bad-event applied to $X'$ bounds it by $delta$.
]
== The Full Proof Of Privacy <hhh:sec:full-dp>

Now we have all the tools needed for the full privacy proof.

#theorem(title: [Privacy])[@hhh:alg:hh is $(xi, delta)$-DP.]
#proof()[

Fix datasets $X$ and $X':= X union {x'}$.
// $
//  exp(-xi) (Prob(rv(arrow(beta')) in cal(G)) - 3 delta)
// &<= Prob(rv(arrow(beta)) in cal(G)) & <= exp(xi) Prob(rv(arrow(beta')) in cal(G)) + 3 delta
// $
 Fix output $arrow(a) := (a_p)_(p in cal(H))$ where each coordinate is either $bot$ or $top$.
  Let $(p_1, dots, p_h)$ be the leaf-to-root path of $x'$ ordered from leaf to root, and let $arrow(a)_(x') := (a_(p_1), dots, a_(p_h))$ be the restriction of $arrow(a)$ to this path (shown in colour in @hhh:fig:proof_tree).
  
  Let $InflexionLevel := sans("Inflexion")(arrow(a)_(x'))$ and define the stopped path
  $
    OnPath := cal(P)(arrow(a)_(x')).
  $
  We decompose $cal(H)$ using this stopped path:
  $
  Unrelated &:= {p in cal(H) : GeneraliseMapNotEq(x', p)}\
  After &:= cal(H) \\ (Unrelated union OnPath).
  $
  Equivalently, in coordinates, $OnPath = (p_1, dots, p_(min {InflexionLevel, h}))$.
  When $InflexionLevel <= h$, the inflexion node is $p_(InflexionLevel)$ and $After$ is exactly the set of its strict ancestors.
  Thus $OnPath$ is the stopped leaf-to-root path from @hhh:def:inflexion-operator (shown with green and orange nodes in @hhh:fig:proof_tree).

  Define $M:=Size(cal(H))$.
  Let $(rv(beta_1), dots, rv(beta_M)) samples A(X)$ and $ (rv(beta'_1), dots, rv(beta'_M)) samples A(X')$ be the output of @hhh:alg:hh on inputs $X$ and $X'$ respectively with randomness over the samples $(rv(arrow(w)), rv(arrow(v))) in RR^M$.
    Now for this fixed $arrow(a)$, we use the three sets $Unrelated$, $OnPath$, $After$ as described by @hhh:fig:proof_tree.
  #v(1em)    
  Let $cal(R) := cal(H) \\ Unrelated = OnPath union After$.
  By Bayes rule, we have 
  $
    Prob(rv(arrow(beta)) = arrow(a))
    = Prob(rv(arrow(beta))_(Unrelated) = arrow(a)_(Unrelated))
      dot Prob(rv(arrow(beta))_(cal(R)) = arrow(a)_(cal(R)) | rv(arrow(beta))_(Unrelated) = arrow(a)_(Unrelated)) #<hhh:eq:full-joint>
  $

 Focusing on the left hand term of the product in @hhh:eq:full-joint, we need only consider $p in Unrelated$.
 As the algorithm proceeds bottom up, we have for any $p in Unrelated$, 

  $
    & Prob(rv(beta_p) = a_p and rv(arrow(beta)_(Successors(p))) = arrow(a)_(Successors(p))) #<hhh:equate:revoke>\
    & quad = Prob(rv(beta_p) = a_p | rv(arrow(beta)_(Successors(p))) = arrow(a)_(Successors(p)))
      dot Prob(rv(arrow(beta)_(Successors(p))) = arrow(a)_(Successors(p))). #<hhh:eq:succ-factor>
  $
  The corresponding local factor is the same under $X'$:
  $
    Prob(rv(beta_p) = a_p | rv(arrow(beta)_(Successors(p))) = arrow(a)_(Successors(p)))
    =
    Prob(rv(beta'_p) = a_p | rv(arrow(beta')_(Successors(p))) = arrow(a)_(Successors(p))). #<hhh:eq:equal>
  $
  To justify @hhh:eq:equal, condition on the event
  $rv(arrow(beta)_(Successors(p))) = arrow(a)_(Successors(p))$.
  This fixes exactly which already-processed successors of $p$ have been selected into $cal(S)$, namely those $q in Successors(p)$ with $a_q = top$.
  Therefore the threshold test at $p$ is determined by the same fresh noise $(rv(w_p), rv(v_p))$ and by the residual count of $p$ after removing this fixed set of selected successors.
  As the unconditional count of $p$ is the same under $X$ and $X'$, the probabilities are equal.

  For brevity of notation define the two unrelated-output events
  $
    E_("Unrel")^X &:= {rv(arrow(beta))_(Unrelated) = arrow(a)_(Unrelated)}\
    E_("Unrel")^(X') &:= {rv(arrow(beta'))_(Unrelated) = arrow(a)_(Unrelated)}.
  $
  Applying @hhh:eq:equal bottom up through the hierarchy over $Unrelated$ gives
  $
    Prob(E_("Unrel")^X)
    =
    Prob(E_("Unrel")^(X'))  #<hhh:eq:unrelated-equal>
  $
  Thus, to prove the theorem it suffices to show that 
    $
	      exp(-xi) (
	        Prob(rv(arrow(beta'))_(cal(R)) = arrow(a)_(cal(R)) | E_("Unrel")^(X'))
        - delta
      )
      &<= Prob(rv(arrow(beta))_(cal(R)) = arrow(a)_(cal(R)) | E_("Unrel")^X) 
      &<= exp(xi) Prob(rv(arrow(beta'))_(cal(R)) = arrow(a)_(cal(R)) | E_("Unrel")^(X')) + delta #<hhh:eq:main>
    $
  Now by Bayes rule and the structure of $cal(H)$, we have 
$
Prob(rv(arrow(beta))_(cal(R)) = arrow(a)_(cal(R)) | E_("Unrel")^X) &= Prob(rv(arrow(beta))_(After) = arrow(a)_(After) | E_("Unrel")^X and rv(arrow(beta))_(OnPath) = arrow(a)_(OnPath) )Prob(rv(arrow(beta))_(OnPath) = arrow(a)_(OnPath) | E_("Unrel")^X) 
$
Notice that $arrow(a)$ defines $cal(S)$, and given the unrelated-output event and the decomposition above, we have 
$
Prob(rv(arrow(beta))_(After) = arrow(a)_(After) | E_("Unrel")^X and rv(arrow(beta))_(OnPath) = arrow(a)_(OnPath) ) = Prob(rv(arrow(beta'))_(After) = arrow(a)_(After) | E_("Unrel")^(X') and rv(arrow(beta'))_(OnPath) = arrow(a)_(OnPath) )
$
as the contribution of $x'$ has been removed in the residual counts.
Thus to prove @hhh:eq:main it suffices to show

$
 e^(-xi)(Prob(rv(arrow(beta'))_(OnPath) = arrow(a)_(OnPath) | E_("Unrel")^(X')) - delta) &<= Prob(rv(arrow(beta))_(OnPath) = arrow(a)_(OnPath)|E_("Unrel")^X ) #<hhh:equate:revoke>\
  & <= e^xi Prob(rv(arrow(beta'))_(OnPath) = arrow(a)_(OnPath)| E_("Unrel")^(X')) + delta #<hhh:eq:new-main>
$


For the upper inequality in @hhh:eq:new-main, first observe that conditioning on $E_("Unrel")^X$ or $E_("Unrel")^(X')$ fixes the same unrelated output $arrow(a)_(Unrelated)$, hence fixes which unrelated successors have already been selected into $cal(S)$.
Given this fixed unrelated output, the residuals on $OnPath$ are fixed functions of the data, and the remaining randomness on $OnPath$ is independent of the randomness used on $Unrelated$.
Thus, conditioning on this event plays _no_ further role in the privacy analysis (we can pretend it was never there).
For the fixed stopped path $OnPath$, the fresh noise on $OnPath$ is drawn independently of the data, with $rv(arrow(w)) samples Laplace(10 Delta)$ and $rv(arrow(v)) samples Laplace(1\/eta)$ i.i.d. per node.
Now apply @hhh:lemma:priv-upper-bound to the leaf-to-root path $(p_1, dots, p_h)$ with the full output vector equal to the fixed output $arrow(a)$.
The stopped path $cal(P)$ in @hhh:lemma:priv-upper-bound is exactly $OnPath$, so the upper bound follows.
Although @hhh:lemma:priv-upper-bound uses the left hand side of the equations below, in its theorem statement, we are really proving a fact about the conditional here when we apply the lemma. 
The reason we don't introduce the notation, is because it plays no role in the privacy analysis, and hence we do not pollute the analysis with unnecessary notation.
$
 PProb(A(X; rv(arrow(w))\, rv(arrow(v)))_(OnPath) = arrow(a)_(OnPath),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta))   &:=  
 Prob(rv(arrow(beta))_(OnPath) = arrow(a)_(OnPath) | E_("Unrel")^X) \
  PProb(A(X'; rv(arrow(w))\, rv(arrow(v)))_(OnPath) = arrow(a)_(OnPath),
    rv(arrow(w)) samples Laplace(10 Delta), rv(arrow(v)) samples Laplace(1\/eta)) &:= Prob(rv(arrow(beta'))_(OnPath) = arrow(a)_(OnPath) | E_("Unrel")^(X')) 
$
The matching lower inequality will follow analogously from @hhh:lemma:priv-lower-bound.
]

#theorem[TODO]<hhh:thm:coverage>
