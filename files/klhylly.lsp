;;; KLHYLLY.LSP - Kylmalaitehyllyn piirtokomennot (parametriset block-instanssit)
;;;
;;; Riippuvuus: rinnalla files/klhylly-levy.dwg ja files/klhylly-tikas.dwg
;;; -block-kirjastot, jotka sisaltavat dynamic blockit KLHYLLY-LEVY ja
;;; KLHYLLY-TIKAS. Blockit on parametrisoitu: Pituus (Linear, continuous)
;;; ja Leveys (Linear, List 300/400/500), molemmat muokattavissa
;;; Properties-paletissa. Pituutta voi myos stretchata gripeilla; TIKAS:n
;;; rungit lisataan/poistetaan automaattisesti 250 mm askeleella array-
;;; actionin myota.
;;;
;;; Erilliset DWG:t per blocki valttaa AutoCAD:n self-reference-virheet
;;; jotka voivat syntya kun molemmat blockit ovat samassa lahde-DWG:ssa.
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto. (klhylly-levy.dwg ja
;;; klhylly-tikas.dwg loydetaan automaattisesti samasta kansiosta.)
;;;
;;; Komennot:
;;;   KLHYLLY    -> LEVY/TIKAS -> 300/400/500 -> pick midpoint -> pick end
;;;                 (kursori = hyllyn keskipiste, end = puolet pituutta)
;;;   KLHYLLYV   -> 300/400/500 -> alaosa -> ylaosa -> leveyden suunta
;;;   HYLLYKORKO -> valitse hyllyt -> kohdekorko z mm
;;;
;;; Layerit luodaan automaattisesti: KYL-LEVYHYLLY ja KYL-TIKASHYLLY,
;;; molemmat true-color RGB(76,76,153). Block-maaritysten sisalla geometria
;;; on layerilla 0 (BYBLOCK), joten instanssin layer periytyy alaspain
;;; ja IFC-vienti (dxf2ifc) tunnistaa hyllytyypin.
;;;
;;; Aloituspisteen snap-logiikka: OSMODE-pakotus ENDP+INT + ssget-fallback
;;; lahimpaan KYL-*HYLLY-nurkkaan <= 80 mm paahan. Toimii sekä uusille
;;; block-instansseille (INSERT) etta vanhoille UNION-3DSOLIDeille.
;;; Auto-perp valitsee leveyssuunnan: jos p1:n toisella puolella on jo
;;; KYL-*HYLLY ja toisella ei, uusi hylly levenee samalle puolelle ->
;;; puhtaat L-mutkat. CW-puolella INSERT kayttaa scaleY=-1 (peilaus).

(vl-load-com)

;; ============================================================
;; LAYER + SNAP HELPERIT
;; ============================================================

;; Varmistaa etta layer on olemassa annetulla AutoCAD color index:lla.
;; Jos layer on jo olemassa, ei kosketa sen asetuksiin (kayttajan custom-vari sailyy).
(defun klhylly-ensure-layer ( layerName colorIndex
                              / acadObj doc layers layer )
  (if (null (tblsearch "LAYER" layerName))
    (progn
      (setq acadObj (vlax-get-acad-object))
      (setq doc (vla-get-ActiveDocument acadObj))
      (setq layers (vla-get-Layers doc))
      (setq layer (vla-Add layers layerName))
      (vla-put-Color layer colorIndex)
    )
  )
  layerName
)

