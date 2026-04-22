(setq *numero* 0)

(defun c:ASETANUMERO ( / n)
  (setq n (getint "\nAnna aloitusnumero: "))
  (if n (setq *numero* n))
  (princ)
)

(defun c:NPALLO ( / pt ent)
  (setvar "ATTREQ" 0)
  (setvar "ATTDIA" 0)

  (while (setq pt (getpoint "\nValitse sijainti (ESC lopettaa): "))
    
    (setq *numero* (1+ *numero*))

    (command "_.-INSERT" "NUMERO_PALLO" pt 1 1 0)

    (setq ent (entlast))

    (if ent
      (progn
        (setq ent (entnext ent))
        (while ent
          (if (= (cdr (assoc 0 (entget ent))) "ATTRIB")
            (if (= (strcase (cdr (assoc 2 (entget ent)))) "NUMERO")
              (entmod
                (subst
                  (cons 1 (itoa *numero*))
                  (assoc 1 (entget ent))
                  (entget ent)
                )
              )
            )
          )
          (setq ent (entnext ent))
        )
      )
    )

    (princ (strcat "\nLisätty numero: " (itoa *numero*)))
  )

  (princ)
)
