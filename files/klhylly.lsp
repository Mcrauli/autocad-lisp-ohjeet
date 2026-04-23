;;; KLHYLLY.LSP - Kylmalaitehyllyn piirtokomento
;;; Lataa: APPLOAD -> valitse tama tiedosto.
;;; Kayta:  KLHYLLY -> LEVY/TIKAS -> 300/400/500 -> pick start -> pick end
;;; Layerit: LEVY -> KYL-LEVYHYLLY, TIKAS -> KYL-TIKASHYLLY.
;;;
;;; Leveyspuoli valitaan automaattisesti: jos p1:n toisella puolella on jo
;;; KYL-*HYLLY-entiteetti ja toisella ei, uusi hylly levenee tyhjalle
;;; puolelle (ei piirry vanhan paalle). Jos molemmat puolet tyhjia tai molemmat
;;; varatut, oletus on CCW (+90 vetosuunnasta).
;;;
;;; Aloituspiste: kaksi-tasoinen snap:
;;;   (a) OSMODE pakotetaan ENDP+INT:iin pickin ajaksi -> AutoCADin natiivi
;;;       OSNAP nappaa kulman visuaalisella merkilla ennen klikkausta.
;;;       Palautuu automaattisesti.
;;;   (b) Fallback: ssget-pohjainen haku lahimpaan nurkkaan
;;;       (LWPOLYLINE-vertex tai 3DSOLID-bbox) <= 80 mm paahan, jos OSNAP
;;;       ei ollut riittava.
;;; Nain uusi hylly tulee flush vanhan reunaan vaikka klikkaus olisi
;;; epa-tarkka. Tyhjassa kohdassa klikkaus jaa paikalleen.
;;; LEVY (levyhylly): taivutettu peltilevy (5 slabia UNIONed) + DASH-hatch
;;;        2D-polyline z=0 tasolla ulkokehyksen kanssa, kaikki yhdessa
;;;        anonyymissa GROUPissa. Yks klikki valitsee kaikki kun PICKSTYLE=1.
;;;        Mitat: 60 mm kokonaiskorkeus, 1.25 mm peltipaksuus,
;;;        9 mm lippa ylhaalla kaannetty sisaanpain.
;;;        Hatch: pattern DASH, scale 40, angle 45, associative, BYLAYER.
;;; TIKAS (valmistajan mitat): yksi 3D-solidi kokonaisuudessaan (UNION).
;;;   - 2 kiskoa reunoilla: 15 mm leveä x 60 mm korkea, pituus = hyllyn pituus.
;;;   - Poikkitikat: 15 mm pituussuunnassa x 15 mm korkeat,
;;;     elevation z = 10 -> yläpinta z=25 eli 35 mm kiskon ylapinnan alla.
;;;     Leveyssuunta kiskojen sisapintojen valissa.
;;;   - 250 mm väli mitataan tikkaan keskipisteesta seuraavan keskipisteeseen.
;;;   - Kaikki osat UNION:oitu yhdeksi 3D-soliditeetiksi = yks klikki valitsee.

(vl-load-com)

;; Varmistaa etta layer on olemassa true color -varilla (RGB).
;; Jos layer jo on, ei kosketa sen asetuksiin.
(defun klhylly-ensure-layer ( layerName r g b
                              / acadObj doc layers layer col classIds cid result )
  (if (null (tblsearch "LAYER" layerName))
    (progn
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq layers (vla-get-Layers doc))
      (setq layer (vla-Add layers layerName))
      ;; Kokeile useita AcCmColor ClassIdita (versioriippuvainen)
      (setq classIds '("AutoCAD.AcCmColor.25"
                       "AutoCAD.AcCmColor.24"
                       "AutoCAD.AcCmColor.23"
                       "AutoCAD.AcCmColor.22"
                       "AutoCAD.AcCmColor.21"
                       "AutoCAD.AcCmColor.20"
                       "AutoCAD.AcCmColor.19"
                       "AutoCAD.AcCmColor.18"
                       "AutoCAD.AcCmColor.17"
                       "AutoCAD.AcCmColor.16"
                       "AutoCAD.AcCmColor"))
      (setq col nil)
      (foreach cid classIds
        (if (null col)
          (progn
            (setq result
              (vl-catch-all-apply
                'vla-GetInterfaceObject
                (list acadObj cid)))
            (if (not (vl-catch-all-error-p result))
              (setq col result))
          )
        )
      )
      (if col
        (progn
          (vla-SetRGB col r g b)
          (vla-put-TrueColor layer col)
          (vlax-release-object col)
        )
        ;; Fallback: lahin index-vari jos AcCmColor ei saatavilla
        (vla-put-Color layer 5)
      )
    )
  )
  layerName
)

