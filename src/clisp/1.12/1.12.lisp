(defun pascal (n k)
  (cond ((or (zerop k) (= n k) ) 1)
        (t (+ (pascal (1- n) k) (pascal (1- n) (1- k))))))
