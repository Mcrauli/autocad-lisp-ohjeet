;;; KLHYLLY.LSP - Kylmalaitehyllyn piirtokomennot (parametriset block-instanssit)
;;;
;;; Riippuvuus: rinnalla files/klhylly.dwg-block-kirjasto, joka sisaltaa
;;; dynamic blockit KLHYLLY-LEVY ja KLHYLLY-TIKAS. Blockit on parametrisoitu:
;;; Pituus (Linear, continuous) ja Leveys (Linear, List 300/400/500),
;;; molemmat muokattavissa Properties-paletissa. Pituutta voi myos
;;; stretchata gripeilla; TIKAS:n rungit lisataan/poistetaan automaattisesti
;;; 250 mm askeleella array-actionin myota.
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto. (klhylly.dwg loydetaan
;;; automaattisesti samasta kansiosta tai Support Path:lta.)
;;;
;;; Komennot:
;;;   KLHYLLY    -> LEVY/TIKAS -> 300/400/500 -> pick start -> pick end
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

(defun klhylly-find-block-file ( / cands self prefix )
  (vl-load-com)
  (setq cands '())
  (if (setq self (klhylly-self-folder))
    (setq cands (cons (strcat self "\\klhylly.dwg") cands)))
  (setq prefix (getvar "DWGPREFIX"))
  (setq cands (append cands
    (list
      (strcat (getenv "USERPROFILE") "\\suunnittelutyokalut\\klhylly.dwg")
      (strcat (getenv "USERPROFILE") "\\AutoCADLisp\\klhylly.dwg")
      "C:\\AutoCADLisp\\klhylly.dwg"
      (if prefix (strcat prefix "klhylly.dwg")))))
  (or
    (findfile "klhylly.dwg")
    (vl-some '(lambda (p) (if (and p (vl-file-systime p)) p)) cands)
  )
)

;; Diagnostic command — printtaa mita klhylly-find-block-file palauttaa.
;; Aja "KLHDEBUG" komentoriviltä jos KLHYLLY/KLHYLLYV ei loyda DWG:ta.
(defun c:KLHDEBUG ( / s b )
  (princ (strcat "\nDWGPREFIX = " (vl-princ-to-string (getvar "DWGPREFIX"))))
  (princ (strcat "\nUSERPROFILE = " (vl-princ-to-string (getenv "USERPROFILE"))))
  (princ (strcat "\nfindfile klhylly.lsp = " (vl-princ-to-string (findfile "klhylly.lsp"))))
  (princ (strcat "\nfindfile klhylly.dwg = " (vl-princ-to-string (findfile "klhylly.dwg"))))
  (setq s (klhylly-self-folder))
  (princ (strcat "\nklhylly-self-folder = " (vl-princ-to-string s)))
  (setq b (klhylly-find-block-file))
  (princ (strcat "\nklhylly-find-block-file = " (vl-princ-to-string b)))
  (princ)
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
                     tyyppi levyStr levy p1 p1snap p2 pituus ang perp
                     blockName blockPath layerName scaleY ent obj
                     firstTime )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

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
      (setq layerName "KYL-TIKASHYLLY"))
    (t
      (setq blockName "KLHYLLY-LEVY")
      (setq layerName "KYL-LEVYHYLLY"))
  )

  ;; 2) Leveys
  (initget "300 400 500")
  (setq levyStr (getkword "\nSelect plate [300/400/500] <300>: "))
  (if (null levyStr) (setq levyStr "300"))
  (setq levy (atof levyStr))

  ;; 3) Block-maaritys: ensikerralla lataa klhylly.dwg:sta
  (setq firstTime (not (tblsearch "BLOCK" blockName)))
  (if firstTime
    (progn
      (setq blockPath (klhylly-find-block-file))
      (if (null blockPath)
        (progn
          (princ "\nVIRHE: klhylly.dwg ei loydy. Varmista etta klhylly.dwg on samassa")
          (princ "\nkansiossa kuin klhylly.lsp.")
          (exit)
        )
      )
    )
  )

  ;; 4) Aloituspiste — kaksi-tasoinen snap
  (setvar "OSMODE" (logior (logand oldOsmode 16383) 33))
  (setq p1 (getpoint "\nPick start point: "))
  (setvar "OSMODE" oldOsmode)
  (if (null p1) (exit))
  (setq p1 (list (car p1) (cadr p1) 0.0))
  (setq p1snap (klhylly-snap-corner p1))
  (if p1snap (setq p1 p1snap))

  ;; 5) Loppupiste
  (setvar "OSMODE" (logior (logand oldOsmode 16383) 33))
  (setq p2 (getpoint p1 "\nPick length end point: "))
  (setvar "OSMODE" oldOsmode)
  (if (null p2) (exit))
  (setq p2 (list (car p2) (cadr p2) 0.0))
  (setq pituus (distance p1 p2))
  (if (<= pituus 0.0) (exit))
  (setq ang (angle p1 p2))

  ;; 6) Auto-perp + scaleY (CW = peilaa Y -> width kasvaa toiselle puolelle)
  (setq perp (klhylly-auto-perp p1 ang))
  (setq scaleY
    (if (equal perp (+ ang (/ pi 2.0)) 0.0001)
      1.0
      -1.0
    )
  )

  ;; 7) Layer luonti tarvittaessa
  (klhylly-ensure-layer layerName 175)

  ;; 8) INSERT
  ;;    Argumentti-jarjestys: insertion / X-scale / Y-scale / rotation(deg)
  (if firstTime
    (command "_.-INSERT" (strcat blockName "=" blockPath)
             p1 1.0 scaleY (* 180.0 (/ ang pi)))
    (command "_.-INSERT" blockName
             p1 1.0 scaleY (* 180.0 (/ ang pi)))
  )

  ;; 9) Aseta layer + dynaamiset properties
  (setq ent (entlast))
  (setq obj (vlax-ename->vla-object ent))
  (vla-put-Layer obj layerName)
  (klhylly-set-dyn-prop ent "Pituus" pituus)
  (klhylly-set-dyn-prop ent "Leveys" levy)

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
                     blockName blockPath layerName firstTime
                     levyStr levy modeKw lenInput
                     p1 p2 p3 length
                     Lraw Lmag L Wraw dotLW Wperp Wmag W D
                     mat ent obj )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ)
  )

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsmode  (getvar "OSMODE"))

  (setvar "CMDECHO" 0)

  (setq blockName "KLHYLLY-TIKAS")
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
      (setq blockPath (klhylly-find-block-file))
      (if (null blockPath)
        (progn (princ "\nVIRHE: klhylly.dwg ei loydy.") (exit))
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

  ;; 6) INSERT WCS-origoon, rotation 0, scale 1
  (if firstTime
    (command "_.-INSERT" (strcat blockName "=" blockPath)
             "0,0,0" 1.0 1.0 0.0)
    (command "_.-INSERT" blockName "0,0,0" 1.0 1.0 0.0)
  )
  (setq ent (entlast))
  (setq obj (vlax-ename->vla-object ent))

  ;; 7) 4x4-muunnos: kanonisen X-akselin -> L, Y-akselin -> W, Z-akselin -> D,
  ;;    sijoitus pisteeseen p1
  (setq mat
    (vlax-tmatrix
      (list
        (list (car L)   (car W)   (car D)   (car p1))
        (list (cadr L)  (cadr W)  (cadr D)  (cadr p1))
        (list (caddr L) (caddr W) (caddr D) (caddr p1))
        (list 0.0 0.0 0.0 1.0))))
  (vla-TransformBy obj mat)

  ;; 8) Layer + dynaamiset properties
  (vla-put-Layer obj layerName)
  (klhylly-set-dyn-prop ent "Pituus" length)
  (klhylly-set-dyn-prop ent "Leveys" levy)

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
