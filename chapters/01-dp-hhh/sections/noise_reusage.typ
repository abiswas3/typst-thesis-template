#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import cosmos.clouds: *
#import "../commands.typ": *

== A Note About Re-using Random Samples <hhh:sec:privacy_breakdown>

In this section we describe how the privacy proof analysis breaks down if we re-use the same random samples for thresholding, and outputting the counts.
Borrowing notation from the proof of @hhh:thm:release_is_dp, if we used fresh randomness then we can go from
$ Pr_(arrow(w), gamma)[C + #highlight($gamma 1^kappa + arrow(w)$) = arrow(y)]
  &= Pr_gamma [C + #highlight($gamma 1^kappa$) + arrow(w) = arrow(y) | arrow(w)] Pr[#highlight($arrow(w)$)] $
to
$ &= Pr[#highlight($arrow(w)$)] product_(i=1)^kappa Pr_gamma [C[i] + #highlight($gamma$) + w_i = y_i | w_i] $
without any issues.
The noisy released count of $C[i]$ is independent of the thresholding operation, and the proof holds.

On the other hand, if we reused noise then the second equation has further constraints.
Consider the event that all noisy counters are above the threshold (this is the worst case, where we reveal maximal information about $gamma$), and let $X_i = C[i] + #highlight($gamma$) + w_i$ for $i in [kappa]$. Then assuming we release counts in lexicographical order, we have

$ Pr_(arrow(w), gamma) [C + #highlight($gamma 1^kappa + arrow(w)$) = arrow(y)]
  &= Pr[#highlight($arrow(w)$)] product_(i=1)^kappa Pr_gamma [#highlight($X_i$) = y_i | arrow(w) and_(j<i) X_j = tilde(C[j]) and_(j<i) X_j >= tau]. $

Each release of a noisy count puts a constraint on the possible values of $gamma$.
Thus, we are no longer able to just use the pdf of the Laplace distribution to upper bound the ratios as we did in our proof (because the privacy distribution has changed to a truncated version of Laplace distribution).
Viewing the same algorithm with the SVT lens, #cite(<lyu2016understanding>, supplement: [Page 5, Algorithm 3]) argue how not using a fresh batch of randomness is _not_ differentially private by showing how a constraint on the value of $gamma$ needs to be ignored to complete the privacy proof (equation 11 on Page 5).
This issue was originally pointed out by #cite(<zhang2016privtree>, supplement: [Appendix A]) where they show that re-using randomness puts additional constraints on the support of the randomness, which results in the variance of the privacy distribution to shrink.
To make up for this shrinkage, they show that the scale of the noise distribution would need to be linear with the number of queries.
This destroys any benefit to using SVT in the first place.
