;;; build-klhylly-blocks.lsp
;;;
;;; INTERNAL TOOL — sisaltaa block-geometrian luonnin klhylly.dwg:lle.
;;; Ei kuulu ZIP-pakettiin (`make-bundle.ps1` ottaa vain files/-kansion).
;;; Aja kerran tyhjassa DWG:ssa kun klhylly.dwg-block-kirjastoa rakennetaan.
;;;
;;; Edellytys: UNITS = mm, tyhja DWG (ei olemassa olevia KLHYLLY-LEVY tai
;;; KLHYLLY-TIKAS block-maarityksia).
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto.
;;; Aja:   KLHYLLY-BUILD-BLOCKS
;;;
;;; Tuottaa kaksi block-maaritysta:
;;;   KLHYLLY-LEVY:  5 LWPOLYLINE-rectanglea joilla thickness
;;;                  (peltipohja + 2 seinaa + 2 lippaa) + outline + DASH-hatch
;;;   KLHYLLY-TIKAS: 2 rail-polylinea + 1 rung-polyline (master)
;;;
;;; KRIITTINEN MUUTOS (vs. v1): geometria on 2D-LWPOLYLINEja joissa thickness
;;; (extrudointi Z-suuntaan), EI 3D-soliditeetteja. Syy: dynamic blockin
;;; stretch-action toimii LWPOLYLINEille luotettavasti, mutta 3D-soliditeetit
;;; eivat stretchaudu vaikka olisivat axiomaattisia primitiivi-BOXeja.
;;; Visuaalisesti polyline+thickness rendaa kuten ohut 3D-laatikko (4 pystyseinaa,
;;; ei ylakkaa/alakkaa-pintaa) — sheet-metal-hyllyssa peltipaksuus 1.25 mm
;;; tekee top/bottom-pinnat kaytannossa nakymattomiksi.
;;;
;;; Block-kontentti layerille "0" (BYBLOCK) jotta block-instanssin layer
;;; (KYL-LEVYHYLLY tai KYL-TIKASHYLLY) periytyy alaspain.

(vl-load-com)

;; LWPOLYLINE-rectangle joilla elevation (Z-sijainti) + thickness (Z-extrudointi).
;; Suljettu (closed = 70 . 1). Layer = "0" -> BYBLOCK behavior.
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

