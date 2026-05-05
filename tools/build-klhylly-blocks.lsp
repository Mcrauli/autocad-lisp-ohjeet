;;; build-klhylly-blocks.lsp
;;;
;;; INTERNAL TOOL — sisaltaa block-geometrian luonnin klhylly-levy.dwg:lle
;;; ja klhylly-tikas.dwg:lle. Ei kuulu ZIP-pakettiin.
;;;
;;; Erilliset DWG:t kahdelle blockille — yhden DWG:n sisalla AutoCAD voi
;;; antaa "Block X references itself" -virheen tietyissa tilanteissa.
;;;
;;; Tyokulku:
;;;   1. Avaa tyhja DWG, APPLOAD tama tiedosto
;;;   2. KLHYLLY-BUILD-LEVY -> luo KLHYLLY-LEVY-block-geometrian
;;;   3. BEDIT KLHYLLY-LEVY -> lisaa parametrit ja actionit
;;;      (ks. tools/KLHYLLY-BEDIT-OHJEET.md)
;;;   4. ERASE all -> SAVEAS files/klhylly-levy.dwg
;;;   5. Avaa toinen tyhja DWG, APPLOAD uudestaan
;;;   6. KLHYLLY-BUILD-TIKAS -> luo KLHYLLY-TIKAS-block-geometrian
;;;   7. BEDIT KLHYLLY-TIKAS -> lisaa parametrit ja actionit
;;;   8. ERASE all -> SAVEAS files/klhylly-tikas.dwg
;;;
;;; Geometria on 2D-LWPOLYLINEja joissa thickness (Z-extrudointi) +
;;; 3DFACEt ylakansiksi. Layer "0" (BYBLOCK) jotta block-instanssin
;;; layer (KYL-LEVYHYLLY/KYL-TIKASHYLLY) periytyy alaspain.

(vl-load-com)

;; LWPOLYLINE-rectangle elevation + thickness
(defun klhylly-build-poly-thick ( xmin ymin xmax ymax elevation thickness / )
  (entmake
    (list
      (cons 0 "LWPOLYLINE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbPolyline")
      (cons 90 4)
      (cons 70 1)              ; closed
      (cons 38 elevation)      ; Z-sijainti
      (cons 39 thickness)      ; Z-extrudointi (vertikaaliset seinat)
      (cons 10 (list xmin ymin))
      (cons 10 (list xmax ymin))
      (cons 10 (list xmax ymax))
      (cons 10 (list xmin ymax))
    )
  )
  (entlast)
)

