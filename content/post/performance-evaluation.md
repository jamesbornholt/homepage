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
sciences, computer science experiments tend to be even more non-deterministic
and prone to omitted-variable bias. Computer systems have many moving parts in
both hardware and software, and controlling each of those components is often
next to impossible. Many existing studies have catalogued seemingly innocuous sources of omitted-variable bias.

### Environmental bias

[Mytkowicz et al][todd09] showed a variety of environmental factors that significantly bias the results of compiler experiments.

[bholt]: http://homes.cs.washington.edu/~bholt/
[todd09]: http://www-plan.cs.colorado.edu/klipto/mytkowicz-asplos09.pdf
