;;; KLHYLLY.LSP - Kylmalaitehyllyn piirtokomento
;;; Lataa: APPLOAD -> valitse tama tiedosto.
;;; Kayta:  KLHYLLY -> LEVY/TIKAS -> 300/400/500 -> pick start -> pick end
;;; Layerit: LEVY -> KYL-LEVYHYLLY, TIKAS -> KYL-TIKASHYLLY.
;;;
;;; Leveyspuoli valitaan automaattisesti: jos p1:n toisella puolella on jo
;;; KYL-*HYLLY-entiteetti ja toisella ei, uusi hylly levenee sille puolelle
;;; jossa vanha hylly on - nain L-mutkat saadaan samaan linjaan ilman
;;; manuaalista siirtoa. Probe 5 mm ja 50 mm etaisyyksilla. Jos molemmat
;;; puolet tyhjia tai molemmat varatut, oletus on CCW (+90 vetosuunnasta).
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
;; ja valitsee sen puolen jossa on jo KYL-*HYLLY-entiteetti lahella.
;; Tama tuottaa puhtaita L-mutkia: uuden hyllyn leveys jatkaa olemassa
;; olevan hyllyn sisemmalle puolelle (huoneen sisaosa) ulkopinnan sijaan.
;; Probe kahdella etaisyydella (5 mm ja 50 mm) - tarttuu nurkkasnappiin
;; mutta myos loyhasti valittuihin p1-pisteisiin. Jos molemmat tyhjia
;; tai molemmat varatut, palauttaa oletus-CCW.
(defun klhylly-auto-perp ( p1 ang / perpCCW perpCW occCCW occCW d )
  (setq perpCCW (+ ang (/ pi 2.0)))
  (setq perpCW  (- ang (/ pi 2.0)))
  (setq occCCW nil occCW nil)
  (foreach d '(5.0 50.0)
    (if (null occCCW)
      (if (klhylly-point-occupied-p (polar p1 perpCCW d))
        (setq occCCW T)))
    (if (null occCW)
      (if (klhylly-point-occupied-p (polar p1 perpCW d))
        (setq occCW T)))
  )
  (cond
    ((and occCCW (not occCW)) perpCCW)    ; toward CCW side (occupied)
    ((and (not occCCW) occCW) perpCW)     ; toward CW side (occupied)
    (t perpCCW)                            ; default CCW
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

  ;; 5) Leveyssuunnan automaattinen valinta: sille puolelle jossa on jo hylly
  ;;    (L-mutkien puhdas yhteensovitus). Fallback: CCW jos molemmat tyhjia.
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

;;; KLHYLLYV: TIKAS-hylly vapaaseen 3D-suuntaan (pystysuoraan tai viistosti).
;;; Kaytto:
;;;   1. KLHYLLYV
;;;   2. Leveys 300/400/500
;;;   3. Alaosa (base point) - mika tahansa 3D-piste
;;;   4. Ylaosa (length end) - maarittaa pituuden ja suunnan (voi olla 3D)
;;;   5. Leveyden viittauspiste - UCS projisoi automaattisesti kohtisuoran
;;;      leveyssuunnan pituusakselia vasten
;;;
;;; Toteutus: UCS 3-piste origin=p1, +X=p2, +Y=p3 niin etta rails ja
;;; poikkitikat piirtyvat BOX:illa UCS-akseleiden mukaan. UCS palautetaan
;;; edelliseen tilaan lopuksi (_P).
;; Muuntaa real-luvun merkkijonoksi piste-desimaalilla (ei lokaalista riippuvaa pilkkua).
(defun klhylly-num->str ( n / s )
  (setq s (rtos n 2 8))
  (if (vl-string-search "," s)
    (vl-string-translate "," "." s)
    s
  )
)

;; Muuntaa 3D-pisteen "x,y,z"-merkkijonoksi piste-desimaaleilla.
;; Tarpeellinen koska AutoLISP muuntaa pistelistat command:lle lokaalin
;; desimaalierottimella — pilkku-lokaalissa "1,5 2,7 3,9" tulkitaan
;; kuudeksi numeroksi.
(defun klhylly-pt->str ( p )
  (strcat (klhylly-num->str (car p)) ","
          (klhylly-num->str (cadr p)) ","
          (klhylly-num->str (caddr p)))
)

(defun c:KLHYLLYV ( / *error* oldClayer oldCmdecho oldCecolor oldOsmode oldSnapmode
                     modeKw levyStr levy lenInput p1 p2 p3 length
                     Lraw Lmag L Wraw dotLW Wperp Wmag W D
                     msp mat solids rail1 rail2 rung
                     i center halfW s ss )

  (defun *error* ( msg )
    (if oldOsmode   (setvar "OSMODE"   oldOsmode))
    (if oldSnapmode (setvar "SNAPMODE" oldSnapmode))
    (if oldCecolor  (setvar "CECOLOR"  oldCecolor))
    (if oldCmdecho  (setvar "CMDECHO"  oldCmdecho))
    (if oldClayer   (setvar "CLAYER"   oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (setq oldClayer   (getvar "CLAYER"))
  (setq oldCmdecho  (getvar "CMDECHO"))
  (setq oldCecolor  (getvar "CECOLOR"))
  (setq oldOsmode   (getvar "OSMODE"))
  (setq oldSnapmode (getvar "SNAPMODE"))

  (setvar "CMDECHO" 0)
  (setvar "CECOLOR" "BYLAYER")

  (klhylly-ensure-layer "KYL-TIKASHYLLY" 76 76 153)
  (setvar "CLAYER" "KYL-TIKASHYLLY")

  (initget "300 400 500")
  (setq levyStr (getkword "\nLeveys [300/400/500] <300>: "))
  (if (null levyStr) (setq levyStr "300"))
  (setq levy (atof levyStr))

  (setq p1 (getpoint "\nAlaosa tai ylaosa (base point): "))
  (if (null p1) (exit))

  ;; Kaksi tapaa maaritella toinen piste:
  ;;  N = numero (pituus mm alaspain p1:sta -- helpoin 2D-plan-nakymassa)
  ;;  P = piste (mika tahansa 3D-piste, vapaa orientaatio)
  (initget "N P")
  (setq modeKw (getkword "\nToinen piste [N=numerona alaspain / P=pisteena] <N>: "))
  (if (null modeKw) (setq modeKw "N"))

  (cond
    ((= modeKw "N")
      (setq lenInput (getreal "\nPituus mm (positiivinen = alaspain p1:sta): "))
      (if (or (null lenInput) (< (abs lenInput) 1.0))
        (progn (princ "\nPituus liian pieni.") (exit)))
      (setq length (abs lenInput))
      (setq p2 (list (car p1) (cadr p1) (- (caddr p1) lenInput)))
    )
    ((= modeKw "P")
      (setq p2 (getpoint p1 "\nYlaosa (length end): "))
      (if (null p2) (exit))
      (setq length (distance p1 p2))
      (if (< length 1.0)
        (progn (princ "\nPituus liian lyhyt.") (exit)))
    )
  )

  (setq p3 (getpoint p1 "\nLeveyden suunta (horisontaalinen viittauspiste): "))
  (if (null p3) (exit))

  ;; --- Rakenna ladder COM API:lla WCS:ssa, sitten muuntomatriisilla kohdalleen.
  ;; Tama valttaa command-funktion string-muunnos- ja UCS-parserin ongelmat
  ;; jotka sotkivat aiemman BOX+UCS-toteutuksen lokaali-Windowsissa.

  (vl-load-com)
  (setq msp (vla-get-ModelSpace
              (vla-get-ActiveDocument (vlax-get-acad-object))))

  ;; 1) Laske target-akselit (unit vektorit WCS:ssa).
  ;;    L = pituusakseli, W = leveysakseli, D = syvyysakseli (L x W).
  (setq Lraw (mapcar '- p2 p1))
  (setq Lmag (distance '(0.0 0.0 0.0) Lraw))
  (if (< Lmag 1.0)
    (progn (princ "\nPituus liian lyhyt.") (exit)))
  (setq L (list (/ (car Lraw)   Lmag)
                (/ (cadr Lraw)  Lmag)
                (/ (caddr Lraw) Lmag)))

  (setq Wraw (mapcar '- p3 p1))
  (setq dotLW (+ (* (car Wraw)   (car L))
                 (* (cadr Wraw)  (cadr L))
                 (* (caddr Wraw) (caddr L))))
  (setq Wperp
    (mapcar '-
            Wraw
            (list (* dotLW (car L))
                  (* dotLW (cadr L))
                  (* dotLW (caddr L)))))
  (setq Wmag (distance '(0.0 0.0 0.0) Wperp))
  (if (< Wmag 0.001)
    (progn
      (princ "\np3 on samalla suoralla kuin p1-p2. Valitse p3 kauemmas sivulle.")
      (exit)))
  (setq W (list (/ (car Wperp)   Wmag)
                (/ (cadr Wperp)  Wmag)
                (/ (caddr Wperp) Wmag)))

  ;; D = L x W (oikeakatinen koordinaatisto)
  (setq D (list
            (- (* (cadr L)  (caddr W)) (* (caddr L) (cadr W)))
            (- (* (caddr L) (car W))   (* (car L)   (caddr W)))
            (- (* (car L)   (cadr W))  (* (cadr L)  (car W)))))

  ;; 2) 4x4-muunnos: kanoniset akselit (X=length, Y=width, Z=depth) -> (L, W, D) + translate p1
  (setq mat
    (vlax-tmatrix
      (list
        (list (car L)   (car W)   (car D)   (car p1))
        (list (cadr L)  (cadr W)  (cadr D)  (cadr p1))
        (list (caddr L) (caddr W) (caddr D) (caddr p1))
        (list 0.0 0.0 0.0 1.0))))

  ;; 3) Luo kanoniset boxit WCS:ssa akselien mukaisesti.
  ;;    vla-AddBox ottaa keskipisteen ja dimensiot (dimX, dimY, dimZ).
  (setq solids nil)

  (setq rail1
    (vla-AddBox msp
                (vlax-3d-point (list (/ length 2.0) 7.5 30.0))
                length 15.0 60.0))
  (setq solids (cons rail1 solids))

  (setq rail2
    (vla-AddBox msp
                (vlax-3d-point (list (/ length 2.0) (- levy 7.5) 30.0))
                length 15.0 60.0))
  (setq solids (cons rail2 solids))

  (setq i 1 center (* i 250.0) halfW 7.5)
  (while (<= (+ center halfW) length)
    (setq rung
      (vla-AddBox msp
                  (vlax-3d-point (list center (/ levy 2.0) 17.5))
                  15.0 (- levy 30.0) 15.0))
    (setq solids (cons rung solids))
    (setq i (1+ i))
    (setq center (* i 250.0))
  )

  ;; 4) Muunnos jokaiselle solidille (rotaatio + translaatio kerralla)
  (foreach s solids
    (vla-TransformBy s mat)
  )

  ;; 5) UNION yhdeksi soliditeetiksi
  (setq ss (ssadd))
  (foreach s solids
    (setq ss (ssadd (vlax-vla-object->ename s) ss)))
  (command "_.UNION" ss "")

  (setvar "OSMODE"   oldOsmode)
  (setvar "SNAPMODE" oldSnapmode)
  (setvar "CECOLOR"  oldCecolor)
  (setvar "CMDECHO"  oldCmdecho)
  (setvar "CLAYER"   oldClayer)

  (princ "\nKLHYLLYV valmis.")
  (princ)
)

;;; HYLLYKORKO: siirtaa valitut hyllyt (tai mita tahansa objekteja) absoluuttiselle
;;; Z-korolle. Lukee valinnan alimman bounding-box Z:n ja laskee siirtyman
;;; niin etta matalin alareuna osuu annettuun Z:aan. Kaytto:
;;;   1. Piirra hyllyt rauhassa z=0:lle KLHYLLY:lla.
;;;   2. Kun suunnitelma valmis, valitse yhden tason hyllyt.
;;;   3. HYLLYKORKO -> anna kohdekorko (absoluuttinen Z mm) -> siirtyy yhdella
;;;      kerralla. Toimii sekä LEVY-ryhmille että TIKAS-3D-soldeille.
(defun c:HYLLYKORKO ( / ss i ent obj minArr maxArr res mn curZ targetZ delta )

  (prompt "\nValitse hyllyt: ")
  (setq ss (ssget))

  (if (null ss)
    (progn
      (princ "\nEi valittuja kohteita.")
      (princ)
    )
    (progn
      ;; Etsi valinnan alin Z bounding boxeista
      (setq i 0 curZ nil)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq obj (vlax-ename->vla-object ent))
        (setq minArr nil maxArr nil)
        (setq res
          (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minArr 'maxArr)))
        (if (and (not (vl-catch-all-error-p res)) minArr)
          (progn
            (setq mn (vlax-safearray->list minArr))
            (if (or (null curZ) (< (nth 2 mn) curZ))
              (setq curZ (nth 2 mn)))
          )
        )
        (setq i (1+ i))
      )
      (if (null curZ) (setq curZ 0.0))

      (princ (strcat "\nNykyinen Z (alareuna): " (rtos curZ 2 1) " mm"))
      (setq targetZ (getreal "\nKohdekorko (absoluuttinen Z mm): "))

      (if (null targetZ)
        (princ "\nKeskeytetty.")
        (progn
          (setq delta (- targetZ curZ))
          (command "_.MOVE" ss "" '(0.0 0.0 0.0) (list 0.0 0.0 delta))
          (princ
            (strcat "\nSiirretty " (rtos delta 2 1) " mm -> Z = "
                    (rtos targetZ 2 1)))
        )
      )
    )
  )
  (princ)
)

(princ "\nKLHYLLY + KLHYLLYV + HYLLYKORKO ladattu. Komennot: KLHYLLY, KLHYLLYV, HYLLYKORKO")
(princ)
