;;; build-klhylly-blocks.lsp
;;;
;;; INTERNAL TOOL — sisaltaa block-geometrian luonnin klhylly.dwg:lle.
;;; Ei kuulu ZIP-pakettiin (`make-bundle.ps1` ottaa vain files/-kansion).
;;; Aja kerran tyhjassa DWG:ssa kun klhylly.dwg-block-kirjastoa rakennetaan
;;; tai ladataan uudestaan (esim. mittoja muutetaan).
;;;
;;; Edellytys: UNITS = mm, tyhja DWG (ei olemassa olevia KLHYLLY-LEVY tai
;;; KLHYLLY-TIKAS block-maarityksia).
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto.
;;; Aja:   KLHYLLY-BUILD-BLOCKS
;;;
;;; Tuottaa kaksi block-maaritysta:
;;;   KLHYLLY-LEVY:  5 erillista BOX-soliditeettia (pohja, 2 seinaa, 2 lippaa)
;;;                  + suljettu LWPOLYLINE-outline + DASH-hatch
;;;   KLHYLLY-TIKAS: 2 rail-BOX-soliditeettia + 1 rung-BOX (master)
;;;
;;; Geometria on TASMALLEEN samaa mitoitusta kuin nykyinen klhylly.lsp:n
;;; UNION-pohjainen tuotos (peltipaksuus 1.25, lippa 9, kisko 15x60, jne.).
;;;
;;; HUOMIO: BLOCK ei sisalla parametreja eika actioneita — niiden lisays
;;; tehdaan BEDIT:lla erikseen. Katso tools/KLHYLLY-BEDIT-OHJEET.md.
;;;
;;; Block-kontentti layerille "0" (BYBLOCK) jotta block-instanssin layer
;;; (KYL-LEVYHYLLY tai KYL-TIKASHYLLY) periytyy alaspain.

(vl-load-com)

;; AddBox: keskipiste + dimensiot. Tassa wrapperi ottaa 6 koordinaattia
;; (xmin/ymin/zmin/xmax/ymax/zmax) jotta mitoitus on luettavampi.
(defun klhylly-build-box ( msp xmin ymin zmin xmax ymax zmax / cx cy cz dx dy dz )
  (setq dx (- xmax xmin))
  (setq dy (- ymax ymin))
  (setq dz (- zmax zmin))
  (setq cx (/ (+ xmin xmax) 2.0))
  (setq cy (/ (+ ymin ymax) 2.0))
  (setq cz (/ (+ zmin zmax) 2.0))
  (vla-AddBox msp (vlax-3d-point (list cx cy cz)) dx dy dz)
)

