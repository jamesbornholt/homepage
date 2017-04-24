---
date: 2016-08-28T18:32:31-07:00
draft: true
title: Building your own Program Synthesizer
excerpt: Building a program synthesis tool, to automatically generate programs from specifications, is easier than you might think. We'll use [Rosette](http://emina.github.io/rosette/) to write a simple synthesizer in 20 lines of code.
---

In an [earlier post][synthpost], we saw an overview of *program synthesis* algorithms that automatically generate a program to implement a desired specification. But while these algorithms are an exciting and evolving field of research, you don't need to implement them yourself. Today, we'll see how to build program synthesizers using existing tools.

### Getting started with Rosette

There are a few excellent frameworks for program synthesis. The original is [Sketch][], which offers a Java-ish language equipped with synthesis features. There's also the [syntax-guided synthesis language][sygus], which offers a common interface to several different synthesis engines.

For this post, we're going to use [Rosette][], which adds synthesis and verification support to the [Racket][] programming language. The nice thing about Rosette is that it extends Racket---itself a full-featured programming language---in an intuitive way, so that most existing operations "just work" when used in synthesis and verification.

> **Following along**: the code for this post is available on GitHub. If you'd like to follow along, you'll need to [install Racket][racketdl] and then [Rosette][rosettedl]. Then you'll be able to run Racket programs either with the DrRacket IDE or the `racket` command-line interpreter.

#### Programming with constraints

Rosette's key feature is programming with *constraints*. Rather than a program in which all variables have known values, a Rosette program has some *unknown* variables, and their values are determined by constraints.

This idea sounds a little abstract, so let's see an example:

{% highlight racket %}
#lang rosette/safe

(define (add2 x)
  (+ x 2))

(define-symbolic y integer?)
(add2 y)
{% endhighlight %}

We've defined a function `add2`, and passed it as input a "symbolic" variable `y`. A symbolic variable is one whose value is unknown. The `integer?` annotation tells Rosette that `y` has type integer (we'll see more types later).

But how can we compute `(add2 y)` if the value of `y` is unknown? Rosette creates a *symbolic representation* of what `add2` should do, and returns this representation from `(add2 y)`:

    (+ y 2)

You can think of this return value as a kind of function: once you know a value of `y`, you can figure out what `(add2 y)` would return by substituting that value into this representation.

#### Symbolic representations
These symbolic representations are very powerful, and Rosette can produce them for a very large subset of Racket code. Here's another example:

{% highlight racket %}
(define (absv x)
  (if (< x 0) (- x) x))
  
(absv y)
{% endhighlight %}

Now we've defined an absolute value function: if the input `x` is negative (`(< x 0)` is true), then return `-x`, otherwise return `x`. (The `(if ...)` form is similar to the ternary `a ? b : c` expression you might know from C, Java, etc -- `(if cond then else)` returns `then` if `cond` is true, or `else` otherwise.)

So, what should `(absv y)` return, if `y` is still unknown? Rosette produces this symbolic representation:

    (ite (< y 0) (- y) y)

This representation captures the intuitive notion of `absv`: if `y` is negative, it would return `(- y)`, otherwise it would return `y`. (`ite` is the same as `if`, but named differently to distinguish symbolic representations from Racket code).

> **Aside**: Rosette generates these symbolic representations using symbolic execution, the same idea that underpins tools like [KLEE][] or Microsoft's newly announced [Project Springfield][springfield]. There are more details in [the Rosette paper][paper].

#### Solving constraints

Once we have a symbolic representation, we can try to fill in values for the symbolic variables. We do this by using the symbolic representations as *constraints* to be solved. For example:

{% highlight racket %}
(solve
  (assert 
    (= (add2 y) 8)))
{% endhighlight %}

This fragment asks Rosette to try to fill in all the unknown variables (so far, just `y`) to satisfy a *constraint* that `(add2 y)` is equal to 8. The `assert` form creates the constraint, and the `solve` form solves it.

Of course, we know the answer should set `y` to 6, because we can do arithmetic. Rosette can do arithmetic, too; here's the output:

    (model
     [y 6])

