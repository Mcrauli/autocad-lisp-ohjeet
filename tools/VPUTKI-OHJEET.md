# VPUTKI: vputki-32/50/75.dwg + 2-grippi venytys

Ohje kolmen drainage-pipe dynamic blockin luontiin **3DFACE-pohjalla**.
Sama entiteetti-tyyppi kuin KLHYLLY-TIKAS:n yläkannet (rail1Top jne.) —
3DFACE:lla on 4 eksplisiittistä vertikkiä, joten dynamic-block-stretch
toimii luotettavasti (kuten TIKAS:n pituuskäännöllä).

**128 × 3DFACE** muodostavat onkaloidun sylinterin 1.8 mm seinämällä:
32 ulkopinta + 32 sisäpinta + 32+32 päätyrengasta (annular wedges).
32 axial divisionia antaa sileän pyöreän visuaalisen pinnan.

> Lue rinnalla `tools/KLHYLLY-MIGRATION-2GRIP-OHJEET.md` jos joku
> perusvaihe ei ole tuttu (Block Authoring Palettes, Linear-parametrien
> lisays, Stretch-actionin syntaksi).

Tee jokainen kolme kokoa erikseen tyhjässä DWG:ssä.

---

## OSA A — VPUTKI-32 (toistetaan 50:lle ja 75:lle)

### A1. Geometrian luonti

1. Avaa **uusi tyhjä DWG** (File → New → acadiso.dwt)
2. `UNITS` → Decimal, Millimeters → OK
3. APPLOAD `tools/build-vputki-blocks.lsp`
4. Komentorivillä: `VPUTKI-BUILD-32` ↵
   - Konsoli: *"VPUTKI-32 block-maaritys luotu (128 x 3DFACE, seinama 1.8 mm)."*
   - *"Koko: OD 32.0 mm, ID 28.4 mm, pituus 1000 mm."*

> **Geometria:** 128 × 3DFACE muodostavat onkaloidun sylinterin:
> - 32 ulkopintaa (R = D/2)
> - 32 sisäpintaa (R = D/2 - 1.8)
> - 32 päätyrengasta X=0:ssa (annular wedge, yhdistää outer→inner)
> - 32 päätyrengasta X=1000:ssa
>
> Stretch-frame catchaa kaikki vertikit X=0 (tai X=1000) -tasolla — sekä
> outer että inner ringivertikit + päätyrengasvertikit liikkuvat yhdessä.
> Pyörättomä silea, 1.8 mm seinämä näkyy päissä ja sectioneissa.

### A2. Parametrin lisäys

1. `BAUTHORPALETTE` ↵ (pidä paletti näkyvissä)
2. `BEDIT` ↵ → `VPUTKI-32` → OK
3. Block Authoring Palettes → Parameters → drag **Linear**
   - *Specify start point of distance:* `0,0,0` ↵
   - *Specify endpoint of distance:* `1000,0,0` ↵
   - *Specify label location:* `500,-30,0` ↵
4. Klikkaa parametria → Properties:
   - **Distance name:** `Pituus`
   - **Distance value:** 1000.0
   - **Value Set:** None
   - **Number of Grips:** **2**

### A3. Stretch-action OIKEA grippi

1. Block Authoring Palettes → Actions → drag **Stretch**
2. *Select parameter:* klikkaa **Pituus**
3. *Specify parameter point:* klikkaa **OIKEAA grippiä** (X=1000-pää)
4. *First corner of stretch frame:* **klikkaa hiirellä** kohdasta joka on
   vähän OIKEALLA gripin ulkopuolella ja sen YLÄPUOLELLA
   - Esim. visuaalisesti: klikkaa pisteessä joka on noin 50 mm putken
     yläreunan yläpuolella ja 100 mm gripin oikealla puolella
5. *Opposite corner:* **klikkaa hiirellä** kohdasta joka on vähän
   VASEMMALLA gripin sisäpuolella ja sen ALAPUOLELLA
   - Esim. klikkaa pisteessä joka on putken alareunan alapuolella ja
     hieman gripin vasemmalla puolella
   - **Frame:n pitää ympäröidä OIKEA grippi** mutta jättää loput putkesta
     framen ulkopuolelle
6. *Select objects:* `_All` ↵ ↵ (valitsee kaikki 128 × 3DFACE)

> **Vihje:** zoomaa BEDIT-ikkunassa lähelle gripin ympärystöä jotta
> voit tarkasti pickata kulmat. Ortho/Snap-tilan voi sammuttaa
> tarkkuuden parantamiseksi.

> **Vaihtoehtoisesti** voit syöttää koordinaatteja näppäimistöltä,
> mutta jos AutoCAD valittaa "invalid 2D point", käytä mouse-pickeja.

### A4. Stretch-action VASEN grippi

1. Block Authoring Palettes → Actions → drag **Stretch**
2. *Select parameter:* klikkaa **Pituus**
3. *Specify parameter point:* klikkaa **VASENTA grippiä** (X=0-pää)
4. *First corner of stretch frame:* **klikkaa hiirellä** kohdasta joka on
   vähän VASEMMALLA gripin ulkopuolella ja sen YLÄPUOLELLA
