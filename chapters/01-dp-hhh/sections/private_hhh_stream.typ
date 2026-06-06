#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import cosmos.clouds: *
#import "../commands.typ": *

= Streaming Private Hierarchical Heavy Hitters <hhh:sec:stream>

In the previous section we proved that the scale of the DP noise per query scales only by a small constant factor that is independent of the height of the hierarchy and the number of hierarchical heavy hitters in the dataset.
A critical factor to being able to bypass composition was that there was no space limitation, and we could store the _exact_ conditional count for _every_ query in memory.
This meant that we could eventually remove the contribution of the neighbouring element $x'$ completely (restricting the privacy loss entirely to the green and orange nodes in @hhh:fig:proof_tree).
Thus for a large majority of queries, neighboring inputs $X$ and $X'$ were treated identically.

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Insertion Operation For A Single MG Sketch],
  pseudocode-list(booktabs: true, numbered-title: [Insert into MG Sketch])[
    *Input:* Next data $x in cal(H)$, increment $v > 0$.
    *Parameters:* Number of counters $kappa$.
    + *if* $x in cal(T)$ *then*
      + $C[x] = C[x] + v$
    + *else if* $C[i] >= v$ for all $i in cal(T)$ *then*
      + $C[i] = C[i] - v$ for all $i in cal(T)$
    + *else*
      + Let $tilde(y) = arg min_(y in cal(T)) C[y]$
      + $cal(T) = (cal(T) \\ {tilde(y)}) union {x}$
      + $C[x] = v$
    + *end if*
  ]
) <hhh:alg:space_saving_insert>

In the streaming setting, we do not have the luxury of storing exact counts.
Thus, we will need to use some streaming data structure @mitzenmacher2012hierarchical @cormode2003finding @chan2012differentially in order to approximate residual frequencies.
In this work, we use one Misra Gries (MG) sketch with $kappa$ counters per level of the hierarchy.
Thus the total space used is $O(kappa h)$.
We choose the MG sketch for two reasons. Firstly, #citet(<agarwal2013mergeable>) showed that the MG sketch is isomorphic to the Space Saving algorithm, and #citet(<mitzenmacher2012hierarchical>) show that the space saving algorithm is optimal for non-private hierarchical heavy hitter estimation.
Thus, if we replace SS with MG in the non private HHH estimation problem, we retain the same optimality results.
Secondly, with the MG sketch we leverage the structure in the output to circumvent the composition bounds due to approximation.
The main bottleneck in approximation algorithms is that the approximated function might have large global sensitivity.
Indeed #citet(<chan2012differentially>) show that the MG sketch has global sensitivity $Delta_G = kappa$.
This implies that if we naively used noise scaled by the sensitivity of the function, the DP error grows as the streaming error drops.
However we are able to leverage the critical observation made by #cite(<lebeda2023better>, supplement: [Lemma 5]), who show that if the global sensitivity of the MG sketch is high, then counts of each counter after processing neighbouring streams are highly correlated.
Just like in @hhh:sec:private_hhh_no_streaming where we made use of monotonicity of residual queries, we will use this correlation to circumvent composition.
Our techniques are related to the more general observation that structure has often been used to bypass composition in the privacy community @dwork2009complexity @dwork2010boosting @kaplan2021sparse @hardt2010geometry.
In summary, to construct our HHH estimation algorithm in the streaming setting, we first modify the #citet(<mitzenmacher2012hierarchical>) HHH algorithm to use the modified MG sketch from #citet(<lebeda2023better>) instead of the SpaceSaving algorithm.
Then we repeatedly leverage the structure of the output to bound the DP error to be independent of the available space.
Note, we cannot avoid the approximation error introduced due to lack of space, regardless of privacy.
In the streaming setting, our contribution is to show that the DP error for HHH is not affected by this approximation parameter $kappa$.
Before describing our algorithm, we first provide an overview of the proof behind how we keep the DP error independent of the number of counters, and why the tricks used in the non-streaming section to make the noise independent of the height of the hierarchy _no longer apply_.

== Technical Overview <hhh:sec:stream_tech_overview>

Our main insight in the non-streaming setting was that the DP noise could be independent of the height of the hierarchy $h$.
Unfortunately, in the streaming setting, this claim no longer holds true.
To fully describe why, we first re-state a lemma by #cite(<lebeda2023better>, supplement: [Lemma 5]) which formally describes the observed outcomes when a MG sketch processes neighbouring input streams.

