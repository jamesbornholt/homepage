#lang rosette

(define K 4)

(define-symbolic lut (~> (bitvector K) (bitvector 1)))

(define-symbolic x (bitvector K))

(define (xor-bits x)
  (apply bvxor (for/list ([i K]) (extract i i x))))

(define soln
  (synthesize #:forall x
              #:guarantee (assert (equal? (xor-bits x) (lut x)))))

(define f (evaluate lut soln))

(for ([i (expt 2 K)])
  (printf "~v -> ~v\n" i (f (bv i K))))
