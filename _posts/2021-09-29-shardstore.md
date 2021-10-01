---
title: ShardStore paper
draft: false
short_post: true
---

We have a [new paper][paper] at [SOSP 2021][] about applying *lightweight formal methods* to validate ShardStore,
Amazon S3's new storage node software.
As part of this work, we open-sourced a new stateless model checker for Rust called [Shuttle][],
which is great at finding subtle concurrency bugs.

[paper]: papers/shardstore-sosp21.pdf
[SOSP 2021]: https://sosp2021.mpi-sws.org
[Shuttle]: https://github.com/awslabs/shuttle