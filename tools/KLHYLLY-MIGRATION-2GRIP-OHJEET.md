# KLHYLLY: erilliset DWG:t + 2-gripin lisäys

Migraatio yhden `klhylly.dwg`:n rakenteesta erillisiin `klhylly-levy.dwg`
+ `klhylly-tikas.dwg` -tiedostoihin, ja samalla 2-grip Stretch-actionien
lisäys jotta hyllyä voi venyttää **kaikista neljästä reunasta** Properties-
gripeillä jälkikäteen.

> Lue rinnalla `tools/KLHYLLY-BEDIT-OHJEET.md` jos joku perusvaihe ei ole
> tuttu (Block Authoring Palettes, Linear-parametrien lisays, Stretch-
> actionin syntaksi).

---

## OSA A — Erilliset DWG-tiedostot

### A1. Pelasta TIKAS WBLOCK:lla

Olet tehnyt KLHYLLY-TIKAS:n jo BEDIT:ssä — älä rakenna uudestaan. Kopioidaan
suoraan omaan DWG-tiedostoonsa.

1. Avaa `files/klhylly.dwg` AutoCAD:ssä
2. Komentorivillä: `WBLOCK` ↵ → dialog avautuu
3. Asetukset:
   - **Source**: valitse "**Block**" radio-button → dropdownista `KLHYLLY-TIKAS`
   - **Insert units**: Millimeters (pidä sama)
   - **Destination**:
     - File name: `klhylly-tikas`
     - Path: `C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files`
4. **OK** → AutoCAD kirjoittaa `files/klhylly-tikas.dwg`
5. Sulje klhylly.dwg **älä tallenna** muutoksia (jos kysytään)
6. Tarkista Explorerista että `files/klhylly-tikas.dwg` on syntynyt

### A2. Rakenna LEVY puhtaasta tyhjästä DWG:stä

LEVY-blockissa oli self-reference, joten rakennetaan uudestaan.

1. Avaa **uusi tyhjä DWG** (File → New → acadiso.dwt)
2. Komentorivillä: `UNITS` → Length: Decimal, Insertion units: Millimeters → OK
3. APPLOAD päivitetty `tools/build-klhylly-blocks.lsp`
4. Komentorivillä: `KLHYLLY-BUILD-LEVY` ↵
   - Konsoli: *"KLHYLLY-LEVY block-maaritys luotu (8 entiteettia)."*
5. Komentorivillä: `BAUTHORPALETTE` ↵ (pidä paletti näkyvissä BEDIT:n ajan)
6. `BEDIT` ↵ → `KLHYLLY-LEVY` → OK
7. **Lisää parametrit:**
   - Drag **Linear** → start `0,0,0` → end `1000,0,0` → label `500,-50,0`
     - Properties: Distance name `Pituus`, Default 1000, Value Set None,
       **Number of Grips: 2**
   - Drag **Linear** → start `0,0,0` → end `0,500,0` → label `-50,250,0`
     - Properties: Distance name `Leveys`, Value Set **List** → "..." → 300/400/500,
       Default 500, **Number of Grips: 2**
8. **Älä vielä tee Stretch-actioneita.** Etene OSA B vaiheeseen B1.

---

## OSA B — KLHYLLY-LEVY: kaikki 4 Stretch-actionia

LEVY:llä on 4 actionia: Pituus oikea + Pituus vasen + Leveys ylä + Leveys ala.
Jokaisessa selection set:ssä on **6 entiteettiä** (sFloor pohja venyy
mukana — tärkeä jotta pohjalevy seuraa muutoksia).

### B1. Pituus-OIKEA Stretch

1. Block Authoring Palettes → Actions → vedä **Stretch** canvasille
2. *Select parameter:* klikkaa **Pituus**-parametriä
3. *Specify parameter point:* klikkaa Pituus-parametrin **OIKEAA grippiä** (X=1000-pää)
4. *First corner of stretch frame:* `950,-50` ↵
5. *Opposite corner:* `1100,600` ↵
6. *Select objects:* **8 entiteettiä** (kaikki):
   - 5 LWPOLYLINEa (sFloor, sLWall, sRWall, sLLip, sRLip)
   - 1 3DFACE (sFloorTop)
   - 1 LWPOLYLINE outline (z=0)
   - 1 DASH-hatch
   - ↵

### B2. Pituus-VASEN Stretch (uusi 2-grip variantti)

1. Stretch canvasille
2. Parameter: **Pituus**
3. Parameter point: **VASEN grippi** (X=0-pää) — tämä on uusi grippi joka
   ilmestyi kun Number of Grips muutettiin 2:ksi
4. First corner: `-100,-50` ↵, Opposite: `50,600` ↵
5. Select objects: **samat 8 entiteettiä** kuin oikealla actionilla → ↵

