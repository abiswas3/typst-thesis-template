#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import "@preview/cetz:0.4.0"
#import cosmos.clouds: *
#import "../commands.typ": *

= Introduction <hhh:sec:introduction>

The task of finding _Heavy Hitters_ (HH), a.k.a. frequent items, in a dataset is one of the most well-studied problems in data science.
The task has been studied under the streaming model of computation @cormode2008finding @cormode2003finding, distributed computation @cheu2021differential, and even through the lens of secure computation @corrigan2017prio.
In this work, we adopt the lens of _differential privacy_ (DP) to study the _Hierarchical Heavy Hitters_ (HHH) problem, introduced by #citet(<cormode2003finding>) as a generalisation of the heavy hitter problem.
The problem of DP-HHH is motivated by the observation that data is often both _hierarchical_ and _confidential_.
Consider checking for evidence of discrimination in mortgage lending decisions, as discussed in #citep(<lee2021algorithmic>).
An analyst is given a database of historical lending decisions and asked to ascertain if a particular demographic has been treated unfairly.
The personal information about loan applicants is inherently hierarchical.
For example, a person's residential address can be divided into street address, postcode, village, city, country, and so on.
As historical data is often difficult to obtain, any given dataset might not include enough applicants from every fine-grained portion of the hierarchy.
However, if we analysed the data at a coarser granularity, we might find a statistically significant number of participants to draw reliable conclusions.
Naturally, whether hierarchical or not, demographic information is considered _highly confidential_.
It is well known that even releasing summary statistics about a population can leak information about individuals in the dataset.
Differential privacy has become the de facto standard for defending against such leakage.
As a result, given a dataset, we wish to output its hierarchical heavy hitters privately.

