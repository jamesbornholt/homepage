---
date: 2014-12-15T01:43:43-08:00
draft: true
title: Program Synthesis for Computer Architecture Professors
description: Rather than keep explaining program synthesis to my <a href="https://homes.cs.washington.edu/~luisceze/">architecture-inclined adviser</a>, I wrote about it!
---

Professor [Luis Ceze][luisceze] is an awesome adviser, but he has one well-hidden, shameful secret: his PhD is in *computer architecture*. I'm working on correcting this grave misjudgement by surrounding him with [experts][djg] in [programming languages][emina], but I feel like I must also make my own contribution. To that end, I present part 1 of my condescendingly-named [1,009-part][dragon] series, *Programming Languages for Computer Architecture Professors*. Today, we'll tackle **program synthesis**.

### Synthesis?

Synthesis is one of the hot computer science buzzwords right now, like [big data][], [deep learning][], and [Ke$ha][]. But what is program synthesis?

It's a little odd that the way we program computers is by giving them explicit instructions. Of course, instructions are what computers are good at following, but they're not necessarily what humans are good at writing. Surely it would be more efficient for us to tell the computer *what* we want the program to do, and leave the details of *how* to the computer to figure out. This is like the ultimate abstraction: a programmer who only tells the computer what to do, rather than how, is completely absolved from any implementation details. This is the promise of program synthesis.

That definition is very vague, though; our immediate objective isn't to be able to ask Xcode to "write a Twitter client" or "build a game where I launch cute-yet-oddly-circular birds into solid objects at high velocities" (though the App Store could certainly do with more Twitter clients and Angry Birds clones). The state of the art in program synthesis isn't quite that advanced. Instead, we set out sights considerably lower, but the results still prove useful.

Fully automated program synthesis is a holy grail of programming, so it's no surprise the field is so hot. The promise of program synthesis to automate both the minutiae of programming (who has time to reinvent bit-twiddling hacks?) and the higher-level aspects is irresistible. While doing [a class project][cse507] this past quarter, I needed to implement a few state-of-the-art program synthesis algorithms. Let's talk about how they work!

### Specifying programs

When we talk about program synthesis, we usually mean a process that takes some form of *specification* of what the program should do, and produces a program that satisfies the specification. The notion of a specification is intentionally vague, because it could be one (or more) of a number of things:

* A complete *formal specification* as a formula in some logic, say, [first-order logic][fol]. For example, we might specify a program *P* that adds 2 to its input by the logical formula ∀*x*. *P*(*x*) = *x*+2.
* A set of input/output pairs -- *examples* of what the program should do. So for the program that adds 2 to its input, we might provide a list of pairs like (5, 7), (-3, -1), ....
* *Demonstrations* of how the program should compute its output. This is similar to input/output pairs, but might also provide intermediate steps of the computation between input and output.
* A *reference implementation* to compare against. This seems strange -- why try to synthesise a program we already have an implementation of? -- but will prove useful in some examples I'll discuss later.

### Inductive program synthesis

Before we get to an actual program synthesiser, let's talk about the general framework.

what's the relationship to CEGIS?

two components: synthesiser and verifier (emina sez: angelic & demonic)

what's the key idea? something like the generational hypothesis: an empirical observation that most programs converge to a unique point in the space of programs very quickly

so what do we need to know to define an inductive synthesiser? (a) how to synthesise a program; (b) how to verify it is or isn't the right program; (c) how to provide feedback for the next "guess"

### Oracle-guided synthesis

* Synthesise: from a library of components, build an SSA-form program using the current set of testcases
* Verify: is this the only program that satisfies the testcases?
    * If so, it means we're done with the loop, but still need to verify this is the right program
* Feedback: if not unique, verifier produces an input which distinguishes two of the programs, and we add that input to the testcases by querying the oracle

### Stochastic superoptimisation

We can view stochastic superoptimisation as inductive program synthesis.

* Synthesise: by mutating the last program we tried
* Verify: by testcases and then a verifier
* Feedback: use the last program's cost to decide where to go next (the cost ratio guides the selection of the next program, though non-deterministically)

[luisceze]: http://homes.cs.washington.edu/~luisceze/
[djg]: http://homes.cs.washington.edu/~djg/
[emina]: http://homes.cs.washington.edu/~emina/
[dragon]: http://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools
[fol]: http://en.wikipedia.org/wiki/First-order_logic
[cse507]: http://courses.cs.washington.edu/courses/cse507/14wi/
