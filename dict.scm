#! /bin/sh
#| -*- scheme -*-
exec csi -s $0 "$@"
|#

(require-extension utf8)                ; make string-length work with codepoints

(use srfi-1)
(use http-client)
(use html-parser)
(use uri-generic)
(use sxpath)
(use args)
(use clojurian-syntax)


;; Settings
(define pronounciation-url "http://www.macmillandictionary.com/dictionary/american/")
(define mp3-path-selector  (sxpath "//img[@class=\"sound audio_play_button\"]/@data-src-mp3"))
(define dict-page-url      "http://edict.pl/dict?word=~a&LANG=~a")


;; Parameters
(define *col-width* (make-parameter 40))
(define *sound* (make-parameter #f))
(define *lang* (make-parameter "EN"))


;; Helper functions
(define-syntax begin1                   ; like prog1 in Elisp
  (syntax-rules ()
    ((_ e1 e2 ...)
     (let ((result e1))
       (begin e2 ...)
       result))))

(define (partition seq count)
  (call/cc
   (lambda (return)
     (let loop ((seq seq)
                (res (list)))
       (when (> count (length seq))
         (return (reverse res)))
       (loop (drop seq count)
             (cons (take seq count) res))))))

(define (compose . funcs)
  (fold (lambda (f g) (lambda (x) (g (f x))))
        (car funcs)
        (cdr funcs)))

(define (max lst key-fn)
  (fold (lambda (x sofar)
          (let ((x (key-fn x)))
            (if (> x sofar) x sofar)))
        0
        lst))

(define (displayln . args)
  (for-each display args)
  (newline))

(define (safe-take lst cnt)
  (if (< (length lst) cnt) lst (take lst cnt)))

(define (safe-alist-ref alist key #!optional default)
  (if (list? key)
    (fold (lambda (a b) (or a b)) #f
          (map (cut safe-alist-ref alist <>) key))
    (alist-ref key alist equal? (or default #f))))


(define enc uri-encode-string)

(define (node->text el)
  (string-join ((sxpath '(// *text*)) el) ""))


;;; dict page handling and results display functions
(define (fetch-dict-page word)
  (let ((url (format dict-page-url (enc word) (*lang*))))
    (with-input-from-request url #f read-string)))

(define (get-pad-len str)
  (- (*col-width*) (string-length str)))

(define (format-line col1 col2)
  (let* ((pad (make-string (get-pad-len col1) #\ )))
    (string-append col1 pad " -- " col2 "\n")))


;; pronounciation page handling and results playing functions
(define (fetch-pronounciation-page word)
  (let ((url (format "~a~a" pronounciation-url (enc word))))
    (with-input-from-request url #f read-string)))

(define (play-url url)
  (let-values (((out in pid err) (process* "/usr/local/bin/mpg123" (list url))))
    (process-wait pid)))

(define (play-word x)
  (let ((p (-> (fetch-pronounciation-page x) html->sxml mp3-path-selector)))
    (when (and (not (null? p)))
      (play-url (cadar p)))))


;; Command-line parsing
(define opts
  (list (args:make-option
         (s sound) (optional: #t)
         "Play a sound file with pronounciation"
         (set! arg (or arg #t)))
        (args:make-option
         (h help) (optional: #f)
         "Display some contextual help.."
         (set! arg (or arg #t)))))


(define (display-help-and-exit)
  (displayln
   (string-append
    "Usage: " (program-name) " [-s | --sound] <word>\n\n"
    "    Fetch and display Polish to English (or vice versa)"
    " translation for word."))
  (exit))


(define (get-args)
  (let*
      ((cmdline (command-line-arguments))
       (args? (not (null? cmdline))))
    (if args?
      (let-values
          (((options arguments) (args:parse cmdline opts)))
        (when (alist-ref 'h options)    (display-help-and-exit))
        (when (not (null? options))     (*sound* (safe-alist-ref options '(sound s))))
        (when (>= (length arguments) 2) (*lang* (string-upcase (cadr arguments))))
        arguments)
      ;; not args?:
      (display-help-and-exit))))


;; Entry point
(let*
    ((xml (-> (get-args) first fetch-dict-page html->sxml))
     (tds ((sxpath "//td[@class=\"resWordCol\"]") xml))
     (rows (partition tds 2))
     (cols (apply zip rows)))
  (*col-width* (max (first cols) (compose string-length
                                          node->text)))
  (let loop ((tds rows))
    (unless (null? tds)
      (let ((pl (node->text (car (car tds))))
            (en (node->text (cadr (car tds)))))
        (display (format-line pl en))
        (loop (cdr tds)))))
  (when (*sound*)
    (let* ((en-words (second cols))
           (words (delete-duplicates (map node->text (safe-take en-words 4)))))
      (for-each play-word words))))
