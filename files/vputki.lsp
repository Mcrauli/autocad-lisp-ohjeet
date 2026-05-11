;;; VPUTKI.LSP - Viemariputken piirtokomennot (suora + fittings)
;;;
;;; Pikakomennot per koko:
;;;   VP32 / VP50 / VP75 -> kysyy mallin (SUORA/45/88.5/T) ja insertoi
;;;   VPUTKI             -> kysyy ensin halkaisijan, sitten mallin
;;;
;;; Mallit:
;;;   SUORA  - dynamic block 1.8 mm seinamalla, 2-grippi-stretch
;;;            INSERT 2-pistetta, sx=sy=sz=1, Pituus-parametri = pisteiden
;;;            etaisyys
;;;   45     - 45-asteen kulma (V-PUTKET fitting)
;;;   88.5   - 88.5-asteen kulma (V-PUTKET fitting)
;;;   T      - T-haara (V-PUTKET fitting)
;;;
;;; Block-DWG-tiedostot ovat files/-kansiossa:
;;;   vputki-<size>.dwg       - suora dynamic block
;;;   vputki-<size>-45.dwg    - 45-kulma WBLOCK
;;;   vputki-<size>-885.dwg   - 88.5-kulma WBLOCK
;;;   vputki-<size>-t.dwg     - T-haara WBLOCK
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto.
;;;
;;; Layerit luodaan automaattisesti: KYL-VIEMARI-32 (ACI 151, vaalea sin),
;;; KYL-VIEMARI-50 (ACI 5, sininen), KYL-VIEMARI-75 (ACI 175, tumma sin).

(vl-load-com)

;; ============================================================
;; LAYER-HELPER
;; ============================================================