#lemma(title: [Lebeda & Tětek; Lemma 5, restated])[
Let $X = X' union {x}$.
Let $(cal(T), C) <- sans("MG")(kappa, X)$ and $(cal(T)', C') <- sans("MG")(kappa, X')$ be the output of @hhh:alg:space_saving_insert with inputs $X$ and $X'$.
Then, $|cal(T) union cal(T)'| >= kappa - 2$; for all $x in.not cal(T) union cal(T)'$, $C[x] <= 1$ and $C'[x] <= 1$;
and exactly one of the following is true:

+ $exists i in cal(T)$, such that $C[i] = C'[i] + 1$, and $forall j != i: C[j] = C'[j]$.
+ $forall i in cal(T)':  C[i] = C'[i] - 1$, and $C'[j] = 0$ for $j in.not cal(T)'$.
] <hhh:lemma:post_MG_sketch>

In the lemma above, $(cal(T), C)$ and $(cal(T)', C')$ denote the output of the MG algorithm (@hhh:alg:space_saving_insert) on the two neighbouring streams $X$ and $X'$.
The lemma states that there can be at most 2 elements that are in $cal(T)$, but not in $cal(T)'$, and vice versa.
We will refer to these as _isolated elements_ (this is distinct from the isolated prefixes from the previous section), and if they appear in the final output, an adversary can always tell if an output was generated by $X$ or $X'$.
Furthermore, the count of an isolated element must always be at most 1.
Thus once again, we can use the thresholding trick from stability histograms to suppress isolated elements with high probability.
The threshold for suppression is set a little higher, as there are two isolated elements instead of one.
Along with the above statements, after processing neighbouring data streams, @hhh:lemma:post_MG_sketch also states that the resulting sketches could be in one of two scenarios illustrated in @hhh:fig:two_cases_for_sketches.
In the first scenario, shown in @hhh:fig:two_cases_for_sketches (b), we have two histograms with $kappa$ bins that differ in at most two locations by a count of 1.
All other bins have the exact same values across both sketches.
We can easily release private versions of these histograms by simply applying the Laplace mechanism with suppression of small values.
The other scenario, described by @hhh:fig:two_cases_for_sketches (a), appears more problematic at first glance.
We have that the counts across two outputs $C$ and $C'$ in the two sketches all differ by the _same_ amount across _all_ the bins.
This is undesirable in two ways.
First, now the global sensitivity of the approximated counts is $kappa$, so it appears that the DP noise will need to scale linearly in $kappa$ (which can be a large constant).
Secondly, notice that we can no longer restrict the influence of differing nodes in $cal(T)'$ to a single hierarchical heavy hitter like we did in the illustration given in @hhh:fig:proof_tree.
The neighbouring elements are now spread across all the bins, and they influence _multiple_ hierarchical heavy hitters.
Furthermore, as the MG sketch often under-approximates the true count of an element, we cannot guarantee that we have removed the influence of a neighbouring element higher up in the tree by removing a descendant lower in the tree.
This means we cannot restrict the influence of neighbouring elements and partition the tree like before to avoid paying the privacy loss due to composition for $h$ levels of the hierarchy.
In other words, it seems challenging to circumvent composition bounds due to the height when using the MG sketch.

#figure(
  image("../assets/PostSketch.pdf", width: 60%),
  caption: [The figure above illustrates the implications of @hhh:lemma:post_MG_sketch. There are two possible configurations after processing neighbouring streams. One configuration, depicted by figure (a), is that every count in one sketch is different from the count in the other sketch by one unit in the same direction. The other outcome is that either exactly one counter is different for all counters that are non-zero in both sketches. Additionally, when in configurations depicted by Figure (b), there can be at most 2 elements per sketch that are not in the other sketch. The count of these elements when present is always 1. The second outcome, denoted by figure (b) is identical to the configuration discussed for stability histograms in the previous section, where each sketch has at most a single count that is different.],
) <hhh:fig:two_cases_for_sketches>

