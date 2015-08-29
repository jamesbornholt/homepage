---
date: 2015-08-31T09:00:00-07:00
draft: true
title: "Memory Consistency Models: Seeing Things in Order is the Hardest Problem in Computer Science"
description: "Computer architecture's solution is everybody else's problem."
---

There are, of course, 
[only two hard things in computer science][fowler]: 
cache invalidation, naming things, and off-by-one errors.
But there is another hard problem 
lurking amongst the tall weeds of computer science:
*seeing things in order*.
Whether it be [web-scale sorting algorithms][bubblesort],
[high-performance un-sorting algorithms][fisheryates],
or [messages in distributed systems][distributed],
seeing things in order is a challenge for the ages.

Today, I want to focus on one example of an ordering problem:
*memory consistency models*.
There's a vast corpus of resources on memory consistency models,
but much of it consists of either [slides][lucia] from [someone's class][kayvon],
or [thorough tomes][synthca] written for experts.
My goal is to produce a short primer;
for the details, you should certainly consult these excellent sources.

## Making threads agree

Consistency models deal with 
how multiple threads (or workers, or nodes, or replicas, etc.)
see the world.
Consider this simple program, 
running two threads,
and where `A` and `B` are initially both `0`:

<div class="pure-g multiple-code">
<div class="pure-u-1 pure-u-md-1-2">
<p><strong>Thread 1</strong></p>
<pre class="multiple">
A = 1
print(B)
</pre>
</div>
<div class="pure-u-1 pure-u-md-1-2">
<p><strong>Thread 2</strong></p>
<pre class="multiple">
B = 1
print(A)
</pre>
</div>
</div>

To understand what this program can output,
we should think about the order in which its events can happen.
Because the threads are so small,
the most likely outcome is that it prints one `0` and one `1`:
first one of the threads executes both its statements,
setting one variable to `1` and printing the other
(which will still be `0` at this point),
and then the other thread executes,
setting the other variable to `1`
(but the first thread already printed it)
and printing the first variable
(which the first thread set to `1`).


[fowler]: http://martinfowler.com/bliki/TwoHardThings.html
[bubblesort]: https://en.wikipedia.org/wiki/Bubble_sort
[fisheryates]: https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
[distributed]: https://twitter.com/mathiasverraes/status/632260618599403520
[lucia]: https://github.com/blucia0a/Talks/blob/master/Other/ConsistencySlides.pdf?raw=true
[kayvon]: http://15418.courses.cs.cmu.edu/spring2015/lecture/consistency
[synthca]: http://www.morganclaypool.com/doi/abs/10.2200/S00346ED1V01Y201104CAC016