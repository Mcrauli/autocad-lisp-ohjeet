;;; build-kotelo-blocks.lsp
;;;
;;; INTERNAL TOOL — sisaltaa KOTELO-block-geometrian luonnin Kotelo.dwg:lle.
;;; Ei kuulu ZIP-pakettiin.
;;;
;;; MIKSI TAMA ON OLEMASSA:
;;; AutoCAD:n dynamic blockin Stretch-action EI venyta 3D-soliditeetteja
;;; — silla ei ole liikuteltavia vertexeja, joten Stretch vain SIIRTAA
;;; koko kappaleen. Sama seina johon KLHYLLY-projekti tormasi (testattu
;;; 5.5.2026). Ratkaisu: geometria rakennetaan 2D-LWPOLYLINEista joilla
;;; on thickness (Z-extrudointi) + 3DFACE-kansista. LWPOLYLINE:n vertexit
;;; liikkuvat Stretchissa -> kotelo venyy oikein.
;;;
;;; KOTELON MUOTO: suljettu suorakaidekotelo, paista auki (4 seinaa:
;;; pohja, kansi, vasen, oikea — vakiopoikkileikkaus koko pituudelta).
;;;
;;; Tyokulku:
;;;   1. Avaa tyhja DWG, APPLOAD tama tiedosto
;;;   2. KOTELO-BUILD -> syota mitat (pituus/leveys/korkeus/seinama)
;;;      -> luo KOTELO-block-geometrian
;;;   3. BEDIT KOTELO -> lisaa Pituus-parametri + Stretch-action
;;;      (ks. tools/KOTELO-BEDIT-OHJEET.md)
;;;   4. ERASE ALL -> SAVEAS files/Kotelo.dwg
;;;
;;; Geometria layerilla "0" (BYBLOCK) jotta block-instanssin layer
;;; (KYL-KOTELO) periytyy alaspain.

(vl-load-com)

;; ============================================================
;; ENTITEETTIHELPERIT
;; ============================================================