Although we cannot remove the dependence on the height of the hierarchy in the streaming setting, inspired by the observations made by #citet(<lebeda2023better>) and #citet(<dwork2009complexity>), we are still able to remove the dependence on $kappa$.
We show that, even in the scenario depicted by @hhh:fig:two_cases_for_sketches (a), the DP noise is actually independent of the number of counters in the sketch.
This might appear unintuitive at first glance, as the global sensitivity is still $kappa$.
To gain intuition towards understanding why, we first review the privacy proof for nodes in $cal(I)_("Active")$ (green and orange nodes in @hhh:fig:proof_tree) in the non-streaming algorithm.
The main observation there was that before we see the inflection node (orange node in @hhh:fig:proof_tree), we could group all the small valued queries for which the output was $bot$, and treat them as _one_ query, thus paying for them only _once_.
We could do so because the event that all of those queries being small is equivalent to saying that the maximum of all the those queries is small.
Given two neighbouring datasets, we might have $t-1$ queries, each with sensitivity 1, and thus a total sensitivity of $t-1$, but the max of these queries is still a single query with sensitivity 1.
Thus, we have a _single_ equivalent query that captures the event described by $t-1$ queries with output $bot$.
A similar reframing also applies to the sketches produced by neighbouring streams.
Observe that despite $kappa$ bins being different in $C$ and $C'$, the direction in which they are different and the amount by which they are different is the same for _all_ bins.
Thus, we have a guarantee that, if one of the bins in $C$ and $C'$ is different, _all_ bins are different, and importantly in the exact _same_ way.
There is actually just one degree of freedom, despite there being $kappa$ different counts to consider.
Once one bin differs by one, _all_ bins differ by one (i.e. the counts are correlated).
In the Above threshold (a single invocation of the SVT algorithm), we looked at the max query, and in this case we can look at any one query (say the first one, which reveals everything about the other ones). The effect is equivalent.
In the proof for @hhh:thm:release_is_dp we formally show how we can handle all $kappa$ counts being different with just one sample of noise, as if we had just a single query.

#block[
*Remark.* #cite(<lebeda2023better>, supplement: [Lemma 6]) make a similar claim to use one sample to cover all bins.
Although the final claim is correct, there is a minor issue in their proof.
In their proof, the authors define the function $g: bb(R) -> bb(R)^k$ such that $g(a) = a 1^k$.
Thus, $g^(-1)(arrow(x))$ is defined only if _all_ coordinates of $arrow(x)$ are the _same_.
@hhh:lemma:post_MG_sketch does not guarantee that all the counts are the same, only that two neighbouring differ by the same amount in the same direction.
However, their proof @lebeda2023better relies on inverting $g^(-1)(arrow(x))$ for general $x in bb(R)^k$, which is undefined.
In our analysis, there is no need to define such a function $g$ and we can obtain our results using the above observations.
]

@hhh:alg:hhh_dp_sketch describes our algorithm for computing hierarchical private heavy hitters.
First, we compute noisy heavy hitters at each level of the hierarchy using @hhh:alg:hhh_private_release.
We show that the output of @hhh:alg:hhh_private_release is private.
Then we conservatively post-process this private output to get our desired result.

#block[
*Remark.* For a fixed level $ell$, @hhh:alg:hhh_private_release is very close to #cite(<lebeda2023better>, supplement: [Algorithm 2]), with an essential alteration.
In the count-release step of the algorithm, we generate a fresh batch of randomness independent of thresholding operation to release approximate counts.
The reason for this is subtle but immediate when viewing the algorithm from the lens of the SVT (where this issue is well documented).
The construction described by #citet(<lebeda2023better>) re-uses the thresholding noise and it is therefore _not_ differentially private.
The intuition for this is the following: If we re-use the noise in the thresholding/release lines, then we reveal partial information about the global sample $gamma_l$ _every_ time we release a noisy count.
With every release, we restrict the possible values $gamma_l$ could take, thereby shrinking the variance of the privacy distribution.
We pay for this shrinkage with a reduced privacy budget, in that the algorithm is now $epsilon'$ private for $epsilon' > epsilon$.
See @hhh:sec:privacy_breakdown for more details about how our privacy proof would break if we re-used noise.
]

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Private Release],
  pseudocode-list(booktabs: true, numbered-title: [Private Release])[
    *Input:* Data stream $X$, Privacy parameters $epsilon$ and $delta$.
    + Construct $h$ sketches $(sans("MG")_1, dots, sans("MG")_h)$ by running @hhh:alg:space_saving_insert for each $x in X$ and every generalisation of $x$.
    + *for* $l in [h, h-1, dots, 1]$ *do*
      + #highlight($gamma_l$) $arrow.l sans("Laplace")((2 h) / epsilon)$
      + Let $(cal(T)_l, C_l) = sans("MG")_l$
      + *for* $i in cal(T)_l$ *do*
        + #highlight($w_i$) $arrow.l sans("Laplace")((4 h) / epsilon)$
        + *if* $C_l [x] + #highlight($gamma_l + w_i$) > 1 + (6 h) / epsilon log(3 h \/ delta)$ *then*
          + $C_l [x] = C_l [x] + #highlight($sans("Laplace")((4 h) / epsilon)$)$
        + *else*
          + $C_l [x] = 0$
        + *end if*
      + *end for*
      + Set $overline(sans("MG")_l) = (cal(T)_l, C_l)$
    + *end for*
    + Output $(overline(sans("MG")_1), dots, overline(sans("MG")_h))$.
  ]
) <hhh:alg:hhh_private_release>

