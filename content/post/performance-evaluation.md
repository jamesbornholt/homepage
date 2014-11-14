---
date: 2014-11-06T21:30:28-08:00
draft: true
title: Adventures in Performance Evaluation
description: In this week's <a href="https://sampa.cs.washington.edu">Sampa</a> group meeting I spoke about pitfalls in performance evaluation.
---

Everyone knows computer science is not a real science. As [my officemate][bholt] put it to me, you know it's
a fake science if they had to put science in the name. But what did we do to
deserve such a bad scientific reputation? One thing that the fields dear to my
heart (architecture and programming languages) do poorly is quantifying their
results. In the real sciences, researchers slave over experimental designs
and quantitative methods, because experiments are often vast and expensive to run. In contrast, our field is the wild west.

This is doubly concerning when you realise that, compared to most other
sciences, computer science experiments tend to be among the most non-deterministic
and prone to omitted-variable bias. Computer systems have many moving parts in
both hardware and software, and controlling each of those components is often
next to impossible. 

### Omitted-variable bias

#### Environmental bias

[Mytkowicz et al][todd09] showed a variety of environmental factors that significantly bias the results of compiler experiments. If you do any kind of computer systems research, this paper should be absolutely terrifying to you. Their first result shows that *linking order* can significantly bias the results of a benchmark (here, `perlbench` from [SPECcpu2006][spec2006]):

![perlbench linking order][perlbench-linking]

Here on the *x*-axis are two fixed linking orders (the SPECcpu default and an alphabetical order) and 31 random orders. The performance variation is 15% and, most worryingly, straddles 1.0 -- so picking the wrong linking order can tell you your compiler is worse when it's actually better! This effect is not unique to one benchmark; here are the results over a variety of SPECcpu2006 programs:

![SPECcpu2006 linking order][speccpu-linking]

I never really pay attention to the order I put things in my Makefiles, as long as everything compiles, but these results might make me start paying attention.

Even more terrifying than linking order is a result in this paper that shows how the size of your UNIX environment variables biases performance. Here's `perlbench` again, with different environment sizes on the *x*-axis:

![perlbench environment size][perlbench-envsize]

The scary part here is that even innocuous things like changing your username can change the size of your UNIX environment. If I run an experiment on a machine logged in as `james`, then [my advisor][djg] runs the same experiment on the same machine logged in as `thagrossmanator9000`, there's every risk of running afoul of this source of bias.

What should we do about these sources of bias? It's probably not practical to expect researchers to randomise or control all these omitted variables, not least because it's hard to control what you don't know. [Some cool work][stabilizer] from UMass randomises code, stack, and heap layouts at runtime to try to control for some of these biases, but it's hard (impossible?) to know whether we caught every possible source of bias.

#### Uncontrolled variables

I think there's an important distinction between variables we don't immediately *expect* to cause bias (like linking order or environment size) and variables we *would* expect to cause bias but just don't control well. 

In the garbage collection world, heap size was one of these variables for a very long time. Researchers often ran their garbage collector comparisons at a single heap size, ignoring the time-space trade-off that garbage collection explores. Only in the last decade or so have we started seeing graphs like this one in garbage collection papers (this one from :

![time-space trade-off][heapsize]

[bholt]: http://homes.cs.washington.edu/~bholt/
[todd09]: http://www-plan.cs.colorado.edu/klipto/mytkowicz-asplos09.pdf
[spec2006]: http://www.spec.org/cpu2006/
[perlbench-linking]: img/post/performance-evaluation/perlbench-linking.png
[speccpu-linking]: img/post/performance-evaluation/speccpu-linking.png
[perlbench-envsize]: img/post/performance-evaluation/perlbench-envsize.png
[djg]: http://homes.cs.washington.edu/~djg/
[stabilizer]: http://people.cs.umass.edu/~emery/pubs/stabilizer-asplos13.pdf
[heapsize]: img/post/performance-evaluation/heapsize.png