> Logiikka: kun käyttäjä vetää vasenta grippiä -X-suuntaan, frame catches
> kaikkien entiteettien VASEMMAT vertikit (X=0). Ne liikkuvat -X-suuntaan
> mukana → geometria ulottuu insertion point:n vasemmalle puolelle.

### B3. Leveys-YLÄ Stretch

1. Stretch canvasille
2. Parameter: **Leveys**
3. Parameter point: **YLÄGRIPPI** (Y=500-pää)
4. First corner: `-50,480` ↵, Opposite: `1050,550` ↵
5. Select objects: **6 entiteettiä**:
   - **sFloor** (pohjan Y=500-reuna venyy)
   - **sRWall** (oikea seinä Y=498.75..500 — kokonaan framessa, siirtyy)
   - **sRLip** (oikea lippa Y=489.75..498.75 — kokonaan framessa, siirtyy)
   - **sFloorTop** 3DFACE (Y=500-reuna venyy)
   - LWPOLYLINE outline (Y=500-reuna venyy)
   - DASH-hatch
   - ↵

> HUOM: pohjan (sFloor) sisältyminen on tärkeää. Jos sen jättää pois,
> pohjalevy pysyy 500mm leveänä vaikka seinät kapenevat → näkyvä ristiriita
> Realistic-tilassa.

### B4. Leveys-ALA Stretch (uusi 2-grip variantti)

1. Stretch canvasille
2. Parameter: **Leveys**
3. Parameter point: **ALAGRIPPI** (Y=0-pää)
4. First corner: `-50,-50` ↵, Opposite: `1050,20` ↵
5. Select objects: **6 entiteettiä** (alaosan elementit):
   - **sFloor** (pohjan Y=0-reuna venyy alas)
   - **sLWall** (vasen seinä Y=0..1.25 — kokonaan framessa, siirtyy alas)
   - **sLLip** (vasen lippa Y=1.25..10.25 — kokonaan framessa, siirtyy alas)
   - **sFloorTop** 3DFACE (Y=0-reuna venyy alas)
   - LWPOLYLINE outline (Y=0-reuna venyy alas)
   - DASH-hatch
   - ↵

### B5. Tallennus + tarkistus

1. `BSAVE` ↵
2. `BCLOSE` ↵
3. Pikatesti modelspacessa:
   - `-INSERT KLHYLLY-LEVY` ↵ → `0,0,0` ↵ → `1` ↵ → `1` ↵ → `0` ↵
   - Klikkaa instanssia → näet **4 grippiä** (oikea, vasen, ylä, ala)
   - Vedä jokaista grippiä → vastaava reuna venyy hallitusti
   - Realistic-tilassa pohja näkyy, ei läpinäkyvyyttä
4. ERASE ALL ↵ ↵
5. SAVEAS → File name `klhylly-levy` → polku `files/`-kansioon → Save
6. Sulje DWG

---

## OSA C — KLHYLLY-TIKAS: 2-gripin lisäys (olemassa olevaan)

Avaa `files/klhylly-tikas.dwg` (juuri WBLOCK:lla luotu OSA A1:ssa).

### C1. Number of Grips = 2 molemmille parametreille

1. `BEDIT` → `KLHYLLY-TIKAS` → OK
2. Klikkaa **Pituus**-parametriä → Properties → **Number of Grips: 2**
3. Klikkaa **Leveys**-parametriä → Properties → **Number of Grips: 2**

> WBLOCK saattoi pudottaa parametrit/actionit. Tarkista — jos parametrit
> puuttuvat, etene OSA C:n vaiheella "Rebuilding" alimmaisena tässä osiossa.

### C2. Pituus-VASEN Stretch (uusi)

1. Stretch canvasille
2. Parameter: **Pituus**
3. Parameter point: **VASEN grippi** (X=0)
4. First corner: `-100,-50` ↵, Opposite: `50,550` ↵
5. Select objects: **rail1 + rail2 + rail1-Top 3DFACE + rail2-Top 3DFACE**
   (4 entiteettiä, **EI** rung-masteria eikä rung-Top:ia) → ↵

> Array-action TIKAS:ssa on yksisuuntainen — rungit eivät lisäänny vasen-
> stretchin myötä, vain oikean Pituus-arvon kasvattaminen lisää uusia
> rungeja. Vasen-stretch venyttää vain rail-LWPOLYLINEt -X-suuntaan.

### C3. Leveys-ALA Stretch (uusi)

