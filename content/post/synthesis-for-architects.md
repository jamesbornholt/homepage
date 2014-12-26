---
date: 2014-12-15T01:43:43-08:00
draft: true
title: Program Synthesis for Computer Architecture Professors
description: Rather than keep explaining program synthesis to my <a href="https://homes.cs.washington.edu/~luisceze/">architecture-inclined adviser</a>, I wrote about it!
---

Professor [Luis Ceze][luisceze] is an awesome adviser, but he has one well-hidden, shameful secret: his PhD is in *computer architecture*. I'm working on correcting this grave misjudgement by surrounding him with [experts][djg] in [programming languages][emina], but I feel like I must also make my own contribution. To that end, I present part 1 of my condescendingly-named [1,009-part][dragon] series, *Programming Languages for Computer Architecture Professors*. Today, we'll tackle **program synthesis**.{{% fn 1 %}}

### Synthesis?

Synthesis is one of the hot computer science buzzwords right now, like [deep learning][], [big data][], and [Ke$ha][]. But what is program synthesis?

It's a little odd that the way we program computers is by giving them explicit instructions. Of course, instructions are what computers are good at following, but they're not necessarily what humans are good at writing. Surely it would be more efficient for us to tell the computer *what* we want the program to do, and leave the details of *how* to the computer to figure out. It's the ultimate abstraction: a programmer who only tells the computer what they want, rather than how to do it, is completely absolved from any implementation details. This is the promise of program synthesis.

That definition is very vague, though; our immediate objective isn't to be able to ask Xcode to "write a Twitter client" or "build a game where I launch cute-yet-oddly-circular birds into solid objects at high velocities" (though the App Store could certainly do with more Twitter clients and Angry Birds clones). The state of the art in program synthesis isn't quite that advanced. Instead, we set our sights considerably lower, but the results still prove useful.

Fully automated program synthesis is a holy grail of programming, so it's no surprise the field is so hot. The promise of program synthesis to automate both the minutiae of programming (who has time to reinvent bit-twiddling hacks?) and the higher-level aspects is irresistible. While doing [a class project][cse507] this past quarter, I needed to implement a few state-of-the-art program synthesis algorithms. Let's talk about how they work!

### Specifying programs

When we talk about program synthesis, we usually mean a process that takes some form of *specification* of what the program should do, and produces a program that satisfies the specification. The notion of a specification is intentionally vague, because it could be one (or more) of a number of things:

* A complete *formal specification* as a formula in some logic, say, [first-order logic][fol]. For example, we might specify that we want the program *P* to add 2 to its input by the logical formula ∀*x*. *P*(*x*) = *x*+2. Many programs *P* satisfy this specification, including the obvious one that just computes *x*+2, but also the one that computes *x*+4-2 (ignoring overflow).
* A set of input/output pairs -- *examples* of what the program should do. So for the program that adds 2 to its input, we might provide a list of pairs like (5, 7), (-3, -1), ....
* *Demonstrations* of how the program should compute its output. This is similar to input/output pairs, but might also provide intermediate steps of the computation between input and output.
* A *reference implementation* to compare against. This seems strange -- why try to synthesise a program we already have an implementation of? -- but will prove useful in some examples I'll discuss later.

A complete formal specification lends itself to a style of *deductive* program synthesis, where we try to deduce an implementation based on the specification and a set of logical axioms. For example, the [Denali superoptimiser][denali] takes a logical specification and an axiomatisation of the instruction set, and explores every possible way to implement the specification. While this sounds great in theory, it depends on having a complete axiomatisation of the target language and a complete formal specification, both of which may be difficult to obtain.

In contrast, *inductive* program synthesis allows a less formal specification and, rather than making logical deductions directly from that specification, applies some iterative refinement technique to find an implementation. The iterative approach has the benefit of flexibility in specification, but can run into significant scaling problems. Since I'm most interested in the relaxed types of specifications, I'll focus on inductive program synthesis.

### Inductive program synthesis

The specific flavour of inductive synthesis I'm going to talk about is called [counterexample-guided inductive synthesis][cegis] (CEGIS). The idea is to have two parts working hand-in-hand in a loop:

{{% img src="post/synthesis-for-architects/cegis-loop.png" alt="the CEGIS loop" %}}

We start with some specification of the desired program. A *synthesiser* produces a candidate program that might satisfy the specification, and then a *verifier* decides whether that candidate does satisfy the specification. If so, we're done. If not, the verifier closes the loop by providing some sort of *feedback* to the synthesiser to use when it produces future candidate programs. It's called "counterexample-guided" because this feedback is traditionally a *counterexample* -- a new input on which the candidate program didn't satisfy the specification.

We can fit a number of different techniques into this template. The axes we have to play with are:

+ how to **specify** the desired behaviour
+ how to **synthesise** candidate programs
+ how to **verify** a candidate program against the specification
+ how to provide **feedback** for future candidates

Notice that so far we've said nothing about whether the CEGIS loop ever terminates, and if so, how many trips around the loop we have to make. Of course the answer to these questions depends on how we fill each of the holes above. But in general, one of the strengths of CEGIS techniques is their empirical tendency to require only very few trips around the loop, even though the space of programs is incredibly large.

I'm going to describe three very different inductive program synthesis techniques that fit into this general CEGIS mold.

### Oracle-guided synthesis

Jha et al's [*oracle-guided* synthesis][oracle] assumes that you already have an implementation of the program you want to synthesise, which they call the *oracle* program. That's a strong assumption I'll talk more about later, but let's go with it for now. This implementation is the **specification** for oracle-guided synthesis. We also start with a collection of *test cases*, which are input-output pairs. Notice that because we have an oracle, we can generate a set of test cases by just generating random inputs and asking the oracle for the correct answer.

