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
;;; Layerit luodaan automaattisesti: KYL-VIEMARI-32 / -50 / -75, kaikki
;;; AutoCAD Color Index 175 (RGB 63,63,127, tumma sininen).

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
;; LSP-KANSION KAAPPAUS LOAD-AIKAAN
;; ============================================================
;;
;; DWG:t ovat ZIP:ssa samassa kansiossa kuin LSP. Etsitaan LSP:n
;; oma kansio findfilella, ja jos APPLOAD ei ole lisannyt sita Support
;; Path:lle, lue viimeisin APPLOAD-kansio rekisterista.

(if (not (boundp '*vputki-cached-folder*))
    (setq *vputki-cached-folder* nil))

(defun vputki-find-lsp-folder ( / regbase ver prod prof appkey val found ff )
  (setq found nil)
  (setq ff (findfile "vputki.lsp"))
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
                     (vl-file-systime (strcat val "\\vputki.lsp")))
              (setq found val)))))))
  found)

(setq *vputki-lsp-folder* (vputki-find-lsp-folder))

;; ============================================================
;; BLOCK-DWG LOCATOR
;; ============================================================
;;
;; Hakujarjestys:
;;   1. AutoCAD Support Path (findfile)
;;   2. Aiemmin file-dialogilla valittu kansio (cached)
;;   3. LSP:n oma kansio (load-time captured)
;;   4. Current DWG-kansio (DWGPREFIX)
;;   5. %USERPROFILE%\suunnittelutyokalut\ (yleinen ZIP-purkupaikka)
;; Fallback: file-dialog, jonka valinta muistetaan istunnon ajaksi.