;; Suljettu LWPOLYLINE-suorakaide XY-tasossa, elevation + thickness
;; (thickness = Z-extrudointi -> pystyseinat). Layer 0 / BYBLOCK.
(defun kotelo-build-poly-thick ( xmin ymin xmax ymax elevation thickness / )
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

;; 3DFACE-quad neljasta vapaasta 3D-pisteesta. Layer 0 / BYBLOCK.
;; 3DFACE:n nurkkapisteet liikkuvat Stretchissa kuten LWPOLYLINE:n
;; vertexit — joten ne venyvat oikein kun X=L -pää on stretch framessa.
(defun kotelo-build-3dface-pts ( p1 p2 p3 p4 / )
  (entmake
    (list
      (cons 0 "3DFACE")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbFace")
      (cons 10 p1)
      (cons 11 p2)
      (cons 12 p3)
      (cons 13 p4)
    )
  )
  (entlast)
)

;; POINT-entiteetti annettuun 3D-pisteeseen. Layer 0 / BYBLOCK.
;; Kaytetaan X=0-paadyn reuna- ja keskipisteissa snap-targetteina —
;; NODe-osnap napsahtaa naihin kun kayttaja siirtaa/kohdistaa kotelon
;; muiden systeemien suhteen. Pisteet sijaitsevat X=0:ssa, joten Pituus-
;; Stretch ei vaikuta niihin — pysyvat alkupaadyssa miten venyykaan.
(defun kotelo-build-point ( x y z / )
  (entmake
    (list
      (cons 0 "POINT")
      (cons 100 "AcDbEntity")
      (cons 8 "0")
      (cons 100 "AcDbPoint")
      (cons 10 (list x y z))
    )
  )
  (entlast)
)

;; ============================================================
;; KOTELO-BUILD
;; ============================================================
;; Suljettu suorakaidekotelo, paista auki. 4 LWPOLYLINE+thickness
;; -seinaa + 8 3DFACE-kantta (ulko- ja sisapinta per seina) = 12
;; entiteettia. Kaikki kulkevat X-suunnassa -> kaikki venyvat
;; Pituus-Stretchissa.

(defun c:KOTELO-BUILD ( / *error* oldClayer oldCmdecho
                          L W H tt
                          pohja kansi vasen oikea
                          pAla pYla kAla kYla vUlko vSisa oUlko oSisa
                          snTop snLeft snRight snCent
                          ss )

  (defun *error* ( msg )
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (if (tblsearch "BLOCK" "KOTELO")
    (progn
      (princ "\nVIRHE: KOTELO on jo olemassa tassa DWG:ssa. Avaa tyhja DWG.")
      (exit)))

  ;; Mitat — getreal, oletukset suluissa. Enter = oletus.
  (setq L (getreal "\nKotelon pituus mm <1000>: "))
  (if (null L) (setq L 1000.0))
  (setq W (getreal "\nKotelon leveys mm <200>: "))
  (if (null W) (setq W 200.0))
  (setq H (getreal "\nKotelon korkeus mm <150>: "))
  (if (null H) (setq H 150.0))
  (setq tt (getreal "\nSeinamavahvuus mm <2>: "))
  (if (null tt) (setq tt 2.0))

  ;; Validointi
  (cond
    ((<= L 1.0)         (princ "\nPituus liian pieni.") (exit))
    ((<= W (* 2.0 tt))  (princ "\nLeveys oltava > 2 x seinamavahvuus.") (exit))
    ((<= H (* 2.0 tt))  (princ "\nKorkeus oltava > 2 x seinamavahvuus.") (exit))
    ((<= tt 0.0)        (princ "\nSeinamavahvuus liian pieni.") (exit))
  )

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (setvar "CLAYER"  "0")

  ;; --- 4 LWPOLYLINE+thickness -seinaa ---
  ;; pohja: koko XY-pohja, thickness tt ylospain
  (setq pohja (kotelo-build-poly-thick 0.0 0.0 L W 0.0 tt))
  ;; kansi: koko XY-pinta korkeudella H-tt, thickness tt
  (setq kansi (kotelo-build-poly-thick 0.0 0.0 L W (- H tt) tt))
  ;; vasen seina: ohut Y-suunnassa (0..tt), thickness H
  (setq vasen (kotelo-build-poly-thick 0.0 0.0 L tt 0.0 H))
  ;; oikea seina: ohut Y-suunnassa (W-tt..W), thickness H
  (setq oikea (kotelo-build-poly-thick 0.0 (- W tt) L W 0.0 H))

  ;; --- 8 3DFACE-kantta (ulko + sisa per seina) ---
  ;; pohja: ala z=0, yla z=tt
  (setq pAla (kotelo-build-3dface-pts
               (list 0.0 0.0 0.0) (list L 0.0 0.0)
               (list L W 0.0)     (list 0.0 W 0.0)))
  (setq pYla (kotelo-build-3dface-pts
               (list 0.0 0.0 tt) (list L 0.0 tt)
               (list L W tt)     (list 0.0 W tt)))
  ;; kansi: ala z=H-tt, yla z=H
  (setq kAla (kotelo-build-3dface-pts
               (list 0.0 0.0 (- H tt)) (list L 0.0 (- H tt))
               (list L W (- H tt))     (list 0.0 W (- H tt))))
  (setq kYla (kotelo-build-3dface-pts
               (list 0.0 0.0 H) (list L 0.0 H)
               (list L W H)     (list 0.0 W H)))
  ;; vasen seina: ulko y=0, sisa y=tt
  (setq vUlko (kotelo-build-3dface-pts
                (list 0.0 0.0 0.0) (list L 0.0 0.0)
                (list L 0.0 H)     (list 0.0 0.0 H)))
  (setq vSisa (kotelo-build-3dface-pts
                (list 0.0 tt 0.0) (list L tt 0.0)
                (list L tt H)     (list 0.0 tt H)))
  ;; oikea seina: ulko y=W, sisa y=W-tt
  (setq oUlko (kotelo-build-3dface-pts
                (list 0.0 W 0.0) (list L W 0.0)
                (list L W H)     (list 0.0 W H)))
  (setq oSisa (kotelo-build-3dface-pts
                (list 0.0 (- W tt) 0.0) (list L (- W tt) 0.0)
                (list L (- W tt) H)     (list 0.0 (- W tt) H)))

  ;; --- 4 POINT-entiteettia X=0-paadyssa: kansi/vasen/oikea-reunojen
  ;;     keskipisteet + paadyn keskipiste. Pohjareunan midpointia ei
  ;;     tarvita (sita ei kayteta snappauksessa). NODe-osnap-targetit
  ;;     kotelon kohdistamiseen toisten systeemien suhteen ilman
  ;;     manuaalista MOVE:a. Pituus-Stretch ei kosketa naita (X=0
  ;;     pysyy paikallaan).
  (setq snTop   (kotelo-build-point 0.0 (* 0.5 W) H))        ; kansireunan keski
  (setq snLeft  (kotelo-build-point 0.0 0.0       (* 0.5 H))); vasen kylki, keski
  (setq snRight (kotelo-build-point 0.0 W         (* 0.5 H))); oikea kylki, keski
  (setq snCent  (kotelo-build-point 0.0 (* 0.5 W) (* 0.5 H))); paadyn keski

  ;; --- Kokoa block-maaritys ---
  (setq ss (ssadd))
  (foreach e (list pohja kansi vasen oikea
                   pAla pYla kAla kYla vUlko vSisa oUlko oSisa
                   snTop snLeft snRight snCent)
    (setq ss (ssadd e ss)))
  (command "_.-BLOCK" "KOTELO" "0,0,0" ss "")

  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ (strcat "\nKOTELO block-maaritys luotu (16 entiteettia: 12 geom + 4 snap-point)."))
  (princ (strcat "\n  Pituus " (rtos L 2 1) "  Leveys " (rtos W 2 1)
                 "  Korkeus " (rtos H 2 1) "  Seinama " (rtos tt 2 1) " mm"))
  (princ "\nSeuraavaksi: BEDIT KOTELO -> Pituus-parametri + Stretch-action")
  (princ "\nohjeen mukaan (tools/KOTELO-BEDIT-OHJEET.md), sitten ERASE ALL")
  (princ "\n+ SAVEAS files/Kotelo.dwg. NODe-osnap napsahtaa 4 snap-pisteeseen.")
  (princ)
)

(princ "\nKOTELO-BUILD ladattu. Aja tyhjassa DWG:ssa, sitten BEDIT + SAVEAS.")
(princ)
