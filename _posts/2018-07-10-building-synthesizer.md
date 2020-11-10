---
date: 2018-07-10T08:00:00-07:00
title: Building a Program Synthesizer
excerpt: Build a [program synthesis](https://homes.cs.washington.edu/~bornholt/post/synthesis-explained.html) tool, to generate programs from specifications, in 20 lines of code using [Rosette](http://emina.github.io/rosette/).
---

In an [earlier post][synthpost], we saw an overview of *program synthesis* algorithms that automatically generate a program to implement a desired specification. While these algorithms are an exciting and evolving field of research, you don't need to implement them yourself. Today, we'll see how to build a program synthesizer using existing tools.

## Getting started with Rosette

There are some great off-the-shelf frameworks for program synthesis. The original is [Sketch][], which offers a Java-ish language equipped with synthesis features. There's also the [syntax-guided synthesis language][sygus], which offers a common interface to several different synthesis engines.

For this post, we're going to use [Rosette][], which adds synthesis and verification support to the [Racket][] programming language. The nice thing about Rosette is that it's an extension of Racket, so we'll be able to use many of
Racket's nice features (like pattern matching) while building our synthesizer.

> **Following along**: the code for this post is [available on GitHub][gist]. If you'd like to follow along, you'll need to [install Racket][racketdl] and [Rosette][rosettedl]. Then you'll be able to run Rosette programs either with the DrRacket IDE or the `racket` command-line interpreter.
{:.callout}

### Programming with constraints

Rosette's key feature is programming with, and solving, *constraints*. Rather than a program in which all variables have known values, a Rosette program has some *unknown* variables, which we call **symbolic variables**.
The values of the symbolic variables will be determined automatically
according to the constraints we generate.

For example, we can try to find an integer whose absolute value is 5:

{% highlight racket %}
#lang rosette/safe

; Compute the absolute value of `x`.
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
The model satisfies all the constraints we generated using `assert`,
which in this case was just the single assertion `(= (absv y) 5)`.

Now let's try to outsmart Rosette by asking for the impossible---a value `y`
whose absolute value is negative:

{% highlight racket %}
(solve (assert (< (absv y) 0)))
{% endhighlight %}

Of course, Rosette agrees this is impossible,
and returns:

    (unsat)

This is an *unsatisfiable* solution: there is no possible `y` that has a negative absolute value.

So constraint programming allows us to fill in unknown values in our program automatically. This ability will underlie our approach to program synthesis.
There are many more examples of this constraint solving in the [Rosette documentation][rosetteessentials].

> **Aside**: Rosette's `(solve ...)` form works by compiling constraints and sending them to the [Z3 SMT solver][z3], which provides high-performance solving algorithms for a variety of types of constraints. The [Z3 tutorial][z3tutorial] is a nice introduction to this lower-level style of constraint progamming that Rosette abstracts away.

## Domain-specific languages: programs in programs

Program synthesis is similar to the problems we just solved: there are some
unknowns whose values we wish to fill in, subject to some constraints.
But in synthesis, the unknowns are *programs*,
usually drawn from a *domain-specific language* (DSL).

A DSL is just a small programming language equipped with exactly the features we are interested in. You can build a DSL for just about anything. In our research, we've built DSLs for synthesis work in [file system crash safety][ferrite],
[memory consistency][memsynth], and [approximate hardware][synapse], and others have done the same for [network configuration][bagpipe] and [K--12 algebra tutoring][rulesynth]. 

DSLs are fundamental in program synthesis because they define the *search space*---the set of possible values for the "unknown program".
If a DSL is too complex, it may be difficult to solve a synthesis problem, because there are many programs to consider. But if a DSL is too simple, it won't be able to express interesting behaviors. Controlling this trade-off is critical to building practical synthesis tools.

### A simple arithmetic DSL

For today, we're going to define a trivial DSL for arithmetic operations. The programs we synthesize in this DSL will be arithmetic expressions like `(plus x y)`. While this isn't a particularly thrilling DSL, it will be simple to implement and demonstrate.

Every DSL needs two parts: its **syntax** (what programs look like) and its **semantics** (what programs mean).

#### Syntax
The syntax for our DSL will use Racket's support for [structures][]. We'll define a new structure type for each operation in our language:

{% highlight racket %}
(struct plus (left right) #:transparent)
(struct mul (left right) #:transparent)
(struct square (arg) #:transparent)
{% endhighlight %}

We've defined three operators in our language: two operators `plus` and `mul` that each take two arguments, and a `square` operator that takes only a single argument. The structure definitions give names to the fields of the structure (`left` and `right` for the two-argument operators, and `arg` for the single-argument operator). The `#:transparent` annotation just tells Racket to automatically generate some niceties for our structures, like string representations and equality predicates.[^transparent]

Our syntax allows us to write programs such as this one:

{% highlight racket %}
(define prog (plus (square 7) 3))
{% endhighlight %}

to stand for the mathematical expression 7<sup>2</sup> + 3.
In essence, we write programs in our DSL by constructing [abstract syntax trees][ast]
for the expressions we're interested in.

#### Semantics
Now that we know what programs in our DSL look like, we need to say what they mean. To do so, we'll implement a simple *interpreter* for programs in our DSL. The interpreter takes as input a program, performs the computations that program describes, and returns the output value. For example, we'd expect the above program to return 52.

Our little interpreter just recurses on the syntax using Rosette's [pattern matching][pattern]:

{% highlight racket %}
(define (interpret p)
  (destruct p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mul a b)   (* (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [_ p]))
{% endhighlight %}

The recursion has a base case `[_ p]`---in Racket patterns, `_` matches any value---that simply returns the input program `p`. This base case handles constants in our programs.

By invoking our interpreter on the program `(plus (square 7) 3)` above:

{% highlight racket %}
(interpret prog)
{% endhighlight %}

we can compute the value it evaluates to:

    52

## Synthesis with DSLs

Because our interpreter is just Racket code, Rosette will make it work even
when symbolic variables are involved. For example, this program:

{% highlight racket %}
(interpret (square (plus y 2)))
{% endhighlight %}

returns an expression

	(* (+ 2 y) (+ 2 y))

since `y` is symbolic. This "lifting" behavior means we can answer simple questions about programs in our DSL. For example, is there a value of `y` that makes the program `(square (plus y 2))` evaluate to 25?

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
it's certainly a form of synthesis: we found a program
that satisfies a constraint.[^progsynth]

### Dealing with program inputs

One thing that's missing from the above synthesis is a notion of "input".
Without input, programs in our DSL are really just constant expressions.
In other words, we might like find a constant `c`
such that `(mul c x)` is equal to `x + x`
*for every possible `x`*, rather than just
a single `x`.

Our earlier approach won't be able to do this.
If we try this program:

{% highlight racket %}
(define-symbolic x c integer?)
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
it any rewrite rules or algebraic laws, as
we would have had to do if we were building a regular compiler,
but instead told it only about the semantics of our DSL.

## A fancier example

[Adrian Sampson][adrian] has a [nice introduction][adrianintro] to program synthesis
using the Z3 SMT solver directly.
I thought it would be interesting to see how his
example language would manifest in Rosette.

Adrian's language is mostly similar to ours,
but it supports *sketches*.
A sketch is just a syntactic template
with *holes* for the synthesizer to fill in.
In our example above,
`(mul c x)` was a sketch,
and `c` was the hole for the synthesizer to explore.
But real sketches can do more than just specify missing constants---they can specify
missing *programs* too.
As a contrived example,
we might want to know if `(mul 10 x)`
can be decomposed as the *sum* of two expressions
(e.g., `(plus (mul 9 x) x)`).

Rosette's approach to sketches is a little different to
that in Adrian's code (which adds conditionals to the DSL to construct sketches).
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
           a))
{% endhighlight %}

The `choose*` procedure is provided by Rosette,
and is where the magic happens.
Given *n* arguments,
`choose*` returns a single value
that can evaluate to any of the *n* arguments.
Our `??expr` function constructs an unknown expression
by first constructing two values `a` and `b`,
each of which can evaluate to any of the values in the list `terminals`.
Then, `??expr` returns an expression which applies any of our DSL operators
to those two values `a` and `b`,
or can evaluate to one of the `terminals` directly.
For example, if we called `(??expr (list 2 x))`,
the resulting expression could evaluate to `2`, `x`, `(plus 2 x)`, `(plus 2 2)`,
and so on (but not multiple nestings---`(plus (plus 2 x) 2)` is not possible with this definition).

Now we can use our unknown expression facility
to answer our burning question above---how do we write
`(mul 10 x)` as the sum of two expressions?
First, we define a sketch of our desired program,
the sum of two unknown expressions:

{% highlight racket %}
(define-symbolic p q integer?)  ; get access to more constants
(define sketch
  (plus (??expr (list x p q)) (??expr (list x p q))))
{% endhighlight %}

Now we invoke the `synthesize` form to find a solution:

{% highlight racket %}
(define M
  (synthesize
    #:forall (list x)
    #:guarantee (assert (= (interpret sketch) (interpret (mul 10 x))))))

(evaluate sketch M)
{% endhighlight %}

Unlike earlier examples, we save the result of `synthesize` to a variable `M`.
Then we use Rosette's `evaluate` procedure,
which *substitutes* concrete values for any symbolic variables in `sketch`
according to the bindings in `M`.
The result of evaluating our sketch against the model `M`
is our synthesized program:

    (plus (mul 8 x) (plus x x))

If you do your math correctly,
you'll find that 8*x* + *x* + *x* is, in fact, equal to 10*x*.
We've synthesized a (slower, sillier) program!


## Wrapping up

At this point, we've barely scratched the surface of program synthesis.
But we've already done something very cool:
notice that when we built the syntax and semantics for our DSL,
we didn't think about synthesis or symbolic reasoning at all.
A simple interpreter for concrete programs became
a powerful automated reasoning tool
that can be used for solving, synthesizing, and verifying programs.
This is the key promise of [Rosette]: write your programs for concrete state
and get these powerful automated tools for free.

Where to from here?
From the program synthesis side,
most excitement in the community is focused on *example-based* synthesis.
In our programs above, we had to write fairly detailed specifications
for the synthesis to work out.
What if we could instead just give a few *examples* of what we want our
program to output for particular concrete inputs?
This approach offers much simpler specifications,
and is the basis of tools like [Flash Fill][flashfill],
but has its own complexities (e.g., what if our examples are ambiguous?).

On the formal methods side,
one key challenge for automated reasoning tools like the one we just built
is *scalability*.
Our examples work well with trivial specifications over a trivial DSL,
but what if we want to talk about real-world code,
like the software for a [clinical radiotherapy system][neutrons]?
Scaling an automated reasoning tool requires careful design.
We've been working on [new abstractions][synapse]
for synthesis tools,
and on better ways to 
[identify scalability bottlenecks][sympro] in automated reasoning tools,
but it's still early in the quest to make automated reasoning accessible to everyone.


[^transparent]: `#:transparent` also has a Rosette-specific meaning: structures with this annotation will be merged together when possible, while those without will be treated as mutable structures that cannot be merged. This is often important for performance, as the [Rosette paper][paper] explains in more detail.

[^progsynth]: Program synthesis people would probably not call this synthesis, though---it's really [angelic execution][angelic], finding a binding that makes the program complete successfully. To call it program synthesis we'd want a universal quantifier over all possible inputs.

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
[pattern]: https://docs.racket-lang.org/rosette-guide/sec_utility-libs.html?q=destruct#%28form._%28%28lib._rosette%2Flib%2Fdestruct..rkt%29._destruct%29%29
[rosetteessentials]: http://emina.github.io/rosette/rosette-guide/ch_essentials.html
[adrian]: https://cs.cornell.edu/~asampson/
[adrianintro]: https://www.cs.cornell.edu/~asampson/blog/minisynth.html
[alist]: https://en.wikipedia.org/wiki/Association_list
[neutrons]: http://neutrons.uwplse.org/
[sympro]: https://2018.splashcon.org/event/splash-2018-oopsla-finding-code-that-explodes-under-symbolic-evaluation
[angelic]: https://parlab.eecs.berkeley.edu/sites/all/parlab/files/angelic-acm-dl.pdf
[ast]: https://en.wikipedia.org/wiki/Abstract_syntax_tree
[gist]: https://gist.github.com/jamesbornholt/b51339fb8b348b53bfe8a5c66af66efe
[flashfill]: https://support.office.com/en-us/article/using-flash-fill-in-excel-3f9bcf1e-db93-4890-94a0-1578341f73f7
