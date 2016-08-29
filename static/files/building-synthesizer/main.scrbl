#lang scribble/base

@(require (for-label racket
                     rosette/base/form/define
                     rosette/query/form
                     rosette/query/eval)
          scribble/eval "util.rkt")

@examples[#:eval rosette-eval
          (define-symbolic x integer?)
          (assert (= x 5))
          (solve #t)]