(defun vputki-find-block-file ( dwgName / cands prefix found p picked )
  (vl-load-com)
  (setq found (findfile dwgName))
  (if (and found (= (type found) 'STR))
    found
    (progn
      (setq found nil)
      (setq cands '())
      (if (and *vputki-cached-folder* (= (type *vputki-cached-folder*) 'STR))
        (setq cands (list (strcat *vputki-cached-folder* "\\" dwgName))))
      (if (and *vputki-lsp-folder* (= (type *vputki-lsp-folder*) 'STR))
        (setq cands (append cands
                            (list (strcat *vputki-lsp-folder* "\\" dwgName)))))
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
              (setq *vputki-cached-folder* (vl-filename-directory picked))
              (princ "\nKansio muistettu istunnon ajaksi.")))))
      found)
  )
)

;; ============================================================
;; INSERT VIA ENTMAKE - kiertää AutoCAD:n _.INSERT bugin Y-scale -1 +
;; 3D UCS -yhdistelmässä.
;;
;; Käytetään suoraan entmaketa INSERT-entiteetin luomiseen, lasketaan
;; WCS->OCS itse perustuen nykyiseen UCS:n Z-akselin suuntaan.
;; ============================================================

(defun vputki-make-insert ( blockName layerName ins-pt-ucs sy rot-deg /
                              ins-pt-wcs extr-wcs ocs-x ocs-y norm
                              ocs-pt rot-rad ucs-x-wcs theta
                              dot-val cross-vec cross-z )
  ;; Selvitä UCS:n perustasot WCS:ssä
  (setq extr-wcs (trans '(0.0 0.0 1.0) 1 0 T)) ; UCS Z direction WCS:ssä
  (setq ucs-x-wcs (trans '(1.0 0.0 0.0) 1 0 T)) ; UCS X direction WCS:ssä
  ;; Konvertoi insertion point UCS -> WCS
  (setq ins-pt-wcs (trans ins-pt-ucs 1 0))
  ;; Konvertoi WCS -> OCS (Arbitrary Axis Algorithm)
  (setq norm extr-wcs)
  (if (and (< (abs (car norm)) 0.015625)
           (< (abs (cadr norm)) 0.015625))
    ;; |Nx|<1/64 ja |Ny|<1/64: käytä WY x N
    (setq ocs-x (list (caddr norm)
                       0.0
                       (- 0.0 (car norm))))
    ;; Käytä WZ x N
    (setq ocs-x (list (- 0.0 (cadr norm))
                       (car norm)
                       0.0)))
  ;; Normalisoi ocs-x
  (setq ocs-x (vputki-vec-normalize ocs-x))
  ;; ocs-y = norm x ocs-x
  (setq ocs-y (vputki-vec-cross norm ocs-x))
  (setq ocs-y (vputki-vec-normalize ocs-y))
  ;; OCS-pt = (pt . ocs-x, pt . ocs-y, pt . norm)
  (setq ocs-pt
    (list (vputki-vec-dot ins-pt-wcs ocs-x)
          (vputki-vec-dot ins-pt-wcs ocs-y)
          (vputki-vec-dot ins-pt-wcs norm)))
  ;; Lasketaan kulma UCS_X:n ja OCS_X:n välillä (UCS_Z:n ympäri)
  ;; ENTMAKE-rotaatio = INSERT-rotaatio - theta
  (setq dot-val (vputki-vec-dot ucs-x-wcs ocs-x))
  (setq cross-vec (vputki-vec-cross ucs-x-wcs ocs-x))
  (setq cross-z (vputki-vec-dot cross-vec extr-wcs))
  (setq theta (atan cross-z dot-val))
  (setq rot-rad (- (vputki-deg->rad rot-deg) theta))
  ;; Luo block reference
  (entmake (list
    '(0 . "INSERT")
    '(100 . "AcDbEntity")
    (cons 8 layerName)
    '(100 . "AcDbBlockReference")
    (cons 2 blockName)
    (cons 10 ocs-pt)
    (cons 41 1.0)
    (cons 42 (float sy))
    (cons 43 1.0)
    (cons 50 rot-rad)
    (cons 210 extr-wcs)))
  (entlast))

(defun vputki-vec-cross ( a b )
  (list (- (* (cadr a) (caddr b)) (* (caddr a) (cadr b)))
        (- (* (caddr a) (car b))  (* (car a)   (caddr b)))
        (- (* (car a)   (cadr b)) (* (cadr a)  (car b)))))

(defun vputki-vec-dot ( a b )
  (+ (* (car a) (car b)) (* (cadr a) (cadr b)) (* (caddr a) (caddr b))))

(defun vputki-vec-normalize ( v / len )
  (setq len (sqrt (vputki-vec-dot v v)))
  (if (< len 1e-12) v
      (list (/ (car v) len) (/ (cadr v) len) (/ (caddr v) len))))

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

(defun vputki-norm-path ( p / out )
  ;; Poista tuplabakslashit (esim. "C:\\foo\\\\bar" -> "C:\\foo\\bar").
  ;; Korjaa sen tilanteen, jossa kansio sattuu paattymaan "\\" jolloin
  ;; strcat folder "\\" name tuottaa kahden bakslashin sekvenssin
  ;; -- INSERT-komento hylkaa polun "Invalid file name".
  (setq out p)
  (while (vl-string-search "\\\\" out)
    (setq out (vl-string-subst "\\" "\\\\" out)))
  out)

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
          (setq dwgPath (vputki-norm-path dwgPath))
          (command "_.-INSERT" (strcat blockName "=" dwgPath))
          (command)
          T))))
)

;; ============================================================
;; LAYER-VARIN VALINTA (per koko)
;; ============================================================

(defun vputki-aci-for-size ( D )
  175)  ; kaikki KYL-* layerit yhtenaisesti ACI 175 (RGB 63,63,127)

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


;; ============================================================
;; CONTINUOUS-TILA (uusi PLINE-tyylinen UX, v0.2)
;; ============================================================
;;
;; Komento VP: pick-pick-pick-jatkuva piirto. Tyokalu paattelee
;; automaattisesti suunnan vaihdosta tarvittavan fittingin (45° / 88.5°)
;; ja insertoi sen kulmapisteeseen.
;;
;; Key 'T' kesken piirron aktivoi T-haaran alikomennon.
;; Key 'U' peruu viimeisen insertion.
;; Enter lopettaa silmukan.

;; ----- Saadettavat asetukset -----------------------------------------
;;
;; Jos fittingin natiivi-orientaatio DWG:ssa eroaa odotetusta (input-
;; portti -X-suunnassa, output 45° / -88.5°), saada *vputki-rot-offset-X*
;; -globaaleja. Yksikko = asteita.

(if (not (boundp '*vputki-rot-offset-45*))  (setq *vputki-rot-offset-45*  -90.0))
(if (not (boundp '*vputki-rot-offset-885*)) (setq *vputki-rot-offset-885* -90.0))
(if (not (boundp '*vputki-rot-offset-t*))   (setq *vputki-rot-offset-t*   0.0))

;; Fittingin natiivi-kaannos: -1 = CW (output kaytrtaa kellon mukaisesti),
;; +1 = CCW. Per 45-fittingin BEDIT-kuva: input west, output SE -> CW natiivi.
;; Saata jos vaarin: (setq *vputki-native-turn-885* 1) jne.
(if (not (boundp '*vputki-native-turn-45*))  (setq *vputki-native-turn-45*  -1))
(if (not (boundp '*vputki-native-turn-885*)) (setq *vputki-native-turn-885* -1))

;; Position offset: missa fittingin INPUT-portti on default-orientaatiossa
;; suhteessa block-originiin (basepointiin). Jos basepoint on tarkalleen
;; input-portissa, jata (0.0 0.0). VP-MEASURE-komento laskee oikeat arvot.
(if (not (boundp '*vputki-pos-offset-45*))  (setq *vputki-pos-offset-45*  '(0.0 78.7)))
(if (not (boundp '*vputki-pos-offset-885*)) (setq *vputki-pos-offset-885* '(0.0 106.5)))

;; Output port -position default-orientaatiossa (mitattu VP-MEASURE:lla
;; size 50:lle). Port-aware trim: seuraava putki alkaa fittingin output-
;; portista, ei p_prev:sta.
(if (not (boundp '*vputki-output-pos-45*))  (setq *vputki-output-pos-45*  '(50.2 125.2)))
(if (not (boundp '*vputki-output-pos-885*)) (setq *vputki-output-pos-885* '(102.0 106.5)))

;; Output axis default-orientaatiossa (mitattu). Force-direction:
;; pipen suunta lukitaan tahan output-axis:iin (ei kayttajan klikkaussuuntaan)
;; -> ei kinkkia fittingin output-portilla.
(if (not (boundp '*vputki-output-axis-45*))  (setq *vputki-output-axis-45*  42.8))
(if (not (boundp '*vputki-output-axis-885*)) (setq *vputki-output-axis-885* 0.0))

;; Salli fittingin Y-peilaus (sy=-1) kun kaannos on CW. Jos nil, CW-
;; kaannos jaa suoraksi varoituksen kera.
(if (not (boundp '*vputki-allow-fitting-mirror*))
    (setq *vputki-allow-fitting-mirror* T))

;; Interaktiivinen fitting-insert: kayttaja pyorittaa fittingin paikoilleen
;; AutoCADin live-preview:lla, INSERT pause hoitaa rotaation. Auto-rotaatio
;; mukana fallbackina (nil), mutta vaatii oikeat *vputki-rot-offset-*-arvot.
;; Suositus: T jos alignment ei toimi auto-tilassa.
(if (not (boundp '*vputki-fitting-interactive*))
    (setq *vputki-fitting-interactive* nil))

;; Kulmaluokituksen toleranssit (asteita).
(if (not (boundp '*vputki-tol-straight*)) (setq *vputki-tol-straight* 5.0))
(if (not (boundp '*vputki-tol-45*))       (setq *vputki-tol-45*       20.0))
(if (not (boundp '*vputki-tol-885*))      (setq *vputki-tol-885*      15.0))

;; ----- Geometria-apufunktiot -----------------------------------------

(defun vputki-rad->deg (rad) (* (/ rad pi) 180.0))

(defun vputki-deg->rad (deg) (* (/ deg 180.0) pi))

(defun vputki-angle-deg (p1 p2 / dx dy)
  ;; Kulma p1->p2 asteina; AutoCAD atan palauttaa (-pi, pi]
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (vputki-rad->deg (atan dy dx)))

(defun vputki-dist-2d (p1 p2 / dx dy)
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (sqrt (+ (* dx dx) (* dy dy))))

(defun vputki-norm-deg (d)
  ;; Normalisoi vali (-180, 180]
  (while (>  d  180.0) (setq d (- d 360.0)))
  (while (<= d -180.0) (setq d (+ d 360.0)))
  d)

(defun vputki-turn-deg (dir-in dir-out)
  ;; Etumerkkinen kaannosaste: positiivinen = CCW, negatiivinen = CW.
  (vputki-norm-deg (- dir-out dir-in)))

(defun vputki-classify-turn (turn-deg / abs-deg)
  ;; turn-deg -> 'straight | '45 | '885 | 'unknown
  (setq abs-deg (abs turn-deg))
  (cond
    ((< abs-deg *vputki-tol-straight*)           'straight)
    ((< (abs (- abs-deg 45.0)) *vputki-tol-45*)  '45)
    ((< (abs (- abs-deg 88.5)) *vputki-tol-885*) '885)
    ((< (abs (- abs-deg 90.0)) *vputki-tol-885*) '885)
    (T 'unknown)))

;; ----- Pre-load: kaikki 4 blokkia kerralla --------------------------

(defun vputki-preload-set (D / sz ok)
  (setq sz (itoa D))
  (setq ok T)
  (if (not (vputki-ensure-block (strcat "VPUTKI-" sz)
                                 (strcat "vputki-" sz ".dwg")))     (setq ok nil))
  (if (not (vputki-ensure-block (strcat "VPUTKI-" sz "-45")
                                 (strcat "vputki-" sz "-45.dwg")))  (setq ok nil))
  (if (not (vputki-ensure-block (strcat "VPUTKI-" sz "-885")
                                 (strcat "vputki-" sz "-885.dwg"))) (setq ok nil))
  (if (not (vputki-ensure-block (strcat "VPUTKI-" sz "-T")
                                 (strcat "vputki-" sz "-t.dwg")))   (setq ok nil))
  ok)

;; ----- Suora putki dynaamisella Pituus-parametrilla -----------------

(defun vputki-cont-insert-straight (D layerName p1 p2 / blockName len ang ref)
  (setq len (vputki-dist-2d p1 p2))
  (if (< len 1.0)
    (progn (princ "\nVAROITUS: putki liian lyhyt (< 1 mm), ohitetaan.")
           nil)
    (progn
      (setq blockName (strcat "VPUTKI-" (itoa D)))
      (setq ang (vputki-angle-deg p1 p2))
      (setvar "CLAYER" layerName)
      (command "_.-INSERT" blockName p1 1 1 ang)
      (setq ref (entlast))
      (vputki-set-dyn-prop ref "Pituus" len)
      ;; Talleta trimausta varten: viimeisin pipe + sen start-piste WORLD-koordinaateissa
      (setq *vputki-last-pipe-ref* ref)
      (setq *vputki-last-pipe-start* (trans p1 1 0))
      (setq *vputki-last-pipe-ang* ang)
      ref)))

;; ----- Kulmafitting kulmapisteeseen p_corner ------------------------
;;
;; Oletettu natiivi-orientaatio: input-portti origosta -X-suunnassa
;; (= portti facing 180°), output 45° (45-fitting) tai 88.5° (88.5-
;; fitting), molemmat CCW-bend. Jos kaannos on CW, peilataan sy=-1.
;;
;; rot-base = dir_in (sisaantulosuunta asteissa, p_prev_prev -> p_corner)
;; turn-sign = +1 (CCW) tai -1 (CW)

(defun vputki-cont-insert-corner (D kind p_corner rot-base turn-sign /
                                   blockName offset rot sy ref native-sign
                                   pos-off rot-rad off-dx off-dy adj-p
                                   out-pos out-dx out-dy out-axis-default)
  (setq offset
    (cond ((eq kind '45)  *vputki-rot-offset-45*)
          ((eq kind '885) *vputki-rot-offset-885*)
          (T              0.0)))
  (setq blockName
    (cond ((eq kind '45)  (strcat "VPUTKI-" (itoa D) "-45"))
          ((eq kind '885) (strcat "VPUTKI-" (itoa D) "-885"))
          (T nil)))
  (cond
    ((null blockName)
      (princ "\nVIRHE: tuntematon fitting-tyyppi.")
      nil)
    (*vputki-fitting-interactive*
      ;; Interaktiivinen: pause rotaatiolle, kayttaja pyorittaa visuaalisesti.
      ;; ENDPOINT/NEAREST-snap auttaa kohdistamaan porttiin.
      (princ "\nPyorita fitting paikoilleen ja paina Enter (snap auttaa).")
      (command "_.-INSERT" blockName p_corner 1 1 pause)
      (setq ref (entlast))
      ref)
    ((and (< turn-sign 0) (not *vputki-allow-fitting-mirror*))
      (princ "\nVAROITUS: CW-kaannos vaatii peilauksen, *vputki-allow-fitting-mirror* on nil -- ohitetaan fitting.")
      nil)
    (T
      ;; Mirror vain jos kayttajan kannosuunta poikkeaa natiivista.
      (setq native-sign
        (cond ((eq kind '45)  *vputki-native-turn-45*)
              ((eq kind '885) *vputki-native-turn-885*)
              (T -1)))
      (setq sy (if (= turn-sign native-sign) 1 -1))
      ;; Mirror-tapauksessa input-axis flippaa Y:n kautta -> offset-merkki
      ;; kaantyy. Ilman tata CCW-kayttaja CW-natiivilla menee 180° vaarin.
      (setq rot (+ rot-base (if (= sy 1) offset (- offset))))
      ;; Position-offset: jos basepoint ei ole tarkalleen input-portissa,
      ;; siirra insert-piste niin etta portti paatyy p_corner:iin.
      (setq pos-off
        (cond ((eq kind '45)  *vputki-pos-offset-45*)
              ((eq kind '885) *vputki-pos-offset-885*)
              (T '(0.0 0.0))))
      (setq rot-rad (vputki-deg->rad rot))
      (setq off-dx (- (* (car pos-off) (cos rot-rad))
                      (* (cadr pos-off) (sin rot-rad) sy)))
      (setq off-dy (+ (* (car pos-off) (sin rot-rad))
                      (* (cadr pos-off) (cos rot-rad) sy)))
      (setq adj-p
        (list (- (car p_corner) off-dx)
              (- (cadr p_corner) off-dy)
              (if (caddr p_corner) (caddr p_corner) 0.0)))
      (princ (strcat "\n[DBG-CORNER] kind=" (vl-prin1-to-string kind)
                     " sy=" (itoa sy) " rot=" (rtos rot 2 2)
                     " adj-p_UCS=(" (rtos (car adj-p) 2 2) ", "
                     (rtos (cadr adj-p) 2 2) ", "
                     (rtos (if (caddr adj-p) (caddr adj-p) 0.0) 2 2) ")"
                     " adj-p_WORLD=(" (rtos (car (trans adj-p 1 0)) 2 2) ", "
                     (rtos (cadr (trans adj-p 1 0)) 2 2) ", "
                     (rtos (caddr (trans adj-p 1 0)) 2 2) ")"))
      ;; ENTMAKE INSERT entity directly, bypassing _.INSERT command (joka bugaa
      ;; Y-scale -1 + 3D UCS yhdistelmässä). Lasketaan WCS->OCS itse.
      (vputki-make-insert blockName (getvar "CLAYER") adj-p sy rot)
      (setq ref (entlast))
      (princ (strcat "\n[DBG-CORNER] entity OCS="
                     (vl-prin1-to-string (cdr (assoc 10 (entget ref))))
                     " extr=" (vl-prin1-to-string (cdr (assoc 210 (entget ref))))
                     " scale=(" (rtos (cdr (assoc 41 (entget ref))) 2 2) ","
                                 (rtos (cdr (assoc 42 (entget ref))) 2 2) ","
                                 (rtos (cdr (assoc 43 (entget ref))) 2 2) ")"
                     " rot=" (rtos (cdr (assoc 50 (entget ref))) 2 2)))
      (setq out-pos
        (cond ((eq kind '45)  *vputki-output-pos-45*)
              ((eq kind '885) *vputki-output-pos-885*)
              (T '(0.0 0.0))))
      (setq out-dx (- (* (car out-pos) (cos rot-rad))
                      (* (cadr out-pos) (sin rot-rad) sy)))
      (setq out-dy (+ (* (car out-pos) (sin rot-rad))
                      (* (cadr out-pos) (cos rot-rad) sy)))
      ;; Input port world = adj-p (basepoint) konvertoituna WORLD-koordinaatteihin
      (setq *vputki-last-input-port* (trans adj-p 1 0))
      (setq *vputki-last-output-pos*
        (list (+ (car adj-p) out-dx)
              (+ (cadr adj-p) out-dy)
              (if (caddr adj-p) (caddr adj-p) 0.0)))
      (setq out-axis-default
        (cond ((eq kind '45)  *vputki-output-axis-45*)
              ((eq kind '885) *vputki-output-axis-885*)
              (T 0.0)))
      (setq *vputki-last-output-axis*
        (vputki-norm-deg
          (if (= sy 1)
            (+ rot out-axis-default)
            (+ rot (- out-axis-default)))))
      ref)))

;; ----- T-haaran insert + haaraputki ---------------------------------
;;
;; Oletus: T-haaran natiivi-orientaatio = paarunko X-akselin suuntaan,
;; haarapaippa +Y-suuntaan. rot-base = paarungon suunta.

(defun vputki-cont-insert-t (D layerName p_t p_branch /
                              blockName rot-main rot sy ref pipe)
  (setq blockName (strcat "VPUTKI-" (itoa D) "-T"))
  (setvar "CLAYER" layerName)
  ;; rot-main = paarungon suunta = (haaran suunta) - 90° (oletus haara +Y)
  (setq rot-main (- (vputki-angle-deg p_t p_branch) 90.0))
  (setq rot (+ rot-main *vputki-rot-offset-t*))
  (setq sy 1)
  (if *vputki-fitting-interactive*
    (progn
      (princ "\nPyorita T-fitting paikoilleen ja paina Enter.")
      (command "_.-INSERT" blockName p_t 1 1 pause))
    (command "_.-INSERT" blockName p_t 1 sy rot))
  (setq ref (entlast))
  (setq pipe (vputki-cont-insert-straight D layerName p_t p_branch))
  (list ref pipe))

;; ----- Undo-helpper -------------------------------------------------

(defun vputki-pop-entities (ent-list / e)
  (foreach e ent-list
    (if (and e (entget e)) (entdel e))))


;; ----- Cardinal direction shortcut (V/O/Y/A) ------------------------
;;
;; V=Vasen=-X=180°, O=Oikea=+X=0°, Y=Ylos=+Y=90°, A=Alas=-Y=270°.
;; Kayttaja painaa kirjainta, antaa pituuden, ja tyokalu paattelee
;; tarvitseeko kayntoa fittingia ja luo suoran sinne suuntaan.

(defun vputki-cont-cardinal-dir (key)
  (cond ((= key "V") 180.0)
        ((= key "O")   0.0)
        ((= key "Y")  90.0)
        ((= key "A") 270.0)
        (T nil)))

(defun vputki-cont-do-cardinal ( D layerName p_prev p_prev_dir target_dir length /
                                  frame-ents turn cls sign end_pt result rad )
  (setq frame-ents '())
  (if p_prev_dir
    (progn
      (setq turn (vputki-turn-deg p_prev_dir target_dir))
      (setq cls (vputki-classify-turn turn))
      (setq sign (if (< turn 0) -1 1))
      (cond
        ((eq cls 'straight) nil)
        ((or (eq cls '45) (eq cls '885))
          (setq result (vputki-cont-insert-corner D cls p_prev p_prev_dir sign))
          (if result
            (progn
              (setq frame-ents (cons result frame-ents))
              (if *vputki-last-output-pos*
                (setq p_prev *vputki-last-output-pos*)))))
        ((eq cls 'unknown)
          (princ (strcat "
VAROITUS: " (rtos turn 2 1)
                         " kaannos -- ei vastaavaa fittingia, jatan suoraksi."))))))
  (setq rad (vputki-deg->rad target_dir))
  (setq end_pt
    (list (+ (car p_prev)  (* length (cos rad)))
          (+ (cadr p_prev) (* length (sin rad)))
          (if (caddr p_prev) (caddr p_prev) 0.0)))
  (setq result (vputki-cont-insert-straight D layerName p_prev end_pt))
  (if result (setq frame-ents (cons result frame-ents)))
  (list end_pt target_dir frame-ents))

;; ----- Pystyputki Z-suuntaan -----------------------------------------
;;
;; UCS-rotaatio +/-Y-akselin ympari muuttaa local +X = world +/-Z.
;; Inserttoi sitten suora-block standalone-tilassa ja palauttaa UCS:n.

(defun vputki-cont-insert-vertical ( D layerName p_prev dz /
                                       blockName p_local ucs-angle ref )
  ;; Yksinkertainen pystyputki ilman elbowta (kaytetaan jos p_prev_dir = nil).
  (if (or (null dz) (< (abs dz) 1.0))
    (progn (princ "\nVAROITUS: Z-muutos liian pieni.") nil)
    (progn
      (setq blockName (strcat "VPUTKI-" (itoa D)))
      (setvar "CLAYER" layerName)
      (setq ucs-angle (if (> dz 0) -90.0 90.0))
      (command "_.UCS" "_W")
      (command "_.UCS" "_Y" ucs-angle)
      (setq p_local (trans p_prev 0 1))
      (command "_.-INSERT" blockName p_local 1 1 0)
      (setq ref (entlast))
      (vputki-set-dyn-prop ref "Pituus" (abs dz))
      (command "_.UCS" "_W")
      ref)))

;; ----- Drop-pattern: top-elbow + pystyputki + bottom-elbow ---------
;;
;; Insertoi:
;;   1. Top elbow (horisontaali -> vertikaali)
;;   2. Pystyputki
;;   3. Bottom elbow (vertikaali -> seuraava horisontaali next-dir)
;;
;; Palauttaa (refs-list new-p_prev new-p_prev_dir).
;; kind = '885 (90 mutka) tai '45 (45 mutka). Toistaiseksi vain 885.

(defun vputki-cont-do-drop ( D layerName p_prev p_prev_dir dz next-dir kind /
                              refs p_local top-elbow top-output-ucs
                              top-output-world bottom-input-world
                              pipe-len pipe-bottom-ucs pipe-bottom-world
                              pipe-bottom-ucs2 bottom-elbow bottom-output-ucs
                              bottom-output-world top-pipe-start-ucs
                              blockName trim-len
                              out-axis-default out-axis-ucs-deg out-axis-ucs-rad
                              out-axis-sin out-axis-cos diag-L x-shift
                              bottom-rot-base )
  (setvar "CLAYER" layerName)
  (setq blockName (strcat "VPUTKI-" (itoa D)))
  (setq refs '())
  ;; --- TOP elbow (port-aware: pipe lahtee output-portista) ---
  (command "_.UCS" "_W")
  (command "_.UCS" "_Z" p_prev_dir)
  (command "_.UCS" "_X" (if (> dz 0) -90.0 90.0))
  (setq p_local (trans p_prev 0 1))
  (setq top-elbow (vputki-cont-insert-corner D kind p_local 0.0 -1))
  (if top-elbow
    (progn
      (setq refs (cons top-elbow refs))
      ;; TRIM aiempi pipe niin etta paatyy top-elbown input-porttiin
      (if (and *vputki-last-pipe-ref* *vputki-last-pipe-start*
               *vputki-last-input-port*)
        (progn
          (setq trim-len
            (vputki-dist-2d *vputki-last-pipe-start* *vputki-last-input-port*))
          (if (> trim-len 1.0)
            (vputki-set-dyn-prop *vputki-last-pipe-ref* "Pituus" trim-len))))))
  ;; Talleta top elbown output-portti WORLD-koordinaateissa (UCS voi muuttua myohemmin)
  (setq top-output-ucs *vputki-last-output-pos*)
  (setq top-output-world (trans top-output-ucs 1 0))
  (princ (strcat "\n[DBG] p_prev WORLD = "
                 (rtos (car p_prev) 2 2) ", "
                 (rtos (cadr p_prev) 2 2) ", "
                 (rtos (if (caddr p_prev) (caddr p_prev) 0.0) 2 2)))
  (princ (strcat "\n[DBG] top input WORLD = "
                 (rtos (car *vputki-last-input-port*) 2 2) ", "
                 (rtos (cadr *vputki-last-input-port*) 2 2) ", "
                 (rtos (if (caddr *vputki-last-input-port*)
                         (caddr *vputki-last-input-port*) 0.0) 2 2)))
  (princ (strcat "\n[DBG] top output WORLD = "
                 (rtos (car top-output-world) 2 2) ", "
                 (rtos (cadr top-output-world) 2 2) ", "
                 (rtos (if (caddr top-output-world) (caddr top-output-world) 0.0) 2 2)))
  ;; --- Lasketaan diagonaalisen pipe-suunnan parametrit (45° = viistossa, 88.5° = pystyssä) ---
  ;; out-axis-default on output-pipe-keskilinjan kulma blockin XY-tasossa.
  ;; UCS-tasossa (rot-base=-90 + offset=-90 + sy=1 + out-axis-default) = -90 + out-axis-default.
  (setq out-axis-default
    (cond ((eq kind '45)  *vputki-output-axis-45*)
          ((eq kind '885) *vputki-output-axis-885*)
          (T 0.0)))
  (setq out-axis-ucs-deg (- out-axis-default 90.0))
  (setq out-axis-ucs-rad (vputki-deg->rad out-axis-ucs-deg))
  (setq out-axis-sin (sin out-axis-ucs-rad))
  (setq out-axis-cos (cos out-axis-ucs-rad))
  ;; Diagonal pipe pituus ja x-siirto: L = -abs(dz) / sin(angle), x-shift = L * cos(angle).
  ;; 88.5°: sin=-1, L = abs(dz), x-shift=0 (pysty). 45°: sin=-0.7336, L=abs(dz)*1.363, x-shift = L*0.6794.
  (if (< (abs out-axis-sin) 0.01)
    (progn (setq diag-L (abs dz)) (setq x-shift 0.0))
    (progn
      (setq diag-L (/ (- 0.0 (abs dz)) out-axis-sin))
      (setq x-shift (* diag-L out-axis-cos))))
  ;; Bottom corner target UCS: top_corner + (x-shift, -abs(dz), 0)
  (setq pipe-bottom-ucs
    (list (+ (car p_local) x-shift)
          (- (cadr p_local) (abs dz))
          (if (caddr p_local) (caddr p_local) 0.0)))
  (setq pipe-bottom-world (trans pipe-bottom-ucs 1 0))
  ;; --- BOTTOM elbow (port-aware) ---
  ;; Bottom rot-base: -90 + out-axis-default (jotta input-axis suuntautuu diagonaalin tuloa kohti).
  ;; 88.5°: -90 + 0 = -90. 45°: -90 + 42.8 = -47.2.
  (setq bottom-rot-base (+ -90.0 out-axis-default))
  (command "_.UCS" "_W")
  (command "_.UCS" "_Z" next-dir)
  (command "_.UCS" "_X" (if (> dz 0) -90.0 90.0))
  (setq pipe-bottom-ucs2 (trans pipe-bottom-world 0 1))
  (setq bottom-elbow (vputki-cont-insert-corner D kind pipe-bottom-ucs2 bottom-rot-base 1))
  (if bottom-elbow (setq refs (cons bottom-elbow refs)))
  ;; bottom elbown input-portti on jo WORLD-koordinaateissa (insert-corner tallettaa sen)
  (setq bottom-input-world *vputki-last-input-port*)
  (setq bottom-output-ucs *vputki-last-output-pos*)
  (setq bottom-output-world (trans bottom-output-ucs 1 0))
  (princ (strcat "\n[DBG] pipe-bottom-target WORLD = "
                 (rtos (car pipe-bottom-world) 2 2) ", "
                 (rtos (cadr pipe-bottom-world) 2 2) ", "
                 (rtos (if (caddr pipe-bottom-world) (caddr pipe-bottom-world) 0.0) 2 2)))
  (princ (strcat "\n[DBG] bottom input WORLD = "
                 (rtos (car bottom-input-world) 2 2) ", "
                 (rtos (cadr bottom-input-world) 2 2) ", "
                 (rtos (if (caddr bottom-input-world) (caddr bottom-input-world) 0.0) 2 2)))
  (princ (strcat "\n[DBG] bottom output WORLD = "
                 (rtos (car bottom-output-world) 2 2) ", "
                 (rtos (cadr bottom-output-world) 2 2) ", "
                 (rtos (if (caddr bottom-output-world) (caddr bottom-output-world) 0.0) 2 2)))
  ;; --- PYSTYPUTKI: laske pituus todellisesta WORLD-etaisyydesta -------
  ;; (ei analyyttisesta top-drop/bottom-drop -laskennasta, jotta visuaalisesti
  ;;  istuu kohillee riippumatta blockin basepoint-erikoisuuksista)
  (setq pipe-len (distance top-output-world bottom-input-world))
  (princ (strcat "\n[DBG] computed pipe-len = " (rtos pipe-len 2 3)))
  (if (< pipe-len 1.0) (setq pipe-len 1.0))
  ;; Sijoita pystyputki samaan UCS-framen kuin top elbow oli (jotta rot=-90 osoittaa alas)
  (command "_.UCS" "_W")
  (command "_.UCS" "_Z" p_prev_dir)
  (command "_.UCS" "_X" (if (> dz 0) -90.0 90.0))
  (setq top-pipe-start-ucs (trans top-output-world 0 1))
  ;; Putken rotation = out-axis-ucs-deg. Pysty (88.5°) = -90. Viistossa (45°) = -47.2.
  (vputki-make-insert blockName layerName top-pipe-start-ucs 1 out-axis-ucs-deg)
  (vputki-set-dyn-prop (entlast) "Pituus" pipe-len)
  (setq refs (cons (entlast) refs))
  (command "_.UCS" "_W")
  (list (reverse refs) bottom-output-world next-dir))

;; ----- Paakomento c:VP ----------------------------------------------

(defun c:VP ( / *error* oldClayer oldCmdecho oldOsmode
                D sizeStr layerName aci
                undo-stack done p_prev p_prev_dir p_cur new-dir
                turn cls sign frame-ents
                tp tb result
                target-dir len-default len-input
                forced-fitting dz-default dz-input
                z-next-str z-next-dir z-kind-str z-kind-sym
                corner-pt forced-len forced-rad trim-len
                start-kind-str start-kind-sym start-next-str start-next-dir
                start-p-local start-elbow
                saved-pos-off-45 saved-pos-off-885 )

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

  ;; Halkaisija
  (initget "32 50 75")
  (setq sizeStr (getkword "\nViemariputken koko [32/50/75] <50>: "))
  (if (null sizeStr) (setq sizeStr "50"))
  (setq D (atoi sizeStr))

  ;; Layer + pre-load blokit
  (setq layerName (strcat "KYL-VIEMARI-" (itoa D)))
  (setq aci (vputki-aci-for-size D))
  (vputki-ensure-layer layerName aci)
  (if (not (vputki-preload-set D))
    (progn
      (princ "\nVIRHE: kaikkia vputki-blokkeja ei loytynyt.")
      (princ "\nTarkista etta vputki-<koko>-{45,885,t}.dwg ovat samassa")
      (princ "\nkansiossa kuin vputki.lsp.")
      (exit)))

  (setvar "CMDECHO" 0)

  ;; Aloituspiste
  (setq p_prev (getpoint "\nAloituspiste: "))
  (if (null p_prev) (exit))
  (setq p_prev_dir nil)
  (setq undo-stack '())
  (setq forced-fitting nil)
  (setq done nil)
  ;; --- Aloita fittingilla? (esim. hoyrystimelta 90-elbow) ---
  (initget "9 4 E")
  (setq start-kind-str
    (getkword "\nAloita fittingilla [9/4/E] <E>: "))
  (if (null start-kind-str) (setq start-kind-str "E"))
  (if (or (= start-kind-str "9") (= start-kind-str "4"))
    (progn
      (setq start-kind-sym (if (= start-kind-str "4") '45 '885))
      (initget "V O Y A")
      (setq start-next-str
        (getkword "\nMihin suuntaan jatkuu [V/O/Y/A] <O>: "))
      (if (null start-next-str) (setq start-next-str "O"))
      (setq start-next-dir (vputki-cont-cardinal-dir start-next-str))
      ;; Insert elbow at p_prev with input UP (+Z), output next-dir
      (setvar "CLAYER" layerName)  ;; varmista oikea layer
      ;; Tilapaisesti pos_offset = (0,0) jotta input-portti landaa start-pisteessa
      (setq saved-pos-off-45  *vputki-pos-offset-45*)
      (setq saved-pos-off-885 *vputki-pos-offset-885*)
      (setq *vputki-pos-offset-45*  '(0.0 0.0))
      (setq *vputki-pos-offset-885* '(0.0 0.0))
      (command "_.UCS" "_W")
      (command "_.UCS" "_Z" start-next-dir)
      (command "_.UCS" "_X" 90.0)
      (setq start-p-local (trans p_prev 0 1))
      (setq start-elbow
        (vputki-cont-insert-corner D start-kind-sym start-p-local -90.0 1))
      (command "_.UCS" "_W")
      ;; Palauta pos_offset
      (setq *vputki-pos-offset-45*  saved-pos-off-45)
      (setq *vputki-pos-offset-885* saved-pos-off-885)
      (if start-elbow
        (progn
          (setq undo-stack
            (cons (list 'STARTELBOW (list start-elbow) p_prev nil) undo-stack))
          (if *vputki-last-output-pos*
            (setq p_prev (trans *vputki-last-output-pos* 1 0)))
          (setq p_prev_dir start-next-dir)))))

  ;; Continuous-loop
  (while (not done)
    (initget "T U V O Y A Z S 4 9")
    (setq p_cur (getpoint p_prev
                  "\nSeuraava piste tai [4/9/T/S/V/O/Y/A/Z/U] <Enter>: "))
    (cond
      ;; --- Enter -> lopeta ---
      ((null p_cur) (setq done T))

      ;; --- Keyword "U" -> undo ---
      ((and (= (type p_cur) 'STR) (= p_cur "U"))
        (if undo-stack
          (progn
            (vputki-pop-entities (cadr (car undo-stack)))
            (setq p_prev     (nth 2 (car undo-stack)))
            (setq p_prev_dir (nth 3 (car undo-stack)))
            (setq undo-stack (cdr undo-stack))
            (princ "\nUndo: viimeinen lisays peruttu."))
          (princ "\nEi mitaan peruutettavaa.")))

      ;; --- Keyword "T" -> T-haara ---
      ((and (= (type p_cur) 'STR) (= p_cur "T"))
        (setq tp (getpoint "\nT-haaran liitospiste olemassaolevaan: "))
        (if tp
          (progn
            (setq tb (getpoint tp "\nT-haaran loppupiste: "))
            (if tb
              (progn
                (setq result (vputki-cont-insert-t D layerName tp tb))
                (setq undo-stack
                  (cons (list 'T result p_prev p_prev_dir) undo-stack))
                ;; Paaputki jatkuu p_prev:sta -- T-haara on stub
                (princ "\nT-haara lisatty. Paaputki jatkuu edellisesta pisteesta."))))))

      ;; --- Keyword 4 -> lukitse 45-fitting seuraavalle insertille ---
      ((and (= (type p_cur) 'STR) (= p_cur "4"))
        (setq forced-fitting '45)
        (princ "\n>> Seuraava insert lukittu 45-fittingiin."))

      ;; --- Keyword 9 -> lukitse 88.5-fitting seuraavalle insertille ---
      ((and (= (type p_cur) 'STR) (= p_cur "9"))
        (setq forced-fitting '885)
        (princ "\n>> Seuraava insert lukittu 88.5-fittingiin."))

      ;; --- Keyword S -> lukitse suora (ei fittingia) ---
      ((and (= (type p_cur) 'STR) (= p_cur "S"))
        (setq forced-fitting 'straight)
        (princ "\n>> Seuraava insert ilman fittingia."))

      ;; --- Keyword Z -> drop-pattern: top-elbow + pystyputki + bottom-elbow ---
      ((and (= (type p_cur) 'STR) (= p_cur "Z"))
        (setq dz-default
          (if (boundp '*vputki-last-dz*) *vputki-last-dz* -500.0))
        (setq dz-input
          (getreal (strcat "\nZ-muutos (+ylos / -alas) <"
                            (rtos dz-default 2 0) ">: ")))
        (if (null dz-input) (setq dz-input dz-default))
        (setq *vputki-last-dz* dz-input)
        (cond
          ((null p_prev_dir)
            (setq result (vputki-cont-insert-vertical D layerName p_prev dz-input))
            (if result
              (progn
                (setq undo-stack
                  (cons (list 'VERT (list result) p_prev p_prev_dir) undo-stack))
                (setq p_prev
                  (list (car p_prev) (cadr p_prev)
                        (+ (if (caddr p_prev) (caddr p_prev) 0.0) dz-input))))))
          (T
            (initget "9 4")
            (setq z-kind-str
              (getkword "\nMutkatyyppi 88.5 vai 45 [9/4] <9>: "))
            (if (null z-kind-str) (setq z-kind-str "9"))
            (setq z-kind-sym
              (if (= z-kind-str "4") '45 '885))
            ;; 45-fitting on tasossaan: jatkaa AINA p_prev_dir-suuntaan.
            ;; (Käännös tehdään erikseen V/O/Y/A-komennolla 45-pudotuksen jälkeen.)
            ;; 88.5-fitting voi kääntyä mihin tahansa horisontaaliseen suuntaan.
            (cond
              ((eq z-kind-sym '45)
                (setq z-next-dir p_prev_dir)
                (princ "\n>> 45-Z-pudotus jatkaa diagonaalisesti samaan suuntaan."))
              (T
                (initget "V O Y A")
                (setq z-next-str
                  (getkword "\nSeuraava horiz suunta [V/O/Y/A] <O>: "))
                (if (null z-next-str) (setq z-next-str "O"))
                (setq z-next-dir (vputki-cont-cardinal-dir z-next-str))))
            (setq result
              (vputki-cont-do-drop D layerName p_prev p_prev_dir
                                    dz-input z-next-dir z-kind-sym))
            (if result
              (progn
                (setq undo-stack
                  (cons (list 'DROP (car result) p_prev p_prev_dir) undo-stack))
                (setq p_prev (nth 1 result))
                (setq p_prev_dir (nth 2 result)))))))

      ;; --- Keywords V/O/Y/A -> cardinal direction + pituus ---
      ((and (= (type p_cur) 'STR)
            (or (= p_cur "V") (= p_cur "O") (= p_cur "Y") (= p_cur "A")))
        (setq target-dir (vputki-cont-cardinal-dir p_cur))
        (setq len-default
          (if (boundp '*vputki-last-length*) *vputki-last-length* 500.0))
        (initget 6)
        (setq len-input
          (getreal (strcat "
Pituus <" (rtos len-default 2 0) ">: ")))
        (if (null len-input) (setq len-input len-default))
        (setq *vputki-last-length* len-input)
        (setq result (vputki-cont-do-cardinal
                       D layerName p_prev p_prev_dir target-dir len-input))
        (if (caddr result)
          (setq undo-stack
            (cons (list 'CARD (caddr result) p_prev p_prev_dir) undo-stack)))
        (setq p_prev     (car  result))
        (setq p_prev_dir (cadr result)))

      ;; --- Piste -> suora + ehka fitting ---
      ((= (type p_cur) 'LIST)
        (setq new-dir (vputki-angle-deg p_prev p_cur))
        (setq frame-ents '())
        (if p_prev_dir
          (progn
            (setq turn (vputki-turn-deg p_prev_dir new-dir))
            (setq sign (if (< turn 0) -1 1))
            (setq cls (if forced-fitting forced-fitting (vputki-classify-turn turn)))
            (cond
              ((eq cls 'straight) nil)
              ((or (eq cls '45) (eq cls '885))
                ;; Port-aware: pipe lahtee fittingin output-portista,
                ;; suunta lukitaan output-axis:iin.
                (setq corner-pt p_prev)
                (setq result (vputki-cont-insert-corner
                               D cls p_prev p_prev_dir sign))
                (if result
                  (progn
                    (setq frame-ents (cons result frame-ents))
                    ;; TRIM edellinen pipe: pipen loppupiste = fittingin input-portti
                    (if (and *vputki-last-pipe-ref* *vputki-last-pipe-start*
                             *vputki-last-input-port*)
                      (progn
                        (setq trim-len
                          (vputki-dist-2d *vputki-last-pipe-start*
                                          *vputki-last-input-port*))
                        (if (> trim-len 1.0)
                          (vputki-set-dyn-prop *vputki-last-pipe-ref* "Pituus" trim-len))))
                    (if *vputki-last-output-pos*
                      (setq p_prev *vputki-last-output-pos*))
                    (if *vputki-last-output-axis*
                      (progn
                        (setq forced-len (vputki-dist-2d corner-pt p_cur))
                        (setq forced-rad
                          (vputki-deg->rad *vputki-last-output-axis*))
                        (setq p_cur
                          (list (+ (car p_prev) (* forced-len (cos forced-rad)))
                                (+ (cadr p_prev) (* forced-len (sin forced-rad)))
                                (if (caddr p_prev) (caddr p_prev) 0.0)))
                        (setq new-dir *vputki-last-output-axis*))))))
              ((eq cls 'unknown)
                (princ (strcat "\nVAROITUS: " (rtos turn 2 1)
                               " kaannos -- ei vastaavaa fittingia, "
                               "jatan suoraksi."))))))
        (setq result (vputki-cont-insert-straight D layerName p_prev p_cur))
        (if result (setq frame-ents (cons result frame-ents)))
        (if frame-ents
          (setq undo-stack
            (cons (list 'SEG frame-ents p_prev p_prev_dir) undo-stack)))
        (setq p_prev p_cur)
        (setq p_prev_dir new-dir)
        (setq forced-fitting nil))

      (T (princ "\n? Tuntematon syote."))))

  (setvar "OSMODE"  oldOsmode)
  (setvar "CMDECHO" oldCmdecho)
  (setvar "CLAYER"  oldClayer)
  (princ (strcat "\nVP valmis: " (itoa (length undo-stack)) " lisaysta."))
  (princ))

;; ============================================================
;; VP-MEASURE-FITTING : kalibroi fitting basepointin/orientaation
;; ============================================================
;;
;; Insertoi fittingin (0,0,0) rotaatiolla 0, kysyy mihin klikkaat
;; INPUT/OUTPUT-portit, ja kertoo mitä setq-arvoja vputki.lsp:n
;; "Saadettavat asetukset" -lohkoon pitää lisätä.

(defun c:VP-MEASURE-FITTING ( / kind-str size-str sfx sfx2 blockname dwgname
                              ip ip2 op op2 ix iy ox oy
                              input-axis output-axis rot-offset
                              native-turn native-sign kind-sym )
  (initget "45 885")
  (setq kind-str (getkword "\nKalibroitava [45/885] <885>: "))
  (if (null kind-str) (setq kind-str "885"))
  (initget "32 50 75")
  (setq size-str (getkword "\nKoko [32/50/75] <50>: "))
  (if (null size-str) (setq size-str "50"))
  (setq sfx  (if (= kind-str "45") "-45" "-885"))
  (setq sfx2 sfx)
  (setq blockname (strcat "VPUTKI-" size-str sfx))
  (setq dwgname   (strcat "vputki-" size-str sfx2 ".dwg"))
  (if (not (vputki-ensure-block blockname dwgname))
    (progn (princ "\nVIRHE: blokin lataus epaonnistui.") (exit)))
  (setvar "CMDECHO" 0)
  (princ (strcat "\nInsertoidaan " blockname " (0,0,0) rotaatiolla 0..."))
  (command "_.-INSERT" blockname '(0 0 0) 1 1 0)
  (princ "\nKlikkaa INPUT-portin KESKIPISTE (CENTER-snap cap-renkaalle):")
  (setq ip (getpoint))
  (if (null ip) (progn (princ "\nKeskeytetty.") (exit)))
  (princ "\nKlikkaa INPUT-pipe-stubin ULKOPAA (= mihin suuntaan portti osoittaa):")
  (setq ip2 (getpoint ip))
  (if (null ip2) (progn (princ "\nKeskeytetty.") (exit)))
  (princ "\nKlikkaa OUTPUT-portin KESKIPISTE:")
  (setq op (getpoint))
  (if (null op) (progn (princ "\nKeskeytetty.") (exit)))
  (princ "\nKlikkaa OUTPUT-pipe-stubin ULKOPAA:")
  (setq op2 (getpoint op))
  (if (null op2) (progn (princ "\nKeskeytetty.") (exit)))
  (setq ix (car ip)) (setq iy (cadr ip))
  (setq ox (car op)) (setq oy (cadr op))
  ;; Axis suunnat lasketaan portti -> ulkopaa-vektorista
  (setq input-axis  (vputki-angle-deg ip ip2))
  (setq output-axis (vputki-angle-deg op op2))
  ;; rot-offset: lisataan rot:iin jotta input-portti osoittaa 180 (west) kun rot=0
  (setq rot-offset (vputki-norm-deg (- 180.0 input-axis)))
  ;; native-turn = output-axis - input-axis - 180  (normalisoitu)
  (setq native-turn (vputki-norm-deg (- output-axis input-axis 180.0)))
  (setq native-sign (if (< native-turn 0) -1 1))
  (setq kind-sym (if (= kind-str "45") "45" "885"))
  (princ "\n\n=== MITTAUSTULOKSET ===")
  (princ (strcat "\nBlock: " blockname))
  (princ (strcat "\nInput  port: (" (rtos ix 2 2) " " (rtos iy 2 2) ") -> axis " (rtos input-axis 2 1) "°"))
  (princ (strcat "\nOutput port: (" (rtos ox 2 2) " " (rtos oy 2 2) ") -> axis " (rtos output-axis 2 1) "°"))
  (princ (strcat "\nNative turn: " (rtos native-turn 2 1) "° (" (if (< native-turn 0) "CW" "CCW") ")"))
  (princ "\n\n=== Kopioi nama vputki.lsp:n alkuun (saadettavat asetukset) ===")
  (princ (strcat "\n(setq *vputki-rot-offset-" kind-sym "*  " (rtos rot-offset 2 2) ")"))
  (princ (strcat "\n(setq *vputki-pos-offset-" kind-sym "* '(" (rtos ix 2 2) " " (rtos iy 2 2) "))"))
  (princ (strcat "\n(setq *vputki-output-pos-" kind-sym "* '(" (rtos ox 2 2) " " (rtos oy 2 2) "))"))
  (princ (strcat "\n(setq *vputki-native-turn-" kind-sym "* " (itoa native-sign) ")"))
  (princ "\n\nVoit ERASE:lla poistaa testifittingin ja kytkea auto-tilan:")
  (princ "\n  (setq *vputki-fitting-interactive* nil)")
  (princ))

(princ "\nVPUTKI ladattu. Komennot: VP, VP32/50/75, VPUTKI, VP-MEASURE-FITTING.")
(princ)