(defun klhylly-point-occupied-p ( pt / delta ss )
  (setq delta 0.5)
  (setq ss (ssget "_C"
                   (list (- (car pt) delta) (- (cadr pt) delta))
                   (list (+ (car pt) delta) (+ (cadr pt) delta))
                   '((8 . "KYL-*HYLLY"))))
  (not (null ss))
)

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

;; Etsii lahimman nurkan KYL-*HYLLY-entiteetista p1:sta. Toimii sekä
;; vanhoille (LWPOLYLINE/3DSOLID) etta uusille (INSERT block) hyllyille.
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
            ((= entType "INSERT")
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
    ((and occCCW (not occCW)) perpCCW)
    ((and (not occCCW) occCW) perpCW)
    (t perpCCW)
  )
)

;; ============================================================
;; BLOCK-DWG LOCATOR (kuvio kopioitu positio.lsp:sta)
;; ============================================================

(defun klhylly-self-folder ( / found regbase target ver prod prof appkey val )
  (vl-load-com)
  (setq target "klhylly.lsp")
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

;; Etsii block-DWG:n nimella (klhylly-levy.dwg tai klhylly-tikas.dwg).
;; Erilliset DWG:t valttavat self-reference-virheet jotka tulevat kun
;; molemmat blockit ovat samassa lahde-DWG:ssa.
(defun klhylly-find-block-file ( dwgName / cands self prefix found p )
  (vl-load-com)
  ;; 1. Support Path
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      ;; Rakenna kandidaattilista: self-folder, sitten yleiset paikat
      (setq cands '())
      (if (setq self (klhylly-self-folder))
        (if (= (type self) 'STR)
          (setq cands (list (strcat self "\\" dwgName)))))
      (setq prefix (getvar "DWGPREFIX"))
      (setq cands (append cands
        (list
          (strcat (getenv "USERPROFILE") "\\suunnittelutyokalut\\" dwgName)
          (strcat (getenv "USERPROFILE") "\\AutoCADLisp\\" dwgName)
          (strcat "C:\\AutoCADLisp\\" dwgName))))
      (if (and prefix (= (type prefix) 'STR) (> (strlen prefix) 0))
        (setq cands (append cands (list (strcat prefix dwgName)))))
      ;; Iteroi listaa, palauta ensimmainen olemassaoleva. Type-check
      ;; varmistaa ettei T tai muu non-string vuoda lapi.
      (foreach p cands
        (if (and (not found)
                 (= (type p) 'STR)
                 (vl-file-systime p))
          (setq found p)))
      found)
  )
)

;; ============================================================
;; DYNAMIC BLOCK PROPERTY -SETTERI
;; ============================================================

;; Asettaa dynamic blockin parametrin arvon nimella. Hiljaa epaonnistuu
;; jos parametria ei ole tai arvo ei kuulu sallittuihin (List-tyyppinen).
(defun klhylly-set-dyn-prop ( ent propName value / obj props p )
  (setq obj (vlax-ename->vla-object ent))
  (setq props (vlax-invoke obj 'GetDynamicBlockProperties))
  (foreach p props
    (if (= (strcase (vla-get-PropertyName p)) (strcase propName))
      (vla-put-Value p (vlax-make-variant value vlax-vbDouble))
    )
  )
)

;; ============================================================
;; KLHYLLY (vaakaversio: LEVY tai TIKAS)
;; ============================================================

(defun c:KLHYLLY ( / *error* oldClayer oldCmdecho oldOsmode
                     tyyppi levyStr levy pmid pmidsnap pend halfLen
                     pituus ang p1 perp scaleY
                     blockName dwgName blockPath layerName firstTime
                     doc ms ins
                     savedFiledia savedCmddia savedExpert )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (vl-load-com)

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsmode  (getvar "OSMODE"))

  (setvar "CMDECHO" 0)

  ;; 1) Tyyppi
  (initget "LEVY TIKAS")
  (setq tyyppi (getkword "\nSelect type [LEVY/TIKAS] <LEVY>: "))
  (if (null tyyppi) (setq tyyppi "LEVY"))

  (cond
    ((= tyyppi "TIKAS")
      (setq blockName "KLHYLLY-TIKAS")
      (setq dwgName   "klhylly-tikas.dwg")
      (setq layerName "KYL-TIKASHYLLY"))
    (t
      (setq blockName "KLHYLLY-LEVY")
      (setq dwgName   "klhylly-levy.dwg")
      (setq layerName "KYL-LEVYHYLLY"))
  )

  ;; 2) Leveys
  (initget "300 400 500")
  (setq levyStr (getkword "\nSelect plate [300/400/500] <300>: "))
  (if (null levyStr) (setq levyStr "300"))
  (setq levy (atof levyStr))

  ;; 3) Block-maaritys: ensikerralla lookup vastaavan DWG:n polku
  (setq firstTime (not (tblsearch "BLOCK" blockName)))
  (if firstTime
    (progn
      (setq blockPath (klhylly-find-block-file dwgName))
      (if (null blockPath)
        (progn
          (princ (strcat "\nVIRHE: " dwgName " ei loydy. Varmista etta tiedosto on samassa"))
          (princ "\nkansiossa kuin klhylly.lsp.")
          (setvar "CMDECHO" oldCmdecho)
          (setvar "CLAYER"  oldClayer)
          (exit)
        )
      )
    )
  )

  ;; 4) Keskipiste — kursori = hyllyn keskipiste, snap-logiikka
  ;;    samalla pattern:lla kuin aiempi p1.
  (setvar "OSMODE" (logior (logand oldOsmode 16383) 33))
  (setq pmid (getpoint "\nPick midpoint: "))
  (setvar "OSMODE" oldOsmode)
  (if (null pmid) (exit))
  (setq pmid (list (car pmid) (cadr pmid) 0.0))
  (setq pmidsnap (klhylly-snap-corner pmid))
  (if pmidsnap (setq pmid pmidsnap))

  ;; 5) Paatepiste = puolet pituutta keskipisteesta
  (setvar "OSMODE" (logior (logand oldOsmode 16383) 33))
  (setq pend (getpoint pmid "\nPick end (= half length): "))
  (setvar "OSMODE" oldOsmode)
  (if (null pend) (exit))
  (setq pend (list (car pend) (cadr pend) 0.0))
  (setq halfLen (distance pmid pend))
  (if (<= halfLen 0.0) (exit))
  (setq pituus (* 2.0 halfLen))
  (setq ang (angle pmid pend))

  ;; 6) Block:n insertion piste p1 = pmid - halfLen * suunta.
  ;;    Block-maaritys olettaa origon vasemmalla paassa, joten
  ;;    siirretaan "puolet pituudesta" taakse jotta keskipiste osuu
  ;;    pmid:hen.
  (setq p1 (polar pmid (+ ang pi) halfLen))

  ;; 7) Auto-perp + scaleY (CW = peilaa Y -> width kasvaa toiselle puolelle)
  (setq perp (klhylly-auto-perp p1 ang))
  (setq scaleY
    (if (equal perp (+ ang (/ pi 2.0)) 0.0001)
      1.0
      -1.0
    )
  )

  ;; 8) Layer luonti tarvittaessa
  (klhylly-ensure-layer layerName 175)

  ;; 9) Lataa block-maaritys ensikerralla -INSERT:lla origin:iin ja poista
  ;;    valittomasti. FILEDIA/CMDDIA/EXPERT vaihdetaan vain talle kapealle
  ;;    blokille jotta -INSERT ei avaa file dialogia, ja palautetaan heti
  ;;    perään. vl-catch-all-apply takaa palautuksen vaikka -INSERT epaonnistuisi.
  (if firstTime
    (progn
      (setq savedFiledia (getvar "FILEDIA"))
      (setq savedCmddia  (getvar "CMDDIA"))
      (setq savedExpert  (getvar "EXPERT"))
      (setvar "FILEDIA" 0)
      (setvar "CMDDIA"  0)
      (setvar "EXPERT"  5)
      (vl-catch-all-apply
        '(lambda ()
           (command "_.-INSERT" (strcat blockName "=" blockPath) "0,0,0" 1 1 0)
           (if (entlast) (entdel (entlast)))))
      (setvar "FILEDIA" savedFiledia)
      (setvar "CMDDIA"  savedCmddia)
      (setvar "EXPERT"  savedExpert)
    )
  )

  ;; 10) Sijoita instanssi vla-InsertBlock:lla — block:n alkupaa p1:hen,
  ;;     keskipiste osuu pmid:hen koska p1 = pmid - halfLen * suunta.
  ;;     scaleY = -1.0 mirroria varten kun perp on CW.
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq ms  (vla-get-ModelSpace doc))
  (setq ins (vla-InsertBlock ms (vlax-3d-point p1) blockName 1.0 scaleY 1.0 ang))

  ;; 11) Aseta layer + dynaamiset properties
  (vla-put-Layer ins layerName)
  (klhylly-set-dyn-prop (vlax-vla-object->ename ins) "Pituus" pituus)
  (klhylly-set-dyn-prop (vlax-vla-object->ename ins) "Leveys" levy)

  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nKLHYLLY valmis. Properties-paletista voi vaihtaa Leveys/Pituus.")
  (princ)
)

