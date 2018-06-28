---
date: 2016-08-28T18:32:31-07:00
draft: true
title: Building your own Program Synthesizer, Part 1
excerpt: Building a program synthesis tool, to automatically generate programs from specifications, is easier than you might think. We'll use [Rosette](http://emina.github.io/rosette/) to write a simple synthesizer in 20 lines of code.
---

In an [earlier post][synthpost], we saw an overview of *program synthesis* algorithms that automatically generate a program to implement a desired specification. But while these algorithms are an exciting and evolving field of research, you don't need to implement them yourself. Today, we'll see how to build program synthesizers using existing tools.

### Getting started with Rosette

There are a few excellent frameworks for program synthesis. The original is [Sketch][], which offers a Java-ish language equipped with synthesis features. There's also the [syntax-guided synthesis language][sygus], which offers a common interface to several different synthesis engines.

For this post, we're going to use [Rosette][], which adds synthesis and verification support to the [Racket][] programming language. The nice thing about Rosette is that it's an extension of Racket, so we'll be able to use many of
Racket's nice features (like pattern matching) while building our synthesizer.

> **Following along**: the code for this post is available on GitHub. If you'd like to follow along, you'll need to [install Racket][racketdl] and then [Rosette][rosettedl]. Then you'll be able to run Racket programs either with the DrRacket IDE or the `racket` command-line interpreter.

#### Programming with constraints

Rosette's key feature is programming with, and solving, *constraints*. Rather than a program in which all variables have known values, a Rosette program has some *unknown* variables, which we call **symbolic variables**.
The values of the symbolic variables will be determined automatically
according to the constraints.

For example, we can try to find an integer whose absolute value is 5:

{% highlight racket %}
#lang rosette/safe

(define (absv x)
  (if (< x 0) (- x) x))

; Define a symbolic variable called y of type integer.
(define-symbolic y integer?)

; Solve a constraint saying |y| = 5.
(solve
  (assert (= (absv y) 5)))
{% endhighlight %}

This program outputs:

    (model
     [y -5])

This is Rosette's way of saying it found a *model* (an assignment of values to all the symbolic variables) in which `y` takes the value -5.

Now let's try to outsmart Rosette by asking for the impossible:

{% highlight racket %}
(solve (assert (< (absv y) 0)))
{% endhighlight %}

Of course, Rosette agrees this is impossible,
and returns:

    (unsat)

This is an *unsatisfiable* model: there is no possible `y` that has a negative absolute value.

So constraint programming allows us to fill in unknown values in our program automatically. This ability will underlie our approach to program synthesis.
There are many more examples of this constraint solving in the [Rosette documentation][rosetteessentials].

> **Aside**: Rosette's `(solve ...)` form works by compiling constraints and sending them to the [Z3 SMT solver][z3], which provides high-performance solving algorithms for a variety of types of constraints. The [Z3 tutorial][z3tutorial] is a nice introduction to this lower-level style of constraint progamming that Rosette abstracts away.

### Domain-specific languages: programs in programs

Program synthesis is similar to the problems we just solved: there are some
unknowns whose values we wish to fill in, subject to some constraints.
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

We've defined three operators in our language: two operations `plus` and `mul` that each take two arguments, and a `square` operation that takes only a single argument. The structure declarations give names to the fields of the structure (`left` and `right` for the two-argument operations, and `arg` for the single-argument operation). The `#:transparent` annotation just tells Racket to automatically generate some niceties, like string representations.[^transparent]

Our syntax allows us to write programs such as this one:

{% highlight racket %}
(define prog (plus (square 7) 3))
{% endhighlight %}

to stand for the mathematical expression 7<sup>2</sup> + 3.

**Semantics**.
Now that we know what programs in our DSL look like, we need to say what they mean. To do so, we'll implement a simple *interpreter* for programs in our DSL. The interpreter takes as input a program, performs the computations that program describes, and returns the output value. For example, we'd expect the above program to return 52.

Our little interpreter just recurses on the syntax using Racket's [pattern matching][pattern]:

{% highlight racket %}
(define (interpret p)
  (match p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mul a b)   (* (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [_ p]))
{% endhighlight %}

The recursion has a base case `[_ p]`---in Racket patterns, `_` matches any value---that simply returns the input program `p`. This base case handles constants in our programs.

### Synthesis with DSLs

Because our interpreter is just Racket code, Rosette will make it work even
when symbolic variables are involved. For example, this program:

{% highlight racket %}
(interpret (square (plus y 2)))
{% endhighlight %}

returns an expression

	(* (+ 2 y) (+ 2 y))

since `y` is symbolic. This "lifting" behavior means we can answer simple questions about programs in our DSL; for example, is there a value of `y` that makes the program `(square (plus y 2))` evaluate to 25?

{% highlight racket %}
(solve 
  (assert 
    (= (interpret (square (plus y 2))) 25)))
{% endhighlight %}

In fact, Rosette was too clever for me, and gave an answer I didn't expect:

	(model
	 [y -7])

I was expecting `y` to be 3, but of course, (-7 + 2)<sup>2</sup> is also equal to 25.

This is our first synthesized program!
It's not a very interesting program---`(square (plus -7 2))`---but
we can certainly call it synthesis: we found an unknown program
that satisfies a constraint.

#### Dealing with program inputs

One thing that's missing from the above synthesis is a notion of "input".
Without input, programs in our DSL are really just constant expressions.
In other words, we might like find a constant `c`
such that `(mul c x)` is equal to `x + x`
*for every possible `x`*, rather than just
a single `x`.

Our earlier approach won't be able to do this.
If we try this program:

{% highlight racket %}
(solve 
  (assert 
    (= (interpret (mul c x)) (+ x x))))
{% endhighlight %}

Rosette gives us a solution:

    (model
     [x 0]
     [c 0])

which isn't quite what we wanted.
What it did was find a value for both `c` *and* `x`
that satisfied the constraint---of course, `(mul 0 0)` is equal to `0 + 0`.

What we want is to tell Rosette to find a value of `c`
that works for *every* `x`, not just one.
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

### A fancier example

[Adrian Sampson][adrian] has a [nice introduction][adrianintro] to program synthesis
using the Z3 SMT solver directly.
I thought it would be interesting to see how that same
example language can be reflected in Rosette.

Adrian's language is mostly similar to ours,
but it supports *sketches*.
A sketch is just a syntactic template
with *holes* for the synthesizer to fill in.
In our example above,
`(mul c x)` was a sketch,
and `c` was the hole for the synthesizer to explore.
But real sketches can do more than just specify missing constants---they can specify
missing programs too.
As a contrived example,
we might want to know if `(mul 10 x)`
can be written as the *sum* of two (unknown) expressions
(e.g., `(plus (mul 9 x) x)`).

Rosette's approach to sketches is a little different to
that in Adrian's code.
Instances of our DSL syntax are first-class values in Rosette,
and so we can manipulate them just like any other value.
We're going to create a simple `??expr` function
that returns an unknown expression,
given some limitations on the values that can be leaves of that expression:

{% highlight racket %}
(define (??expr terminals)
  (define a (apply choose* terminals))
  (define b (apply choose* terminals))
  (choose* (plus a b)
           (mul a b)
           (square a)
           (shl a b)
           (shr a b)
           a))
{% endhighlight %}

The `choose*` procedure is provided by Rosette,
and is where the magic happens.
Given `n` arguments,
`choose*` returns a single value
that can evaluate to any of the `n` arguments.
Our `??expr` function constructs an unknown expression
by first constructing two values `a` and `b`,
each of which can evaluate to any of the values in the list `terminals`.
Then, `??expr` returns an expression which applies any of our DSL operators
to those two values `a` and `b`,
or can evaluate to one of the `terminals` directly.
For example, if we called `(??expr (list 2 x))`,
the resulting expression could evaluate to `2`, `x`, `(plus 2 x)`, `(plus 2 2)`,
and so on (but not multiple nestings---`(plus (plus 2 x) 2)` is not possible).

Now we can use our unknown expression facility
to answer our burning question above---how do we write
`(mul 10 x)` as the sum of two expressions?

{% highlight racket %}
(define-symbolic p q integer?)  ; get access to more constants
(define sketch
  (??expr (list x p q)))

(define M
  (synthesize
    #:forall (list x)
    #:guarantee (assert (= (interpret sketch) (interpret (mul 10 x))))))

(evaluate sketch M)
{% endhighlight %}

We invoke the `synthesize` procedure as we did before,
but this time, we save the resulting model to a variable `M`.
Then we use Rosette's `evaluate` procedure,
which *substitutes* any symbolic values in `sketch`
with concrete values as specified by `M`.

TK


<!--
The biggest difference between Adrian's language
and our DSL above is that Adrian's works over *bitvectors*,
which are fixed-width integers,
rather than the mathematical integers we've been using above.
Bitvectors are closer to what a real computer does,
and offer the opportunity for lots of [clever optimizations][hd],
so they're a fruitful target for synthesis.

We're going to change the semantics of our language to
operate over bitvectors.
This is mostly mechanical---we just use bitvector operations
instead of `+` and `*`---but there's one catch.
Earlier, we were freely using integer constants like `2`,
but now we're going to need to say what size of bitvector
those constants are.[^bitwidth]
For convenience, we're just going to assume
all constants are 8 bits wide,
and add a new case in our interpreter to do that onversion for us.
Here's our new `interpret` function,
including semantics for new `shl` and `shr` operations
that work on bitvectors:

{% highlight racket %}
(define (interpret p)
  (match p
    [(plus a b)   (bvadd (interpret a) (interpret b))]
    [(mul a b)    (bvmul (interpret a) (interpret b))]
    [(square a)   (let ([a* (interpret a)]) (bvmul a* a*))]
    [(shl a b)    (bvshl (interpret a) (interpret b))]
    [(shr a b)    (bvashr (interpret a) (interpret b))]
    [(? integer?) (bv p 8)]  ; convert int constants to 8-bit BVs
    [_ p]))
{% endhighlight %}

And here's the new syntax we added to our DSL:

{% highlight racket %}
(struct shl (a b) #:transparent)
(struct shr (a b) #:transparent)
{% endhighlight %}

Now we can synthesize
Adrian's language features conditional expressions,
so let's add those to our DSL too.
While we're at it, we'll add some simple bitwise operations,
to realize some optimization opportunities.
First, we need to add the new syntax:

{% highlight racket %}
(struct ite (cond then else) #:transparent)
{% endhighlight %}

Now we can add the new cases to `interpret`,
inserting these lines right before the final `[_ p]` case from above:[^if]

{% highlight racket %}
    [(shl a b) (bvshl (interpret a) (interpret b))]
    [(shr a b) (bvashr (interpret a) (interpret b))]
    [(ite cond then else)
     (if (interpret cond) (interpret then) (interpret else))]
{% endhighlight %}



First, 
{% highlight racket %}
(define (interpret p env)
  (match p
    [(plus a b)  (+ (interpret a env) (interpret b env))]
    [(mul a b)   (* (interpret a env) (interpret b env))]
    [(square a)  (expt (interpret a env) 2)]
    [(var n)     (cdr (assoc n env))]
    [_ p]))
{% endhighlight %}

Our new interpreter can now handle variables:

{% highlight racket %}
(interpret (plus (mul (var 'x) 2) 1) (list (cons 'x 5)))
{% endhighlight %}


The biggest difference is that Adrian's language
supports *sketches*,
which are just programs in our DSL
but with *holes* for the synthesizer to fill in.
In the example above, `(mul c x)` was our sketch,
and `c` the hole to fill in.
But it would be nice to have a simpler interface
-->

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


[^transparent]: If you know Haskell, this is like `deriving (Show, Eq)`. But `#:transparent` also has a Rosette-specific meaning: structures with this annotation will be merged together when possible, while those without will be treated as mutable structures that cannot be merged. This is often important for performance.

[^bitwidth]: This conversion is something Z3's Python bindings do automatically, which can lead to surprising behavior. For example, if we wrote `x = z3.BitVec('x', 4)`, then the Python expressions `x + 16` and `x` are equal, because the bindings assume that when you wrote the integer `16`, and added it to a 4-bit value, you really meant `16` to be a 4-bit value holding the lowest 4 bits of `16`. Rosette prefers to make this conversion explicit when it's required, and would give you a type error here.

[^if]: Unlike in Adrian's example, we get to just use Racket's built-in `if` form here to implement `ite`, and Rosette will take care of generating the right constraints.

[synthpost]: synthesis-explained.html
[sketch]: https://bitbucket.org/gatoatigrado/sketch-frontend/wiki/Home
[sygus]: http://www.sygus.org/index.html
[rosette]: http://emina.github.io/rosette/
[racket]: http://racket-lang.org/
[racketdl]: https://download.racket-lang.org/
[rosettedl]: http://emina.github.io/rosette/rosette-guide/ch_getting-started.html
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
[rosetteessentials]: http://emina.github.io/rosette/rosette-guide/ch_essentials.html
[adrian]: https://cs.cornell.edu/~asampson/
[adrianintro]: https://www.cs.cornell.edu/~asampson/blog/minisynth.html
[alist]: https://en.wikipedia.org/wiki/Association_list
