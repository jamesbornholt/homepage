---
date: 2015-01-25T14:36:53-08:00
draft: true
title: Computer Architecture is Not About Gates
description: "I have a misconception that computer architecture is just electrical engineering. Here I set myself straight."
---

Sometimes I feel uncomfortable calling myself a member of [a computer architecture research group][sampa], because I know nothing about electrical engineering.{{% fn 1 %}} In our group's kickoff meeting at the start of this quarter, we gave two-minute [wild and crazy idea][waci] talks. I used this slide, funny to exactly five people in the world, in mine:

{{% img src="post/architecture-gates/half-adders.png" alt="funny to exactly five people" %}}

In my talk I joked that "half adders are the extent of my electrical engineering knowledge", which is fairly accurate; if I tried hard enough I might be able to draw a full adder, but that's about it.

The joke plays well to my academic insecurities. But there's also a serious point: I have a misconception that computer architecture is about hardware. Maybe you have it too.{{% fn 2 %}} In reality, architecture is something far more interesting.

### Abstracting the IBM System/360

<a href="http://en.wikipedia.org/wiki/File:DM_IBM_S360.jpg">{{% img src="post/architecture-gates/system-360.jpg" alt="every computer should have an emergency pull" width="60%" %}}</a>

In a reading group recently, we read [*Architecture of the IBM System/360*][360paper], published in the IBM Journal of Research and Development in 1964. It was one of the very first computer architecture papers -- so new, in fact, that it had to define *architecture* as a footnote to the title:

> The term *architecture* is used here to describe the attributes of a system as seen by the programmer, i.e., the conceptual structure and functional behavior, as distinct from the organization of the data flow and controls, the logical design, and the physical implementation.

This kind of abstraction was a novel idea in 1964. We already had a separation between "programmers" and "engineers" by this point, but it was driven by a desire for generality. Rather than build a computer that can solve only one problem (like the [Bombe][]), it was more effective to build a computer that could be reprogrammed to do different tasks (like the [ENIAC][]). But even the reprogrammable computer required programmers to understand its intricate electrical details. The paper heralds the looming trend of abstraction:

> In the last few years, many computer architects had realized, usually implicitly, that logical structure (as seen by the programmer) and physical structure (as seen by the engineer) are quite different.

It's this semantic gap that defines computer architecture. What we do is not really about physical structure (that's what electrical engineers are for). Nor is it about high-level logical structure (that's what programming language research is all about). Computer architecture is really about how these layers of abstraction interact with each other.

### Software and Hardware and Everything In Between

That's not to say there's no place for electrical engineering or programming languages know-how in computer architecture. The best computer architects I know are often experts in one of those layers of the stack. But the first thing I love about computer architecture is how broad the field is. What sets those best computer architects apart from the rest is not their deep knowledge of one layer of abstraction, but their intuition for *all* the layers.

I've been known to make fun of [how boring memory models are](consistency). But memory consistency models are a great example of how computer architecture mediates a fundamental tension between software and hardware. On the software side, we know we want programming models that are as simple as possible, and Leslie Lamport's [sequential consistency][sc] gift to the world is one of the simplest models you can imagine. On the hardware side, we'd really like to offer those simple models, but they make everything incredibly slow, with lots of wires or something (I *did* say I don't understand electrical engineering).