(defun vputki-ensure-layer ( layerName colorIndex
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

;; ============================================================
;; BLOCK-DWG LOCATOR
;; ============================================================

(defun vputki-self-folder ( / found regbase target ver prod prof appkey val )
  (vl-load-com)
  (setq target "vputki.lsp")
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

(defun vputki-find-block-file ( dwgName / cands self prefix found p )
  (vl-load-com)
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      (setq cands '())
      (if (setq self (vputki-self-folder))
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
      (foreach p cands
        (if (and (not found)
                 (= (type p) 'STR)
                 (vl-file-systime p))
          (setq found p)))
      found)
  )
)

;; ============================================================
;; DYNAMIC BLOCK PROPERTY -SETTERI (vain suoralle putkelle)
;; ============================================================

(defun vputki-set-dyn-prop ( ent propName value / obj props p )
  (setq obj (vlax-ename->vla-object ent))
  (setq props (vlax-invoke obj 'GetDynamicBlockProperties))
  (foreach p props
    (if (= (strcase (vla-get-PropertyName p)) (strcase propName))
      (vla-put-Value p (vlax-make-variant value vlax-vbDouble))))
  (princ))

;; ============================================================
;; BLOCK-DEFINITION LOADER
;; ============================================================

(defun vputki-ensure-block ( blockName dwgFileName / dwgPath )
  (if (tblsearch "BLOCK" blockName)
    T
    (progn
      (setq dwgPath (vputki-find-block-file dwgFileName))
      (if (or (null dwgPath) (not (= (type dwgPath) 'STR)))
        (progn
          (princ (strcat "\nVIRHE: " dwgFileName " ei loydy."))
          (princ "\nTarkista etta vputki-*.dwg-tiedostot ovat samassa kansiossa")
          (princ "\nkuin vputki.lsp tai $USERPROFILE\\suunnittelutyokalut\\.")
          nil)
        (progn
          (command "_.-INSERT" (strcat blockName "=" dwgPath))
          (command)
          T))))
)

;; ============================================================
;; LAYER-VARIN VALINTA (per koko)
;; ============================================================

(defun vputki-aci-for-size ( D )
  (cond
    ((= D 32) 151)    ; vaalea sininen
    ((= D 50)   5)    ; perussininen
    ((= D 75) 175)    ; tumma sininen
    (T          7)))  ; default fallback

;; ============================================================
;; INSERT: SUORA putki (dynamic block + Pituus-parametri)
;; ============================================================

(defun vputki-insert-suora ( D layerName /
                              p1 p2 dx dy len ang
                              blockName dwgName ok blkRef )
  (setq blockName (strcat "VPUTKI-" (itoa D)))
  (setq dwgName   (strcat "vputki-" (itoa D) ".dwg"))

  (setq ok (vputki-ensure-block blockName dwgName))
  (if (null ok) (exit))

  (setq p1 (getpoint "\nAloituspiste: "))
  (if (null p1) (exit))
  (setq p2 (getpoint p1 "\nLoppupiste: "))
  (if (null p2) (exit))

  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (setq len (sqrt (+ (* dx dx) (* dy dy))))
  (if (< len 1.0)
    (progn (princ "\nVIRHE: putki on liian lyhyt (< 1 mm).") (exit)))
  (setq ang (* 180.0 (/ (atan dy dx) pi)))

  (setvar "CLAYER" layerName)
  (setvar "CMDECHO" 0)
  (command "_.-INSERT" blockName p1 1 1 ang)
  (setq blkRef (entlast))
  (vputki-set-dyn-prop blkRef "Pituus" len)
  (princ (strcat "\n" blockName " luotu: pituus " (rtos len 2 1) " mm.")))

;; ============================================================
;; INSERT: FITTING (45/88.5/T -kulma, ei dynamic)
;; ============================================================

(defun vputki-insert-fitting ( D suffix layerName /
                                blockName dwgName ok )
  (setq blockName (strcat "VPUTKI-" (itoa D) "-" suffix))
  (setq dwgName   (strcat "vputki-" (itoa D) "-" suffix ".dwg"))

  (setq ok (vputki-ensure-block blockName dwgName))
  (if (null ok) (exit))

  (setvar "CLAYER" layerName)
  (setvar "CMDECHO" 0)

  ;; Anna AutoCAD:n hoitaa INSERT-prompts interaktiivisesti — pause on
  ;; LISP-vakio joka pyytaa kayttajan syotetta. Sequence:
  ;;   blockName -> [pause: insertion point] -> 1 (X) -> 1 (Y) -> [pause: rotation]
  ;; Kayttaja nakee blokin live-preview:na kun pyorittaa rotaatiota
  ;; (sama kuin natiivin INSERT-komennon kayttayttyminen).
  (command "_.-INSERT" blockName pause 1 1 pause)
  (princ (strcat "\n" blockName " luotu.")))

;; ============================================================
;; PAALOGIIKKA: malli-valinta + INSERT
;; ============================================================

(defun vputki-pipe-command ( D / *error* oldClayer oldCmdecho oldOsmode
                                 layerName aci malli suffix )

  (defun *error* ( msg )
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsmode  (getvar "OSMODE"))

  (setq layerName (strcat "KYL-VIEMARI-" (itoa D)))
  (setq aci (vputki-aci-for-size D))
  (vputki-ensure-layer layerName aci)

  ;; Kysy malli (88.5° -> "885" koska . ei ole sallittu initget-kwargissa)
  (initget "SUORA 45 885 T")
  (setq malli (getkword "\nMalli [SUORA/45/885/T] <SUORA>: "))
  (if (null malli) (setq malli "SUORA"))

  (cond
    ((= malli "SUORA") (vputki-insert-suora   D layerName))
    ((= malli "45")    (vputki-insert-fitting D "45"  layerName))
    ((= malli "885")   (vputki-insert-fitting D "885" layerName))
    ((= malli "T")     (vputki-insert-fitting D "t"   layerName)))

  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)
  (princ))

;; ============================================================
;; KAYTTAJAN KOMENNOT
;; ============================================================

;; Pikakomennot per koko (ei kysy halkaisijaa)
(defun c:VP32 ( / ) (vputki-pipe-command 32))
(defun c:VP50 ( / ) (vputki-pipe-command 50))
(defun c:VP75 ( / ) (vputki-pipe-command 75))

;; Pitka komento — kysyy halkaisijan ensin
(defun c:VPUTKI ( / size sizeNum )
  (initget "32 50 75")
  (setq size (getkword "\nViemariputken koko [32/50/75] <50>: "))
  (if (null size) (setq size "50"))
  (setq sizeNum (atoi size))
  (vputki-pipe-command sizeNum))

(princ "\nVPUTKI ladattu. Komennot: VP32, VP50, VP75 (tai VPUTKI).")
(princ)
