(setq *numero* 0)

(defun c:ASETANUMERO ( / n)
  (setq n (getint "\nAnna aloitusnumero: "))
  (if n (setq *numero* n))
  (princ)
)

(defun c:POSITIO ( / pt ent blockName blockPath firstTime)
  (setvar "ATTREQ" 0)
  (setvar "ATTDIA" 0)

  (setq blockName "POSITIOV2")
  (setq blockPath "C:\\Users\\LauriRekola\\CAD_LISP\\positio.dwg")

  ;; Jos block ei ole maariteltyna piirroksessa, ladataan se tiedostosta
  ;; ensimmaisen insertin yhteydessa (syntaxi NAME=PATH).
  (setq firstTime (not (tblsearch "BLOCK" blockName)))

  ;; Varmista etta tiedosto on olemassa jos lataus tarvitaan
  (if (and firstTime (not (findfile blockPath)))
    (progn
      (princ (strcat "\nVIRHE: Block-tiedostoa ei loydy: " blockPath))
      (exit)
    )
  )

  (while (setq pt (getpoint "\nValitse sijainti (ESC lopettaa): "))

    (setq *numero* (1+ *numero*))

    (if firstTime
      (progn
        (command "_.-INSERT" (strcat blockName "=" blockPath) pt 1 1 0)
        (setq firstTime nil)
      )
      (command "_.-INSERT" blockName pt 1 1 0)
    )

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