Rosette says that it found a *model* (an assignment of values to all the unknown variables) in which `y` takes the value 6.

Let's try a slightly more difficult constraint involving `absv`:

{% highlight racket %}
(solve (assert (and (= (absv y) 5) 
                    (< y 0))))
{% endhighlight %}

This code says that `(absv y)` should be equal to 5, and that `y` should be negative. Rosette figures this out:

    (model
     [y -5])
     
Now let's try to outsmart Rosette by asking for the impossible:

{% highlight racket %}
(solve (assert (< (absv y) 0)))
{% endhighlight %}

Is there any value of `y` which has a negative absolute value? Rosette says:

    (unsat)

This is an *unsatisfiable* model: there is no possible `y` that has a negative absolute value.

So constraint programming allows us to fill in unknown values in our program automatically. This ability will underlie our approach to program synthesis.

> **Aside**: Rosette's `(solve ...)` form works by compiling constraints and sending them to the [Z3 SMT solver][z3], which provides high-performance solving algorithms for a variety of types of constraints. The [Z3 tutorial][z3tutorial] is a nice introduction to this lower-level style of constraint progamming that Rosette abstracts away.

### Domain-specific languages: programs in programs

Program synthesis is similar to the problems we just solved: there are some
unknowns whose values we wish to fill in subject to some constraints.
But in synthesis, the unknowns are *programs*,
usually drawn from a *domain-specific language* (DSL).

A DSL is just a small programming language equipped with exactly the features we are interested in. You can build a DSL for just about anything. In our research, we've built DSLs for synthesis work in [file system operations][ferrite],
[memory consistency][memsynth], and [approximate hardware][synapse], and others have done the same for [network configuration][bagpipe] and [K--12 algebra tutoring][rulesynth]. 

DSLs are fundamental in program synthesis because they define the *search space*---the set of possible values for the "unknown program".
If a DSL is too complex, it may be difficult to solve a synthesis problem, because there are many programs to consider. But if a DSL is too simple, it won't be able to express interesting behaviors. Controlling this trade-off is critical to building practical synthesis tools.

#### A simple arithmetic DSL

For today, we're going to define a trivial DSL for arithmetic operations. The programs we synthesize in this DSL will be arithmetic expressions like `(plus x y)`. While this isn't a particularly thrilling DSL, it will be simple to implement and demonstrate.

We need to define two parts of our language: its **syntax** (what programs look like) and its **semantics** (what programs do).

**Syntax**. The syntax for our DSL will use Racket's support for [structures][]. We'll define a new structure type for each operation in our language:

