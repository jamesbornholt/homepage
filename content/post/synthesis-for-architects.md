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

Jha et al's [*oracle-guided* synthesis][oracle] assumes that you already have an implementation of the program you want to synthesise, which they call the *oracle* program. That's a strong assumption I'll talk more about later, but let's go with it for now. This implementation is the **specification** for oracle-guided synthesis. We treat the oracle as a black box we can execute on arbitrary inputs; we do not need to inspect the oracle's implementation.

We also start with a collection of *test cases*, which are input-output pairs. Notice that because we have an oracle, we can generate a set of test cases by just generating random inputs and asking the oracle for the correct answer for each.

#### Synthesis step

We provide oracle-guided synthesis with a library of *components*, which form the basis of the synthesised programs it considers. The **synthesis** step is going to arrange these components into a program in [static single assignment form][ssa]; in essence, it's going to take all the components, and decide how to connect their inputs and outputs together to form a program. (This formulation disallows loops, so the programs we generate will always be loop-free).

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

#### Starting with an existing program

Oracle-guided synthesis assumes you have an *oracle*, an existing implementation of the program to synthesise. As I mentioned above, we don't actually need to inspect the implementation; we need only treat it as a black box that provides outputs when we supply inputs. But even this seems a little absurd: why synthesise a program we already have? 

