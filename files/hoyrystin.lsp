;;; HOYRYSTIN.LSP - Hoyrystimien insertointikomennot
;;;
;;; Pikakomennot per puhallinmaara (lyhyet ja pitkat aliakset):
;;;   HY1 / HOYR1 -> 1-puhaltimen hoyrystin (hoyrystin-1.dwg)
;;;   HY2 / HOYR2 -> 2-puhaltimen hoyrystin (hoyrystin-2.dwg)
;;;   HY3 / HOYR3 -> 3-puhaltimen hoyrystin (hoyrystin-3.dwg)
;;;
;;; Layer: KYL-HOYRYSTIMET (ACI 30, oranssi — erottuu sinisistä putkista).
;;; dxf2ifc:n preprocessing.py kayttaa wildcardia *yrystin* matchaamaan
;;; sekä ä/o että H/h variantit -> IfcEvaporator IFC-eksportissa.
;;;
;;; Komento-flow: APPLOAD -> HOYR1/2/3 -> nayttat lisayspisteen ->
;;; live-preview rotaatio kuin natiivissa INSERT:ssa.
;;;
;;; Block-DWG-tiedostot files/-kansiossa:
;;;   hoyrystin-1.dwg / hoyrystin-2.dwg / hoyrystin-3.dwg

(vl-load-com)

