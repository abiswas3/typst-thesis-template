#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import cosmos.clouds: *
#import "../commands.typ": *

== Greater Privacy For Larger Groups <hhh:sec:relative_error>

As discussed earlier, we only bound the relative error of approximating the unconditional frequency of any prefix.
As pointed out by #cite(<ghazi2022differentially>, supplement: [Page 2]), if we instead wanted to upper bound the worst case absolute error, then it is known that the error _must_ scale linearly with the height of the hierarchy.
The problem of estimating private counts in a tree can be reformulated as releasing a _linear query_ of the form $A arrow(x)$ privately, where $arrow(x)$ is a vector of unconditional counts for all leaves in the hierarchy, and then finding heavy hitters post processing.
The matrix $A in {0,1}^(|cal(H)| times |cal(H)|)$ is an adjacency matrix representation of the tree that represents if one node is a parent of another or not.
Releasing linear queries privately has been exhaustively studied in the privacy community @zhao2022differentially @edmonds2020power @dwork2007price @hardt2010geometry.
#citet(<edmonds2020power>) provide lower bounds for the absolute error of linear queries under pure and approximate differential privacy.
They show that even when considering $(epsilon, delta)$-DP, the absolute error for any private linear query algorithm scales $norm(A)_oo = Theta(h)$ (which is the same as just releasing the entire tree privately with Laplace noise).
Remember, we are able to circumvent composition by leveraging the structure of a hierarchy.
Requiring the error of every estimate at every level to be bounded by the same constant destroys this structure.
We cannot use information gained lower down the hierarchy to make useful claims about elements higher in the hierarchy.
We need to treat each level independently as we want the noise for each node to be independent.
Thus the advantage of our algorithm, and that of #cite(<ghazi2022differentially>, supplement: [Algorithm 1]), is that we can re-use information from earlier queries while still preserving privacy, paying for absolute error instead.
A second advantage to considering relative error is that it is the more practical notion of error.
This was also observed by #citet(<DPorg-open-problem-better-privacy-guarantees-for-larger-groups>), who posted as an open problem the task of finding algorithms that allow larger groups to have more privacy than smaller groups.
When dealing with hierarchies, nodes higher up in the tree by definition can be estimated by counts lower in the tree (via partitions or hierarchical heavy hitters) — and this information is public knowledge.
So we would like to utitlise this when designing algorithms.
Consider the situation where the exact count of a node is $10^6$.
If we incur an absolute error of $100$ units when estimating the count of a node, we do not expect that to affect the final social decision associated with this private statistic.
However, when the exact answer is $99$, say, and we incur an error of $100$ units, such a large error in estimation is unacceptable.

#para[Relationship To Counting Over Trees:] The estimation error from @hhh:thm:coverage can be used to obtain better results in practice for #cite(<ghazi2022differentially>, supplement: [Definition 1.4]) for the simpler problem of estimating unconditional frequencies with constant relative error.
Note the main difference between our result and that of #citet(<ghazi2022differentially>) is that they add noise with scale $O(c \/ epsilon)$ to estimate the count of any node, regardless of the distribution of heavy hitters#footnote[Remember $c$ is an upper bound on the total number of hierarchical heavy hitters.].
In our case, the relative error is independent of both the height and the number of hierarchical heavy hitters.
Furthermore, our algorithm is simpler to define. In #cite(<ghazi2022differentially>, supplement: [Algorithm 3]), the authors use a geometric progression of decreasing $tau$'s, and repeatedly apply #cite(<ghazi2022differentially>, supplement: [Algorithm 1]) on these thresholds to get the relative error guarantee.
It is not clear how to set these thresholds for practical algorithms on real-world datasets, and the constants are larger than the height of any hierarchical domain in practice.