;; ============================================================
;; KLHYLLYV (TIKAS-hylly vapaaseen 3D-suuntaan)
;; ============================================================
;; Sama dynamic block KLHYLLY-TIKAS kuin vaakaversiossa. INSERT WCS-origoon,
;; sitten vla-TransformBy 4x4-matriisilla haluttuun 3D-orientaatioon.
;; Pituus/Leveys-parametrit toimivat instanssin paikallisessa avaruudessa,
;; joten Properties-paletti ja stretch toimivat samoin kuin vaakaversiossa.

(defun c:KLHYLLYV ( / *error* oldClayer oldCmdecho oldOsmode
                     blockName dwgName blockPath layerName firstTime
                     levyStr levy modeKw lenInput
                     p1 p2 p3 length
                     Lraw Lmag L Wraw dotLW Wperp Wmag W D
                     mat doc ms ins
                     savedFiledia savedCmddia savedExpert )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (vl-load-com)

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsmode  (getvar "OSMODE"))

  (setvar "CMDECHO" 0)

  (setq blockName "KLHYLLY-TIKAS")
  (setq dwgName   "klhylly-tikas.dwg")
  (setq layerName "KYL-TIKASHYLLY")

  ;; 1) Leveys
  (initget "300 400 500")
  (setq levyStr (getkword "\nLeveys [300/400/500] <300>: "))
  (if (null levyStr) (setq levyStr "300"))
  (setq levy (atof levyStr))

  ;; 2) Block-maaritys
  (setq firstTime (not (tblsearch "BLOCK" blockName)))
  (if firstTime
    (progn
      (setq blockPath (klhylly-find-block-file dwgName))
      (if (null blockPath)
        (progn (princ (strcat "\nVIRHE: " dwgName " ei loydy.")) (exit))
      )
    )
  )

  ;; 3) Pisteet
  (setq p1 (getpoint "\nAlaosa tai ylaosa (base point): "))
  (if (null p1) (exit))

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

  ;; 4) Akseliyksikkovektorit (samat kaavat kuin vanhassa toteutuksessa)
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

  (setq D (list
            (- (* (cadr L)  (caddr W)) (* (caddr L) (cadr W)))
            (- (* (caddr L) (car W))   (* (car L)   (caddr W)))
            (- (* (car L)   (cadr W))  (* (cadr L)  (car W)))))

  ;; 5) Layer luonti
  (klhylly-ensure-layer layerName 175)

  ;; 6) Lataa block-maaritys ensikerralla -INSERT:lla origin:iin ja poista
  ;;    valittomasti. FILEDIA/CMDDIA/EXPERT vain talle kapealle blokille.
  (if firstTime
    (progn
      (setq savedFiledia (getvar "FILEDIA"))
      (setq savedCmddia  (getvar "CMDDIA"))
      (setq savedExpert  (getvar "EXPERT"))
      (setvar "FILEDIA" 0)
      (setvar "CMDDIA"  0)
      (setvar "EXPERT"  5)
      (vl-catch-all-apply
        '(lambda ()
           (command "_.-INSERT" (strcat blockName "=" blockPath) "0,0,0" 1 1 0)
           (if (entlast) (entdel (entlast)))))
      (setvar "FILEDIA" savedFiledia)
      (setvar "CMDDIA"  savedCmddia)
      (setvar "EXPERT"  savedExpert)
    )
  )

  ;; 7) Sijoita instanssi WCS-origoon vla-InsertBlock:lla
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq ms  (vla-get-ModelSpace doc))
  (setq ins (vla-InsertBlock ms (vlax-3d-point '(0.0 0.0 0.0))
                             blockName 1.0 1.0 1.0 0.0))

  ;; 8) 4x4-muunnos: kanonisen X-akselin -> L, Y-akselin -> W, Z-akselin -> D,
  ;;    sijoitus pisteeseen p1
  (setq mat
    (vlax-tmatrix
      (list
        (list (car L)   (car W)   (car D)   (car p1))
        (list (cadr L)  (cadr W)  (cadr D)  (cadr p1))
        (list (caddr L) (caddr W) (caddr D) (caddr p1))
        (list 0.0 0.0 0.0 1.0))))
  (vla-TransformBy ins mat)

  ;; 9) Layer + dynaamiset properties
  (vla-put-Layer ins layerName)
  (klhylly-set-dyn-prop (vlax-vla-object->ename ins) "Pituus" length)
  (klhylly-set-dyn-prop (vlax-vla-object->ename ins) "Leveys" levy)

  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)

  (princ "\nKLHYLLYV valmis.")
  (princ)
)

;; ============================================================
;; HYLLYKORKO - siirtaa valitut kohteet absoluuttiselle Z-korolle
;; ============================================================
;; Toimii sekä uusille block-instansseille etta vanhoille UNION-3DSOLIDeille
;; (MOVE-pohjainen). Lukee valinnan alimman bbox-Z:n ja laskee siirtyman
;; niin etta matalin alareuna osuu annettuun Z:aan.

(defun c:HYLLYKORKO ( / ss i ent obj minArr maxArr res mn curZ targetZ delta )

  (prompt "\nValitse hyllyt: ")
  (setq ss (ssget))

  (if (null ss)
    (progn
      (princ "\nEi valittuja kohteita.")
      (princ)
    )
    (progn
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

(princ "\nKLHYLLY + KLHYLLYV + HYLLYKORKO ladattu.")
(princ "\nProperties-paletista voi vaihtaa Leveys/Pituus, gripeilla stretchata.")
(princ)
