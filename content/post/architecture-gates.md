---
date: 2015-01-25T14:36:53-08:00
draft: true
title: Computer Architecture is Not About Gates
description: "I have a misperception that computer architecture is just electrical engineering. Here I set myself straight."
---

Sometimes I feel uncomfortable calling myself a member of [a computer architecture research group][sampa], because I know nothing about electrical engineering (or as I prefer to call it, "how stuff actually works"). In our group's kickoff meeting at the start of this quarter, we gave two-minute [wild and crazy idea][waci] talks. I used this slide, funny to exactly five people in the world, in mine:

{{% img src="post/architecture-gates/half-adders.png" alt="funny to exactly five people" %}}

In my talk I joked that "half adders are the extent of my electrical engineering knowledge", which is pretty much true -- if I tried hard enough I might be able to draw a full adder too. **blah blah something** 

### Abstracting the IBM System/360

In a reading group recently, we read [*Architecture of the IBM System/360*][360paper], published in the IBM Journal of Research and Development in 1964. It was one of the very first computer architecture papers -- so new, in fact, that it had to define *architecture* as a footnote to the title:

> The term *architecture* is used here to describe the attributes of a system as seen by the programmer, i.e., the conceptual structure and functional behavior, as distinct from the organization of the data flow and controls, the logical design, and the physical implementation.

This kind of abstraction was a novel idea in 1964. We already had a separation between "programmers" and "engineers" by this point, but it was driven by a desire for generality. Rather than build a computer that can solve only one problem (like the [Bombe][]), it was more effective to build a computer that could be reprogrammed to do different tasks (like the [ENIAC][]). But even the reprogrammable computer required programmers to understand its intricate electrical details. The paper heralds the looming trend of abstraction:

> In the last few years, many computer architects had realized, usually implicitly, that logical structure (as seen by the programmer) and physical structure (as seen by the engineer) are quite different.

It's this abstraction space that modern computer architects inhabit.

### Software and Hardware and Everything In Between

There are two things I love about computer architecture. The first is how broad the field is. **yada yada software/hardware** the best computer architects i know have intuition for the entire system stack

digital abstractions serve us well, but are expensive. scaling coming to an end -- harbingers of doom? 

### The Intersection of Design and Implementation

The second thing I love about computer architecture is that many of its problems require innovation in both design and implementation. 

good computer architecture works the scientific method just as hard as any other science -- hypothesis, experiment

but fundamentally computer architecture is about interfaces, because computers are about humans

risc vs cisc -- hpca paper -- misses the point -- it's a design question -- fuzzy (not a science?)

crazy race logic idea -- incredible hardware, but how to expose it?

[sampa]: https://sampa.cs.washington.edu
[waci]: http://asplos15.bilkent.edu.tr/waci.html
[360paper]: http://www.eecs.berkeley.edu/~culler/courses/cs252-s05/papers/amdahl.pdf
[bombe]: http://en.wikipedia.org/wiki/Bombe
[eniac]: http://en.wikipedia.org/wiki/ENIAC
