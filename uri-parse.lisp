(defun appendVero (x lista)
  (reverse (append (list x) (reverse lista))))

(defun uri-parse (stringa)
  (cond ((null stringa) nil))
  (if (null (check-special-scheme (stringa-lista stringa) (list) (list)))
      (check-scheme (stringa-lista stringa) (list) (list))
    (check-special-scheme (stringa-lista stringa) (list) (list))))

(defun stringa-lista (stringa)
  (mapcar 'string (coerce (string stringa) 'list)))

(defun check-special-scheme (x scheme info)
  (let ((c (first x)))
    (cond ((null x) (error "uri non corretto"))
          ((or (equal c "#") 
               (equal c "?") 
               (equal c "/"))
           (error "carattere non accettato"))

          ((equal c ":")
           (cond ((equal (string-downcase scheme) "mailto")
                  (cond ((equal (second x) "@")
                         (error "carattere non accettato")))
                  (check-mailto-userinfo (rest x) (list) 
				(appendVero scheme info)))

                 ((equal (string-downcase scheme) "news")
                  (check-mailto/news-host (rest x) (list) 
				(appendVero scheme info)))

                 ((or (equal (string-downcase scheme) "tel")
                      (equal (string-downcase scheme) "fax"))
                  (check-tel/fax-userinfo (rest x) (list) 
				(appendVero scheme info)))

                 ((equal (string-downcase scheme) "zos")
                  (check-authorithy-exixts (rest x) 1 
				(appendVero scheme info)))))

          (t (check-special-scheme (rest x) 
			(concatenate 'string scheme c) info)))))

(defun check-mailto-userinfo (x userinfo info)
  (let ((c (first x)))
    (cond ((null x) (appendVero userinfo info))
          ((or (equal c "/")
               (equal c "?")
               (equal c "#")
               (equal c ":")) 
           (error "carattere non accettato"))

          ((equal c "@")
           (cond ((null (rest x)) 
                  (error "uri non terminato correttamente")))
           (check-mailto/news-host (rest x) 
           (list) (appendVero userinfo info)))

          (t (check-mailto-userinfo (rest x) 
		(concatenate 'string userinfo c) info)))))

(defun check-mailto/news-host (x host info)
  (let ((c (first x)))
    (cond ((null x) (appendVero host info))
          ((or (equal c "/")
               (equal c "?")
               (equal c "#")
               (equal c ":")
               (equal c "@")) 
           (error "carattere non accettato"))

          (t (check-mailto/news-host (rest x) 
		(concatenate 'string host c) info)))))

(defun check-tel/fax-userinfo (x userinfo info)
  (let ((c (first x)))
    (cond ((null x) (appendVero userinfo info))
          ((or (equal c "/")
               (equal c "?")
               (equal c "#")
               (equal c ":")
               (equal c "@")) 
           (error "carattere non accettato"))

          (t (check-tel/fax-userinfo 
              (rest x) 
              (concatenate 'string userinfo c) info)))))

(defun check-scheme (x scheme info)
  (let ((c (first x))) 
    (cond ((null x) (error "uri non corretto"))
          ((equal c ":") 
           (cond ((null (rest x))
                  (appendVero scheme info)))
           (check-authorithy-exixts (rest x) 0 (appendVero scheme info)))

          ((or (equal c "#") 
               (equal c "?") 
               (equal c "/"))
           (error "carattere non accettato"))

          (t (check-scheme (rest x) 
              (concatenate 'string scheme c) info)))))                    

(defun check-authorithy-exixts (x zos info)
  (let ((c (first x)))
    (cond ((null x) info)
          ((and (equal c "/") 
                (equal (second x) "/"))
           (cond ((null (rest (rest x))) 
                  (error "uri non terminato correttamente")))
           (cond ((equal (third x) "/")
                  (error "uri non corretto")))
           (cond ((find #\@ (mapcar 
                             (lambda (x) (find #\@ x)) x))
                  (cond ((equal (third x) "@")
                         (error "carattere non accettato")))
                                
                  (check-userinfo (rest (rest x)) 
                                  (list) zos info))                           
                 (t (cond ((null (rest (rest x)))
                           (error "uri non terminato correttamente"))
                          ((or (equal (third x) ":")
                               (equal (third x) "/")
                               (equal (third x) "."))
                           (error "uri non corretto")))
                    (check-host (rest (rest x)) 
                                (list) zos 
                                (appendVero '() info)))))

          ((and (equal c "/") 
                (equal (second x) "?"))
           (cond ((null (rest (rest x))) 
                  (error "uri non terminato correttamente"))
                 ((equal (third x) "#") 
                  (error "uri non corretto")))
           (check-query (rest (rest x)) 
		(list) 
		(appendVero '() (appendVero 80 (appendVero '() 
                                    (appendVero '() info))))))

          ((and (equal c "/") 
                (equal (second x) "#"))
           (cond ((null (rest (rest x))) 
                  (error "uri non terminato correttamente")))
           (check-fragment (rest (rest x)) 
			(list) (appendVero '() (appendVero '()  
		(appendVero 80 (appendVero '() (appendVero '() info)))))))

          ((equal c "?") 
           (cond ((null (rest x)) (error "uri non terminato correttamente"))
                 ((equal (second x) "#") (error "uri non corretto")))
           (check-query (rest x) (list) 
			(appendVero '() (appendVero 80 (appendVero '() 
                     (appendVero '() info))))))

          ((equal c "#")
           (cond ((null (rest x)) 
           (error "uri non terminato correttamente")))
           (check-fragment (rest x) 
              (list) (appendVero '() (appendVero '()(appendVero 80 
                     (appendVero '() (appendVero '() info)))))))

          ((null (rest x)) info)

          (t (cond ((equal c "/")
                    (cond ((and (eq zos 1)
                                (null (rest x)))
                            (error "uri non terminato correttamente")))
                    (check-path (rest x) (list) zos 
		(appendVero 80 (appendVero '() (appendVero '() info)))))
                   (t (check-path x (list) zos (appendVero 80 
					(appendVero '() 
                                   (appendVero '() info))))))))))

(defun check-userinfo (x userinfo zos info)
  (let ((c (first x)))
    (cond ((null x) (appendVero userinfo info))

          ((or (equal c ":")
               (equal c "#")
               (equal c "?") 
               (equal c "/"))
           (error "carattere non accettato"))

          ((equal c "@")
           (cond ((or (equal (second x) ":")
                      (equal (second x) "/")
                      (equal (second x) "."))
                  (error "uri non corretto"))) 
           (cond ((null (rest x)) 
                  (error "uri non terminato correttamente")))
           (check-host (rest x) (list) zos (appendVero userinfo info)))

          (t (check-userinfo (rest x) 
                             (concatenate 'string userinfo c) zos info)))))

(defun check-number (x)
  (cond ((or (equal x "1") 
             (equal x "2") 
             (equal x "3") 
             (equal x "4") 
             (equal x "5")
             (equal x "6") 
             (equal x "7") 
             (equal x "8") 
             (equal x "9") 
             (equal x "0")))))

(defun check-host (x host zos info)
  (let ((c (first x)))
    (cond ((null x) (appendVero host info))
        
          ((equal c "@") 
           (error "carattere non accettato"))

          ((and (equal c ".")
                (null (rest x))) 
           (error "uri non terminato correttamente"))

          ((and (equal c ".")
                (equal (second x) "."))
           (error "carattere non accettato"))

          ((equal c ":") 
           (cond ((null (rest x))
                  (error "uri non terminato correttamente"))
                 ((equal (second x) "/") 
                  (error "uri non corretto")))
           (check-port (rest x) (list) zos (appendVero host info))) 

          ((equal c "?") 
           (cond ((null (rest x))
                  (error "uri non terminato correttamente"))
                 ((equal (second x) "#") 
                  (error "uri non corretto")))
           (check-query (rest x) (list) 
			(appendVero '() 
                     (appendVero 80 (appendVero host info)))))

          ((equal c "#")
           (cond ((null (rest x))
                  (error "uri non terminato correttamente")))
           (check-fragment (rest x) (list) 
			(appendVero '() (appendVero '() 
                     (appendVero 80 (appendVero host info))))))

          ((and (equal c "/")
                (equal (second x) "?")) 
           (cond ((null (rest (rest x)))
                  (error "uri non terminato correttamente"))
                 ((equal (third x) "#") 
                  (error "uri non corretto")))
           (check-query (rest (rest x)) (list) 
		(appendVero '() (appendVero 80 (appendVero host info)))))

          ((and (equal c "/")
                (equal (second x) "#"))
           (cond ((null (rest (rest x)))
                  (error "uri non terminato correttamente")))
           (check-fragment (rest (rest x)) (list) 
			(appendVero '() (appendVero '() 
				(appendVero 80 (appendVero host info))))))

          ((equal c "/") 
           (cond ((and (eq zos 1)
                       (null (rest x)))
                  (error "uri non terminato correttamente")))
           (check-path (rest x) (list) zos 
				(appendVero 80 (appendVero host info))))

          (t (check-host (rest x) 
          (concatenate 'string host c) zos info)))))

(defun check-port (x port zos info)
  (let ((c (first x)))
    (cond ((null x) (appendVero port info))
          ((and (equal c "/")
                (equal (second x) "?"))
           (cond ((null (rest (rest x))) 
                  (error "uri non terminato correttamente"))
                 ((equal (third x) "#") 
                  (error "uri non corretto")))
           (check-query (rest (rest x)) (list) 
			(appendVero '() (appendVero port info))))
          ((and (equal c "/")
                (equal (second x) "#"))
           (cond ((null (rest (rest x))) 
                  (error "uri non terminato correttamente")))
           (check-fragment (rest (rest x)) (list) 
		(appendVero '() (appendVero '() (appendVero port info)))))
          ((equal c "?") 
           (cond ((null (rest x)) 
                  (error "uri non terminato correttamente"))
                 ((equal (second x) "#") 
                  (error "uri non corretto")))
           (check-query (rest x) (list) (appendVero '() 
                                        (appendVero port info))))
          ((equal c "#")
           (cond ((null (rest x)) 
                  (error "uri non terminato correttamente"))) 
           (check-fragment (rest x) (list) 
		(appendVero '() (appendVero '() (appendVero port info)))))
          ((equal c "/") 
           (cond ((and (eq zos 1)
                       (null (rest x)))
                  (error "uri non terminato correttamente")))
           (check-path (rest x) (list) zos (appendVero port info)))
          ((not (check-number c)) 
           (error "la porta non accetta caratteri"))
          (t (check-port (rest x) 
          (concatenate 'string port c) zos info)))))

(defun check-path (x path zos info)
  (let ((c (first x)))
    (cond ((null x) (appendVero path info))
          ((equal zos 1)
           (cond ((or (equal c "(")
                      (equal c ".")
                      (equal c "?")
                      (equal c "#")
                      (check-number c))
                  (error "uri non corretto")))
           (check-id44 x 1 path info))
        
          ((or (equal c ":")
               (equal c "@")) 
           (error "carattere non accettato"))
        
          ((equal c "?") 
           (cond ((null (rest x)) 
              (error "uri non terminato correttamente"))
                 ((equal (second x) "#") (error "uri non corretto")))        
           (check-query (rest x) (list) (appendVero path info)))

          ((equal c "#") 
           (cond ((null (rest x)) 
              (error "uri terminato non correttamente")))
           (check-fragment (rest x) (list) 
                           (appendVero '() (appendVero path info)))) 
                                                                                
          (t (check-path (rest x) 
              (concatenate 'string path c) zos info)))))

(defun check-id44 (x cont path info)
  (let ((c (first x)))
    (cond ((null x) (appendVero path info))
          ((> cont 44) (error "id44 troppo lungo"))

          ((equal c "(")
           (cond ((check-number (second x)) 
                  (error "id8 non puo' iniziare con un numero")))
           (cond ((or (null (rest x))
                      (equal (second x) ")")
                      (equal (second x) "?")
                      (equal (second x) "#"))
                  (error "path terminato non correttamente")))

           (cond ((find #\) (mapcar (lambda (x) (find #\) x)) x))
              (check-id8 (rest x) 1 (concatenate 'string path c) info))))

          ((equal c "#")
           (cond ((null (rest x)) 
                  (error "uri terminato non correttamente")))
           (check-fragment (rest x) (list) (appendVero path info)))

          ((equal c "?")
           (cond ((null (rest x)) 
                  (error "uri terminato non correttamente"))
                 ((equal (second x) "#")
                  (error "uri non corretto")))         
           (check-query (rest x) (list) (appendVero path info)))
        
          ((and (not (alphanumericp (first (coerce c 'list))))
                (not (equal c ".")))
           (error "carattere non accettato"))

          ((cond ((and (or (null (rest x))
                           (equal (first (rest x)) "("))
                       (equal c "."))
                  (error "id8 non puo' iniziare con il '.'"))))

          (t (check-id44 (rest x) (+ cont 1) 
                         (concatenate 'string path c) info)))))

(defun check-id8 (x cont path info)
  (let ((c (first x)))
    (cond ((null x) (appendVero path info))
          ((> cont 8) (error "id8 troppo lungo"))
          ((equal c ")")
           (cond ((equal (second x) "#")
                  (cond ((null (rest (rest x))) 
                         (error "uri terminato non correttamente")))
                  (check-fragment (rest (rest x)) (list) 
				(appendVero '() (appendVero 
                            (concatenate 'string path c) info))))
               
                 ((equal (second x) "?")
                  (cond ((null (rest (rest x))) 
                         (error "uri terminato non correttamente"))
                        ((equal (second x) "#")
                         (error "uri non corretto")))
                  (check-query (rest (rest x)) (list) 
                     (appendVero (concatenate 'string path c) info)))
                 (t (check-id8 (rest x) (+ cont 1) 
                               (concatenate 'string path c) info))))

          ((not (alphanumericp (first (coerce c 'list))))
           (error "carattere non accettato"))

          (t (check-id8 (rest x) (+ cont 1) 
			(concatenate 'string path c) info)))))

(defun check-query (x query info)
  (let ((c (first x)))
    (cond ((null x) (appendVero query info))
          ((equal c "#") 
           (cond ((null (rest x)) 
                  (error "uri non terminato correttamente")))
           (check-fragment (rest x) (list) (appendVero query info)))
          (t (check-query (rest x) (concatenate 'string query c) info)))))

(defun check-fragment (x fragment info) 
  (cond ((null x) (appendVero fragment info))  
        (t (check-fragment (rest x) 
			(concatenate 'string fragment (first x)) info))))

(defun uri-scheme (lista)
  (cond ((null lista) nil)
        (t (first lista))))

(defun uri-userinfo (lista)
  (cond ((null lista) nil)
        (t (second lista))))

(defun uri-host (lista)
  (cond ((null lista) nil)
        (t (third lista))))

(defun uri-port (lista)
  (cond ((null lista) nil)
        ((null (fourth lista)) 80)
        ((not (equal (fourth lista) 80)) 
              (first (list (parse-integer (fourth lista)))))
        (t (fourth lista))))

(defun uri-path (lista)
  (cond ((null lista) nil)
        (t (fifth lista))))

(defun uri-query (lista)
  (cond ((null lista) nil)
        (t (sixth lista))))

(defun uri-fragment (lista)
  (cond ((null lista) nil)
        (t (seventh lista))))

(defun uri-display (lista &optional stream)
  (cond ((null lista) nil)
        ((null stream)  
         (format t 
         "Scheme: ~S ~%Userinfo: ~S ~%Host: ~S ~%Port: ~D ~%Path: ~S 
Query: ~S ~%Fragment: ~S ~%"
                 (first lista)
                 (second lista)
                 (third lista)
                 (fourth lista)
                 (fifth lista)
                 (sixth lista)
                 (seventh lista)))
        (t (format stream "Scheme: ~S ~%Userinfo: ~S ~%Host: ~S ~%Port: ~D
              ~%Path: ~S ~%Query: ~S ~%Fragment: ~S ~%"
                   (first lista)
                   (second lista)
                   (third lista)
                   (fourth lista)
                   (fifth lista)
                   (sixth lista)
                   (seventh lista)))))