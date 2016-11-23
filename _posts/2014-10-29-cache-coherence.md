---
date: "2014-10-29T11:41:23-07:00"
title: "My love [for cache coherence] is as a fever, longing still"
excerpt: "This week for assigned readings in <a href='http://cs.uw.edu/548'>our architecture class</a>, we read about cache coherence. I love cache coherence and wrote about why."
---

I really love cache coherence. It sits atop the pyramid of
abstraction-preserving techniques that enable compilers to be awful at
optimisation and yet still make my 100,000 lines of PHP code run fast. In my
dream world, software would understand the cache hierarchy intimately, like a
naval navigator understands the stars, and cache coherence would be unnecessary
because compilers would perfectly arrange memory accesses (and instruction
scheduling, and ...). 

Unfortunately, compilers are distressingly atrocious,
and so it falls to hardware to preserve the outdated, rigid, overly complex
abstraction of memory, to save compiler writers from themselves. Compilers
should free us from the shackles of the memory abstraction, shield us from the
yoke of increasingly parallel systems, and empower us to build ever more
disruptive applications at scales we can scarcely imagine today. Until compilers
get better, however, cache coherence is here to stay. It is at least some small
comfort to know that Martin, Hill, and Sorin have shown that cache coherence
will continue to scale as we keep building computer systems that do not live up
to their full potential.
