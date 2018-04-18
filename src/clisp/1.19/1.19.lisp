(defun fib (n)
  (fib-iter 1 0 0 1 n))
(defun fib-iter (a b p q c)
  (cond ((= c 0) b)
        ((evenp c) (fib-iter a
                             b
                             (+ (* p p) (* q q))
                             (+ (* 2 (* p q)) (* q q))
                             (/ c 2)))
        (t (fib-iter (+ (* b q) (* a q) (* a p))
                     (+ (* b p) (* a q))
                     p
                     q
                     (- c 1)))))