(defun c:KLHYLLY-BUILD-BLOCKS ( / *error*
                                  oldClayer oldCmdecho oldHpassoc oldDelobj
                                  doc msp
                                  sFloor sLWall sRWall sLLip sRLip poly hatch
                                  rail1 rail2 rung
                                  ss e )

  (defun *error* ( msg )
    (if oldDelobj  (setvar "DELOBJ"  oldDelobj))
    (if oldHpassoc (setvar "HPASSOC" oldHpassoc))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  ;; Pre-check: alaa korvaa olemassa olevia maarityksia hiljaa
  (if (or (tblsearch "BLOCK" "KLHYLLY-LEVY")
          (tblsearch "BLOCK" "KLHYLLY-TIKAS"))
    (progn
      (princ "\nVIRHE: KLHYLLY-LEVY tai KLHYLLY-TIKAS on jo olemassa.")
      (princ "\nAvaa tyhja DWG ja yrita uudestaan, tai PURGE block-maarit ensin.")
      (exit)
    )
  )

  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq msp (vla-get-ModelSpace doc))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldHpassoc (getvar "HPASSOC"))
  (setq oldDelobj  (getvar "DELOBJ"))

  (setvar "CMDECHO" 0)
  (setvar "HPASSOC" 1)
  (setvar "DELOBJ"  1)
  (setvar "CLAYER"  "0")

  ;; ============================================================
  ;; KLHYLLY-LEVY
  ;; ============================================================
  ;; 5 erillista peltiseinama-BOXia. EI UNION:eja — dynamic blockin
  ;; stretch-action vaatii akseliyhdensuuntaisia primitiivi-BOXeja.
  (setq sFloor (klhylly-build-box msp 0.0    0.0    0.0    1000.0 500.0  1.25 ))
  (setq sLWall (klhylly-build-box msp 0.0    0.0    0.0    1000.0 1.25   60.0 ))
  (setq sRWall (klhylly-build-box msp 0.0    498.75 0.0    1000.0 500.0  60.0 ))
  (setq sLLip  (klhylly-build-box msp 0.0    1.25   58.75  1000.0 10.25  60.0 ))
  (setq sRLip  (klhylly-build-box msp 0.0    489.75 58.75  1000.0 498.75 60.0 ))

  ;; Suljettu LWPOLYLINE-outline z=0 — toimii hatchin assosiaatio-frame:na
  ;; ja stretch-actionin yksi target-entiteetti.
  (entmake
    (list
      (cons 0 "LWPOLYLINE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbPolyline")
      (cons 90 4)
      (cons 70 1)              ; closed flag
      (cons 38 0.0)            ; elevation
      (cons 10 (list 0.0    0.0))
      (cons 10 (list 1000.0 0.0))
      (cons 10 (list 1000.0 500.0))
      (cons 10 (list 0.0    500.0))
    )
  )
  (setq poly (entlast))

  ;; DASH-hatch outline:n sisalle, scale 40, angle 45, associative
  (command "_.-HATCH" "_P" "DASH" 40 45 "_S" poly "" "")
  (setq hatch (entlast))

  ;; Block-maaritys: select 7 entiteettia (5 BOX + 1 LWPOLYLINE + 1 HATCH)
  (setq ss (ssadd))
  (setq ss (ssadd (vlax-vla-object->ename sFloor) ss))
  (setq ss (ssadd (vlax-vla-object->ename sLWall) ss))
  (setq ss (ssadd (vlax-vla-object->ename sRWall) ss))
  (setq ss (ssadd (vlax-vla-object->ename sLLip)  ss))
  (setq ss (ssadd (vlax-vla-object->ename sRLip)  ss))
  (setq ss (ssadd poly  ss))
  (setq ss (ssadd hatch ss))
  (command "_.-BLOCK" "KLHYLLY-LEVY" "0,0,0" ss "")

  ;; ============================================================
  ;; KLHYLLY-TIKAS
  ;; ============================================================
  ;; 2 kiskoa + 1 master-rung. Array-action arrayttaa rungin BEDIT:ssa.
  (setq rail1 (klhylly-build-box msp 0.0    0.0   0.0   1000.0 15.0  60.0))
  (setq rail2 (klhylly-build-box msp 0.0    485.0 0.0   1000.0 500.0 60.0))
  (setq rung  (klhylly-build-box msp 242.5  15.0  10.0  257.5  485.0 25.0))

  (setq ss (ssadd))
  (setq ss (ssadd (vlax-vla-object->ename rail1) ss))
  (setq ss (ssadd (vlax-vla-object->ename rail2) ss))
  (setq ss (ssadd (vlax-vla-object->ename rung)  ss))
  (command "_.-BLOCK" "KLHYLLY-TIKAS" "0,0,0" ss "")

  ;; Palauta sysvarit
  (setvar "DELOBJ"  oldDelobj)
  (setvar "HPASSOC" oldHpassoc)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nLisatty 2 block-maaritysta: KLHYLLY-LEVY, KLHYLLY-TIKAS")
  (princ "\nSeuraavaksi: avaa BEDIT kummallekin ja lisaa parametrit + actionit")
  (princ "\nohjeen mukaan (tools/KLHYLLY-BEDIT-OHJEET.md). Tallenna lopuksi")
  (princ "\nfiles/klhylly.dwg.")
  (princ)
)

(princ "\nKLHYLLY-BUILD-BLOCKS ladattu. Aja komento KLHYLLY-BUILD-BLOCKS tyhjassa DWG:ssa.")
(princ)