(defun c:KLHYLLY-BUILD-BLOCKS ( / *error*
                                  oldClayer oldCmdecho oldHpassoc
                                  sFloor sLWall sRWall sLLip sRLip poly hatch
                                  rail1 rail2 rung
                                  ss )

  (defun *error* ( msg )
    (if oldHpassoc (setvar "HPASSOC" oldHpassoc))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (if (or (tblsearch "BLOCK" "KLHYLLY-LEVY")
          (tblsearch "BLOCK" "KLHYLLY-TIKAS"))
    (progn
      (princ "\nVIRHE: KLHYLLY-LEVY tai KLHYLLY-TIKAS on jo olemassa.")
      (princ "\nAvaa tyhja DWG ja yrita uudestaan, tai PURGE block-maarit ensin.")
      (exit)
    )
  )

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldHpassoc (getvar "HPASSOC"))

  (setvar "CMDECHO" 0)
  (setvar "HPASSOC" 1)
  (setvar "CLAYER"  "0")

  ;; ============================================================
  ;; KLHYLLY-LEVY — 5 LWPOLYLINE-rectangle thickness:lla + 3DFACE pohjalle
  ;; ============================================================
  ;; Pohja: 0..1000 X, 0..500 Y, Z=0..1.25
  (setq sFloor (klhylly-build-poly-thick 0.0    0.0    1000.0 500.0  0.0    1.25))
  ;; Vasen seina: 0..1000 X, 0..1.25 Y, Z=0..60
  (setq sLWall (klhylly-build-poly-thick 0.0    0.0    1000.0 1.25   0.0    60.0))
  ;; Oikea seina: 0..1000 X, 498.75..500 Y, Z=0..60
  (setq sRWall (klhylly-build-poly-thick 0.0    498.75 1000.0 500.0  0.0    60.0))
  ;; Vasen lippa: 0..1000 X, 1.25..10.25 Y, Z=58.75..60
  (setq sLLip  (klhylly-build-poly-thick 0.0    1.25   1000.0 10.25  58.75  1.25))
  ;; Oikea lippa: 0..1000 X, 489.75..498.75 Y, Z=58.75..60
  (setq sRLip  (klhylly-build-poly-thick 0.0    489.75 1000.0 498.75 58.75  1.25))

  ;; 3DFACE pohjan ylapinnaksi z=1.25 — Realistic-tilassa floor renderoituu
  ;; tayttena pintana. Polyline+thickness yksinaan luo vain 4 pystyseinama,
  ;; ei ylakanta — Realistic-naytossa lattian lapi nakisi muuten.
  (entmake
    (list
      (cons 0 "3DFACE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 (list 0.0    0.0    1.25))
      (cons 11 (list 1000.0 0.0    1.25))
      (cons 12 (list 1000.0 500.0 1.25))
      (cons 13 (list 0.0    500.0 1.25))
    )
  )
  (setq sFloorTop (entlast))

  ;; Outline (z=0, ei thickness) — hatch:n associative-frame
  (entmake
    (list
      (cons 0 "LWPOLYLINE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbPolyline")
      (cons 90 4)
      (cons 70 1)
      (cons 38 0.0)
      (cons 10 (list 0.0    0.0))
      (cons 10 (list 1000.0 0.0))
      (cons 10 (list 1000.0 500.0))
      (cons 10 (list 0.0    500.0))
    )
  )
  (setq poly (entlast))

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

  ;; ============================================================
  ;; KLHYLLY-TIKAS — 2 rail + 1 rung (master) + 3DFACEt ylakansiksi
  ;; ============================================================
  ;; Rail1: 0..1000 X, 0..15 Y, Z=0..60
  (setq rail1 (klhylly-build-poly-thick 0.0    0.0    1000.0 15.0   0.0    60.0))
  ;; Rail2: 0..1000 X, 485..500 Y, Z=0..60
  (setq rail2 (klhylly-build-poly-thick 0.0    485.0  1000.0 500.0  0.0    60.0))
  ;; Rung-master: 242.5..257.5 X, 15..485 Y, Z=10..25
  (setq rung  (klhylly-build-poly-thick 242.5  15.0   257.5  485.0  10.0   15.0))

  ;; 3DFACEt ylakansiksi — Realistic-tilassa rails ja rung renderoituvat
  ;; tayttena pintana ylhaalta katsoen (polyline+thickness yksinaan luo
  ;; vain 4 pystyseinama, ilman ylakanta nakisi lapi).
  (entmake (list (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
                 (cons 100 "AcDbFace")
                 (cons 10 (list 0.0    0.0   60.0))
                 (cons 11 (list 1000.0 0.0   60.0))
                 (cons 12 (list 1000.0 15.0  60.0))
                 (cons 13 (list 0.0    15.0  60.0))))
  (setq rail1Top (entlast))

  (entmake (list (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
                 (cons 100 "AcDbFace")
                 (cons 10 (list 0.0    485.0 60.0))
                 (cons 11 (list 1000.0 485.0 60.0))
                 (cons 12 (list 1000.0 500.0 60.0))
                 (cons 13 (list 0.0    500.0 60.0))))
  (setq rail2Top (entlast))

  (entmake (list (cons 0 "3DFACE") (cons 100 "AcDbEntity") (cons 8 "0")
                 (cons 100 "AcDbFace")
                 (cons 10 (list 242.5  15.0  25.0))
                 (cons 11 (list 257.5  15.0  25.0))
                 (cons 12 (list 257.5  485.0 25.0))
                 (cons 13 (list 242.5  485.0 25.0))))
  (setq rungTop (entlast))

  (setq ss (ssadd))
  (setq ss (ssadd rail1    ss))
  (setq ss (ssadd rail2    ss))
  (setq ss (ssadd rung     ss))
  (setq ss (ssadd rail1Top ss))
  (setq ss (ssadd rail2Top ss))
  (setq ss (ssadd rungTop  ss))
  (command "_.-BLOCK" "KLHYLLY-TIKAS" "0,0,0" ss "")

  (setvar "HPASSOC" oldHpassoc)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nLisatty 2 block-maaritysta: KLHYLLY-LEVY, KLHYLLY-TIKAS")
  (princ "\nGeometria on LWPOLYLINEja joilla thickness — stretchaa luotettavasti.")
  (princ "\nSeuraavaksi: BEDIT + parametrit + actionit ohjeen mukaan,")
  (princ "\nlopuksi tallenna files/klhylly.dwg.")
  (princ)
)

(princ "\nKLHYLLY-BUILD-BLOCKS ladattu. Aja komento KLHYLLY-BUILD-BLOCKS tyhjassa DWG:ssa.")
(princ)