So we compromise, and design relaxed memory models that give reasonable programming models while enabling high-performance hardware. Getting these models right requires understanding both the software and hardware sides of the spectrum; designing in ignorance of one or the other just takes us back to where we started. This is why the [recent PipeCheck paper][pipecheck] is a real tour de force: it takes the best ideas of formal verification (it's a [Coq][] paper published at [MICRO][]!) and applies them to a detailed model of the underlying hardware. I think this is the very essence of good computer architecture research: attacking hard questions with techniques from across the system stack.

Crossing this hardware-software divide only becomes more crucial as the traditional founts of scaling and performance gains become more barren. The line in the sand we've chosen as the divide between "software" and "hardware" is a little arbitrary, and doesn't really suit modern applications. (With any luck, [Adrian][], [Luis][], and I will get to talk more about the relationship between hardware and software at [SNAPL][] in May.)

### The Intersection of Design and Implementation

The second thing I love about computer architecture is that many of its problems require innovation in both design and implementation.

Good computer architecture research exercises the scientific method just as hard as any other science (all jokes aside about [computer science not being a real science][benchmarking]). We formulate hypotheses about how computers work, make predictions based on those hypotheses, and run experiments to test those predictions and inform new hypotheses. Some of my favourite computer architecture papers are purely about this kind of quantitative exploration; I think we can all appreciate good experimental design and execution.

But computer architecture is ultimately about interfaces. Architecture tells us how layers of abstraction interact with each other. And abstraction is mostly about *humans*. So in addition to a hard quantitative side, computer architecture has a soft design-centric side, missing from most hard sciences. Something we don't recognise enough as a community is the virtue of good *design*, regardless of the resulting hard numbers.

For example, a recent paper tries to decide [whether RISC is better than CISC][risccisc]. This is an incredibly difficult question to answer quantitatively: there aren't really any directly comparable RISC and CISC architectures, so comparing the dominant CISC (x86) to the dominant RISC (ARM) requires very careful experiment design. The authors do a good job of that design (though they drop the ball in a few places I've [discussed previously][benchmarking]). Fundamentally, though, I think this paper misses the point. The debate about RISC and CISC is not really one of quantitative differences, which the paper shows to be mostly non-existent. The question is one of design: which style of design is more successful as an *interface for humans* to work with? We are the ones who write the compilers, and we are the ones who design the ISAs; the true question is which school of design most helps *us*?

This isn't an argument to do away with quantitative evaluation in computer architecture. Numbers are critical evidence, but evidence is all they are. What I love about computer architecture is that the most successful research provides both quantitative evidence *and* a convincing design: "this is something I can see myself actually doing" is a pretty good barometer for quality research.

### Electric Feel

I still feel bad about my poor knowledge of electrical engineering. I wish our PhD program had a "Wires and Gates for Dummies" course. But I'm also comforted by the knowledge that computer architecture is about more than just gates -- it's about how abstractions are built. Those are the problems I care about, and I'm here to stay.

{{% footnotes %}}
{{% footnote 1 %}}I'm also uncomfortable being a member of our [programming languages group](https://plse.cs.washington.edu), because I don't read Greek and my favourite programming language is neither functional nor formally verified.{{% /footnote %}}
{{% footnote 2 %}}Alternative post title: "Yes, I'm a computer architect. No, I can't help with your [FPGA](http://en.wikipedia.org/wiki/Field-programmable_gate_array)."{{% /footnote %}}
{{% /footnotes %}}

[sampa]: https://sampa.cs.washington.edu
[waci]: http://asplos15.bilkent.edu.tr/waci.html
[360paper]: http://www.eecs.berkeley.edu/~culler/courses/cs252-s05/papers/amdahl.pdf
[bombe]: http://en.wikipedia.org/wiki/Bombe
[eniac]: http://en.wikipedia.org/wiki/ENIAC
[consistency]: http://homes.cs.washington.edu/~bornholt/post/cache-coherence.html
[sc]: http://en.wikipedia.org/wiki/Sequential_consistency
[pipecheck]: https://www.princeton.edu/~dlustig/dlustig_MICRO14.pdf
[coq]: https://coq.inria.fr/
[micro]: http://www.microarch.org/micro47/
[adrian]: https://homes.cs.washington.edu/~asampson/
[luis]: https://homes.cs.washington.edy/~luisceze/
[snapl]: http://snapl.org
[benchmarking]: http://homes.cs.washington.edu/~bornholt/post/performance-evaluation.html
[risccisc]: http://research.cs.wisc.edu/vertical/papers/2013/hpca13-isa-power-struggles.pdf