#theorem(title: [Privacy])[
@hhh:alg:hhh_private_release is $(epsilon, delta)$-DP. Full proof deferred to the appendix.
] <hhh:thm:release_is_dp>

#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Final Algorithm],
  pseudocode-list(booktabs: true, numbered-title: [Final HHH-Streaming Algorithm])[
    *Input:* Data $X$, Privacy parameter $epsilon in (0, log n)$, $delta = o(1 \/ n)$, Threshold $tau > 0$, Confidence Parameter $eta in (0, 1\/2)$.
    *Parameters:* Number of counters $kappa$, Height of hierarchy $h$.
    + Run @hhh:alg:hhh_private_release with input $X$, Threshold $tau$, and privacy parameters $(epsilon, delta)$ to get outputs $(overline(sans("MG")_1), dots, overline(sans("MG")_h))$.
    + $Delta_1 = (1 + (4 h log[6 h \/ delta]) / epsilon) + n / (kappa + 1) + ((8 h) / epsilon log[(2 kappa h) / eta])$
    + $Delta_2 = (1 + (4 h log[6 h \/ delta]) / epsilon) + ((8 h) / epsilon log[(2 kappa h) / eta])$
    + *for* $l in [h, h-1, dots, 1]$ *do*
      + Let $(cal(T)_l, C_l) = overline(sans("MG")_l)$
      + *for* $e in cal(T)_l$ *do*
        + *if* $C_l [e] + Delta_1 > tau - Delta_1$ *then*
          + $cal(S) = cal(S) union {e}$
          + $tilde(f)_X (e) = C_l [e]$ #h(1em) (Noisy Estimate)
          + *for* $p in sans("Generalise")(e)$ *do*
            + Let $i = sans("Level")(p)$, $(cal(T)_i, C_i) = sans("MG")_i$
            + *if* $p in cal(T)_i$ *then*
              + $C_i [p] = C_i [p] - (C_l [e] - Delta_2)$ (conservatively remove residual)
            + *end if*
          + *end for*
        + *end if*
      + *end for*
    + *end for*
    + Output $(cal(S), tilde(f)_X (cal(S)))$.
  ]
) <hhh:alg:hhh_dp_sketch>

#corollary(title: [Privacy of Final Algorithm])[
@hhh:alg:hhh_dp_sketch is $(epsilon, delta)$-DP, since it is post-processing the $(epsilon, delta)$-DP output of @hhh:alg:hhh_private_release (by @hhh:thm:post_process).
] <hhh:cor:final_dp>

#theorem(title: [Error])[
For all $p in cal(S)$, we have with probability $1 - eta$,
$ |tilde(f)_X (p) - f_X (p)| <= Delta $
where
$ Delta = (1 + (6 h log(3 h \/ delta)) / epsilon) + n / (kappa + 1) + ((8 h) / epsilon log((2 kappa h) / eta)). $
Full proof deferred to the appendix.
] <hhh:thm:abs_erro_stream>

We note that the dependence on $h$ here is not optimal.
We have used basic composition to show a linear dependence on $h$, in order to keep the development clear.
However, it is possible to show an improved dependence on $sqrt(h)$, by invoking more advanced composition theorems @dwork2014algorithmic @bun2016concentrated.
Since we assume that $h$ is relatively small in practice, we don't expand on this point in this presentation.
Note that as we cannot avoid the composition error due to the height of the hierarchy, we can directly estimate the unconditional frequencies of a node $p$ by looking at the noisy count of $C_(sans("Level")(p))[p]$.
However, this means that there is no advantage to reporting relative error guarantees instead of the absolute error in the streaming case: all prefixes incur noise of the same magnitude.
We leave it open to show whether this gap is provably unavoidable or can be surmounted using different techniques.

#theorem(title: [Coverage])[
For all $p in.not cal(S)$, with probability $1 - eta$, $Residual(p, cal(S)) <= tau - Delta$. Full proof deferred to the appendix.
] <hhh:thm:stream_coverage>
