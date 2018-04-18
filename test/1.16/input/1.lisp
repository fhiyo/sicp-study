(load "src/clisp/1.16/1.16.lisp")

(princ (mapcar #'(lambda (x) (my-expt 2 x)) (loop :for n :from 0 :to 10 :collect n)))
