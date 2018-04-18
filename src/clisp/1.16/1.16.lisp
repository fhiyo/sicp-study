(defun my-expt (b n)
  (my-expt-iter b n 1))

(defun my-expt-iter (b n product)
  (cond ((= n 0) product)
        ((evenp n) (my-expt-iter (expt b 2) (/ n 2) product))
        (t (my-expt-iter b (1- n) (* b product)))))
