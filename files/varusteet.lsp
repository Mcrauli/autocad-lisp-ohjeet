;;; VARUSTEET.LSP - Kylmakoneikon sahkovarustelun blockit
;;;
;;; Riippuvuus: rinnalla files/ -kansiossa kuusi DWG-tiedostoa:
;;;   co2-anturi.dwg         - CO2-vuotoanturi
;;;   co2-sireeni.dwg        - CO2-halytinsireeni
;;;   huolto-pc.dwg          - Huolto-PC tai valvomotyoasema
;;;   rk-jk10.dwg            - Ryhmakeskus (esimerkki JK10)
;;;   saadinkeskus-ku.dwg    - Saadinkeskus (kontrolliyksikko)
;;;   hataseispainike.dwg    - Kylmakoneikon hatdiseispainike
;;;
;;; Lataa: APPLOAD -> tama tiedosto. (DWG:t loydetaan automaattisesti
;;; samasta kansiosta josta varusteet.lsp ladataan, vastaavaan tapaan
;;; kuin klhylly.lsp / positio.lsp tekevat omille block-DWG:lleen.)
;;;
;;; Komento:
;;;   VARUSTEET
;;;     -> keyword-prompti: CO2anturi / CO2sireeni / HuoltoPC /
;;;        RKJK10 / Saadinkeskus / Hataseis (nuolinappaimet)
;;;     -> insertointipiste pickilla
;;;     -> rotaatio pickilla tai numerona
;;;
;;; Layerit luodaan automaattisesti per laite (KYL-CO2-ANTURI,
;;; KYL-CO2-SIREENI, KYL-HUOLTO-PC, KYL-RK-JK10, KYL-SAADINKESKUS-KU,
;;; KYL-HATASEIS) AutoCAD-vareilla. Block-maaritysten sisalla geometria
;;; on layerilla 0 (BYBLOCK), joten instanssin layer periytyy alaspain
;;; ja dxf2ifc tunnistaa laitetyypin layer-pattern-mappauksesta.
;;;
;;; dxf2ifc-mappaus (default_kylmalaite.toml, v0.2.0a19+):
;;;   KYL-CO2-ANTURI*       -> IfcSensor / CO2SENSOR
;;;   KYL-CO2-SIREENI*      -> IfcAlarm / SIREN
;;;   KYL-HUOLTO-PC*        -> IfcCommunicationsAppliance / COMPUTER
;;;   KYL-RK-*              -> IfcElectricDistributionBoard / DISTRIBUTIONBOARD
;;;   KYL-SAADINKESKUS-*    -> IfcController / PROGRAMMABLE
;;;   KYL-HATASEIS*         -> IfcSwitchingDevice / EMERGENCYSTOP
;;;
;;; Kaikkien RAVA-koodi on T-TATE-02-01-003 (Tilavaraus - laitteisto)
;;; tai T-TATE-02-01-004 (Tilavaraus - keskus): kylmasuunnittelija
;;; varaa tilan, sahkdosuunnittelija korvaa lopullisella laitteella.

(vl-load-com)

;; ============================================================
;; LAITTEIDEN MAPPAUS
;; ============================================================
;;
;; Lista per laite:
;;   (keyword dwg-filename acad-block-name target-layer-name aci-color)
;;
;; - keyword on getkword-valikon nimi (ASCII, ei valilyonteja).
;; - dwg-filename loaytetaan samasta kansiosta kuin varusteet.lsp.
;; - acad-block-name on nimi jolla -INSERT lataa blockin AutoCAD:in
;;   block-tauluun. Sama session yli (uudelleenkutsu ei lataa
;;   blokkia uudelleen jos se on jo blocks-taulussa).
;; - target-layer-name luodaan automaattisesti puuttuessaan annetulla
;;   ACI-varilla. Olemassaolevaan layeriin ei kosketa.

