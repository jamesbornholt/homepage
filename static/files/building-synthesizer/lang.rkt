#lang rosette

(require rackunit rosette/lib/roseunit)

#|
Part 1: simple expression language
show concrete language, symbolic bounded verification, synthesis of constants,
synthesis of expressions
|#

(struct unary (val) #:transparent)
(struct binary (left right) #:transparent)
(define-syntax-rule (define-ops [op type] ...)
  (begin (struct op type () #:transparent) ...))
(define-ops [add binary] [sub binary] [mul binary] [sq unary])

(define (interpret expr)
  (match expr
    [(add a b) (+ (interpret a) (interpret b))]
    [(sub a b) (- (interpret a) (interpret b))]
    [(mul a b) (* (interpret a) (interpret b))]
    [(sq a)    (* (interpret a) (interpret a))]
    [x x]))

(check-equal? (interpret (add 5 6)) 11)
(check-equal? (interpret (sub 7 3)) 4)
(check-equal? (interpret (sub 3 7)) -4)
(check-equal? (interpret (mul 2 3)) 6)
(check-equal? (interpret (add (sub 6 2) 1)) 5)
(check-equal? (interpret (sq 3)) 9)

(define-symbolic x y integer?)

(check-unsat (verify (assert (= (interpret (add x y)) (interpret (add y x))))))
(check-unsat (verify (assert (= (interpret (add x x)) (interpret (mul x 2))))))
(check-sat   (verify (assert (= (interpret (add x y)) (interpret (mul x 2))))))

(define-symbolic c integer?)

(check-sat
 (synthesize #:forall x
             #:guarantee (assert (= (interpret (add x x)) (interpret (mul x c))))))
(check-unsat
 (synthesize #:forall x
             #:guarantee (assert (= (interpret (add x 5)) (interpret (mul x c))))))

; todo: synthesize expressions (should we use synthax or define our own?)

#|
Part 2: IMP?
show mutation, a "more realistic" language
|#

#|
Part 3: spatial architecture?
more complex language with spatial organization
|#
