;;; KONEIKKO.LSP - Kylmakoneikon insertointikomento
;;;
;;; Komennot:
;;;   KONEIKKO / KKO -> sijoittaa Koneikko.dwg-blockin live-preview-
;;;                     rotaatiolla kuten natiivi INSERT
;;;
;;; Layer: KYL-KONEIKKO (AutoCAD Color Index 175, RGB 63,63,127) - sama
;;; vari kuin muilla KYL-tyokaluilla. dxf2ifc tunnistaa KYL-KONEIKKO*-
;;; layerin -> IfcUnitaryEquipment IFC-eksportissa.
;;;
;;; Block-DWG samassa kansiossa kuin tama LSP: Koneikko.dwg
;;;
;;; Lataa: APPLOAD -> valitse tama tiedosto.

(vl-load-com)

;; Globaali kansio-cache: kayttajan valitsema kansio muistetaan istunnon
;; ajaksi jos locator ei ole loytanyt DWG:ta automaattisesti.
(if (not (boundp '*koneikko-cached-folder*)) (setq *koneikko-cached-folder* nil))

;; Kaapataan LSP:n kansio LOAD-aikaan. Locator kayttaa tata DWG-haussa.
(defun koneikko-find-lsp-folder ( / regbase ver prod prof appkey val found ff )
  (setq found nil)
  (setq ff (findfile "koneikko.lsp"))
  (if (and ff (= (type ff) 'STR))
    (setq found (vl-filename-directory ff))
    (progn
      (setq regbase "HKEY_CURRENT_USER\\SOFTWARE\\Autodesk\\AutoCAD")
      (foreach ver (vl-registry-descendents regbase)
        (foreach prod (vl-registry-descendents (strcat regbase "\\" ver))
          (foreach prof (vl-registry-descendents
                          (strcat regbase "\\" ver "\\" prod "\\Profiles"))
            (setq appkey (strcat regbase "\\" ver "\\" prod
                                 "\\Profiles\\" prof "\\Dialogs\\Appload"))
            (setq val (vl-registry-read appkey "MainDialog"))
            (if (and (null found) val (= (type val) 'STR)
                     (vl-file-systime (strcat val "\\koneikko.lsp")))
              (setq found val)))))))
  found)

(setq *koneikko-lsp-folder* (koneikko-find-lsp-folder))

;; ============================================================
;; LAYER-HELPER
;; ============================================================

(defun koneikko-ensure-layer ( layerName colorIndex
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
;; Etsii dwgName:n: Support Path -> cached -> LSP-kansio -> DWGPREFIX ->
;; %USERPROFILE%\suunnittelutyokalut\. Jos ei loydy -> file-dialog.

(defun koneikko-find-block-file ( dwgName / cands prefix found p picked )
  (vl-load-com)
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      (setq cands '())
      (if (and *koneikko-cached-folder* (= (type *koneikko-cached-folder*) 'STR))
        (setq cands (list (strcat *koneikko-cached-folder* "\\" dwgName))))
      (if (and *koneikko-lsp-folder* (= (type *koneikko-lsp-folder*) 'STR))
        (setq cands (append cands
                            (list (strcat *koneikko-lsp-folder* "\\" dwgName)))))
      (setq prefix (getvar "DWGPREFIX"))
      (if (and prefix (= (type prefix) 'STR) (> (strlen prefix) 0))
        (setq cands (append cands (list (strcat prefix dwgName)))))
      (setq cands (append cands
        (list (strcat (getenv "USERPROFILE")
                      "\\suunnittelutyokalut\\" dwgName))))
      (foreach p cands
        (if (and (not found) (= (type p) 'STR) (vl-file-systime p))
          (setq found p)))
      (if (null found)
        (progn
          (princ (strcat "\n" dwgName " ei loytynyt — valitse kansio file-dialogilla."))
          (setq picked (getfiled (strcat "Etsi " dwgName) dwgName "dwg" 0))
          (if (and picked (= (type picked) 'STR))
            (progn
              (setq found picked)
              (setq *koneikko-cached-folder* (vl-filename-directory picked))
              (princ "\nKansio muistettu istunnon ajaksi.")))))
      found)
  )
)

;; ============================================================
;; BLOCK-DEFINITION LOADER
;; ============================================================

;; Aina pakota block-maarityksen lataus polusta — varmistaa etta
;; ATTDEF:n / geometrian / varin paivitykset DWG:hen naky vat ilman
;; etta kayttajan tarvitsee manuaalisesti redefinetada blockia. Jos
;; block oli jo maaritetty tassa piirustuksessa, "_Y" vastaa AutoCAD:n
;; "Redefine block?"-promptiin. Tyhja (command) cancel-tekee INSERT:n
;; nopeasti niin etta vain block-maaritys paivittyy — paakomento luo
;; instanssin erikseen.
(defun koneikko-ensure-block ( blockName dwgFileName / dwgPath isRedefine )
  (setq dwgPath (koneikko-find-block-file dwgFileName))
  (if (or (null dwgPath) (not (= (type dwgPath) 'STR)))
    (progn
      (princ (strcat "\nVIRHE: " dwgFileName " ei loydy."))
      (princ "\nTarkista etta Koneikko.dwg on samassa kansiossa kuin")
      (princ "\nkoneikko.lsp tai $USERPROFILE\\suunnittelutyokalut\\.")
      nil)
    (progn
      (setq isRedefine (if (tblsearch "BLOCK" blockName) T nil))
      (command "_.-INSERT" (strcat blockName "=" dwgPath))
      (if isRedefine (command "_Y"))   ; "Redefine block?" -> Yes
      (command)                         ; cancel INSERT instance
      T))
)

;; ============================================================
;; PAAKOMENTO: insert koneikko
;; ============================================================

(defun koneikko-insert ( / *error* oldClayer oldCmdecho oldOsmode
                             oldAttreq oldAttdia
                             blockName dwgName ok )

  (defun *error* ( msg )
    (if oldAttdia  (setvar "ATTDIA"  oldAttdia))
    (if oldAttreq  (setvar "ATTREQ"  oldAttreq))
    (if oldOsmode  (setvar "OSMODE"  oldOsmode))
    (if oldCmdecho (setvar "CMDECHO" oldCmdecho))
    (if oldClayer  (setvar "CLAYER"  oldClayer))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*ABORT*,*EXIT*")))
      (princ (strcat "\nVirhe: " msg)))
    (princ))

  (setq oldClayer  (getvar "CLAYER"))
  (setq oldCmdecho (getvar "CMDECHO"))
  (setq oldOsmode  (getvar "OSMODE"))
  (setq oldAttreq  (getvar "ATTREQ"))
  (setq oldAttdia  (getvar "ATTDIA"))

  (koneikko-ensure-layer "KYL-KONEIKKO" 175)   ; ACI 175 (RGB 63,63,127)

  (setq blockName "KONEIKKO")
  (setq dwgName   "Koneikko.dwg")

  (setq ok (koneikko-ensure-block blockName dwgName))
  (if (null ok) (exit))

  (setvar "CLAYER" "KYL-KONEIKKO")
  (setvar "CMDECHO" 0)
  ;; Pakota attribuuttien kysely INSERT:in yhteydessa. ATTREQ=1 vaatii
  ;; niiden tayttamista, ATTDIA=1 avaa dialog-ikkunan (muuten kysytaan
  ;; rivi riveltä komentorivilla). Kayttajan kone-asetukset palautetaan
  ;; lopussa / *error*-haarassa.
  (setvar "ATTREQ" 1)
  (setvar "ATTDIA" 1)

  ;; Anna AutoCAD:n hoitaa INSERT-prompts interaktiivisesti — kayttaja
  ;; saa live-preview kun pyorittaa rotaatiota. "_S" 1 lukitsee skaalan
  ;; heti, while-pause -loop luovuttaa loput (insertointipiste + rotaatio)
  ;; kayttajalle. Toimii seka AutoCAD etta BricsCAD vaikka niiden
  ;; -INSERT-prompt-sekvenssi muuten eroaa (sama kuvio kuin varusteet.lsp).
  (command "_.-INSERT" blockName "_S" 1)
  (while (= 1 (logand 1 (getvar "CMDACTIVE")))
    (command pause))

  (setvar "ATTDIA"  oldAttdia)
  (setvar "ATTREQ"  oldAttreq)
  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)
  (princ "\nKONEIKKO luotu."))

;; ============================================================
;; KAYTTAJAN KOMENNOT
;; ============================================================

(defun c:KONEIKKO ( / ) (koneikko-insert))
(defun c:KKO      ( / ) (koneikko-insert))

(princ "\nKONEIKKO ladattu. Komento: KONEIKKO (tai KKO).")
(princ)