;; 3DFACE-quad annetuilla 4 nurkalla yhdella Z-tasolla
(defun klhylly-build-3dface ( xmin ymin xmax ymax z / )
  (entmake
    (list
      (cons 0 "3DFACE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list xmin ymin z))
      (cons 11 (list xmax ymin z))
      (cons 12 (list xmax ymax z))
      (cons 13 (list xmin ymax z))
    )
  )
  (entlast)
)

;; ============================================================
;; KLHYLLY-BUILD-LEVY
;; ============================================================
;; 5 LWPOLYLINEa thickness:lla + 3DFACE pohjalle + outline + DASH-hatch
(defun c:KLHYLLY-BUILD-LEVY ( / *error*
                                oldClayer oldCmdecho oldHpassoc
                                sFloor sLWall sRWall sLLip sRLip sFloorTop
                                poly hatch ss )

  (defun *error* ( msg )
    (if oldHpassoc (setvar "HPASSOC" oldHpassoc))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (if (tblsearch "BLOCK" "KLHYLLY-LEVY")
    (progn
      (princ "\nVIRHE: KLHYLLY-LEVY on jo olemassa. Avaa tyhja DWG.")
      (exit)))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldHpassoc (getvar "HPASSOC"))

  (setvar "CMDECHO" 0)
  (setvar "HPASSOC" 1)
  (setvar "CLAYER"  "0")

  ;; 5 peltiseinama-LWPOLYLINEa
  (setq sFloor (klhylly-build-poly-thick 0.0    0.0    1000.0 500.0  0.0    1.25))
  (setq sLWall (klhylly-build-poly-thick 0.0    0.0    1000.0 1.25   0.0    60.0))
  (setq sRWall (klhylly-build-poly-thick 0.0    498.75 1000.0 500.0  0.0    60.0))
  (setq sLLip  (klhylly-build-poly-thick 0.0    1.25   1000.0 10.25  58.75  1.25))
  (setq sRLip  (klhylly-build-poly-thick 0.0    489.75 1000.0 498.75 58.75  1.25))

  ;; 3DFACE pohjan ylapinnaksi z=1.25 — Realistic-tilan tayte
  (setq sFloorTop (klhylly-build-3dface 0.0 0.0 1000.0 500.0 1.25))

  ;; Outline + DASH-hatch (plan-annotation)
  (setq poly (klhylly-build-poly-thick 0.0 0.0 1000.0 500.0 0.0 0.0))
  (command "_.-HATCH" "_P" "DASH" 40 45 "_S" poly "" "")
  (setq hatch (entlast))

  (setq ss (ssadd))
  (setq ss (ssadd sFloor    ss))
  (setq ss (ssadd sLWall    ss))
  (setq ss (ssadd sRWall    ss))
  (setq ss (ssadd sLLip     ss))
  (setq ss (ssadd sRLip     ss))
  (setq ss (ssadd sFloorTop ss))
  (setq ss (ssadd poly      ss))
  (setq ss (ssadd hatch     ss))
  (command "_.-BLOCK" "KLHYLLY-LEVY" "0,0,0" ss "")

  (setvar "HPASSOC" oldHpassoc)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nKLHYLLY-LEVY block-maaritys luotu (8 entiteettia).")
  (princ "\nSeuraavaksi: BEDIT KLHYLLY-LEVY -> parametrit + actionit")
  (princ "\nohjeen mukaan, sitten ERASE ALL + SAVEAS files/klhylly-levy.dwg.")
  (princ)
)

;; ============================================================
;; KLHYLLY-BUILD-TIKAS
;; ============================================================
;; 2 rail + 1 rung-master + 3 3DFACEa ylakansiksi
(defun c:KLHYLLY-BUILD-TIKAS ( / *error*
                                 oldClayer oldCmdecho
                                 rail1 rail2 rung rail1Top rail2Top rungTop ss )

  (defun *error* ( msg )
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (if (tblsearch "BLOCK" "KLHYLLY-TIKAS")
    (progn
      (princ "\nVIRHE: KLHYLLY-TIKAS on jo olemassa. Avaa tyhja DWG.")
      (exit)))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))

  (setvar "CMDECHO" 0)
  (setvar "CLAYER"  "0")

  ;; 2 rail-LWPOLYLINEa + 1 rung-master
  (setq rail1 (klhylly-build-poly-thick 0.0    0.0    1000.0 15.0   0.0    60.0))
  (setq rail2 (klhylly-build-poly-thick 0.0    485.0  1000.0 500.0  0.0    60.0))
  (setq rung  (klhylly-build-poly-thick 242.5  15.0   257.5  485.0  10.0   15.0))

  ;; 3DFACEt ylakansiksi
  (setq rail1Top (klhylly-build-3dface 0.0    0.0   1000.0 15.0   60.0))
  (setq rail2Top (klhylly-build-3dface 0.0    485.0 1000.0 500.0  60.0))
  (setq rungTop  (klhylly-build-3dface 242.5  15.0  257.5  485.0  25.0))

  (setq ss (ssadd))
  (setq ss (ssadd rail1    ss))
  (setq ss (ssadd rail2    ss))
  (setq ss (ssadd rung     ss))
  (setq ss (ssadd rail1Top ss))
  (setq ss (ssadd rail2Top ss))
  (setq ss (ssadd rungTop  ss))
  (command "_.-BLOCK" "KLHYLLY-TIKAS" "0,0,0" ss "")

  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nKLHYLLY-TIKAS block-maaritys luotu (6 entiteettia).")
  (princ "\nSeuraavaksi: BEDIT KLHYLLY-TIKAS -> parametrit + actionit")
  (princ "\nohjeen mukaan, sitten ERASE ALL + SAVEAS files/klhylly-tikas.dwg.")
  (princ)
)

(princ "\nKLHYLLY-BUILD-LEVY ja KLHYLLY-BUILD-TIKAS ladattu.")
(princ "\nAja molemmat erikseen tyhjissa DWG:issa, BEDIT, SAVEAS.")
(princ)
