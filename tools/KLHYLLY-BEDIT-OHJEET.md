# KLHYLLY-BEDIT-OHJEET

Step-by-step ohjeet `files/klhylly.dwg`-block-kirjaston rakentamiseen.
Tehdään **kerran**, kun block-määrityksiä luodaan tai mitoituksia muutetaan.

---

## Vaihe 0 — Valmistelut

1. Avaa AutoCAD, **tyhjä DWG** (esim. File → New → acadiso.dwt-pohja).
2. Varmista yksiköt: komentorivillä `UNITS` → Length: Decimal, Insertion units: Millimeters → OK.
3. APPLOAD → valitse `tools/build-klhylly-blocks.lsp` repon polusta.
4. Komentorivillä: `KLHYLLY-BUILD-BLOCKS` ↵
   - Konsoliin tulee teksti: *"Lisatty 2 block-maaritysta: KLHYLLY-LEVY, KLHYLLY-TIKAS"*
   - Modelspace pysyy tyhjänä (block-määritykset ovat block-tablessa, eivät näkyvinä).

---

## Vaihe 1 — Block Authoring Palettes käyttöön

Kirjoita komentoriville: `BAUTHORPALETTE` ↵.
Oikealle reunalle ilmestyy paletti, jossa on välilehdet **Parameters**,
**Actions**, **Parameter Sets**. Pidä se näkyvissä koko BEDIT-vaiheen ajan.

---

## Vaihe 2 — KLHYLLY-LEVY: parametrit

1. Komentorivillä: `BEDIT` ↵ → valitse listalta `KLHYLLY-LEVY` → OK.
   Block Editor avautuu, näet 5 BOX-soliditeettia + outline-polyline + hatch.
2. **Lisää Pituus-parametri:**
   - Block Authoring Palettes → Parameters-välilehti → vedä **Linear**
     parametri canvasille
   - Specify start point: kirjoita `0,0,0` ↵
   - Specify endpoint: kirjoita `1000,0,0` ↵
   - Specify label location: kirjoita `500,-50,0` ↵ (sijoittuu alle, ei haittaa)
   - **Klikkaa Linear-parametriä** valituksi. Avaa Properties-paletti
     (Ctrl+1) → muokkaa:
     - **Distance name:** `Pituus`
     - **Default Distance:** `1000`
     - **Distance type:** `Distance` *(Value Set: None — continuous)*
     - **Number of Grips:** `1`
3. **Lisää Leveys-parametri:**
   - Vedä toinen **Linear** Parameters-paletista canvasille
   - Specify start point: `0,0,0` ↵
   - Specify endpoint: `0,500,0` ↵
   - Specify label location: `-50,250,0` ↵
   - Klikkaa parametriä → Properties-paletissa:
     - **Distance name:** `Leveys`
     - **Distance type:** `List` *(EI Distance — vaihda dropdownista)*
     - **Dist value list:** klikkaa kohtaa "..." nappi → ikkunaan kirjoita
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
   tai klikkaa yksitellen kaikki **7 entiteettiä**:
   - 5 BOXia (pohja, vasen seinä, oikea seinä, vasen lippa, oikea lippa)
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
6. *"Select objects:"* — valitse **4 entiteettiä**:
   - oikea seinä BOX (sRWall)
   - oikea lippa BOX (sRLip)
   - LWPOLYLINE-outline
   - DASH-hatch
   - ↵

> Leveys-actionin myötä yläreunan elementit liikkuvat Y-suunnassa kun
> dropdown-arvo vaihtuu (300/400/500).

---

## Vaihe 5 — Tallennus + Block Editor sulku (LEVY)

1. Komentorivillä: `BSAVE` ↵ — tallentaa block-määrityksen muutokset.
2. Komentorivillä: `BCLOSE` ↵ — poistuu Block Editor:sta.

---

## Vaihe 6 — KLHYLLY-TIKAS: parametrit

1. `BEDIT` ↵ → `KLHYLLY-TIKAS` → OK.
   Näet 2 rail-BOXia + 1 rung-BOXin (master, X=242.5–257.5).
2. **Pituus-parametri** (sama kuin LEVY:ssä):
   - Linear: start `0,0,0` → end `1000,0,0` → label `500,-50,0`
   - Distance name `Pituus`, Default 1000, Distance type Distance, Grips 1
3. **Leveys-parametri** (sama kuin LEVY:ssä):
   - Linear: start `0,0,0` → end `0,500,0` → label `-50,250,0`
   - Distance name `Leveys`, Distance type List `300/400/500`,
     Default 500, Grips 1

---

## Vaihe 7 — KLHYLLY-TIKAS: Pituus-Stretch (kiskot)

1. **Stretch** action canvasille
2. Select parameter: **Pituus**
3. Parameter point: **Pituus oikea päätygrippi** (X=1000)
4. First corner: `950,-50` ↵, Opposite: `1100,550` ↵
5. Select objects: **vain rail1 + rail2** (kaksi BOXia, EI rung-master) → ↵

> Kiskot pitenevät stretchin myötä; rungin lisäys/vähennys hoitaa Array.

---

## Vaihe 8 — KLHYLLY-TIKAS: Pituus-Array (rungit)

1. Vedä **Array** action canvasille
2. Select parameter: **Pituus**
3. Select objects: **vain rung-master BOX** (X=242.5–257.5) → ↵
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
5. Select objects: **rail2 + rung-master** → ↵
   - rail2 koko BOX siirtyy +Y (siellä X-suunnassa pitkä)
   - rung-master:n yläpää venyy Y-suunnassa