#figure(
  cetz.canvas(length: 0.52cm, {
    import cetz.draw: *

    let blank = rgb("#f1f5f9")
    let teal = rgb("#0d9488")
    let stroke = rgb("#1e293b")
    let node-w = 0.42
    let node-h = 0.58

    let node(x, y, selected) = {
      let fill = if selected { teal } else { blank }
      rect(
        (x - node-w / 2, y - node-h / 2),
        (x + node-w / 2, y + node-h / 2),
        radius: 0.10,
        fill: fill,
        stroke: (
          paint: if selected { teal.darken(35%) } else { stroke.lighten(40%) },
          thickness: 1pt,
        ),
      )
    }

    let link(a, b) = {
      line(a, b, stroke: (paint: stroke.lighten(40%), thickness: 0.6pt))
    }

    let count-right(x, y, body) = {
      content((x + 0.46, y), text(size: 7.5pt, fill: stroke)[#body], anchor: "west")
    }

    let count-below(x, y, body) = {
      content((x, y - 0.72), text(size: 7.5pt, fill: stroke)[#body], anchor: "north")
    }

    let draw-tree(xoff, title, root-selected, child-selected, leaf-selected, root-count, child-counts, leaf-counts) = {
      let root = (xoff, 5.2)
      let children = ((xoff - 2.7, 3.55), (xoff, 3.55), (xoff + 2.7, 3.55))
      let leaves = (
        (xoff - 3.75, 2.05), (xoff - 2.7, 2.05), (xoff - 1.65, 2.05),
        (xoff - 1.05, 2.05), (xoff, 2.05), (xoff + 1.05, 2.05),
        (xoff + 1.65, 2.05), (xoff + 2.7, 2.05), (xoff + 3.75, 2.05),
      )

      for c in children {
        link(root, c)
      }

      for (i, leaf) in leaves.enumerate() {
        link(children.at(calc.floor(i / 3)), leaf)
      }

      node(..root, root-selected)
      count-right(..root, root-count)

      for (i, c) in children.enumerate() {
        node(..c, child-selected.at(i))
        count-right(..c, child-counts.at(i))
      }

      for (i, leaf) in leaves.enumerate() {
        node(..leaf, leaf-selected.at(i))
        count-below(..leaf, leaf-counts.at(i))
      }

      content((xoff, 0.15), text(size: 8pt, fill: stroke)[#title], anchor: "north")
    }

    draw-tree(
      -5.6,
      [Hierarchical Heavy Hitters],
      false,
      (false, true, true),
      (false, true, false, false, false, false, true, false, false),
      [5],
      ([5], [15], [15]),
      ([2], [20], [3], [5], [5], [5], [45], [7], [8]),
    )

    draw-tree(
      5.6,
      [Heavy Hitters],
      true,
      (true, true, true),
      (false, true, false, false, false, false, true, false, false),
      [100],
      ([25], [15], [60]),
      ([2], [20], [3], [5], [5], [5], [45], [7], [8]),
    )
  }),
  caption: [A dataset of 100 elements over a hierarchy with residual counts (left) and unconditional counts (right).],
) <hhh:fig:why_hhh>

Note that finding hierarchical heavy hitters is _not_ the same as finding heavy hitters at each level in a hierarchy (referred to as counting over trees in #citep(<ghazi2022differentially>)).
Hierarchical heavy hitters, which we formally define later (@hhh:def:hhh), is a generalisation of the heavy hitters problem.
At a high level, apart from telling us _if_ an element is heavy, it also tells us _how_ it is heavy.
HHH allows us to distinguish between an element that is heavy because it has a heavy child (or a few heavy children) and an element that is heavy because it has many light children that are cumulatively heavy.
Furthermore, if we are given the set of (exact) hierarchical heavy hitters of a dataset, we can derive the heavy hitters at each level of the hierarchy.
The converse, however, is not true.
@hhh:fig:why_hhh illustrates this difference with a toy example.
The figure shows a dataset of 100 elements drawn from a hierarchy of height 3.
Each node in the tree corresponds to an element in the hierarchical universe.
The leaf nodes are fully specified elements, while the root node describes the fully generalised element of the hierarchy.
The edges between nodes represent a partial order between elements of the hierarchy (see @hhh:sec:prelims for formal details).
Given a public threshold of #Threshold $= 10$, a node is heavy if its count exceeds #Threshold.
The counts listed next to the nodes on the _right_ tree are the underlined unconditional counts (@hhh:def:absolute_count) of the node in the dataset.
The nodes marked in teal on the right tree are the heavy hitters at each level of the hierarchy.
The nodes marked in teal on the left tree are the hierarchical heavy hitters of the dataset.
The counts listed next to the nodes on the _left_ tree are called underlined residual counts (@hhh:def:cond_count).
The residual count of a node is the count of a node ignoring its heavy children, whereas the unconditional count of a node is just the sum of the counts of its children.
Observe that the root node is _not_ a hierarchical heavy hitter, although its absolute count is greater than the threshold.
The root node is heavy only because it has heavy children, not because it is an aggregation of several light children.
If we were to just see the output of heavy hitters, we would lose this information.

== Related work

=== Streaming HHH
The hierarchical heavy hitter problem was first defined and studied in the streaming setting, as the offline problem is straightforward.
Initial work defined the problem for streams of data drawn from a single hierarchy, and showed upper bounds on the problem, by building streaming heavy hitter summaries of data at each level @cormode2003finding @lin2007separator @mitzenmacher2012hierarchical.
Subsequent work extended the problem to data with multiple hierarchical attributes @cormode2004diamond @cormode2008finding, and showing lower bounds on the space required to solve the problem @hershberger2005space @mitzenmacher2012hierarchical.
In the streaming model, data arrives incrementally, and we assume that the algorithm does not have enough space to store the entire dataset, or enough counters for each element of the data universe.
#citet(<mitzenmacher2012hierarchical>) show that approximating HHH via the Space Saving algorithm (SS) for heavy hitters @metwally2006integrated is optimal in terms of error and space complexity in the streaming setting.

=== Private Counting
Despite its relevance to data analytics, the HHH problem has not been previously studied under differential privacy.
However, there has been much research on simpler non-hierarchical heavy hitter estimation under privacy, in both the non-streaming @balcer2017differential @bassily2017practical @cormode2012differentially @korolova2009releasing @ghosh2009universally, and streaming models @lebeda2023better @chan2012differentially.
In this work, we show that despite this extensive body of work in the non-hierarchical setting, we need new algorithms to privately estimate HHH efficiently in theory and practice.
The most closely related work to ours is concerned with outputting "unconditional counts" in a hierarchy, due to Ghazi et al. @ghazi2022differentially.
As any fully specified element ("leaf") affects the counts for nodes at each level of the hierarchy, we must account for it every time we release a count for a node that is an ancestor of said leaf.
Hence, the DP error scales linearly with the height #Height of the hierarchy when using basic composition, or $sqrt(#Height)$ under advanced composition @dwork2014algorithmic.
#citet(<edmonds2020power>) provide lower bounds showing that such a polynomial dependence on the hierarchy height is unavoidable if we want to estimate just the unconditional counts for every element in the hierarchy#footnote[This is a strictly simpler problem than HHH, which involves estimating conditional counts. Therefore these lower bounds immediately apply to HHH as well.] with _pure_ or _approximate_ differential privacy (see @hhh:sec:relative_error).

#citet(<ghazi2022differentially>) circumvent this dependence on the height of the hierarchy by relaxing the problem to consider _relative_ error in estimating node counts, where the estimation gap for a node scales with the absolute count of the node#footnote[In other words, nodes with large unconditional frequencies are allowed to tolerate more estimation error than nodes with smaller unconditional frequencies.].
Their algorithmic guarantees replace the linear dependence on the height of the hierarchy with a linear dependence of the maximum number of hierarchical heavy hitters in a dataset#footnote[Algorithm 1 of their paper uses the constant $c$, independent of the height of the hierarchy, as an upper bound on the maximum number of hierarchical heavy hitters.].
Although this is an asymptotic improvement, the number of heavy hitters is much larger than the hierarchy height for any practical scenario we can envisage.
Hence the real-world performance will be much worse than the naive baseline of estimating the counts at each level and paying for #Height levels of composition.
Concretely, most real-world datasets are associated with shallow and wide hierarchies.
Consider a dataset of bit strings of size $n=10^6$, and a threshold of $2500$, so there are up to 400 hierarchical heavy hitters.
For this algorithm to improve on the simple baseline, the hierarchy would need to have more than 400 levels, implying over $2^(400)$ elements.

== Our results

=== Non-Streaming Setting

In this work, we show that the relative error for any node when estimating private hierarchical heavy hitters scales by a _much_ smaller constant that is independent of _both_ the height of the hierarchy and the number of hierarchical heavy hitters in the tree.
Our algorithm is simpler than that of #cite(<ghazi2022differentially>, supplement: [Algorithm 1]), and it can be used to solve the more general problem with better error guarantees than prior attempts would imply.
Our algorithm is optimal in the sense that we match the constants in optimal algorithms for DP heavy hitters in the non-hierarchical setting @balcer2017differential, and thus it incurs the lowest error one can hope for in the non-streaming setting.
At a high level, an intuitive explanation is that by targeting relative error instead of absolute error, elements higher up in the hierarchy with larger frequencies can tolerate more DP noise.
This structure proves to be critical for circumventing composition bounds, by allowing us to re-use information about lower regions of the hierarchy, and apply them to higher regions of the hierarchy.
Bounding the absolute error for every node requires us to treat each node independently, therefore destroying the structure we leverage to propose more accurate algorithms.

=== Streaming Setting

In the streaming setting, along with DP error and composition error, we also need to account for the approximation error due to space constraints.
The main issue with streaming algorithms is that although the exact version of the function (exact hierarchical heavy hitters) has low global sensitivity (as counting queries are 1-sensitive), the approximation function can have high global sensitivity.
For instance, the Space Saving (SS) algorithm described by #citet(<mitzenmacher2012hierarchical>) is optimal in the non-private setting, but #citet(<chan2012differentially>) show that the global sensitivity of the approximation function induced by SS scales linearly with the number of counters per sketch (denoted with #NumSketchCounter in this document).
This would imply an error that scales linearly with #NumSketchCounter.
#citet(<lebeda2023better>) improve on this by providing a DP mechanism for non-hierarchical heavy hitters, where the estimation error of the protocol does not rely on global sensitivity.
Inspired by @lebeda2023better, we design algorithms for hierarchical heavy hitters with DP noise whose variance is independent of #NumSketchCounter.
The intuition behind our algorithm is that although the approximation algorithm we use has high sensitivity, the counters in a sketch are highly correlated, with few degrees of freedom.
This structure (correlated counters) can be used to bypass composition bounds typically enforced due to high global sensitivity of the function.
This observation is closely related to why the seminal Sparse Vector Technique algorithm (SVT) by #citet(<dwork2009complexity>) also circumvents composition bounds.
Although the two appear unrelated at first glance, we show that releasing private counts for our sketching algorithm and SVT algorithm are essentially equivalent and use the _same_ underlying theoretical concepts to bypass composition.
More broadly, the message of this work is that _"where we have structure (sparsity, monotonicity, correlation, etc.), we can leverage this structure to circumvent basic or advanced composition bounds"_.
Hierarchies offer structure in that the frequency of elements higher up in the hierarchy is computed using frequencies of elements lower down.
In streams, we show that despite high global sensitivity, we can leverage correlation between counters in a sketch to circumvent composition bounds.
We refer the reader to @hhh:sec:composition for further discussion on the role of structure in circumventing composition.
To summarize:

+ In @hhh:sec:private_hhh_no_streaming, we propose the first known private algorithm for the task of hierarchical heavy hitter estimation. In the non-streaming setting, the relative error of our algorithm is independent of the height of the hierarchy and the number of hierarchical heavy hitters in the dataset. Our constants match the best known constants for private heavy hitter estimation in the non-hierarchical setting. Thus, our algorithm incurs the smallest error one can hope for.

+ In the non-streaming setting, our algorithm can also be used to solve the problem of counting over trees posed by #citet(<ghazi2022differentially>) (described by the figure on the right in @hhh:fig:why_hhh), with better _relative_ error guarantees.

+ In the streaming setting (@hhh:sec:stream), we show that the DP error of our HHH estimation algorithm is independent of the space bound. However, in this setting, the DP error still depends on the height of the hierarchy (which we show is likely unavoidable). Therefore, there is a gap in relative estimation error between the streaming setting and the non-streaming setting under privacy. Despite this gap, for all practical situations, removing the dependence on space is far more critical than the dependence on the height of the hierarchy (as the number of counters is often orders of magnitude larger than the height of the hierarchy).

The rest of the paper is organised as follows.
In @hhh:sec:prelims, we formally introduce the problem of hierarchical heavy hitter estimation and review preliminary results from differential privacy.
In @hhh:sec:private_hhh_no_streaming we describe our solution in the non-streaming setting with unlimited space.
In @hhh:sec:stream, we describe our algorithm in the streaming setting.
We defer the full proofs to the appendices and provide proof sketches in the main body.
