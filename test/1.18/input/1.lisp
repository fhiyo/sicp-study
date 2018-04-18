(load "src/clisp/1.18/1.18.lisp")

(princ (mapcar #'(lambda (x) (my-mul2 2 x)) (loop for n from 0 to 10 collect n)))