> HUOMIO: array-kopioidut rungit periytyvät master:lta — kun Leveys-action
> stretchaa master:n, kaikki array-kopiot stretchaantuvat samaan tahtiin.

---

## Vaihe 10 — Tallennus + Block Editor sulku (TIKAS)

1. `BSAVE` ↵
2. `BCLOSE` ↵

---

## Vaihe 11 — Pikatesti BEDIT-vaiheen jälkeen

Modelspace pitäisi olla tyhjä. Testaa molemmat blockit:

**LEVY-testi:**
1. Komentorivillä: `-INSERT` ↵
2. Block name: `KLHYLLY-LEVY` ↵
3. Insertion point: `0,0,0` ↵
4. X scale: `1` ↵, Y scale: `1` ↵, Rotation: `0` ↵
5. Klikkaa instanssia. Ctrl+1 → Properties → otsikon **Custom** alta löytyy:
   - **Pituus** *(numeerinen syöttö)*
   - **Leveys** *(dropdown 300/400/500)*
6. Vaihda Leveys 500 → 300 → hylly kapenee Y-suunnassa.
   - Hatch venyy mukana ja outline-frame seuraa.
7. Tartu Pituus-grippiin (oikea pää) → vedä → hylly venyy X-suunnassa.
   Hatch venyy mukana.

**TIKAS-testi:**
1. `-INSERT` → `KLHYLLY-TIKAS` → `0,500,0` (siirrä toiseen kohtaan ettei
   mene päällekkäin) → 1 1 0 ↵
2. Properties → vaihda Pituus 1000 → 2000 → kiskot pidentyvät, **rungit
   lisääntyvät** automaattisesti 250 mm askeleella.
3. Vaihda Leveys 500 → 300 → kiskot lähentyvät, rungit kapenevat.

**Jos jokin ei toimi:**
- Stretch frame ei kata grippiä → BEDIT, klikkaa actionia, Properties
  paletista *"Stretch frame"* uudestaan
- Selection set väärä → BEDIT, klikkaa actionia, Properties paletista
  *"Selection set"* → "..." → muokkaa
- Array ei toistu → varmista että action on liitetty Pituus-parametriin
  (eikä Leveys), ja että distance = 250
- Jos päädyt umpikujaan → poista ko. action canvasilta ERASE:llä,
  lisää uudestaan.

---

## Vaihe 12 — Lopputallennus klhylly.dwg

1. Poista testi-instanssit modelspaceesta: `ERASE` ↵ → `ALL` ↵ → ↵
2. Komentorivillä: `SAVEAS` ↵
   - Files of type: **AutoCAD 2018 Drawing (\*.dwg)** *(tai uudempi
     2018-formaatti — älä vie aivan uusinta versioon, jotta vanhat
     AutoCAD-versiot löytäisivät)*
   - File name: `klhylly.dwg`
   - Polku: `C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files\klhylly.dwg`
   - Save
3. Sulje DWG.
4. Tarkista kansiossa: `files/klhylly.dwg` on nyt olemassa, ja `files/klhylly.lsp`
   on rinnalla.

---

## Vaihe 13 — Lopullinen yhteistesti (klhylly.lsp:n rinnalla)

Avaa **uusi** tyhjä DWG (ei se jossa rakensit blockit). APPLOAD `klhylly.lsp`.
Aja:

1. `KLHYLLY` → LEVY → 500 → klikkaa kaksi pistettä → block-instanssi syntyy
   - Tarkista Properties: Pituus = etäisyys, Leveys = 500
   - Layer = KYL-LEVYHYLLY
2. `KLHYLLY` → TIKAS → 400 → klikkaa kaksi pistettä → block-instanssi
   - Layer = KYL-TIKASHYLLY
3. `KLHYLLYV` → 500 → kolme pistettä → vino tikashylly
4. `HYLLYKORKO` → valitse hyllyt → 2400 → siirtyy oikealle korolle

Jos toimii, blocks-kirjasto on valmis. Aja repon juuressa
`make-bundle.ps1` PowerShellissä → `files/suunnittelutyokalut.zip`
päivittyy sisältämään `klhylly.dwg`:n.

---

## Yleisia virheitä

- **"Block already exists"** kun ajat `KLHYLLY-BUILD-BLOCKS` toista kertaa
  → avaa tyhjä DWG.
- **Properties-paletissa ei näy Pituus/Leveys** → joko block-määritys ei
  ole dynamic (parametria/actionia puuttuu), tai INSERT-instanssi viittaa
  väärään blockiin. Tarkista BEDIT.
- **Stretch venyttää väärää suuntaa** → parameter point liitetty väärään
  grippiin (vrt. ohjeessa "oikea pää" / "yläpää"). Korjaa BEDIT:ssä.
- **Array-rungit eivät katoa kun pituus pienenee** → tarkista Array-actionin
  Column distance = 250 ja että parametri on Pituus.
- **Hatch jää paikalleen kun stretchaa** → hatchin pitää olla associative
  (HPASSOC=1 luonti-hetkellä, mikä on helper-skriptin oletusarvo) ja
  liittyä outline-polylineen — jos ei, BEDIT → poista hatch → luo uudestaan
  associative HATCH-komennolla.

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