1. Stretch canvasille
2. Parameter: **Leveys**
3. Parameter point: **ALAGRIPPI** (Y=0)
4. First corner: `-50,-50` ↵, Opposite: `1050,20` ↵
5. Select objects: **rail1 + rail1-Top + rung-master + rung-Top** (4 entiteettiä):
   - rail1 (Y=0..15) → kokonaan framessa, siirtyy alas
   - rail1-Top (Y=0..15 z=60) → kokonaan framessa, siirtyy alas
   - rung-master (Y=15..485) → vain Y=15-edge framessa, alaosa venyy alas
   - rung-Top (Y=15..485 z=25) → vain Y=15-edge framessa, alaosa venyy alas
   - ↵

> Array-kopiot perivät master:n stretch-tilan, joten kaikki rungit
> stretchaantuvat samaan tahtiin Y-suunnassa.

### C4. Tallennus + tarkistus

1. `BSAVE` → `BCLOSE`
2. Pikatesti:
   - `-INSERT KLHYLLY-TIKAS 0,0,0 1 1 0`
   - 4 grippiä, kaikki neljä reunaa venyy
   - Pituutta venyttäessä rungit lisääntyvät 250 mm askeleella oikean gripin
     suunnassa
3. ERASE ALL → SAVE (overwrite klhylly-tikas.dwg)

### C5. (Vaihtoehto) Rebuild jos WBLOCK pudotti parametrit

WBLOCK voi joskus pudottaa dynamic-block-parametreja kun source on Block
ja Destination on uusi DWG. Jos C1:ssä Properties ei näytä Pituus/Leveys-
parametreja, tee TIKAS uudestaan tyhjään DWG:hen:

1. Avaa toinen tyhjä DWG, APPLOAD `tools/build-klhylly-blocks.lsp`
2. `KLHYLLY-BUILD-TIKAS` ↵
3. BEDIT → lisää parametrit (Pituus + Leveys, Grips=2 alusta), 4 Stretch-actionia
   (Pituus oikea + vasen, Leveys ylä + ala) ja 1 Array-action Pituus-oikealle
4. Vaihtoehtoisesti voit kopioida actionit TIKAS:n vanhasta versiosta —
   AutoCAD:n COPY ↔ PASTE klikkailu ei välttämättä toimi dynamic-actioneille,
   joten helpompi luoda uudestaan
5. ERASE ALL → SAVEAS klhylly-tikas.dwg (overwrite)

---

## OSA D — Loppuvarmistus + ZIP-rebuild

1. **Tarkista files/-kansio:** sisältää
   - `klhylly.lsp` ✓
   - `klhylly-levy.dwg` ✓
   - `klhylly-tikas.dwg` ✓
   - **EI** `klhylly.dwg` (poista vanha jos vielä on)
   - Plus muut LSP:t (positio, kaato, putkityokalu) + positio.dwg

2. **Yhteistesti puhtaassa DWG:ssä:**
   - Avaa uusi tyhjä DWG
   - APPLOAD `klhylly.lsp` (`files/`-kansiosta tai purku-kansiosta)
   - `KLHYLLY` → LEVY → 500 → kaksi pistettä → 4 grippiä toimii
   - `KLHYLLY` → TIKAS → 500 → kaksi pistettä → 4 grippiä toimii
   - `KLHYLLYV` → 500 → kolme pistettä → vino tikashylly
   - `HYLLYKORKO` → valitse → kohdekorko → toimii

3. **Kerro minulle** kun kaikki toimii → rebuildaan
   `files/suunnittelutyokalut.zip` ja committoidaan + pushataan.

---

## Tärkeät huomiot

- **Insertion point pysyy origossa** (block-tasolla (0,0)). Kun käyttäjä
  vetää vasenta tai alagrippiä, geometria laajenee insertion point:n -X
  tai -Y -puolelle. Visuaalisesti näyttää että block "kasvaa taaksepäin"
  mutta käyttäjän alkuperäinen klikkauspiste pysyy paikallaan.

- **Mirrored block (CW perp)** — kun klhylly.lsp INSERT:ää scaleY=-1:llä
  (auto-perp valitsi CW-puolen), block on peilattu Y-akselin ympäri.
  WCS:ssä "vasen grippi" voi visuaalisesti olla "oikealla" — mutta
  parametrin logiikka pysyy block-paikallisessa avaruudessa, joten
  stretchaaminen toimii oikein.

- **TIKAS Array-action on yksisuuntainen** — rungit lisääntyvät vain
  oikean Pituus-gripin suuntaan. Tämä on hyväksyttävä rajoitus, koska
  käyttötapauksessa "lisää rungeja" tarkoittaa yleensä pidentää pituutta
  käyttäjän tarkoittamaan suuntaan.

- **Yhdistettyjen actioneiden yhteispeli** — AutoCAD allokoi kullekin
  grippille oman Stretch-actionin. Parametrin arvon päivitys (esim. Pituus
  500 → 700) yhdistyy molempien actionien dummy-tiloista — lopputulos on
  symmetrinen ja ennustettava.
