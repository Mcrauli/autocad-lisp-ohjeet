# KLHYLLY-BEDIT-OHJEET

Step-by-step ohjeet `files/klhylly-levy.dwg` ja `files/klhylly-tikas.dwg`
-block-kirjastojen rakentamiseen. Tehdään **kerran**, kun block-määrityksiä
luodaan tai mitoituksia muutetaan.

> **Versio v3 — 5.5.2026:** kaksi erillistä DWG-tiedostoa, yksi blockia
> kohden, jotta vältetään AutoCAD:n "Block X references itself" -virheet.
>
> Geometria on **2D-LWPOLYLINEja joilla thickness** (vertikaalinen
> extrudointi Z-suuntaan) + **3DFACEt ylakansiksi** Realistic-tilaa varten.
> Stretch-action toimii LWPOLYLINEille mutta ei 3D-soliditeeteille.

---

## Vaihe 0 — Valmistelut

1. Avaa AutoCAD, **tyhjä DWG** (esim. File → New → acadiso.dwt-pohja).
2. Varmista yksiköt: komentorivillä `UNITS` → Length: Decimal, Insertion units: Millimeters → OK.
3. APPLOAD → valitse `tools/build-klhylly-blocks.lsp` repon polusta.
4. Komentorivillä: `KLHYLLY-BUILD-LEVY` ↵
   - Konsoliin: *"KLHYLLY-LEVY block-maaritys luotu (8 entiteettia)."*
   - Modelspace pysyy tyhjänä (block-määritys on block-tablessa).

---

## Vaihe 1 — Block Authoring Palettes käyttöön

Kirjoita komentoriville: `BAUTHORPALETTE` ↵.
Oikealle reunalle ilmestyy paletti, jossa on välilehdet **Parameters**,
**Actions**, **Parameter Sets**. Pidä se näkyvissä koko BEDIT-vaiheen ajan.

---

## Vaihe 2 — KLHYLLY-LEVY: parametrit

1. Komentorivillä: `BEDIT` ↵ → valitse listalta `KLHYLLY-LEVY` → OK.
   Block Editor avautuu, näet **5 LWPOLYLINEa** (joilla thickness Z-suunnassa) + **1 3DFACE** (pohjan yläkansi z=1.25) + outline-polyline + hatch = **8 entiteettiä yhteensä**.
2. **Lisää Pituus-parametri:**
   - Block Authoring Palettes → Parameters-välilehti → vedä **Linear**
     parametri canvasille
   - Specify start point: kirjoita `0,0,0` ↵
   - Specify endpoint: kirjoita `1000,0,0` ↵
   - Specify label location: kirjoita `500,-50,0` ↵ (sijoittuu alle, ei haittaa)
   - **Klikkaa Linear-parametriä** valituksi. Avaa Properties-paletti
     (Ctrl+1) → muokkaa Value Set / Property Labels -osion alta:
     - **Distance name:** `Pituus`
     - **Default Distance:** `1000`
     - **Value Set** *(tai "Dist value set")* **= `None`** (continuous,
       mikä tahansa arvo sallittu)
     - **Number of Grips:** `1`
3. **Lisää Leveys-parametri:**
   - Vedä toinen **Linear** Parameters-paletista canvasille
   - Specify start point: `0,0,0` ↵
   - Specify endpoint: `0,500,0` ↵
   - Specify label location: `-50,250,0` ↵
   - Klikkaa parametriä → Properties-paletissa:
     - **Distance name:** `Leveys`
     - **Value Set** *(tai "Dist value set")* **= `List`** (pakottaa
       arvon tiettyihin vaihtoehtoihin — vaihda dropdownista; vaihtoehdot
       ovat None / Increment / List)
     - **Dist value list:** klikkaa kohtaa → "..." nappi → ikkunaan kirjoita
       `300`, `400`, `500` (yksi per rivi) → OK
     - **Default Distance:** `500`
     - **Number of Grips:** `1`

