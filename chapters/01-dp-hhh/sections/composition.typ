#import "@local/random-walks:0.4.1": *
#import "@preview/equate:0.3.2": equate
#import "@preview/lovelace:0.3.0": *
#import cosmos.clouds: *
#import "../commands.typ": *

== Composition and Structure <hhh:sec:composition>

Differential Privacy was initially motivated by the study of counting queries, and heavy hitter estimation can be seen as post processing of private release of counting queries.
The privacy community has studied extensively the composition of privacy parameters when dealing with _arbitrary_ counting queries.
From basic composition we know that the maximum DP error of $q$ invocations of the Laplace mechanism scales $O(1 \/ epsilon dot q log[q])$.
#citet(<steinke2015between>) show that we can save the $log q$ factor by exploiting the structure of correlated noise used for DP, and have error scale by $O(q \/ epsilon)$.
Of course we could also use advanced composition @dwork2010boosting on top of this to further reduce the error to $O(1 \/ epsilon dot sqrt(q log[1 \/ delta]))$.
#citet(<kairouz2015composition>) show an exact characterisation of the best privacy parameters that can be guaranteed when composing many $(epsilon, delta)$-differentially private mechanisms.
Unfortunately computing these parameters for arbitrary queries with different privacy parameters is $\#sans("P")$-complete @murtagh2015complexity.
While the early work was focused on arbitrary counting queries, there has been considerable work in exploiting structure in queries to obtain better error than basic or advanced composition.
#citet(<dwork2009complexity>) proposed the Above Threshold algorithm and showed that one can group similar queries together, and replace them with a single query to pay for many queries just once.
This insight has led to multiple constructions of highly accurate DP algorithms that would have been impractical if we considered basic or advanced composition @chen2015privacy @bun2017make @dwork2015preserving @nissim2016locating.
#citet(<kaplan2021sparse>) identified that for certain distribution of queries, the composition of the above threshold algorithm could be further improved, by observing that not all large queries include the neighbouring element.
#citet(<dong2023better>) show how to bypass composition for special class of conjunctive queries.
We direct the reader to the chapter by #citet(<steinke2022composition>) for a detailed survey on the role of composition in differential privacy.
Despite an enormous body of work on counting queries and composition, the question of hierarchical counting with privacy has remained unexplored.
In this work, we show that one can use similar tricks to the above work to exploit the structure of a hierarchy, and get highly accurate algorithms, that are not possible with general purpose techniques.
