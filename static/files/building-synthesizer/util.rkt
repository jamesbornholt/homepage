#lang racket

(require scribble/eval racket/sandbox)
(provide rosette-eval)

(define (rosette-printer v)
  (match v
    [(? void?) (void)]
    [(? custom-write?) 
     ((custom-write-accessor v) v (current-output-port) 1)]
    [(? pair?) (printf "'~a" v)]
    [(? null?) (printf "'()")]
    [(? symbol?) (printf "'~a" v)]
    [_  (printf "~a" v)]))
(define rosette-eval
   (parameterize ([sandbox-output 'string]
                  [sandbox-error-output 'string]
                  [sandbox-path-permissions `((execute ,(byte-regexp #".*")))]
                  [sandbox-memory-limit #f]
                  [sandbox-eval-limits #f]
                  [current-print rosette-printer])
     (make-evaluator 'rosette/safe)))