The authors use two domains to illustrate why their technique is useful. The first is the traditional suite of bitvector benchmarks from [Hacker's Delight][hackers]. Many synthesis papers use these benchmarks because they illustrate small non-intuitive programs. The suggestion is that programmers will write an implementation of a bitvector manipulation that is simple but inefficient, and the role of program synthesis is to synthesise an optimal program. The second domain is program deobfuscation -- taking an obfuscated program and synthesising a new, simpler program that matches its behaviour.

It's worth noting that [a follow-up paper][loopfree] to this one takes basically the same approach, but instead of requiring an oracle, requires a logical specification of the desired behaviour. 

### Stochastic superoptimisation

Schkufza et al's [*stochastic superoptimisation*][stoke] is a completely different approach to program synthesis that I'll attempt to beat into the CEGIS mold. Again, it assumes you have an existing implementation as the **specification** to compare against. This isn't a problem for them, because as the name suggests, the problem they're tackling is *superoptimisation*: finding the optimal instruction sequence for a given piece of code. Stochastic superoptimisation searches the space of programs to find a new program that matches the original's behaviour but is faster or more efficient. It's the search aspect that makes it a form of program synthesis.

#### Searching the space of programs

What's the simplest way to search the space of programs? Suppose we start with a randomly generated program. To decide which program to try next, we could just randomly mutate one of the instructions in the program. Assuming the mutations satisfy some basic properties, this search will eventually find the optimal program (for example, if the optimal program has an `add` instruction, the mutations obviously must be able to generate an `add` instruction for this to work). But this will probably take a very long time; there's no guidance to decide if we're on the right track, or "near" an answer.

Stochastic superoptimisation uses [Markov-chain Monte Carlo (MCMC) sampling][mcmc] to search the space of programs in a more guided way. Essentially, stochastic superoptimisation defines a cost function that measures how "good" a candidate program is, and uses MCMC (in particular, the [Metropolis algorithm][metropolis]) to sample from programs highly weighted by that function. Rather than searching randomly, the MCMC search is more likely to visit programs with higher cost functions, which correspond to programs nearer to optimal. So long as the search is set up correctly, MCMC provides a fairly weak but sufficient guarantee, that it will eventually visit the optimum program. But empirically, because of the bias in the search, it often quickly discovers correct programs that are almost optimal.

#### Synthesis step

The **synthesis step** of stochastic superoptimisation decides which program *P'* to try next by drawing an MCMC sample based on the candidate program *P*. It proposes *P'* by randomly applying one of a few mutations to *P*:

* changing the opcode of an instruction
* changing an operand of an instruction
* inserting a new random instruction
* swapping two randomly selected instructions
* deleting an existing instruction

The MCMC sampler uses the cost function, which measures how "close" to the target program *P'* is and how fast *P'* is, to decide whether to *accept* the candidate *P'*. A candidate is more likely to be accepted if it is close to the target or very fast. But even programs distant from the target and slow have some probability of being accepted; this ensures we explore novel programs. If the candidate is accepted, we move on to the verification step, and set *P* = *P'* for next time. If not, we repeat this process until a candidate is accepted, and do not change *P* until we find a candidate to accept.

Evaluating the cost function involves executing the candidate program *P'* on a suite of test cases and comparing the results to the correct outputs. The paper counts the number of bits that differ between the two outputs to measure how "close" *P'* is to the target.

#### Verification step

Having accepted a candidate program *P'*, the **verification step** simply passes the candidate and target programs to a verifier to decide if they are equivalent. The paper has a few tricks to make this verification a little more forgiving of, for example, getting the correct result but in a different register. 

The most important trick is that before executing the verifier, which could be slow, stochastic superoptimisation first uses the test cases from the cost function. If any of the test cases fail, we know the candidate can't possibly be the correct program, and so there's no need to call the verifier. Empirically, most bad candidates tend to fail fast on these test cases, and so this trick considerably improves the throughput of the MCMC search.

#### Feedback step

The **feedback step** of stochastic superoptimisation is implicit in the MCMC sampling. We compare new candidate programs *P'* to the previously accepted program *P* to decide whether *P'* is a program we should explore. If *P'* is better than *P* (i.e., has a higher cost function, and so is either faster or closer to the target, or both) we are certain to explore it. Otherwise, there is still some probability of exploring *P'* which depends on how much worse *P'* is.

### Enumerative search

The last synthesis technique I'm going to try to fit into the CEGIS mold is enumerative search. It's a fairly obvious brute force approach with a neat trick, and despite its seeming naiveté, has been used to great effect, for example by Udupa et al in [synthesising distributed systems protocols][transit].

For a **specification** we're going to use a finite set of test cases. Of course, since you can generate test cases given an implementation of the program, it's fine to instead assume an existing implementation like we did with oracle-guided synthesis and stochastic superoptimisation. We also assume we have a grammar of the target language. For our purposes, we'll use a simple grammar that has two operations `add` and `sub`, and two available variables `x` and `y`. The grammar defines expressions over these terms, so for example, `add(x, sub(x, y))` is a program in this grammar. There's no assignment statement.

#### Synthesis step

The key idea of enumerative search is to just brute force search all possible programs. The concrete strategy breaks programs up into depths based on the deepest path in their parse tree. For example, the program that just returns `x` has depth zero, while the program `x+y` has depth 1, and `(x+y)+x` has depth 2.

We **synthesise** candidate programs by starting at depth 0 and enumerating all programs at that depth. In our case, that means the first two candidates are just the two programs `x` and `y`. Once we're done with a depth, we increment and repeat this process. So at depth 1, there are eight candidate programs, which all take the form `operation(a, b)`:

{{% img src="post/synthesis-for-architects/enumerative-1.png" alt="enumerative search level 1" width="50%" %}}

Notice how the possible expressions for `a` and `b` are exactly the programs of depth 0. This is how we do the enumeration: at depth *k*, we explore all programs of the form `operation(a, b)`, where `a` and `b` are any expression of depth at most *k*-1. This dynamic programming search is going to be exponential in the depth *k*: at depth 2, each hole can be filled with one of 8 depth-1 or 2 depth-0 expressions, and so we'll have to explore 2×(8+2)² = 200 programs; at depth 3, we'll have to explore 2×(200+8+2)² = 88,200 programs! We'll rely on the feedback step to try to prune this search space.

#### Verification step

Because we specified the program in terms of test case, the **verification step** is simply going to execute all the test cases and compare the output to the goal. If they match, we're done.

#### Feedback step

The test case output is also the key to the feedback step. The trick is that when trying to fill the holes in programs of depth *k*, we don't need to consider *every* program of depth at most *k*-1. Instead, we need only consider those programs with *distinct* outputs. For example, there's no point considering both `sub(x, x)` and `sub(y, y)` -- they both have the same effect. This insight prunes the search space.

But how do we decide if two programs are distinct? That's where the test cases come in. Because we defined the target program behaviour in terms of the test cases, it actually doesn't matter if two programs are semantically equivalent, but rather only whether they differ *on the test cases*. So to decide if a new program *P* is distinct, we simply compare its test case outputs to those from every other program we've seen so far. If it matches an existing program, there's no point keeping *P*, and so we throw it away.

For example, if every test case has *y* = 0, then `add(x, y)` and `sub(x, y)` are equivalent, even though that's clearly untrue in general. We get to prune a whole bunch of programs that are not semantically equivalent in general, but are equivalent for the set of behaviours we actually care about.

It turns out that this strategy works remarkably well for some problems. When synthesising cache coherence protocols, Udupa et all found that the pruning reduces the search space by nearly a factor of nearly 100× at depth 10. Of course, how well it works on your problem will depend on both the set of behaviours you care about and the set of components you include in the grammar.

### Conclusion

The promise of program synthesis is that programmers can stop telling computers *how* to do things, and focus instead on telling them *what* they want to do. Inductive program synthesis tackles this problem with fairly vague specifications and, although many of the algorithms seem intractable, in practice they work quite well.

Unfortunately, "quite well" in this context means they can synthesise programs with up to around 100 instructions. We're not really close to the dream of synthesising entire applications from scratch. But in many cases, these smaller programs might be exactly what we're after from synthesis -- we can ask the programmer to bolt high-level pieces together, and fill in the details automatically. This is the idea of *sketching*, which prompted the [original CEGIS work][cegis]. It's also an appeal to the [80-20 rule] -- programs spend most of their time in a few small areas of the code, and so synthesis on those small parts can still deliver significant efficiency improvements. 

Hopefully one day soon, you'll be able to tell Siri your awesome new app idea and have it on the App Store the next day.

{{% footnotes %}}
{{% footnote 1 "Sorry, Luis! We mock because we love." %}}
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
[stoke]: http://cs.stanford.edu/people/eschkufz/research/asplos291-schkufza.pdf
[hackers]: http://www.hackersdelight.org/
[loopfree]: http://dl.acm.org/citation.cfm?id=1993506
[mcmc]: http://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo
[metropolis]: http://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm
[transit]: http://dl.acm.org/citation.cfm?id=2462174
[80-20]: http://swreflections.blogspot.com/2013/11/applying-8020-rule-in-software.html
