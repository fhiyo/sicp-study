(load "src/clisp/1.19/1.19.lisp")

(princ (mapcar #'(lambda (x) (fib x)) (loop for n from 0 to 10 collect n)))
