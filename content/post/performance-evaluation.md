---
date: 2014-11-17T12:00:00-08:00
draft: false
title: How Not to Measure Computer Systems
description: In a recent <a href="https://sampa.cs.washington.edu">Sampa</a> group meeting, I spoke about the many pitfalls in measuring computer system performance.
---

Everyone knows computer science is not a real science. As [my officemate][bholt] put it to me, you know it's
a fake science if they had to put science in the name. But what did we do to
deserve such a bad scientific reputation? One thing that the fields dear to my
heart (architecture and programming languages) do poorly is quantifying their
results. In the real sciences, researchers slave over experimental designs
and quantitative methods, because experiments are often vast and expensive to run. In contrast, our field is the wild west.

This is doubly concerning when you realise that, compared to other
sciences, computer science experiments tend to be among the most non-deterministic
and prone to omitted-variable bias. Computer systems have many moving parts in
both hardware and software, researchers are unlikely to have a complete understanding of every part in those systems, and controlling each of those components is often
next to impossible. 

### Omitted-variable bias

#### Environmental bias

[Mytkowicz et al][todd09] showed a variety of environmental factors that significantly bias the results of compiler experiments. If you do any kind of computer systems research, this paper should be absolutely terrifying to you. Their first result shows that *linking order* can significantly bias the results of a benchmark (here, `perlbench` from [SPECcpu2006][spec2006]):

{{% img src="post/performance-evaluation/perlbench-linking.png" alt="perlbench linking order" %}}

Here on the *x*-axis are two fixed linking orders (the SPECcpu default and an alphabetical order) and 31 random orders. The performance variation is 15% and, most worryingly, straddles 1.0 -- so picking the wrong linking order can tell you your compiler is worse when it's actually better! This effect is not unique to one benchmark; here are the results over a variety of SPECcpu2006 programs:

{{% img src="post/performance-evaluation/speccpu-linking.png" alt="SPECcpu2006 linking order" %}}

I never really pay attention to the order I put things in my Makefiles, as long as everything compiles, but these results might make me start paying attention.

Even more terrifying than linking order is a result in this paper that shows how the size of your UNIX environment variables biases performance. Here's `perlbench` again, with different environment sizes on the *x*-axis:

{{% img src="post/performance-evaluation/perlbench-envsize.png" alt="perlbench environment size" %}}

The scary part here is that even innocuous things like changing your username can change the size of your UNIX environment. If I run an experiment on a machine logged in as `james`, then [my advisor][djg] runs the same experiment with the same binaries on the same machine logged in as `thagrossmanator9000`, there's every risk of running afoul of this source of bias.

What should we do about these sources of bias? It's probably not practical to expect researchers to randomise or control all these omitted variables, not least because it's hard to control what you don't know. [Some cool work][stabilizer] from UMass randomises code, stack, and heap layouts at runtime to try to control for some of these biases, but it's hard (impossible?) to know whether we caught every possible source of bias.

#### Uncontrolled variables

I think there's an important distinction between variables we don't immediately *expect* to cause bias (like linking order or environment size) and variables we *would* expect to cause bias but just don't control well. 

In the garbage collection world, heap size was one of these variables for a very long time. Researchers often ran their garbage collector comparisons at a single heap size, ignoring the time-space trade-off that garbage collection explores. Only in the last decade or so have garbage collector papers started showing graphs like this one, from [*Wake Up and Smell the Coffee: Evaluation Methodology for the 21st Century*][dacapo-cacm] (an excellent paper you should certainly read):

{{% img src="post/performance-evaluation/heapsize.png" alt="time-space trade-off" width="60%" %}}

