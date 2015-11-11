---
date: 2015-08-31T09:00:00-07:00
draft: true
title: "Memory Consistency Models: Seeing Things in Order is the Hardest Problem in Computer Science"
description: "Computer architecture's solution is everybody else's problem."
---

There are, of course, 
[only two hard things in computer science][fowler]: 
cache invalidation, naming things, and off-by-one errors.
But there is another hard problem 
lurking amongst the tall weeds of computer science:
*seeing things in order*.
Whether it be [web-scale sorting algorithms][bubblesort],
[high-performance un-sorting algorithms][fisheryates],
or [messages in distributed systems][distributed],
seeing things in order is a challenge for the ages.

Today, I want to focus on one example of an ordering problem:
*memory consistency models*.
There's a vast corpus of resources on memory consistency models,
but much of it consists of either [slides][lucia] from [someone's class][kayvon],
or [thorough tomes][synthca] written for experts.
My goal is to produce a short primer;
for the details, you should certainly consult these excellent sources.

## Making threads agree

Consistency models deal with 
how multiple threads (or workers, or nodes, or replicas, etc.)
see the world.
Consider this simple program, 
running two threads,
and where `A` and `B` are initially both `0`:

{{% img src="post/ordering/wb.png" alt="two threads running in parallel" width="45%" %}}

To understand what this program can output,
we should think about the order in which its events can happen.
Intuitively, there are two obvious orders in which this program could run:

* `(1)` → `(2)` → `(3)` → `(4)`: The first thread runs both its events before the second thread, and so the program prints `01`.
* `(3)` → `(4)` → `(1)` → `(2)`: The second thread runs both its events before the first thread. The program still prints `01`.

There are also some less obvious orders, where the instructions are interleaved with each other:

* `(1)` → `(3)` → `(2)` → `(4)`: The first instruction in each thread runs before the second instruction in either thread, printing `11`.
* `(1)` → `(3)` → `(4)` → `(2)`: The first instruction from the first thread runs, then both instructions from the second thread, then the second instruction from the first thread. The program still prints `11`.
* and a few others that have the same effect.

### Things that shouldn't happen

Intuitively, it shouldn't be possible for this program to print `00`. For line `(2)` to print `0`, we have to print `B` before line `(3)` writes a `1` to it. We can represent this graphically with an edge:

{{% img src="post/ordering/wb1.png" alt="two threads running in parallel" width="45%" %}}

An edge from operation `x` to operation `y` says that `x` must *happen before* `y` to get the behavior we're interested in. Similarly, for line `(4)` to print `0`, that print must happen before line `(1)` writes a `1` to `A`, so let's add that to the graph:

{{% img src="post/ordering/wb2.png" alt="two threads running in parallel" width="45%" %}}

And finally, of course, each thread's events should happen in order---`(1)` before `(2)`, and `(3)` before `(4)`---because that's what we expect from an imperative program. So let's add those edges too:

{{% img src="post/ordering/wb3.png" alt="two threads running in parallel" width="45%" %}}

But now we have a problem. If we start at `(1)`, and follow the edges---to `(2)`, then `(3)`, then `(4)`, then... `(1)` again! Remember that the edges are saying which events must happen before other events. So if we start at `(1)`, and end up back at `(1)` again, the graph is saying that `(1)` must *happen before itself*! Barring a very concerning advance in physics, this is unlikely to be possible.

Since this execution would require time-warping, we can conclude that this program can't print `00`. Think of it as a [proof by contradiction][raa]: suppose this program *could* print `00`. Then all the ordering rules we just showed must hold. But those rules lead to a contradiction (`(1)` happening before itself). So the assumption is false.

### Sequential consistency: an intuitive model of parallelism

Architects and programming language designers believe the rules we just explored to be *intuitive* to programmers. The idea is that multiple threads running in parallel are manipulating a single main memory, and so everything must happen in order. There's no notion that two events can occur "at the same time", because they are all accessing a single main memory.

Note that this rule says nothing about *what* order the events happen in---just that they happen in *some* order. The other part of this intuitive model is that events happen in *program order*: the events in a single thread happen in the order in which they were written. This is what programmers expect: all sorts of bad things would start happening if my programs were allowed to launch their missiles before checking that the key was turned.

Together, these two rules---a single main memory, and program order---define *sequential consistency*. [Defining sequential consistency][sc] is one of the many achievements that earned [Leslie Lamport][lamport] the [Turing award][turing] in 2013.{{% fn 1 %}}

Sequential consistency is our first example of a *memory consistency model*. A memory consistency model (which we often just call a "memory model") defines the allowed orderings of multiple threads on a multiprocessor. For example, on the program above, sequential consistency *forbids* any ordering that results in printing `00`, but *allows* some orderings that print `01` and `11`.

## The problem with sequential consistency

One nice way to think about sequential consistency is as a switch. On each cycle, the switch selects a thread to run, and runs its next event completely. This model preserves the rules of sequential consistency: events are accessing a single main memory, and so happen in order; and by always running the *next* event from a selected thread, each thread's events happen in program order.

The problem with this model is that it's *terribly, disastrously slow*. We can only run a single instruction at a time, so we've lost most of the benefit of having multiple threads run in parallel. Worse, we have to wait for each instruction to finish before we can start the next one---no more instructions can run until the current instruction's effects become *visible* to every other thread.

### Coherence

Sometimes, this requirement to wait makes sense: consider the case where two threads both want to write to a variable `A` that another thread wants to read:

{{% img src="post/ordering/coherence.png" alt="coherence" width="70%" %}}

If we give up on the idea of a single main memory, to allow `(1)` and `(2)` to run in parallel, it's suddenly unclear which value of `A` event `(3)` should read. The single main memory guarantees that there will always be a "winner": a single last write to each variable. Without this guarantee, after both `(1)` and `(2)` happen, some threads could see `A` to be `1` while others see it as `2`.

We call this guarantee *coherence*, and it says that all writes *to the same location* are seen in the same order by every thread. It doesn't prescribe the actual order (either `(1)` or `(2)` could happen first), but does require that everyone sees the same "winner".

## Relaxed memory models

Outside of coherence, the requirement for a single main memory is often unnecessary. Consider this example again:

{{% img src="post/ordering/wb.png" alt="two threads running in parallel" width="45%" %}}

There's no reason why performing event `(2)` (a read from `B`) needs to wait until event `(1)` (a write to `A`) completes. They don't interfere with each other at all, and so should be allowed to run in parallel. Event `(1)` is particularly slow because it's a write. With a single view of memory, we can't run `(2)` until `(1)` has become visible to every other thread. On a modern CPU, that's a very expensive operation due to the cache hierarchy: 

{{% img src="post/ordering/wb-cores.png" alt="two threads running in parallel" width="45%" %}}

The only shared memory between the two cores is all the way back at the L3 cache, which often takes upwards of 90 cycles to access.

### Total store ordering (TSO)

Rather than waiting for the write `(1)` to become visible, we could instead place it into a *write buffer* and then begin `(2)` immediately:

{{% img src="post/ordering/wb-wb.png" alt="two threads running in parallel" width="45%" %}}

Then `(2)` could start immediately after putting `(1)` into the write buffer, rather than waiting for it to reach the L3 cache. At some time in the future, the cache hierarchy will pull the write from the write buffer and propagate it through the caches so that it becomes visible to other threads.

The write buffer is nice because it preserves single-threaded behavior. For example, consider this simple single-threaded program:

{{% img src="post/ordering/wb-local.png" alt="write buffers preserve local behavior" width="45%" %}}

The read in `(2)` needs to see the value written by `(1)` for this program to preserve the expected single-threaded behavior. Write `(1)` has not yet gone to memory---it's sitting in core 1's write buffer---so if read `(2)` just looks to memory, it's going to get an old value. But because it's running on the same CPU, the read can instead just inspect the write buffer directly, see that it contains a write to the location it's reading, and use that value instead. So even with a write buffer, this program correctly prints `1`.

A popular memory model that allows write buffering is called *total store ordering* (TSO).


{{% footnotes %}}
{{% footnote 1 %}}Though Lamport was originally writing about multiprocessors, his later work moved toward distributed systems. In the modern distributed systems context, "sequential consistency" means something slightly different (and weaker) to what architects intend. What architects call "sequential consistency" is what distributed systems folks would call "linearizability".{{% /footnote %}}
{{% /footnotes %}}


[fowler]: http://martinfowler.com/bliki/TwoHardThings.html
[bubblesort]: https://en.wikipedia.org/wiki/Bubble_sort
[fisheryates]: https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
[distributed]: https://twitter.com/mathiasverraes/status/632260618599403520
[lucia]: https://github.com/blucia0a/Talks/blob/master/Other/ConsistencySlides.pdf?raw=true
[kayvon]: http://15418.courses.cs.cmu.edu/spring2015/lecture/consistency
[synthca]: http://www.morganclaypool.com/doi/abs/10.2200/S00346ED1V01Y201104CAC016
[raa]: https://en.wikipedia.org/wiki/Proof_by_contradiction
[sc]: http://research.microsoft.com/en-us/um/people/lamport/pubs/multi.pdf
[lamport]: http://www.lamport.org/
[turing]: http://amturing.acm.org/