(setq varusteet-device-map
  (list
    (list "CO2anturi"    "co2-anturi.dwg"        "CO2-anturi"       "KYL-CO2-ANTURI"        5)
    (list "CO2sireeni"   "co2-sireeni.dwg"       "CO2-sireeni"      "KYL-CO2-SIREENI"       1)
    (list "HuoltoPC"     "huolto-pc.dwg"         "Huolto-PC"        "KYL-HUOLTO-PC"         250)
    (list "RKJK10"       "rk-jk10.dwg"           "RK-JK10"          "KYL-RK-JK10"           6)
    (list "Saadinkeskus" "saadinkeskus-ku.dwg"   "Saadinkeskus-KU"  "KYL-SAADINKESKUS-KU"   2)
    (list "Hataseis"     "hataseispainike.dwg"   "Hataseispainike"  "KYL-HATASEIS"          1)
  )
)

;; ============================================================
;; LAYER HELPER
;; ============================================================

;; Varmistaa etta layer on olemassa annetulla AutoCAD color index:lla.
;; Jos layer on jo olemassa, ei kosketa sen asetuksiin (kayttajan
;; custom-vari sailyy).
(defun varusteet-ensure-layer ( layerName colorIndex
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
;; SELF-FOLDER + BLOCK-DWG LOCATOR
;; ============================================================
;;
;; Sama strategia kuin klhylly.lsp:n vastaavissa funktioissa:
;; etsi paasta varusteet.lsp:n sijainti -> sisterns DWG:t loytyvat
;; samasta kansiosta. Fallback yleisiin polkuihin
;; (suunnittelutyokalut, AutoCADLisp).

(defun varusteet-self-folder ( / found regbase target ver prod prof appkey val )
  (vl-load-com)
  (setq target "varusteet.lsp")
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

(defun varusteet-find-block-file ( dwgName / cands self prefix found p )
  (vl-load-com)
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      (setq cands '())
      (if (setq self (varusteet-self-folder))
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
;; VARUSTEET-KOMENTO
;; ============================================================

(defun c:VARUSTEET ( / *error* oldClayer oldCmdecho oldOsmode
                       choice entry dwgName blockName layerName colorIndex
                       blockPath )

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

  ;; 1) Valitse laite
  (initget "CO2anturi CO2sireeni HuoltoPC RKJK10 Saadinkeskus Hataseis")
  (setq choice
    (getkword
      (strcat
        "\nValitse varuste "
        "[CO2anturi/CO2sireeni/HuoltoPC/RKJK10/Saadinkeskus/Hataseis] "
        "<CO2anturi>: ")))
  (if (null choice) (setq choice "CO2anturi"))

  ;; 2) Hae mappaus-rivi
  (setq entry (assoc choice varusteet-device-map))
  (if (null entry)
    (progn
      (princ (strcat "\nVirhe: tuntematon varuste '" choice "'"))
      (setvar "CMDECHO" oldCmdecho)
      (setvar "CLAYER"  oldClayer)
      (exit)))
  (setq dwgName    (nth 1 entry))
  (setq blockName  (nth 2 entry))
  (setq layerName  (nth 3 entry))
  (setq colorIndex (nth 4 entry))

  ;; 3) Etsi block-DWG
  (setq blockPath (varusteet-find-block-file dwgName))
  (if (null blockPath)
    (progn
      (princ (strcat
        "\nVIRHE: " dwgName " ei loydy. Varmista etta tiedosto on samassa"
        "\nkansiossa kuin varusteet.lsp. (DWG-tiedostot kuuluvat"
        "\nsuunnittelutyokalut.zip-pakettiin.)"))
      (setvar "CMDECHO" oldCmdecho)
      (setvar "CLAYER"  oldClayer)
      (exit)))

  ;; 4) Varmista target-layer + aseta CLAYER:ksi
  (varusteet-ensure-layer layerName colorIndex)
  (setvar "CLAYER" layerName)

  ;; 5) Insertoi block. -INSERT-komento:
  ;;    blockName=blockPath   -> lataa blocks-tauluun ekalla kerralla
  ;;    pause                 -> kayttaja pickaa insertion-pisteen
  ;;    "" ""                 -> X-scale + Y-scale defaultit (1,1)
  ;;    pause                 -> kayttaja pickaa rotaation
  (command "_.-INSERT" (strcat blockName "=" blockPath) pause "" "" pause)

  ;; 6) Palauta tila
  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)
  (princ)
)

(princ "\nVARUSTEET.LSP ladattu - komento: VARUSTEET")
(princ)