> Kummassakin parametrissä pitäisi nyt näkyä keltainen **!** (huutomerkki)
> = "parametriin ei vielä liitetty actionia". Korjautuu seuraavissa vaiheissa.

---

## Vaihe 3 — KLHYLLY-LEVY: Pituus-Stretch

1. Block Authoring Palettes → **Actions**-välilehti → vedä **Stretch**
   canvasille.
2. *"Select parameter:"* — klikkaa **Pituus**-parametriä
3. *"Specify parameter point to associate with action:"* — klikkaa
   **Pituus-parametrin oikeaa päätygrippiä** (X=1000-pää, neliö-kahva)
4. *"Specify first corner of stretch frame:"* — kirjoita `950,-50` ↵
5. *"Specify opposite corner of stretch frame:"* — kirjoita `1100,600` ↵
6. *"Select objects:"* — vedä **valintaikkuna** (window, ei crossing)
   tai klikkaa yksitellen kaikki **8 entiteettiä**:
   - 5 LWPOLYLINEia (pohja, vasen seinä, oikea seinä, vasen lippa, oikea lippa)
   - **3DFACE** (pohjan yläkansi z=1.25:llä)
   - LWPOLYLINE-outline
   - DASH-hatch
   - ↵ kun kaikki valittu

> Tämä action venyttää X-suunnassa kaikki entiteetit joiden **oikea pää**
> on stretch frame:n sisällä. Kun käyttäjä myöhemmin vetää Pituus-grippiä,
> vain oikeat reunat siirtyvät — vasemmat pysyvät.

---

## Vaihe 4 — KLHYLLY-LEVY: Leveys-Stretch

1. Vedä toinen **Stretch** Actions-paletista canvasille.
2. *"Select parameter:"* — klikkaa **Leveys**-parametriä
3. *"Specify parameter point:"* — klikkaa **Leveys-parametrin yläpäätygrippiä**
   (Y=500-pää)
4. *"Specify first corner:"* — `-50,480` ↵
5. *"Specify opposite corner:"* — `1050,550` ↵
6. *"Select objects:"* — valitse **5 entiteettiä**:
   - oikea seinä LWPOLYLINE (sRWall)
   - oikea lippa LWPOLYLINE (sRLip)
   - **3DFACE** (pohjan yläkansi — sen Y=500-reuna venyy)
   - LWPOLYLINE-outline
   - DASH-hatch
   - ↵

> Leveys-actionin myötä yläreunan elementit liikkuvat Y-suunnassa kun
> dropdown-arvo vaihtuu (300/400/500).

---

## Vaihe 5 — Tallennus + LEVY-DWG:n luonti

1. Komentorivillä: `BSAVE` ↵ — tallentaa block-määrityksen muutokset.
2. Komentorivillä: `BCLOSE` ↵ — poistuu Block Editor:sta.
3. **Pikatesti modelspace:ssa**: `-INSERT KLHYLLY-LEVY` ↵ → `0,0,0` ↵ → `1` ↵ → `1` ↵ → `0` ↵.
   - Klikkaa instanssia → Properties (Ctrl+1) → Custom-otsikon alla pitäisi näkyä **Pituus** ja **Leveys**
   - Vaihda Leveys 500 → 300 → hylly kapenee, hatch venyy
   - Tartu Pituus-grippiin → vedä → hylly venyy
   - Realistic-tilassa (`VSCURRENT R`) pohja näkyy täytenä
4. **Lopputallennus:**
   - `ERASE ALL ↵ ↵` — poista testi-instanssi
   - `SAVEAS` → Files of type **AutoCAD 2018 Drawing** → File name `klhylly-levy` → polku
     `C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files` → Save
5. **Sulje DWG** (älä tallenna muutoksia jos kysytään)

---

## Vaihe 6 — KLHYLLY-TIKAS: omassa tyhjässä DWG:ssä

1. **Avaa toinen tyhjä DWG** (File → New → acadiso.dwt)
2. APPLOAD `tools/build-klhylly-blocks.lsp` (jos ei vielä ladattu)
3. Komentorivillä: `KLHYLLY-BUILD-TIKAS` ↵
   - Konsoliin: *"KLHYLLY-TIKAS block-maaritys luotu (6 entiteettia)."*
