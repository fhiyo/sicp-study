(load "src/clisp/1.17/1.17.lisp")

(princ (mapcar #'(lambda (x) (my-mul -3 x)) (loop :for n :from -4 :to 4 :collect n)))