;; Globaali kansio-cache: kayttajan valitsema kansio muistetaan istunnon
;; ajaksi jos locator ei ole loytanyt DWG:ta automaattisesti.
(if (not (boundp '*hoyr-cached-folder*)) (setq *hoyr-cached-folder* nil))

;; ============================================================
;; LAYER-HELPER
;; ============================================================

(defun hoyr-ensure-layer ( layerName colorIndex
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
;; BLOCK-DWG LOCATOR (kuvio kopioitu klhylly.lsp:sta)
;; ============================================================

(defun hoyr-self-folder ( / found regbase target ver prod prof appkey val )
  (vl-load-com)
  (setq target "hoyrystin.lsp")
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

;; Splittaa Support Path -merkkijono (ACADPREFIX) puolipisteella.
(defun hoyr-split-support-paths ( s / result start i ch )
  (setq result '() start 0 i 0)
  (while (< i (strlen s))
    (setq ch (substr s (1+ i) 1))
    (if (= ch ";")
      (progn
        (setq result (cons (substr s (1+ start) (- i start)) result))
        (setq start (1+ i))))
    (setq i (1+ i)))
  (setq result (cons (substr s (1+ start)) result))
  (reverse result))

(defun hoyr-find-block-file ( dwgName / cands self prefix found p picked
                                       acadprefix paths )
  (vl-load-com)
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      (setq cands '())
      ;; 1. Aiemmin muistettu kansio
      (if (and *hoyr-cached-folder*
               (= (type *hoyr-cached-folder*) 'STR))
        (setq cands (list (strcat *hoyr-cached-folder* "\\" dwgName))))
      ;; 2. AutoCAD Support Paths (ACADPREFIX = ";"-separated lista)
      (setq acadprefix (getvar "ACADPREFIX"))
      (if (and acadprefix (= (type acadprefix) 'STR))
        (foreach p (hoyr-split-support-paths acadprefix)
          (if (> (strlen p) 0)
            (setq cands (append cands
                                (list (strcat p "\\" dwgName)))))))
      ;; 3. Self-folder via APPLOAD-registry
      (if (setq self (hoyr-self-folder))
        (if (= (type self) 'STR)
          (setq cands (append cands (list (strcat self "\\" dwgName))))))
      ;; 4. Current DWG-kansio
      (setq prefix (getvar "DWGPREFIX"))
      (if (and prefix (= (type prefix) 'STR) (> (strlen prefix) 0))
        (setq cands (append cands (list (strcat prefix dwgName)))))
      ;; 5. Yleiset asennuspaikat
      (setq cands (append cands
        (list
          (strcat (getenv "USERPROFILE") "\\suunnittelutyokalut\\" dwgName)
          (strcat (getenv "USERPROFILE") "\\AutoCADLisp\\" dwgName)
          (strcat "C:\\AutoCADLisp\\" dwgName))))
      ;; Etsi ensimmainen olemassaoleva
      (foreach p cands
        (if (and (not found)
                 (= (type p) 'STR)
                 (vl-file-systime p))
          (setq found p)))
      ;; Jos ei loydy mistaan -> tulosta yrityspolut + kysy file-dialogilla
      (if (null found)
        (progn
          (princ (strcat "\n" dwgName " ei loytynyt seuraavista paikoista:"))
          (foreach p cands
            (if (= (type p) 'STR) (princ (strcat "\n  " p))))
          (princ "\nValitse kansio file-dialogilla.")
          (setq picked (getfiled
                        (strcat "Etsi " dwgName)
                        dwgName "dwg" 0))
          (if (and picked (= (type picked) 'STR))
            (progn
              (setq found picked)
              (setq *hoyr-cached-folder* (vl-filename-directory picked))
              (princ (strcat "\nHoyrystin-kansio muistettu: "
                             *hoyr-cached-folder*))))))
      found)
  )
)

;; ============================================================
;; BLOCK-DEFINITION LOADER
;; ============================================================

(defun hoyr-ensure-block ( blockName dwgFileName / dwgPath )
  (if (tblsearch "BLOCK" blockName)
    T
    (progn
      (setq dwgPath (hoyr-find-block-file dwgFileName))
      (if (or (null dwgPath) (not (= (type dwgPath) 'STR)))
        (progn
          (princ (strcat "\nVIRHE: " dwgFileName " ei loydy."))
          (princ "\nTarkista etta hoyrystin-*.dwg-tiedostot ovat samassa kansiossa")
          (princ "\nkuin hoyrystin.lsp tai $USERPROFILE\\suunnittelutyokalut\\.")
          nil)
        (progn
          (command "_.-INSERT" (strcat blockName "=" dwgPath))
          (command)
          T))))
)

;; ============================================================
;; PAAKOMENTO: insert hoyrystin
;; ============================================================

(defun hoyr-insert ( puh / *error* oldClayer oldCmdecho oldOsmode
                          blockName dwgName ok )

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

  (hoyr-ensure-layer "KYL-HOYRYSTIMET" 30)   ; oranssi

  (setq blockName (strcat "HOYRYSTIN-" (itoa puh) "PUH"))
  (setq dwgName   (strcat "hoyrystin-" (itoa puh) ".dwg"))

  (setq ok (hoyr-ensure-block blockName dwgName))
  (if (null ok) (exit))

  (setvar "CLAYER" "KYL-HOYRYSTIMET")
  (setvar "CMDECHO" 0)

  ;; Anna AutoCAD:n hoitaa INSERT-prompts interaktiivisesti — kayttaja
  ;; saa live-preview kun pyorittaa rotaatiota.
  (command "_.-INSERT" blockName pause 1 1 pause)

  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)
  (princ (strcat "\n" blockName " luotu.")))

;; ============================================================
;; KAYTTAJAN KOMENNOT
;; ============================================================

;; Lyhyet pikakomennot
(defun c:HY1 ( / ) (hoyr-insert 1))
(defun c:HY2 ( / ) (hoyr-insert 2))
(defun c:HY3 ( / ) (hoyr-insert 3))

;; Pidemmat aliakset (taaksepain yhteensopivuus)
(defun c:HOYR1 ( / ) (hoyr-insert 1))
(defun c:HOYR2 ( / ) (hoyr-insert 2))
(defun c:HOYR3 ( / ) (hoyr-insert 3))

(princ "\nHOYRYSTIN ladattu. Komennot: HY1, HY2, HY3 (tai HOYR1/2/3).")
(princ)