4. `BEDIT` ↵ → `KLHYLLY-TIKAS` → OK.
   Näet **2 rail-LWPOLYLINEia** + **1 rung-LWPOLYLINE** (master, X=242.5–257.5)
   + **3 3DFACEa** (rail1-Top z=60, rail2-Top z=60, rung-Top z=25) =
   **6 entiteettiä yhteensä**.
2. **Pituus-parametri** (sama kuin LEVY:ssä):
   - Linear: start `0,0,0` → end `1000,0,0` → label `500,-50,0`
   - Distance name `Pituus`, Default 1000, Value Set = None, Grips 1
3. **Leveys-parametri** (sama kuin LEVY:ssä):
   - Linear: start `0,0,0` → end `0,500,0` → label `-50,250,0`
   - Distance name `Leveys`, Value Set = List `300/400/500`,
     Default 500, Grips 1

---

## Vaihe 7 — KLHYLLY-TIKAS: Pituus-Stretch (kiskot)

1. **Stretch** action canvasille
2. Select parameter: **Pituus**
3. Parameter point: **Pituus oikea päätygrippi** (X=1000)
4. First corner: `950,-50` ↵, Opposite: `1100,550` ↵
5. Select objects: **rail1 + rail2 + rail1-Top 3DFACE + rail2-Top 3DFACE**
   (4 entiteettiä, **EI** rung-masteria eikä rung-Top:ia) → ↵

> Kiskot ja niiden ylakannet pitenevät stretchin myötä; rungin (+ rung-Top:n)
> lisäys/vähennys hoitaa Array. Rail1-Top on z=60:llä, rail2-Top samoin —
> niiden X=1000-reunat venyvät kun frame on `(950,-50)→(1100,550)`.

---

## Vaihe 8 — KLHYLLY-TIKAS: Pituus-Array (rungit)

1. Vedä **Array** action canvasille
2. Select parameter: **Pituus**
3. Select objects: **rung-master LWPOLYLINE + rung-Top 3DFACE** (2 entiteettiä,
   molemmat keskellä X=242.5..257.5) → ↵
4. *"Enter the distance between columns (|||):"* — kirjoita `250` ↵

> Kun käyttäjä venyttää Pituus-grippiä esim. 1000 → 2500, master-rung
> kopioituu 250 mm askeleella → 10 instanssia. Viimeinen instanssi
> näkyy vain jos se mahtuu kokonaan Pituus-välille.

---

## Vaihe 9 — KLHYLLY-TIKAS: Leveys-Stretch

1. **Stretch** action canvasille
2. Select parameter: **Leveys**
3. Parameter point: **Leveys yläpäätygrippi** (Y=500)
4. First corner: `-50,480` ↵, Opposite: `1050,550` ↵
5. Select objects: **rail2 + rung-master + rail2-Top 3DFACE + rung-Top 3DFACE**
   (4 entiteettiä) → ↵
   - rail2 (+ rail2-Top) koko LWPOLYLINE siirtyy +Y
   - rung-master (+ rung-Top) -korkean Y=485-reuna venyy Y-suunnassa,
     Y=15-reuna pysyy paikallaan (frame ei kata)

> HUOMIO: array-kopioidut rungit periytyvät master:lta — kun Leveys-action
> stretchaa master:n, kaikki array-kopiot (sekä LWPOLYLINE että 3DFACE)
> stretchaantuvat samaan tahtiin.

---

## Vaihe 10 — Tallennus + TIKAS-DWG:n luonti

1. `BSAVE` ↵
2. `BCLOSE` ↵
3. **Pikatesti modelspace:ssa**: `-INSERT KLHYLLY-TIKAS` ↵ → `0,0,0` ↵ → `1` `1` `0` ↵.
   - Properties → vaihda Pituus 1000 → 2500 → kiskot pidentyvät, rungit lisääntyvät 250 mm askeleella
   - Vaihda Leveys → kiskot lähentyvät, rungit kapenevat