;; Piirtaa suljetun LWPOLYLINE-rectanglen annetulla elevation+thickness.
;; Palauttaa luodun polylinen ename. Layer = CLAYER (aseta ennen kutsua).
(defun klhylly-make-frame ( q1 q2 q3 q4 elevation frameThickness / )
  (entmake
    (list
      (cons 0 "LWPOLYLINE")
      (cons 100 "AcDbEntity")
      (cons 8 (getvar "CLAYER"))
      (cons 100 "AcDbPolyline")
      (cons 90 4)
      (cons 70 1)
      (cons 38 elevation)
      (cons 39 frameThickness)
      (cons 10 (list (car q1) (cadr q1)))
      (cons 10 (list (car q2) (cadr q2)))
      (cons 10 (list (car q3) (cadr q3)))
      (cons 10 (list (car q4) (cadr q4)))
    )
  )
  (entlast)
)

;; Tekee suljetun 2D LWPOLYLINE-rectanglen ja ekstrudoi sen 3D-solidiksi.
;; Poistaa lahdepolylinen (DELOBJ=1 asetettu ylakomennossa).
;; Palauttaa luodun 3D-solidin ename:n.
(defun klhylly-extrude-rect ( q1 q2 q3 q4 elevation height / )
  (klhylly-make-frame q1 q2 q3 q4 elevation 0.0)
  (command "_.EXTRUDE" (entlast) "" height)
  (entlast)
)

;; Yleinen "slab" 3D-solidi: rectangle shelf-local koordinaateissa, ekstrudoitu
;; pystysuoraan. Parametrit:
;;   p1, ang, perp        = shelfin aloituspiste ja suunnat
;;   offsetFromP1         = slabin alareunan etaisyys p1:sta perp-suunnassa
;;   width                = slabin leveys perp-suunnassa
;;   elevation            = slabin pohjan z-korkeus
;;   thickness            = slabin Z-paksuus (extrude height)
;; Palauttaa luodun 3D-solidin ename:n.
(defun klhylly-make-slab ( p1 ang pituus perp offsetFromP1 width elevation thickness
                            / q1 q2 q3 q4 )
  (setq q1 (polar p1 perp offsetFromP1))
  (setq q2 (polar q1 ang pituus))
  (setq q3 (polar q2 perp width))
  (setq q4 (polar q1 perp width))
  (klhylly-extrude-rect q1 q2 q3 q4 elevation thickness)
)

;; Kisko 3D-solidina (TIKAS). Alareuna aina z=0.
(defun klhylly-make-rail ( p1 ang pituus perp offsetFromP1 railWidth railThickness / )
  (klhylly-make-slab p1 ang pituus perp offsetFromP1 railWidth 0.0 railThickness)
)

;; Poikkitikas 3D-solidina (EXTRUDE).
;; center = tikkaan keskipiste pituussuunnassa p1:sta mitattuna
;; rungWidth = tikkaan leveys pituussuunnassa
;; perpStart, perpEnd = perp-suuntaiset rajat p1:sta
(defun klhylly-make-rung ( p1 ang perp center rungWidth perpStart perpEnd
                            rungZ rungThickness
                            / halfW pA pB q1 q2 q3 q4 )
  (setq halfW (/ rungWidth 2.0))
  (setq pA (polar p1 ang (- center halfW)))
  (setq pB (polar p1 ang (+ center halfW)))
  (setq q1 (polar pA perp perpStart))
  (setq q2 (polar pB perp perpStart))
  (setq q3 (polar pB perp perpEnd))
  (setq q4 (polar pA perp perpEnd))
  (klhylly-extrude-rect q1 q2 q3 q4 rungZ rungThickness)
)

