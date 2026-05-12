;;; build-vputki-blocks.lsp
;;;
;;; INTERNAL TOOL — sisaltaa block-geometrian luonnin vputki-32.dwg:lle,
;;; vputki-50.dwg:lle ja vputki-75.dwg:lle. Ei kuulu ZIP-pakettiin.
;;;
;;; Geometria: 64 × 3DFACE muodostavat onkaloidun sylinterin (1.8 mm
;;; seinama nakyvana geometriana):
;;;   - 16 OUTER 3DFACE  (sivupinta ulkonä, R = D/2)
;;;   - 16 INNER 3DFACE  (sivupinta sisanä, R = D/2 - 1.8)
;;;   - 16 END-CAP X=0   (annular wedge yhdistaa outer/inner)
;;;   - 16 END-CAP X=1000 (annular wedge)
;;;
;;; Sama entiteetti-tyyppi kuin KLHYLLY-TIKAS:n rail1Top/rail2Top/rungTop
;;; -- 3DFACE:lla on 4 eksplisiittistä vertikkiä joita
;;; dynamic-block-stretch voi liikuttaa luotettavasti (toisin kuin
;;; 3DSOLID:eilla). Stretch-frame catchaa molemmat outer + inner vertikit
;;; samalla X-tasolla, joten putki venyy ehjana onkalona.
;;;
;;; Tyokulku per koko (32/50/75):
;;;   1. Avaa tyhja DWG, APPLOAD tama tiedosto
;;;   2. VPUTKI-BUILD-32 (tai 50/75) -> 64 × 3DFACE + block-maaritys
;;;   3. BEDIT VPUTKI-<size> -> Linear Pituus + 2 stretch-actionia
;;;      (ks. tools/VPUTKI-OHJEET.md)
;;;   4. ERASE ALL + SAVEAS files/vputki-<size>.dwg
;;;
;;; Layer "0" (BYBLOCK) jotta INSERT:n layer (KYL-VIEMARI-<size>)
;;; periytyy alaspain.

(vl-load-com)

(setq *VPUTKI-WALL* 1.8)         ; mm, seinämäpaksuus
(setq *VPUTKI-NUMSEGS* 16)       ; axial divisions (16 = vertex 90 = top easy to snap)

;; ============================================================
;; 3DFACE-builder: 4 × NUMSEGS face per putki
;;   - NUMSEGS outer side  (R)
;;   - NUMSEGS inner side  (R - wall)
;;   - NUMSEGS end-cap X=0    (annular wedge)
;;   - NUMSEGS end-cap X=1000 (annular wedge)
;; ============================================================
(defun vputki-build-3dface-pipe ( D / R Ri i theta1 theta2
                                      y1o z1o y2o z2o
                                      y1i z1i y2i z2i
                                      ents )
  (setq R  (/ D 2.0))
  (setq Ri (- R *VPUTKI-WALL*))
  (setq i 0)
  (setq ents '())

  (while (< i *VPUTKI-NUMSEGS*)
    (setq theta1 (* 2.0 pi (/ (float i)        (float *VPUTKI-NUMSEGS*))))
    (setq theta2 (* 2.0 pi (/ (float (1+ i))   (float *VPUTKI-NUMSEGS*))))

    ;; Outer ring (R)
    (setq y1o (* R (cos theta1)))
    (setq z1o (* R (sin theta1)))
    (setq y2o (* R (cos theta2)))
    (setq z2o (* R (sin theta2)))

    ;; Inner ring (R - wall)
    (setq y1i (* Ri (cos theta1)))
    (setq z1i (* Ri (sin theta1)))
    (setq y2i (* Ri (cos theta2)))
    (setq z2i (* Ri (sin theta2)))

    ;; OUTER side wall: rectangular patch
    (entmake (list
      (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list 0.0    y1o z1o))
      (cons 11 (list 1000.0 y1o z1o))
      (cons 12 (list 1000.0 y2o z2o))
      (cons 13 (list 0.0    y2o z2o))))
    (setq ents (cons (entlast) ents))

    ;; INNER side wall: rectangular patch (vertices reversed for inward normal)
    (entmake (list
      (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list 0.0    y2i z2i))
      (cons 11 (list 1000.0 y2i z2i))
      (cons 12 (list 1000.0 y1i z1i))
      (cons 13 (list 0.0    y1i z1i))))
    (setq ents (cons (entlast) ents))

    ;; END-CAP @ X=0: annular wedge connecting outer→inner ring
    (entmake (list
      (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list 0.0 y1o z1o))   ; outer @ theta1
      (cons 11 (list 0.0 y2o z2o))   ; outer @ theta2
      (cons 12 (list 0.0 y2i z2i))   ; inner @ theta2
      (cons 13 (list 0.0 y1i z1i)))) ; inner @ theta1
    (setq ents (cons (entlast) ents))

    ;; END-CAP @ X=1000: annular wedge (reversed for outward normal)
    (entmake (list
      (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list 1000.0 y1i z1i))   ; inner @ theta1
      (cons 11 (list 1000.0 y2i z2i))   ; inner @ theta2
      (cons 12 (list 1000.0 y2o z2o))   ; outer @ theta2
      (cons 13 (list 1000.0 y1o z1o)))) ; outer @ theta1
    (setq ents (cons (entlast) ents))

    (setq i (1+ i)))
  ents)

;; ============================================================
;; Yhteinen build + block-define -funktio
;; ============================================================
(defun vputki-build-and-block ( D / *error* oldClayer oldCmdecho
                                    blockName ents ss e )

  (defun *error* ( msg )
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ))

  (setq blockName (strcat "VPUTKI-" (itoa D)))

  (if (tblsearch "BLOCK" blockName)
    (progn
      (princ (strcat "\nVIRHE: " blockName " on jo olemassa. Avaa tyhja DWG."))
      (exit)))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))

  (setvar "CMDECHO" 0)
  (setvar "CLAYER"  "0")

  (setq ents (vputki-build-3dface-pipe (float D)))

  ;; Selection set kaikista 3DFACE:ista
  (setq ss (ssadd))
  (foreach e ents (setq ss (ssadd e ss)))

  (command "_.-BLOCK" blockName "0,0,0" ss "")

  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ (strcat "\n" blockName " block-maaritys luotu ("
                 (itoa (* 4 *VPUTKI-NUMSEGS*)) " x 3DFACE, seinama "
                 (rtos *VPUTKI-WALL* 2 1) " mm)."))
  (princ (strcat "\nKoko: OD " (rtos (float D) 2 1) " mm, ID "
                 (rtos (- (float D) (* 2 *VPUTKI-WALL*)) 2 1) " mm,"
                 " pituus 1000 mm."))
  (princ (strcat "\nSeuraavaksi: BEDIT " blockName " -> Linear Pituus (2 grips) +"))
  (princ "\n2 stretch-actionia (oikea + vasen) ohjeen mukaan.")
  (princ (strcat "\nLopuksi ERASE ALL + SAVEAS files/vputki-" (itoa D) ".dwg."))
  (princ))

;; ============================================================
;; Per-koko-komennot
;; ============================================================
(defun c:VPUTKI-BUILD-32 ( / ) (vputki-build-and-block 32))
(defun c:VPUTKI-BUILD-50 ( / ) (vputki-build-and-block 50))
(defun c:VPUTKI-BUILD-75 ( / ) (vputki-build-and-block 75))

(princ "\nVPUTKI-BUILD-32, VPUTKI-BUILD-50 ja VPUTKI-BUILD-75 ladattu.")
(princ "\nAja jokainen erikseen tyhjassa DWG:ssa, BEDIT, SAVEAS.")
(princ)
