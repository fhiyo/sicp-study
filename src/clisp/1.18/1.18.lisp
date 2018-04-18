(defun double (a)
  (+ a a))
(defun halve (a)
  (assert (evenp a))
  (/ a 2))

(defun my-mul2 (a b)
  (my-mul2-iter a b 0))

(defun my-mul2-iter (a counter sum)
  (cond ((= counter 0) sum)
        ((evenp counter) (my-mul2-iter (double a) (halve counter) sum))
        (t (my-mul2-iter a (1- counter) (+ sum a)))))