5. *Opposite corner:* **klikkaa hiirellä** kohdasta joka on vähän
   OIKEALLA gripin sisäpuolella ja sen ALAPUOLELLA
   - **Frame:n pitää ympäröidä VASEN grippi**, ei oikeaa
6. *Select objects:* `_All` ↵ ↵

> **Logiikka:** kun käyttäjä vetää oikeaa grippiä +X-suuntaan,
> stretch-frame catches kaikki vertikit X=1000-tasolla (= 16 × 3DFACE:n
> oikeat vertikit, c2 ja c3) ja siirtää ne mukana. Cylinder pitenee.
> Sama vasemmalla.

### A5. Tallennus WBLOCK:lla (EI SAVEAS!)

**TÄRKEÄÄ:** käytä `WBLOCK Source=Block`-tekniikkaa, EI suoraan
SAVEAS:ia. Syy: SAVEAS säilyttää block-määrityksen sisäisesti,
jolloin `-INSERT VPUTKI-32=path` target-piirustuksessa antaa "Block
VPUTKI-32 references itself" -virheen samannimisen sisäisen block:n
takia. WBLOCK Source=Block kirjoittaa block:n geometrian source
DWG:n modelspaceen suoraan ilman sisäistä block-määritystä → ei
konfliktia. (Sama tekniikka kuin klhylly-tikas.dwg luotiin.)

1. `BSAVE` ↵
2. `BCLOSE` ↵
3. `WBLOCK` ↵ → dialog avautuu:
   - **Source**: valitse "**Block**" radio-button
   - Dropdownista: **VPUTKI-32**
   - **Insert units**: Millimeters
   - **Destination** → File name: `vputki-32` → Path:
     `OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files`
   - **OK** → AutoCAD kirjoittaa `files/vputki-32.dwg`
4. Sulje nykyinen DWG (älä tallenna jos kysytään)
5. **Verifiointi**: avaa juuri kirjoitettu `files/vputki-32.dwg`
   - Pikatesti: `-INSERT VPUTKI-32 0,0,0 1 1 0` → 2 grippiä, vetele
   - Conceptual/Realistic-tilassa näkyy pyöreä sylinteri (32-segmentti)
6. **Jos parametrit/actionit katosivat WBLOCK:ssa** (tunnettu rajoite):
   - `BEDIT` → `VPUTKI-32` → rakenna Linear Pituus + 2 Stretch-actionit
     uudestaan tässä DWG:ssä → `BSAVE` → `BCLOSE`
7. `ERASE ALL` ↵ ↵ → `SAVE` ↵

---

## OSA B — VPUTKI-50

Toista OSA A:n vaiheet, mutta:
- A1 vaihe 4: aja **`VPUTKI-BUILD-50`**
- A2 vaihe 2: `BEDIT` → **`VPUTKI-50`**
- A5 vaihe 3: WBLOCK → Source Block: **`VPUTKI-50`** → File name **`vputki-50`**

DN50: OD = 50 mm, R = 25 mm.

---

## OSA C — VPUTKI-75

Toista OSA A:n vaiheet, mutta:
- A1 vaihe 4: aja **`VPUTKI-BUILD-75`**
- A2 vaihe 2: `BEDIT` → **`VPUTKI-75`**
- A5 vaihe 3: WBLOCK → Source Block: **`VPUTKI-75`** → File name **`vputki-75`**

DN75: OD = 75 mm, R = 37.5 mm. Stretch-frame Y/Z ±50 mm kattaa.

---

## OSA D — Loppuvarmistus

1. **Tarkista files/-kansio:** sisältää nyt
   - `vputki-32.dwg` ✓
   - `vputki-50.dwg` ✓
   - `vputki-75.dwg` ✓
   - `vputki.lsp` ✓
   - Plus aiemmat: klhylly.lsp, klhylly-levy.dwg, klhylly-tikas.dwg,
     positio.lsp, positio.dwg, kaato.lsp, putkityokalu.lsp

2. **Yhteistesti puhtaassa DWG:ssä:**
   - Avaa uusi tyhjä DWG
   - APPLOAD `vputki.lsp` (`files/`-kansiosta)
   - **Pikakomennot per koko:** `VP32` / `VP50` / `VP75`
     - Kysyy mallin: `SUORA` / `45` / `88.5` / `T`
     - SUORA → klikkaa 2 pistettä → dynamic-block-putki venyy gripeillä
     - 45/88.5/T → klikkaa lisäyspiste + rotaatio → fitting paikoillaan
   - Pitkä komento `VPUTKI` kysyy halkaisijan ensin (tai voi käyttää
     pikakomentoa)
   - SUORA-mallin instanssia klikatessa: 2 stretch-grippiä molemmissa
     päissä; vedä grippejä → sylinteri venyy/lyhenee kummasta tahansa
     päästä

   **Käyttämät DWG-tiedostot files/-kansiossa:**
   - `vputki-32.dwg` / `vputki-50.dwg` / `vputki-75.dwg` (suorat)
   - `vputki-32-45.dwg` / `vputki-50-45.dwg` / `vputki-75-45.dwg` (45°)
   - `vputki-32-885.dwg` / `vputki-50-885.dwg` / `vputki-75-885.dwg` (88.5°)
   - `vputki-32-t.dwg` / `vputki-50-t.dwg` / `vputki-75-t.dwg` (T-haarat)

   Fittings-DWG:t kopioitiin `OneDrive\Tiedostot\V-PUTKET`-kansiosta
   ASCII-nimillä (ilman °-merkkiä). Niitä ei tarvitse rakentaa
   manuaalisesti — ne ovat sun valmiit WBLOCKit.