4. **Lopputallennus:**
   - `ERASE ALL ↵ ↵`
   - `SAVEAS` → File name `klhylly-tikas` → polku `files/`-kansioon → Save
5. Sulje DWG.

## Vaihe 11 — Yhteistesti (klhylly.lsp:n rinnalla)

Avaa **uusi tyhjä DWG**. APPLOAD `klhylly.lsp`. Aja:

1. `KLHYLLY` → LEVY → 500 → klikkaa kaksi pistettä → block-instanssi syntyy
   - Layer = KYL-LEVYHYLLY (color 175)
   - Properties: Pituus, Leveys
2. `KLHYLLY` → TIKAS → 400 → klikkaa kaksi pistettä → block-instanssi
   - Layer = KYL-TIKASHYLLY
3. `KLHYLLYV` → 500 → kolme pistettä → vino tikashylly
4. `HYLLYKORKO` → valitse hyllyt → 2400 → siirtyy oikealle korolle

Jos toimii, block-kirjastot ovat valmiit. Aja repon juuressa
`make-bundle.ps1` PowerShellissä → `files/suunnittelutyokalut.zip`
päivittyy sisältämään sekä `klhylly-levy.dwg` että `klhylly-tikas.dwg`.

---

## Yleisia virheitä

- **"Block already exists"** kun ajat BUILD-komennon toista kertaa
  → avaa tyhjä DWG.
- **"Block X references itself"** kun KLHYLLY yrittää INSERT:ata
  → block-määrityksen sisällä on viittaus itseensä. BEDIT, tarkista
  ettei kanvasilla ole INSERT-tyypin entiteettiä, ERASE jos on,
  BSAVE → BCLOSE → SAVE. Tämä on syy miksi blockit ovat erillisissä
  DWG-tiedostoissa (yhden DWG:n sisällä molemmat aiheuttivat
  vastaavia virheitä).
- **Properties-paletissa ei näy Pituus/Leveys** → block-määritys ei ole
  dynamic (parametria/actionia puuttuu) tai INSERT-instanssi viittaa
  väärään blockiin. Tarkista BEDIT.
- **Stretch venyttää väärää suuntaa** → parameter point liitetty väärään
  grippiin. Korjaa BEDIT:ssä.
- **Array-rungit eivät katoa kun pituus pienenee** → tarkista Array-actionin
  Column distance = 250 ja että parametri on Pituus.
- **Hatch jää paikalleen kun stretchaa** → hatchin pitää olla associative
  (HPASSOC=1 helper-skriptin oletusarvo) ja liittyä outline-polylineen.

---

## Mitoitus (helper-skriptin tuottamat — viite)

| Block | Entiteetti | Min-corner | Max-corner |
|-------|------------|------------|------------|
| LEVY | sFloor (pohja) | (0, 0, 0) | (1000, 500, 1.25) |
| LEVY | sLWall (vas. seinä) | (0, 0, 0) | (1000, 1.25, 60) |
| LEVY | sRWall (oik. seinä) | (0, 498.75, 0) | (1000, 500, 60) |
| LEVY | sLLip (vas. lippa) | (0, 1.25, 58.75) | (1000, 10.25, 60) |
| LEVY | sRLip (oik. lippa) | (0, 489.75, 58.75) | (1000, 498.75, 60) |
| LEVY | LWPOLYLINE outline | (0, 0) → (1000, 0) → (1000, 500) → (0, 500), closed |
| LEVY | DASH-hatch | pattern DASH, scale 40, angle 45, associative outlineen |
| TIKAS | rail1 | (0, 0, 0) | (1000, 15, 60) |
| TIKAS | rail2 | (0, 485, 0) | (1000, 500, 60) |
| TIKAS | rung-master | (242.5, 15, 10) | (257.5, 485, 25) |

Default-pituus 1000 mm, default-leveys 500 mm. Block-instanssit
INSERTataan klhylly.lsp:stä ja parametrit asetetaan käyttäjän valintojen
mukaan.