;; Piirtaa poikkitikkaat kiskojen sisapintojen valille.
;; Palauttaa listan luoduista tikka-solidi-enameista (UNION-kayttoön).
(defun klhylly-draw-rungs ( p1 ang perp pituus levy rungSpacing
                             rungWidth rungZ rungThickness railWidth
                             / halfW innerStart innerEnd i center rungs )
  (setq halfW (/ rungWidth 2.0))
  (setq innerStart railWidth)
  (setq innerEnd   (- levy railWidth))
  (setq i 1)
  (setq center (* i rungSpacing))
  (setq rungs nil)
  (while (<= (+ center halfW) pituus)
    (setq rungs
      (cons (klhylly-make-rung p1 ang perp center rungWidth innerStart innerEnd
                               rungZ rungThickness)
            rungs))
    (setq i (1+ i))
    (setq center (* i rungSpacing))
  )
  rungs
)

;; Palauttaa T jos pisteen ymparilla (pieni crossing-box) on KYL-*HYLLY-entiteetti.
(defun klhylly-point-occupied-p ( pt / delta ss )
  (setq delta 0.5)
  (setq ss (ssget "_C"
                   (list (- (car pt) delta) (- (cadr pt) delta))
                   (list (+ (car pt) delta) (+ (cadr pt) delta))
                   '((8 . "KYL-*HYLLY"))))
  (not (null ss))
)

;; Palauttaa 3DSOLIDin 4 akseliaalin bbox-nurkkaa (XY, z ignore).
;; Kiertyneille solideille bbox on akseliaalinen -> vain X/Y-akseliset oikein.
(defun klhylly-solid-bbox-corners ( ent / obj minArr maxArr result mn mx )
  (setq obj (vlax-ename->vla-object ent))
  (setq minArr nil maxArr nil)
  (setq result
    (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minArr 'maxArr)))
  (if (and (not (vl-catch-all-error-p result)) minArr maxArr)
    (progn
      (setq mn (vlax-safearray->list minArr))
      (setq mx (vlax-safearray->list maxArr))
      (list
        (list (nth 0 mn) (nth 1 mn))
        (list (nth 0 mx) (nth 1 mn))
        (list (nth 0 mx) (nth 1 mx))
        (list (nth 0 mn) (nth 1 mx))
      )
    )
    nil
  )
)

;; Etsii lahimman nurkan KYL-*HYLLY-entiteetista p1:sta.
;; LWPOLYLINE: DXF 10 -vertexit. 3DSOLID: bbox-nurkat.
;; Palauttaa snappi-pisteen jos <= maxDist paahan, muuten nil.
;; Toimii zoomista riippumatta — ei kayta OSNAP/APERTURE-systemiikkaa.
(defun klhylly-snap-corner ( pt / boxR maxDist ss i ent entType corners
                                   best bestD c d )
  (setq boxR 100.0)
  (setq maxDist 80.0)
  (setq ss (ssget "_C"
                   (list (- (car pt) boxR) (- (cadr pt) boxR))
                   (list (+ (car pt) boxR) (+ (cadr pt) boxR))
                   '((8 . "KYL-*HYLLY"))))
  (setq best nil bestD maxDist)
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent     (ssname ss i))
        (setq entType (cdr (assoc 0 (entget ent))))
        (setq corners
          (cond
            ((= entType "LWPOLYLINE")
              (mapcar '(lambda (pr)
                          (list (car (cdr pr)) (cadr (cdr pr))))
                      (vl-remove-if-not '(lambda (pr) (= (car pr) 10))
                                        (entget ent))))
            ((= entType "3DSOLID")
              (klhylly-solid-bbox-corners ent))
            (t nil)
          )
        )
        (foreach c corners
          (setq d (distance (list (car pt) (cadr pt))
                            (list (car c) (cadr c))))
          (if (< d bestD)
            (progn
              (setq best  (list (car c) (cadr c) 0.0))
              (setq bestD d)
            )
          )
        )
        (setq i (1+ i))
      )
    )
  )
  best
)

;; Valitsee perp-suunnan automaattisesti: probiaa p1:n molemmilla puolilla
;; pienen offsetin paassa ja valitsee sen puolen, joka on tyhja.
;; Jos molemmat tyhjia tai molemmat varatut, palauttaa oletus-CCW.
(defun klhylly-auto-perp ( p1 ang / perpCCW perpCW pCCW pCW occCCW occCW )
  (setq perpCCW (+ ang (/ pi 2.0)))
  (setq perpCW  (- ang (/ pi 2.0)))
  (setq pCCW    (polar p1 perpCCW 1.0))
  (setq pCW     (polar p1 perpCW  1.0))
  (setq occCCW  (klhylly-point-occupied-p pCCW))
  (setq occCW   (klhylly-point-occupied-p pCW))
  (cond
    ((and occCCW (not occCW)) perpCW)
    ((and (not occCCW) occCW) perpCCW)
    (t perpCCW)
  )
)

;; Paakomento
(defun c:KLHYLLY ( / *error* oldClayer oldCmdecho oldHpassoc oldCecolor oldDelobj
                     oldOsmode
                     tyyppi levyStr levy p1 p1snap p2 pituus ang perp
                     rail1 rail2 rungs ss e
                     sFloor sLWall sRWall sLLip sRLip
                     solidEnt polyEnt hatchEnt q1 q2 q3 q4 )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldDelobj  (setvar "DELOBJ"  oldDelobj))
    (if oldHpassoc (setvar "HPASSOC" oldHpassoc))
    (if oldCecolor (setvar "CECOLOR" oldCecolor))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg))
    )
    (princ)
  )

  ;; Tallenna sysvarit
  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldHpassoc (getvar "HPASSOC"))
  (setq oldCecolor (getvar "CECOLOR"))
  (setq oldDelobj  (getvar "DELOBJ"))
  (setq oldOsmode  (getvar "OSMODE"))

  (setvar "CMDECHO" 0)
  (setvar "HPASSOC" 1)
  (setvar "CECOLOR" "BYLAYER")
  (setvar "DELOBJ"  1)  ;; EXTRUDE poistaa lahdepolylinen (tikas-profiilin)

  ;; 1) Tyyppi
  (initget "LEVY TIKAS")
  (setq tyyppi (getkword "\nSelect type [LEVY/TIKAS] <LEVY>: "))
  (if (null tyyppi) (setq tyyppi "LEVY"))

  ;; Layer kullekin tyypille (luodaan jos ei ole)
  (cond
    ((= tyyppi "TIKAS")
      (klhylly-ensure-layer "KYL-TIKASHYLLY" 76 76 153)
      (setvar "CLAYER" "KYL-TIKASHYLLY"))
    (t  ;; LEVY
      (klhylly-ensure-layer "KYL-LEVYHYLLY" 76 76 153)
      (setvar "CLAYER" "KYL-LEVYHYLLY"))
  )

  ;; 2) Levy
  (initget "300 400 500")
  (setq levyStr (getkword "\nSelect plate [300/400/500] <300>: "))
  (if (null levyStr) (setq levyStr "300"))
  (setq levy (atof levyStr))

  ;; 3) Aloituspiste. Kaksi-tasoinen snap:
  ;;    (a) OSMODE pakotetaan ENDP+INT:iin pick-ajaksi -> AutoCADin natiivi
  ;;        OSNAP nappaa kulman visuaalisella markerilla aukon sisalla.
  ;;    (b) Fallback: ssget-pohjainen haku lahimpaan LWPOLYLINE-vertexiin
  ;;        <= 80 mm paahan jos natiivi OSNAP ei lauennut.
  (setvar "OSMODE" (logior oldOsmode 33))  ;; 1=ENDP, 32=INT
  (setq p1 (getpoint "\nPick start point: "))
  (setvar "OSMODE" oldOsmode)
  (if (null p1) (exit))
  (setq p1snap (klhylly-snap-corner p1))
  (if p1snap (setq p1 p1snap))

  ;; 4) Pituuden loppupiste (maarittaa pituuden ja suunnan)
  (setq p2 (getpoint p1 "\nPick length end point: "))
  (if (null p2) (exit))
  (setq pituus (distance p1 p2))
  (if (<= pituus 0.0) (exit))
  (setq ang (angle p1 p2))

  ;; 5) Leveyssuunnan automaattinen valinta: tyhjalle puolelle p1:sta.
  (setq perp (klhylly-auto-perp p1 ang))

  (cond
    ((= tyyppi "TIKAS")
      ;; 2 kiskoa + N tikkaa, sitten UNION kaikki yhdeksi 3D-solidiksi.
      (setq rail1 (klhylly-make-rail p1 ang pituus perp 0.0           15.0 60.0))
      (setq rail2 (klhylly-make-rail p1 ang pituus perp (- levy 15.0) 15.0 60.0))
      (setq rungs (klhylly-draw-rungs p1 ang perp pituus levy 250.0
                                      15.0 10.0 15.0 15.0))
      (setq ss (ssadd))
      (setq ss (ssadd rail1 ss))
      (setq ss (ssadd rail2 ss))
      (foreach e rungs (setq ss (ssadd e ss)))
      (command "_.UNION" ss "")
    )
    (t  ;; LEVY: taivutettu peltilevy (5 slabia UNION) + DASH-hatch 2D-polyline z=0,
        ;; ryhmitelty anonyymiin GROUPiin -> yks klikki valitsee kaikki.
      ;; Mitat: 60 mm kokonaiskorkeus, 1.25 mm peltipaksuus, 9 mm lippa sisaanpain.
      (setq sFloor (klhylly-make-slab p1 ang pituus perp 0.0
                                       levy 0.0 1.25))              ; pohja
      (setq sLWall (klhylly-make-slab p1 ang pituus perp 0.0
                                       1.25 0.0 60.0))               ; vasen seina
      (setq sRWall (klhylly-make-slab p1 ang pituus perp (- levy 1.25)
                                       1.25 0.0 60.0))               ; oikea seina
      (setq sLLip  (klhylly-make-slab p1 ang pituus perp 1.25
                                       9.0 58.75 1.25))              ; vasen lippa
      (setq sRLip  (klhylly-make-slab p1 ang pituus perp (- levy 10.25)
                                       9.0 58.75 1.25))              ; oikea lippa
      (setq ss (ssadd))
      (foreach e (list sFloor sLWall sRWall sLLip sRLip)
        (setq ss (ssadd e ss)))
      (command "_.UNION" ss "")
      (setq solidEnt (entlast))

      ;; 2D polyline z=0 ulkokehyksen kanssa + DASH-hatch (scale 40, angle 45)
      (setq q1 p1)
      (setq q2 (polar p1 ang pituus))
      (setq q3 (polar q2 perp levy))
      (setq q4 (polar p1 perp levy))
      (setq polyEnt  (klhylly-make-frame q1 q2 q3 q4 0.0 0.0))
      (command "_.-HATCH" "_P" "DASH" 40 45 "_S" polyEnt "" "")
      (setq hatchEnt (entlast))

      ;; GROUP solid + polyline + hatch yhteen (anonyymi nimi "*" -> *A1, *A2...)
      (command "_.-GROUP" "_C" "*" "" solidEnt polyEnt hatchEnt "")
    )
  )

  ;; Palauta sysvarit
  (setvar "OSMODE"  oldOsmode)
  (setvar "DELOBJ"  oldDelobj)
  (setvar "HPASSOC" oldHpassoc)
  (setvar "CECOLOR" oldCecolor)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nKLHYLLY valmis.")
  (princ)
)

(princ "\nKLHYLLY ladattu. Kirjoita komento: KLHYLLY")
(princ)