{% highlight racket %}
(struct plus (left right) #:transparent)
(struct mul (left right) #:transparent)
(struct square (arg) #:transparent)
{% endhighlight %}

We've defined four operators in our language: two operations `plus` and `mul` that each take two arguments, and a `square` operation that takes only a single argument. The structure declarations give names to the fields of the structure (`left` and `right` for the two-argument operations, and `arg` for the single-argument operation). The `#:transparent` annotation just tells Racket that it can look "into" these structures and, for example, automatically generate string representations for them.[^transparent]

Our syntax allows us to write programs such as this one:

{% highlight racket %}
(define prog (plus (square 7) 3))
{% endhighlight %}

to stand for the mathematical expression 7<sup>2</sup> + 3.

**Semantics**.
Now that we know what programs in our DSL look like, we need to say what they mean. To do so, we'll implement a simple *interpreter* for programs in our DSL. The interpreter takes as input a program, performs the computations that program describes, and returns the output value. For example, we'd expect the above program to return 52.

Our interpreter just recurses on the syntax using Racket's [pattern matching][pattern]:

{% highlight racket %}
(define (interpret p)
  (match p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mul a b)   (* (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [_ p]))
{% endhighlight %}

The recursion has a base case `[_ p]`---in Racket patterns, `_` matches any value---that simply returns the input program `p`. This base case handles constants in our programs.

**Solving with DSLs**.
Because our interpreter is just Racket code, Rosette will make it work even
when unknown values are involved. For example, this program:

{% highlight racket %}
(interpret (square (plus y 2)))
{% endhighlight %}

returns the symbolic representation

	(* (+ 2 y) (+ 2 y))
	
as we might expect, since `y` is unknown. This "lifting" behavior means we can answer simple questions about programs in our DSL; for example, can the program `(square (plus y 2))` ever evaluate to 25?

{% highlight racket %}
(solve (assert (= (interpret (square (plus y 2))) 25)))
{% endhighlight %}

In fact, Rosette was too clever for me, and gave an answer I didn't expect:

	(model
	 [y -7])

I was expecting `y` to be 3, but of course, (-7 + 2)<sup>2</sup> is also equal to 25.

#### Dealing with program inputs

There's one thing missing from the programs we've talked about so far: they haven't had any notion of "input". Without input, programs in our DSL are really just constant expressions.

In other words, we'd like to be able to find a constant `c`
such that `(mul c x)` is equal to `x + x`
*for every possible `x`*, rather than just
a single `x`.

To do this, we'll ask Rosette to *synthesize* rather than solve,
using its `synthesize` form. For example:

{% highlight racket %}
(synthesize
  #:forall (list x)
  #:guarantee (assert (= (interpret (mul c x)) (+ x x))))
{% endhighlight %}

Here, we're asking Rosette to fill in the unknowns
such that the constraint (the `#:guarantee` part)
holds for any possible value of `x` (the `#:forall` part).
We find the answer we probably expect:

    (model
     [c 2])
            
In other words, `(mul 2 x)` is equivalent to `x + x`. Surprise!
What's neat is that the synthesizer discovered this identity
(which is a property of our DSL) all by itself.
We didn't have to teach
it any rewrite rules or algebraic laws---only the DSL's semantics---which
we would have had to do if we were building a regular compiler.

### Wrapping up

We've barely scratched the surface of program synthesis.
All we've done so far is synthesize constants:
in the example above, we told the synthesizer it should look for
a program of the form `(mul c x)`, which feels a bit like cheating.
(In the synthesis world, we'd call this a *sketch* of a program:
a syntactic template that the synthesizer will try to complete).

In a later post, we'll look at how we can make the synthesizer discover
entire programs, so that we don't have to give it such a helping hand.
It's not much more complex than this example
(in fact, we won't change our interpreter at all);
the only difficulty comes from telling the synthesizer
what valid programs look like.


[^transparent]: `#:transparent` also has a Rosette-specific meaning: structures with this annotation will be merged together when possible, while those without will be treated as mutable structures that cannot be merged.


[synthpost]: synthesis-for-architects.html
[sketch]: https://bitbucket.org/gatoatigrado/sketch-frontend/wiki/Home
[sygus]: http://www.sygus.org/index.html
[rosette]: http://emina.github.io/rosette/
[racket]: http://racket-lang.org/
[racketdl]: https://download.racket-lang.org/
[rosettedl]: http://emina.github.io/rosette/doc/rosette-guide/ch_getting-started.html#%28part._sec~3aget%29
[lisp]: https://en.wikipedia.org/wiki/Lisp_(programming_language)
[racketquick]: https://docs.racket-lang.org/quick/index.html
[learnracket]: https://learnxinyminutes.com/docs/racket/
[br]: http://beautifulracket.com/
[lang]: http://beautifulracket.com/explainer/lang-line.html
[klee]: https://klee.github.io/
[springfield]: https://www.microsoft.com/en-us/springfield/
[paper]: http://homes.cs.washington.edu/~emina/pubs/rosette.pldi14.pdf
[z3]: https://github.com/Z3Prover/z3
[z3tutorial]: http://rise4fun.com/Z3/tutorial/guide
[ferrite]: http://sandcat.cs.washington.edu/ferrite/
[synapse]: http://synapse.uwplse.org/
[memsynth]: http://memsynth.uwplse.org/
[bagpipe]: http://bagpipe.uwplse.org/bagpipe/
[rulesynth]: http://homes.cs.washington.edu/~emina/pubs/rulesynth.its16.pdf
[structures]: https://docs.racket-lang.org/guide/define-struct.html#%28part._.Simple_.Structure_.Types__struct%29
[pattern]: https://docs.racket-lang.org/guide/match.html
