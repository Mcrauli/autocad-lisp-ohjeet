(setq *numero* 0)

(defun c:ASETANUMERO ( / n)
  (setq n (getint "\nAnna aloitusnumero: "))
  (if n (setq *numero* n))
  (princ)
)

;; Etsi positio.lsp:n lataushakemisto. Yritetaan ensin findfile (jos Support
;; Path:lla); muuten luetaan APPLOADin MainDialog-arvo (viimeisin APPLOAD-
;; kansio) jokaiselta AutoCAD-profiililta ja katsotaan loytyyko sielta
;; positio.lsp.
(defun positio-self-folder ( / found regbase target ver prod prof appkey val)
  (vl-load-com)
  (setq target "positio.lsp")
  (cond
    ((setq found (findfile target))
     (vl-filename-directory found))
    (T
     (setq found nil)
     (setq regbase "HKEY_CURRENT_USER\\SOFTWARE\\Autodesk\\AutoCAD")
     (foreach ver (vl-registry-descendents regbase)
       (foreach prod (vl-registry-descendents (strcat regbase "\\" ver))
         (foreach prof (vl-registry-descendents
                         (strcat regbase "\\" ver "\\" prod "\\Profiles"))
           (setq appkey (strcat regbase "\\" ver "\\" prod
                                "\\Profiles\\" prof "\\Dialogs\\Appload"))
           (if (and (not found)
                    (setq val (vl-registry-read appkey "MainDialog"))
                    (= (type val) 'STR)
                    (findfile (strcat val "\\" target)))
             (setq found val))
         )
       )
     )
     found)
  )
)

(defun positio-find-block-file ( / cands self prefix)
  (vl-load-com)
  (setq cands '())
  (if (setq self (positio-self-folder))
    (setq cands (cons (strcat self "\\positio.dwg") cands)))
  (setq prefix (getvar "DWGPREFIX"))
  (setq cands (append cands
    (list
      (strcat (getenv "USERPROFILE") "\\suunnittelutyokalut\\positio.dwg")
      (strcat (getenv "USERPROFILE") "\\AutoCADLisp\\positio.dwg")
      "C:\\AutoCADLisp\\positio.dwg"
      (if prefix (strcat prefix "positio.dwg")))))
  (or
    (findfile "positio.dwg")
    (vl-some '(lambda (p) (if (and p (vl-file-systime p)) p)) cands)
  )
)

;; Diagnostic command — printtaa mita positio-find-block-file palauttaa.
;; Aja "POSDEBUG" kommandiriviltä jos POSITIO ei loyda DWG:ta.
(defun c:POSDEBUG ( / s b)
  (princ (strcat "\nDWGPREFIX = " (vl-princ-to-string (getvar "DWGPREFIX"))))
  (princ (strcat "\nUSERPROFILE = " (vl-princ-to-string (getenv "USERPROFILE"))))
  (princ (strcat "\nfindfile positio.lsp = " (vl-princ-to-string (findfile "positio.lsp"))))
  (princ (strcat "\nfindfile positio.dwg = " (vl-princ-to-string (findfile "positio.dwg"))))
  (setq s (positio-self-folder))
  (princ (strcat "\npositio-self-folder = " (vl-princ-to-string s)))
  (setq b (positio-find-block-file))
  (princ (strcat "\npositio-find-block-file = " (vl-princ-to-string b)))
  (princ)
)

(defun c:POSITIO ( / pt ent blockName blockPath firstTime)
  (setvar "ATTREQ" 0)
  (setvar "ATTDIA" 0)

  (setq blockName "POSITIO")
  (setq firstTime (not (tblsearch "BLOCK" blockName)))
  (setq blockPath (if firstTime (positio-find-block-file)))

  (if (and firstTime (not blockPath))
    (progn
      (princ "\nVIRHE: positio.dwg ei loydy. Varmista etta positio.dwg on samassa kansiossa kuin positio.lsp.")
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
