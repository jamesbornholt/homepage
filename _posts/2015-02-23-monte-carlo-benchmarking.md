---
date: 2015-02-23T09:30:25-08:00
draft: false
title: Monte Carlo Benchmarking
excerpt: <a href="http://snapl.org">SNAPL</a> rejected my crazy abstract, so I'm sharing my craziness with the world instead.
---

I submitted both a paper and an abstract to [SNAPL][], a ["new kind of PL conference, focused on big-picture questions rather than concrete technical results"][pl-enthusiast]. I'm pretty excited that the paper [Adrian Sampson][adrian] and I wrote with our advisor [Luis Ceze][luis] was accepted, along with two other papers from the kick-ass [UW PLSE group][plse]. But my one-page abstract was just *too crazy* for SNAPL. Bruised but not defeated, I present my completely insane abstract about random benchmarking.

## Monte Carlo Benchmarking

We all like decisive claims in our papers: "Mipso[^mipso] speeds up programs
by 2×". Strong claims put stakes in the ground for our readers: if you
do what we say, these are the results you'll see. Performance
measurement is similar to opinion polling: journalists would like to say
"Obama will [win/lose] the election", but evidence from opinion polls
is not so definitive.
To generalise from opinion poll to conclusion, we have to consider both
*how* the question was asked, and to *whom*. The same is true
in performance measurement.

For computer systems, the *how* means measuring the *right thing* in
the *right way*, and is comparatively well studied. There is extensive work
on [measuring systems without bias][myblogpost]. For
example, Curtsinger and Berger's [Stabilizer][] controls variables such as
code and data layout, using randomisation to mitigate alignment and
cache biases. Work continues to encourage more researchers
to embrace sound methodology, but we are making progress.

Less well understood is of *whom* we ask questions. For opinion
polling the challenge is clear -- a sample of 100 young males from San Francisco
does not generalise to the entire voting population.
For computer systems, the *whom* is the set of programs we measure. 
Today, these programs are usually a benchmark suite.

### Benchmark Suites
Benchmark suites give a common basis for evaluating our work, and for comparing
our work to prior results. But
benchmark suites do not help defend a claim that our work
"speeds up programs by 2×". The problem is that the space of programs
is very large, and we do not know whether the set of benchmark
programs fairly reflects the diverse possibilities. In opinion polling,
this would be like lacking demographic data; for example, if
a random sample of the US population was 70% Californian, we wouldn't know if
that was a fair reflection of the US.
We are making strides in [broadening the diversity of benchmark programs][dacapo]. 

I argue that we should go to the next level
and generate *random benchmarks*. Random benchmarks best reflect the space
of all possible programs, and so provide the right evidence (by the law of
large numbers) for strong claims about overall speedups. Generated the right way,
random benchmarks also enable more nuanced and intuitive evaluations by reweighting
the benchmarks.

### Random Benchmarks as Synthesis 
"Random benchmarks" seem a little crazy, because the space of programs is so
large, but work on program synthesis should give us hope.

[Stochastic superoptimisation][stoke] optimises segments of code by
performing stochastic search over all programs up to a fixed
length. The search algorithm is MCMC -- it *samples*
random programs, guided by a cost function that encodes each
program's correctness (distance to the target function being optimised) and performance.

We can generate benchmarks with stochastic superoptimisation to estimate
expected speedup for an arbitrary program.
Let *X* be a random variable for the speedup our fictional Mipso system creates.
We can approximate the *expected speedup* E<sub>*P*</sub>[*X*]
over the space *P* of all programs by Monte Carlo integration.
Stochastic superoptimisation draws random samples from
*P* that we need, with a simple uniform cost function.
For each sampled program *p* we measure its speedup
*x<sub>p</sub>*. By the law of large numbers, the sample average *s* = Σ *x<sub>p</sub>* / N$
estimates E<sub>*P*</sub>[*X*], with the accuracy improving as N → ∞.
The central limit theorem gives
confidence intervals for the estimate. Random benchmarks
make strong claims about the average over *all* programs, whereas benchmark
suites only allow claims about the average over the suite itself.

### The Right Level of Randomness
We must choose the target language whose
components we will generate randomly. Stochastic superoptimisation
randomises individual x86 instructions in short programs
(≈ 50). This scope may not
expose interesting macro behaviour. We could work at higher levels, as with compiler
fuzzers, or [language models learned from real code][slm].

At the other extreme, we could randomise over *programs*:
randomly download programs from GitHub to use as benchmarks.

### Weighted Randomisation
Stochastic superoptimisation with a uniform cost function is naive.
If we have a program *P*, and another *P'* which is *P* with a no-op appended,
should *P* and *P'* get equal weight when measuring performance? The cost
function should use heuristics to avoid similar programs
(this is the *opposite* of stochastic superoptimisation, which
gives higher weight to *closer* programs).

In fact, the cost function is a powerful and underexplored benchmarking abstraction.
Should we weight programs by how many people use them? A 5% speedup in *libc*'s quicksort
is more useful to the world than a 5%
speedup in my CS 101 project, but a uniform cost function weights them equally.

We could monitor live application clusters to determine which segments of code
are hot (like a profiler), and build random benchmarks weighted by the frequency
of code segment execution.

### Random Benchmarks Already Exist!
Some fields already embrace random benchmarks. For example, the [SAT Competition][sat]
includes a random benchmark category alongside real
application benchmarks. Just as random benchmarks do not
supplant application benchmarks in SAT, neither should they do so in our work.
Benchmark suites expose particular interesting behaviours.
For example in Java, poor performance on
SPECjvm98's *mpegaudio* benchmark likely indicates degraded mutator
performance, since that benchmark does little to no garbage collection.

### Conclusion
It's worth reflecting on whether benchmark
suites help us reach our research goals. Monte Carlo benchmarks are
an extreme idea to re-emphasise this question.
They give us the data to make strong claims that benchmark
suites alone cannot defend.

[^mipso]: A fictional system I made up; apologies if it already exists!

[snapl]: http://snapl.org/2015/
[pl-enthusiast]: http://www.pl-enthusiast.net/2015/01/01/snapl-new-kind-pl-conference/
[adrian]: https://homes.cs.washington.edu/~asampson/
[luis]: http://homes.cs.washington.edu/~luisceze/
[plse]: http://plse.cs.washington.edu
[myblogpost]: http://homes.cs.washington.edu/~bornholt/post/performance-evaluation.html
[stabilizer]: http://plasma.cs.umass.edu/emery/stabilizer.html
[dacapo]: http://portal.acm.org/citation.cfm?doid=1167473.1167488
[stoke]: http://cs.stanford.edu/people/eschkufz/research/asplos291-schkufza.pdf
[slm]: http://www.cs.technion.ac.il/~yahave/papers/pldi14-statistical.pdf
[sat]: https://helda.helsinki.fi/bitstream/handle/10138/135571/sc2014_proceedings.pdf?sequence=1
