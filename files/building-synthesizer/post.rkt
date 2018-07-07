#lang rosette

(require rosette/lib/angelic rosette/lib/match)
(current-bitwidth #f)


(define (absv x)
  (if (< x 0) (- x) x))

; Define a symbolic variable called y of type integer.
(define-symbolic y integer?)

; Solve a constraint saying |y| = 5.
(solve
  (assert (= (absv y) 5)))


; Try to outsmart Rosette by asking for the impossible:
(solve (assert (< (absv y) 0)))


; Syntax for our simple DSL
(struct plus (left right) #:transparent)
(struct mul (left right) #:transparent)
(struct square (arg) #:transparent)


; A simple program
(define prog (plus (square 7) 3))


; Interpreter for our DSL.
; We just recurse on the program's syntax using pattern matching.
(define (interpret p)
  (match p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mul a b)   (* (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [_ p]))


; (plus (square 7) 3) evaluates to 42.
(interpret prog)


(interpret (square (plus y 2)))


(solve 
  (assert 
    (= (interpret (square (plus y 2))) 25)))


(define-symbolic x c integer?)
(solve 
  (assert 
    (= (interpret (mul c x)) (+ x x))))


(synthesize
  #:forall (list x)
  #:guarantee (assert (= (interpret (mul c x)) (+ x x))))


(define (??expr terminals)
  (define a (apply choose* terminals))
  (define b (apply choose* terminals))
  (choose* (plus a b)
           (mul a b)
           (square a)
           a))


(define-symbolic p q integer?)
(define sketch
  (plus (??expr (list x p q)) (??expr (list x p q))))

(define M
  (synthesize
    #:forall (list x)
    #:guarantee (assert (= (interpret sketch) (interpret (mul 10 x))))))

(evaluate sketch M)