3. **Lisää snap-pisteet fitting-DWG:hin** (kerran per DWG, 9 yhteensä):
   - Avaa `files/vputki-32-45.dwg`
   - Aseta OSNAP → ENDPOINT + CENTER (jotta saa snapattua cap-circle:n
     keskelle)
   - Komentorivillä `POINT` ↵
   - Klikkaa CENTER-snapilla kulman kummankin pään cap-circle:t
     (= liitäntäpisteet joista jatkuu putki)
   - ↵ (lopeta POINT)
   - `SAVE` ↵
   - Sulje
   - Toista samalle 50.dwg / 75.dwg / -45 / -885 / -t -tiedostoille
     (T-haaralle 3 liitäntäpistettä, kulmille 2)

   Käyttöön: aseta OSNAP → **NODE** päälle. Sitten VP32 → 45 → kun
   pyydetään Lisayspistettä, snappaa NODE-snapilla edellisen putken
   loppuun → fitting kohdistuu täydellisesti.

3. **Kerro minulle** kun kaikki toimii → rebuildaan
   `files/suunnittelutyokalut.zip` (`make-bundle.ps1`) ja committoidaan
   + pushataan.

---

## "Block VPUTKI-X references itself" -korjaus

Jos saat tämän virheen kun ajaa `VP32`/`VP50`/`VP75` ja yritetään
ladata `vputki-X.dwg`, syy on: source-DWG:n modelspace sisältää
INSERT-instanssin samannimisestä blockista → circular reference.

Korjaus:
1. Avaa `files/vputki-X.dwg` AutoCAD:issa
2. `ERASE` ↵ → `_All` ↵ → ↵  (poistaa modelspacen sisällön)
3. **ÄLÄ AJA `PURGE`** — se poistaisi block-määrityksen koska sitä ei
   ole insertattu enää mihinkään → DWG jäisi täysin tyhjäksi.
4. `SAVE` ↵ (ylikirjoita)
5. Sulje
6. Kokeile uudestaan target-piirustuksessa

Jos PURGE on jo poistanut block-määrityksen (DWG on tyhjä eikä BEDIT
löydä VPUTKI-X-block:ia), tee koko build-prosessi uudestaan: avaa
uusi tyhjä DWG, APPLOAD `build-vputki-blocks.lsp`, aja VPUTKI-BUILD-X,
BEDIT → parametrit + actionit, ERASE ALL, SAVEAS.

## Tärkeät huomiot

- **Geometria on 128 × 3DFACE, ei 3DSOLID eika MESH.** AutoCAD:n
  dynamic-block-stretch toimii 3DFACE:lla luotettavasti (todistettu
  KLHYLLY-TIKAS:n yläkansiilla). 3DSOLID-stretch jättää solidin
  paikalleen; CONVTOMESH ei aina kelpaa LISP-`command`-rajapinnasta.
  3DFACE on yksinkertainen primitiivi joka aina toimii.

- **INSERT käyttää uniform skalaa (sx=sy=sz=1)** vputki.lsp:ssä.
  Pituus tulee Pituus-parametrista. Tama valttaa non-uniform-INSERT-bug:n.

- **1.8 mm seinämäpaksuus on todellista AutoCAD-geometriaa** —
  outer + inner pinnat + päätyrenkaat. Section-näkymässä ja päissä
  näkyy oikea rengas-poikkileikkaus, kuten oikea muoviputki. Sama
  wall thickness kirjataan myös IFC:n `fi_tekninen.Seinamapaksuus`-
  kenttään (dxf2ifc-profiili).

- **Visuaalinen tarkkuus:** 32 axial divisionia antaa sileän pyöreän
  sylinterin (32-segmenttinen polygon). Conceptual/Realistic visual
  style:lla AutoCAD:n smoothing pyöristää reunat täysin sileäksi.
  Jos haluat enemmän/vähemmän, vaihda `*VPUTKI-NUMSEGS*`
  build-skriptissä (huom: face count = 4 × NUMSEGS).

- **dxf2ifc-yhteensopivuus:** 3DFACE-sylinteri rajähtää INSERT-explode-
  vaiheessa, ezdxf lukee 3DFACE:t ja preprocessing CONVTOSOLID promotoi
  ne 3DSOLID:ksi → STLOUT tessellöi → IfcPipeSegment KYL-VIEMARI-<size>-
  rule:lla. Sama flow kuin KLHYLLY-LEVY:lla (jossa LWPOLYLINE+thickness
  kanssa CONVTOSOLID promotoi).
