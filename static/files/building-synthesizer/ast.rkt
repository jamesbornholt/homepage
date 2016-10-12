#lang rosette

(require rosette/lib/angelic rosette/lib/match)

(struct op () #:transparent)
(struct binop (left right) #:transparent)
(struct plus binop () #:transparent)
(struct minus binop () #:transparent)
(struct times binop () #:transparent)
(struct unaryop (arg) #:transparent)
(struct square unaryop () #:transparent)

(define (interpret prog)
  (match prog
    [(plus a b) (+ (interpret a) (interpret b))]
    [(minus a b) (- (interpret a) (interpret b))]
    [(times a b) (* (interpret a) (interpret b))]
    [(square a) (* (interpret a) (interpret a))]
    [x x]))

(interpret 3)
(interpret (plus 3 4))
(interpret (minus 5 2))
(interpret (square 4))

(define-symbolic c integer?)

(solve (assert (= (interpret (plus 5 5)) (interpret (times c 5)))))

(define-symbolic x integer?)

(synthesize #:forall x
            #:guarantee (assert (= (interpret (plus x (minus x x))) (interpret (times c x)))))

(define (??op)
  (choose* plus minus times))

(define prog ((??op) c x))

(define soln
  (synthesize #:forall x
              #:guarantee (assert (= (interpret (plus x x)) (interpret prog)))))

(evaluate prog soln)  ; fill in symbolic values in prog with values from soln