This graph shows that we could have gamed our results to show either mark-sweep or semi-space as the "best" garbage collector by being judicious in our choice of heap sizes. (Of course, it turns out both collectors are pretty bad, but that's another story.) 
[//]: <> (Notice that the *x*-axis here is relative to a "minimum" heap size. We usually compute this axis by running each benchmark in our suite at progressively smaller heap sizes until it reliably crashes with an out of memory error. In theory, this threshold is close to the [working set][workingset] of the benchmark, but in practice there is some minor variation due to different collector strategies.)

Charts like this one are very dangerous if you don't understand what they actually measure. If you're one of the six people in the world who care about garbage collection, you might have read [*Why mobile web apps are slow*][crawford], which tries to use results from [a fantastic paper][gcvsmalloc] by [Matthew Hertz][hertzm] and [Emery Berger][emery] to claim that garbage collection couldn't possibly work. The article uses a graph like the one above to defend its thesis that garbage collection is impossibly slow in small heaps. But it neglects to consider that (a) the paper compares against an explicit memory management oracle, which is probably much more precise in its deallocations than regular programmers; and (b) the collectors in the paper were mostly out of date in 2005 when it was written, and certainly are all out of date now ([Vitaly Mikheev compares this][bubblesort] to using bubble sort to argue that sorting is slow). As always, it's easy to lie with statistics.

### Compiler bugs

When it comes to benchmarking, we're usually happy to trust the compiler. For example, we would usually assume that compiling a system twice should yield two binaries with the same performance characteristics, even if we don't have [deterministic builds][deterministic] to guarantee that the binaries are byte-for-byte equivalent. Unfortunately, our trust is often misplaced.

In 2012, I was working on some experiments with [Jikes RVM][jikesrvm], a Java virtual machine. At one point, I thought it would be clever to build the VM ten times and run performance experiments on all ten binaries. Here are the results from those ten binaries on the `_228_jack` benchmark from SPECjvm98:

{{% img src="post/performance-evaluation/build-variance.png" alt="build performance variation" %}}

These supposedly identical builds vary in performance by up to 7%! If you've ever compiled an old system and a new system to compare the two, and the quantum of the difference was in this range, results like this mean you can't really be sure whether you saw a true difference or a build artefact.

This particular result turned out to be a bug in Jikes RVM's implementation of [Pettis-Hansen code reordering][pettis-hansen], an old technique for profile-guided optimisation of code layout at the basic block level. I [fixed the bug][rvm963], but it lurked in Jikes for over ten years before we noticed it.

### Bad benchmarks

The performance evaluation world is also plagued by bad benchmarks. You might have noticed that every browser vendor now has their own JavaScript benchmark suite, and claims that theirs is the most neutral, and that it's just a coincidence that their browser wins on their benchmark suite. The reality is that benchmarks are tragically easy to game.

Cliff Click gave a [fantastic presentation][click] about the art of Java benchmarking in 2009, and highlighted just how many benchmark suites are completely bogus. In the research community, benchmark suites are in a sorry state. For managed languages, most researchers still run SPECjvm98, which is now 16 years old and was released only three years after Java. It's hard to argue that SPECjvm98 benchmarks bear any relevance to modern Java or modern computer systems. Likewise, many architecture researchers appear to still be wedded to SPECcpu2000, which is now 14 years old. Again, it's hard to argue that these benchmarks are still relevant to today's problems.

Even if you choose a good benchmark suite, it's often tempting to drop outliers or benchmarks that don't run the right way. For example, [a recent HPCA paper][hpca13] used SPECcpu2006 benchmarks to compare ARM and x86. They had trouble running some benchmarks, so only ran "10 of 17 [floating-point] benchmarks". But then they found that some of those 10 were outliers, and dropped them from the results, leaving only 5 of the original 17 floating-point benchmarks.

The problem with subsetting benchmarks in this way is that you ignore important behaviour. Benchmark suites are supposed to reflect the space of possible programs, and by subsetting the set of benchmarks, you (unwittingly) bias your results towards certain regions of that space. To make this argument concrete, [Perez&nbsp;et&nbsp;al][perez04] found that when comparing different cache optimisations, subsetting the benchmarks could create many different "best" optimisations, depending on which benchmarks are included:

{{% img src="post/performance-evaluation/subsetting.png" alt="subsetting benchmarks" %}}

This graph says that even if we drop just a few benchmarks from the 26 in the suite, we can create two or more possible "best" systems. If we go so far as to drop 12 benchmarks, as the HPCA paper does, there are 7 possible "best" systems out of 12 being tested. This is not to suggest that the authors gamed their results in any way. Rather, the point is that dropping benchmarks from your comparison creates bias.

We should also be careful when creating new benchmarks. For example, the same HPCA paper uses the [lighttpd web server][lighttpd] as a server benchmark. But the benchmark completes in just 47 milliseconds on a modern desktop CPU. This means the benchmark is likely only measuring the start-up and tear-down time of the web server, rather than the actual work whose performance we care about. I doubt there are many production users of lighttpd who are restarting their web server process 20 times per second.

### Conclusions

What should we take from all these results, apart from a deep feeling of sadness and despair for computer "science"? I think part of the problem is that we are chronically afraid of running "big" experiments, because the tools we use aren't equipped to do so efficiently. Most researchers I've met tend to rebuild their infrastructure over and over again, writing new scripts to parse, tabulate and plot their results for every experiment. This approach clearly doesn't scale.

We should be investing more heavily in infrastructure to support our computer systems research. We're lucky to get funding to [build hardware infrastructure][raijin] for our experiments, but that doesn't seem to extend to building software for actually *using* this infrastructure effectively. Part of my undergraduate research was to build [plotty][], a web application that managed the output of most of our group's experiments, ingesting raw output from benchmarks and outputting (arguably nice-looking) graphs and tables:

{{% img src="post/performance-evaluation/plotty.png" alt="plotty plots things" %}}

Plotty saves us from having to reimplement common analyses over and over again, and protects us from the bugs that crop up when doing so (can you remember, off the top of your head, how to use [scipy's *t* distribution][scipy-t] for a hypothesis test?). It works well for our small group, and helps us collaborate. I think infrastructure like this is increasingly important.

Measuring modern computer systems requires clever and thoughtful experiment design, careful execution, and delicate, large-scale analysis. But remember that measurement is ultimately just a way of quantifying the real problem: are our systems improving? The sooner we accept that measurement is getting harder, and that our existing strategies aren't good enough, the sooner we can start convincingly solving the real problems.

[bholt]: http://homes.cs.washington.edu/~bholt/
[todd09]: http://www-plan.cs.colorado.edu/klipto/mytkowicz-asplos09.pdf
[spec2006]: http://www.spec.org/cpu2006/
[djg]: http://homes.cs.washington.edu/~djg/
[stabilizer]: http://people.cs.umass.edu/~emery/pubs/stabilizer-asplos13.pdf
[dacapo-cacm]: http://users.cecs.anu.edu.au/~steveb/downloads/pdf/dacapo-cacm-2008.pdf
[workingset]: http://en.wikipedia.org/wiki/Working_set
[crawford]: http://sealedabstract.com/rants/why-mobile-web-apps-are-slow/
[gcvsmalloc]: http://people.cs.umass.edu/~emery/pubs/gcvsmalloc.pdf
[hertzm]: http://www-cs.canisius.edu/~hertzm/
[emery]: http://emeryberger.com/
[arc]: http://clang.llvm.org/docs/AutomaticReferenceCounting.html
[bubblesort]: http://www.excelsior-usa.com/blog/java/5plus-garbage-collectors/
[deterministic]: http://www.conifersystems.com/2008/10/17/build-determinism/
[jikesrvm]: http://jikesrvm.org
[pettis-hansen]: http://dl.acm.org/citation.cfm?id=93550
[rvm963]: http://jira.codehaus.org/browse/RVM-963
[click]: http://www.azulsystems.com/events/javaone_2009/session/2009_J1_Benchmark.pdf
[hpca13]: http://research.cs.wisc.edu/vertical/papers/2013/hpca13-isa-power-struggles.pdf
[perez04]: http://dl.acm.org/citation.cfm?id=1038930
[lighttpd]: http://www.lighttpd.net/
[raijin]: http://news.anu.edu.au/2012/11/13/nci-supercomputer-best-in-australia-24th-in-world-2/
[plotty]: https://github.com/jamesbornholt/plotty
[scipy-t]: http://docs.scipy.org/doc/scipy-0.14.0/reference/generated/scipy.stats.t.html