#### Synthesis step

We provide oracle-guided synthesis with a library of *components*, which form the basis of the synthesised programs it considers. The **synthesis** step is going to arrange these components into a program in [static single assignment form][ssa]; in essence, it's going to take all the components, and decide how to connect their inputs and outputs together to form a program.

For example, here is a library of three components -- two adds and a square root -- and a possible way to connect them together:

{{% img src="post/synthesis-for-architects/oracle-components.png" alt="oracle-guided synthesis strings components together" %}}

The program those connections implement is in SSA form:

    program(x, y):
        o1 = add(x, y)
        o2 = add(o1, y)
        o3 = sqrt(o1)
        return o3

Notice that we have two `add` components that are identical; the SSA form simply connects each component together, so if we want the final program to use two additions, we must supply at least two `add` components. Notice also that `o2` is dead code -- its output is unused. This is fine, and is what prevents us from having to decide in advance exactly how many of each component the final program will use. Unused components will be dead code, and so the inputs we decide to use for those unused components are irrelevant.

The key to the synthesis step is that the test cases provide constraints on how the components can be linked together correctly. We use an SMT solver to solve for the links between each component such that the program satisfies all the test cases in the collection. If there is no solution, then no program that uses only these components can implement the oracle -- the components are insufficient.

#### Verification step

If there is a solution, we pass the candidate program to the **verify** step. Remember that the candidate program satisfies all the test cases in the existing collection. The verify step is going to use an SMT solver to answer a subtle question:

> Does there exist *another* program P', different from the candidate program P, that also satisfies all the test cases in the existing collection, but on some other input *z* disagrees with the candidate program P?

Let's break this one down a bit. We have a set of test case inputs. We have an oracle program *O*. We have a candidate program *P*. On all the test case inputs, the programs *O* and *P* are equal. What we're asking the verifier for now is a *new* test case *z* and a *new* program *P'*, so that for the input *z*, *P* and *P'* produce different outputs. We're not asking for anything about *O*. In particular, it might be the case that *P* and *P'*  *both* produce wrong answers for input *z*; all that matters to the verifier is that they produce *different* answers.

For example, here's how it might work for a collection of two cases with the same components we saw above:

{{% img src="post/synthesis-for-architects/oracle-table.png" alt="oracle-guided synthesis test cases" width="70%" %}}

We're trying to synthesise the program `sqrt(x+y)`. The only test cases we have are (0,0) and (1,0). The synthesiser gave us a as a candidate *P* the program `sqrt(x)+y`, which satisfies both test cases since it agrees with the oracle on both. We asked the verifier to produce two things: a new program *P'* and a new test case *z*. In this case, it was successful. It produced a new program `x+y` and a new test case (4,5). Remember that the synthesiser is allowed to produce dead code, and so doesn't have to use the square root component if it doesn't want to. On this new test case (4,5), the candidate *P* and the new program *P'* disagree: sqrt(4)+5 = 7, while 4+5 = 9. In fact in this case, *both* programs are wrong, since the oracle's output for the new test case is sqrt(4+5) = 3.

#### Feedback step

The **feedback** step is going to exploit the new test case generated by the verifier. It asks the oracle *O* what the *correct* output is for that new test case, and adds the result to the collection of test cases that the synthesiser will use in the next trip around the loop. 

In the example, that next trip around the loop will be the last: the only way to use two adds and a square root to satisfy the now three test cases is the program `sqrt(x+y)`. The verifier therefore won't be able to produce a new program that agrees with *P* on the test cases but is different to *P*, and so we are done. 

To be completely correct, Jha et al note that we must also have some kind of *validation oracle*, which we consult after finishing the CEGIS loop to make sure the final program is actually the right one. This is necessary because the verification step doesn't actually consider the target program specification at all. While the program the loop produces is the only possible one that uses the components to produce the test cases seen in the loop, it might be that the components were actually insufficient, and we just got lucky by not finding a test case demonstrating the insufficiency before we found a unique program.

### Stochastic superoptimisation

We can view stochastic superoptimisation as inductive program synthesis.

* Synthesise: by mutating the last program we tried
* Verify: by testcases and then a verifier
* Feedback: use the last program's cost to decide where to go next (the cost ratio guides the selection of the next program, though non-deterministically)

### Enumerative search

ala TRANSIT

* Synthesise: enumerates every possible program of size *k*
* Verify: execute all the testcases on the program
* Feedback: keep the program in a table if it's unique, to be used when doing *k*+1 

{{% footnotes %}}
{{% footnote 1 "Blah blah" %}}
{{% /footnotes %}}

[luisceze]: http://homes.cs.washington.edu/~luisceze/
[djg]: http://homes.cs.washington.edu/~djg/
[emina]: http://homes.cs.washington.edu/~emina/
[dragon]: http://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools
[deep learning]: http://www.digitalstrategyconsulting.com/netimperative/news/google%20ai1.jpg
[big data]: http://www.adrants.com/images/sxswcats_bigdatacruncher.jpg
[Ke$ha]: http://i.dailymail.co.uk/i/pix/2012/08/30/article-2195779-14BE2A44000005DC-690_468x625.jpg
[fol]: http://en.wikipedia.org/wiki/First-order_logic
[cse507]: http://courses.cs.washington.edu/courses/cse507/14wi/
[denali]: http://dl.acm.org/citation.cfm?id=512566
[cegis]: http://dl.acm.org/citation.cfm?id=1168907
[oracle]: http://www.eecs.berkeley.edu/~sseshia/pubdir/synth-icse10.pdf
[ssa]: http://en.wikipedia.org/wiki/Static_single_assignment_form
