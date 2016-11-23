#lang rosette

(require rosette/lib/angelic rosette/lib/match)

(define registers (list 'r0 'r1 'r2))
(define (reg->idx reg)
  (- (length registers) (length (member reg registers))))

(struct insn () #:transparent)
(struct binary (dst src) #:transparent)
(struct unary (dst) #:transparent)
(struct add binary () #:transparent)
(struct sub binary () #:transparent)
(struct mul binary () #:transparent)
(struct ret unary () #:transparent)

(define (interpret prog init)
  (define memory (make-vector (length registers) 0))
  (for ([(v i) (in-indexed init)])
    (vector-set! memory i v))
  (define (set reg val)
    (vector-set! memory (reg->idx reg) val))
  (define (get reg)
    (vector-ref memory (reg->idx reg)))
  (define return-value #f)
  (for ([op prog])
    (match op
      [(add d s) (set d (+ (get d) (get s)))]
      [(sub d s) (set d (- (get d) (get s)))]
      [(mul d s) (set d (* (get d) (get s)))]
      [(ret d) (set! return-value (get d))]))
  return-value)


(define init '(1 2))

(interpret (list (add 'r0 'r0) (ret 'r0)) init)
(interpret (list (mul 'r1 'r1) (ret 'r1)) init)

(define (??reg)
  (apply choose* registers))
(define (??binop)
  (choose* add sub mul))
(define (??insn)
  ((??binop) (??reg) (??reg)))


(define prog (list (??insn) (??insn) (ret 'r0)))

(define sol (solve (assert (= (interpret prog init) 2))))

(when (sat? sol)
  (evaluate prog sol))
