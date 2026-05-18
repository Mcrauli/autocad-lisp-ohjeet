# KLHYLLY-blockien korjaus BricsCADissa

Ohje `klhylly-levy.dwg` ja `klhylly-tikas.dwg` -blockien dynamic-actionien
korjaamiseen niin että ne toimivat **BricsCADissa**. Blockit on alun perin
rakennettu AutoCADissa (`KLHYLLY-BEDIT-OHJEET.md`) ja niiden **geometria +
parametrit ovat kunnossa** — vain **actionit** evaluoidaan BricsCADissa eri
tavalla, ja siksi hyllyt vinoutuvat / rungit jäävät jumiin.

> Tämä ohje EI rakenna blockeja alusta. Geometria ja parametrit ovat jo
> tallessa. Korjataan vain actionit. AutoCAD-puolen blockit eivät tästä
> kärsi — sama korjattu rakenne toimii myös AutoCADissa.

---

## Tausta — miksi BricsCAD eroaa

AutoCAD evaluoi dynamic blockin **kaikki actionit yhtenä kokonaisuutena**
lopuksi, joten actionien luontijärjestyksellä ei ole väliä. **BricsCAD
evaluoi actionit luontijärjestyksessä** (se action joka luotiin ensin
ajetaan ensin). Tästä seuraa kaksi vikaa:

1. **TIKAS — rungit jäävät 500-leveyteen.** Nykyinen block: Array luotiin
   ENNEN Leveys-Stretchiä. BricsCAD ajaa Array ensin → kopioi
   default-levyisen (500) rung-masterin → sitten Leveys-Stretch venyttää
   VAIN alkuperäisen masterin, ei array-kopioita.
   **Korjaus: Leveys-Stretch on luotava ENNEN Arrayta.** Silloin BricsCAD
   venyttää masterin ensin ja Array kopioi jo-venytetyn masterin.

2. **LEVY — outline-polyline vinoutuu.** Closed-LWPOLYLINE jonka samat
   nurkka­verteksit ovat sekä Pituus- että Leveys-Stretch-framessa
   venyy BricsCADissa epävakaasti.
   **Korjaus: outline tehdään neljästä erillisestä LINE-entiteetistä**,
   jokainen vain yhdessä Stretch-actionissa — ei yhtään verteksiä kahteen
   actioniin.

---

## Stretch-actionin perusperiaate (lue tämä ensin)

Stretch venyttää **vain ne verteksit jotka ovat stretch-framen
(katkoviivasuorakulmion) SISÄLLÄ**. Framen ulkopuoliset verteksit pysyvät
paikallaan.

- Frame kattaa **koko** entiteetin → kaikki verteksit liikkuvat yhtä
  paljon → entiteetti **siirtyy** (ei veny).
- Frame kattaa **vain toisen reunan** → vain se reuna liikkuu →
  entiteetti **venyy / lyhenee**.

Tämä on se mitä huomasit: "liikuttaa koko paskaa" = frame kattoi koko
rungin. Frame pitää rajata niin että se kattaa **vain liikkuvan reunan**.

---

## Vaihe 0 — Esivalmistelut

1. **Experimental Mode** on jo päällä (`EXPERIMENTALMODE = 1`). Jos BEDIT
   silti valittaa, käynnistä BricsCAD uudelleen kerran.
2. Avaa `files/klhylly-tikas.dwg` BricsCADissa.
3. Komento: `BEDIT` ↵ → valitse `KLHYLLY-TIKAS` → OK. Block Editor avautuu.
4. Block Editor -tilassa näkyy oma ribbon-välilehti / työkalupaletti jossa
   on **Parameters** ja **Actions**. Pidä se näkyvissä. (Jos ei näy:
   komento `BPARAMETER` ja `BACTIONTOOL` avaavat työkalut, tai katso
   Block Editor -välilehden työkalurivi.)

---

## Vaihe 1 — KLHYLLY-TIKAS: poista vanhat actionit

Block Editor näyttää canvasilla parametrit (Pituus, Leveys) ja actionit
(pienet salama-/työkalukuvakkeet). Parametrit JÄÄVÄT — vain actionit
poistetaan ja luodaan uudelleen oikeassa järjestyksessä.

1. Klikkaa **Array-action**-kuvaketta canvasilla → `Delete`-näppäin.
2. Klikkaa **Leveys-Stretch-action**-kuvaketta (se Stretch joka liittyy
   Leveys-parametriin) → `Delete`.
3. Klikkaa **Pituus-Stretch-action**-kuvaketta → `Delete`.
   *(Myös Pituus-Stretch luodaan uudelleen, jotta evaluointijärjestys on
   varmasti oikea: Pituus-Stretch → Leveys-Stretch → Array.)*

Nyt canvasilla on vain 2 parametria (Pituus, Leveys) + geometria
(2 rail + rung-master + 3 3DFACEa). Parametreissa näkyy keltainen
huutomerkki (= ei actionia) — korjautuu seuraavissa vaiheissa.

---

## Vaihe 2 — KLHYLLY-TIKAS: Pituus-Stretch (kiskot)

1. Actions → vedä **Stretch** canvasille.
2. Select parameter: klikkaa **Pituus**-parametriä.
3. Specify parameter point: klikkaa **Pituus-parametrin oikeaa
   päätygrippiä** (X=1000-pää).
4. First corner of stretch frame: `950,-50` ↵
5. Opposite corner: `1100,550` ↵
6. Select objects: **rail1 + rail2 + rail1-Top 3DFACE + rail2-Top 3DFACE**
   (4 entiteettiä — EI rung-masteria, EI rung-Topia) → ↵

> Frame `950..1100` kattaa vain kiskojen X=1000-reunan → kiskot
> pitenevät, vasen pää pysyy.

---

## Vaihe 3 — KLHYLLY-TIKAS: Leveys-Stretch (ENNEN Arrayta!)

**Tämä on se kriittinen järjestysmuutos.** Leveys-Stretch luodaan nyt,
ENNEN Array-actionia.

1. Actions → vedä **Stretch** canvasille.
2. Select parameter: klikkaa **Leveys**-parametriä.
3. Specify parameter point: klikkaa **Leveys-parametrin yläpäätygrippiä**
   (Y=500-pää).
4. First corner of stretch frame: `-50,400` ↵
5. Opposite corner: `1100,550` ↵
6. Select objects: **rail2 + rung-master + rail2-Top 3DFACE +
   rung-Top 3DFACE** (4 entiteettiä) → ↵

> Frame `Y=400..550` kattaa rung-masterin **yläreunan** (Y=485) mutta
> EI alareunaa (Y=15). Rungin yläreuna liikkuu, alareuna pysyy kiinni
> rail1:ssä → rung **lyhenee** kun leveys pienenee. Sama rail2:lle:
> koko rail2 on Y=485..500, framen sisällä → rail2 siirtyy alas.

---

## Vaihe 4 — KLHYLLY-TIKAS: Pituus-Array (VIIMEISENÄ)

1. Actions → vedä **Array** canvasille.
2. Select parameter: klikkaa **Pituus**-parametriä.
3. Select objects: **rung-master LWPOLYLINE + rung-Top 3DFACE**
   (2 entiteettiä) → ↵
4. Distance between columns: `250` ↵

> Koska Array luotiin VIIMEISENÄ, BricsCAD ajaa sen viimeisenä → se
> kopioi rung-masterin **sen jälkeen** kun Leveys-Stretch on jo
> venyttänyt sen oikean levyiseksi. Kaikki kopiot perivät oikean
> leveyden.

---

## Vaihe 5 — KLHYLLY-TIKAS: testaa

1. Komento: `BTESTBLOCK` ↵ → testi-ikkuna avautuu.
2. Klikkaa block-instanssia → näet gripit.
3. **Venytä Pituus-grippiä** → kiskot pitenevät, rungit lisääntyvät
   250 mm välein, vasen pää pysyy.
4. **Venytä Leveys-grippiä** (tai Properties → Leveys 500 → 300) →
   **KAIKKI rungit** kapenevat, eivät vain ensimmäinen.
5. Jos kumpikin toimii: sulje testi-ikkuna.
6. `BSAVE` ↵ → `BCLOSE` ↵.
7. Modelspace: `ERASE` → `ALL` ↵ ↵ (poista mahd. testi-instanssit).
8. `SAVEAS` → AutoCAD 2018 Drawing → `klhylly-tikas` → polku
   `...\work\autocad-lisp-ohjeet\files\` → Save.

> Jos rungit EIVÄT vieläkään skaalaudu järjestysmuutoksesta huolimatta,
> BricsCADin Array+Stretch on liian rikki — ilmoita, siirrytään
> klhylly.lsp:n CAD-tunnistukseen (BricsCADissa staattinen geometria).

---

## Vaihe 6 — KLHYLLY-LEVY: outline neljäksi LINE-entiteetiksi

Avaa `files/klhylly-levy.dwg` → `BEDIT` → `KLHYLLY-LEVY`.

Ongelma: closed-LWPOLYLINE-outline jonka nurkkaverteksit ovat sekä
Pituus- että Leveys-Stretch-framessa vinoutuu BricsCADissa. Korjaus:
korvataan se neljällä erillisellä LINE-entiteetillä, jolloin **mikään
verteksi ei ole kahdessa actionissa**.

1. Klikkaa **outline-LWPOLYLINE** (se closed nelikulmio joka kiertää
   hyllyn, ja johon DASH-hatch on liitetty) → `Delete`.
   - Hatch häviää samalla (se oli associative outlineen). Hatch
     luodaan uudelleen kohdassa 4.
2. Piirrä **4 erillistä LINE-entiteettiä** layerille `0`:
   - **Vasen reuna:** `LINE` `0,0` → `0,500` ↵ ↵
   - **Oikea reuna:** `LINE` `1000,0` → `1000,500` ↵ ↵
   - **Alareuna:** `LINE` `0,0` → `1000,0` ↵ ↵
   - **Yläreuna:** `LINE` `0,500` → `1000,500` ↵ ↵
3. Poista vanhat Pituus-Stretch- ja Leveys-Stretch-actionit
   (klikkaa kuvake → `Delete`). Luo ne uudelleen, ja valitse
   stretch-objekteihin **vain ne LINE:t joiden pitää liikkua**:

   **Pituus-Stretch** (frame `950,-50` → `1100,600`):
   - Select parameter: Pituus, parameter point: Pituus oikea grip
   - Select objects: sFloor, sLWall, sRWall, sLLip, sRLip, sFloorTop
     3DFACE, **oikea reuna LINE, alareuna LINE, yläreuna LINE**
     (EI vasenta reunaa — se pysyy paikallaan)

   **Leveys-Stretch** (frame `-50,480` → `1050,550`):
   - Select parameter: Leveys, parameter point: Leveys yläpää-grip
   - Select objects: sRWall, sRLip, sFloorTop 3DFACE,
     **yläreuna LINE** (EI ala- eikä sivureunoja — vain yläreuna
     siirtyy leveyssuunnassa)

   > Huom: yläreuna-LINE on molemmissa actioneissa, MUTTA sen
   > **verteksit** ovat eri framessa: Pituus-Stretch venyttää sen
   > oikeaa päätyä (X), Leveys-Stretch siirtää koko LINE:n (Y). Koska
   > kyseessä on yksinkertainen avoin LINE eikä closed-polyline,
   > BricsCAD käsittelee tämän vakaasti.

4. **DASH-hatch uudelleen:** komento `-HATCH` → `_P` (Properties) →
   `DASH` → scale `40` → angle `45` → `_S` (Select objects) → klikkaa
   kaikki 4 LINE:ä jotka muodostavat reunan → ↵ ↵.
   - Tarkista että `HPASSOC` = 1 ennen hatchausta (associative).
   - Lisää syntynyt hatch **molempien** Stretch-actionien select-settiin
     (klikkaa actionin kuvake → oikea klikkaus → "Modify selection set"
     / "Edit selection" → lisää hatch). Hatch seuraa LINE-reunoja.
5. `BTESTBLOCK` → venytä molempia grippejä → outline + hatch pysyvät
   suorakulmaisina, ei vinoutta.
6. `BSAVE` → `BCLOSE` → `ERASE ALL` → `SAVEAS` `klhylly-levy.dwg`.

---

## Vaihe 7 — Yhteistesti

Avaa tyhjä DWG BricsCADissa. LSP:t latautuvat automaattisesti
(`on_doc_load.lsp`). Aja:

1. `KLH` → LEVY → 400 → V → kaksi pistettä → hylly syntyy suorana
2. Valitse hylly → venytä Pituus-grip → pysyy suorana
3. Properties → Leveys 400 → 300 → kapenee suorana, hatch seuraa
4. `KLH` → TIKAS → 300 → kaksi pistettä → tikashylly
5. Venytä Pituus → rungit lisääntyvät, kaikki 300-levyisiä
6. Properties → Leveys 300 → 500 → KAIKKI rungit levenevät

Jos kaikki toimii: aja repon juuressa `tools/install-radika.ps1`
(rebuildaa `suunnittelutyokalut.zip` korjatuilla DWG:illä).

---

## Yleisiä virheitä BricsCADissa

- **"Editing of dynamic blocks only possible in Experimental Mode"** →
  `EXPERIMENTALMODE` ei ole aktivoitunut. Käynnistä BricsCAD uudelleen.
- **Stretch siirtää koko entiteetin** → frame kattaa kaikki sen
  verteksit. Rajaa frame niin että vain liikkuva reuna on sisällä.
- **Array-kopiot eivät seuraa Leveys-muutosta** → Array luotiin ENNEN
  Leveys-Stretchiä. Poista Array, luo se uudelleen VIIMEISENÄ.
- **Hatch ei seuraa stretchiä** → hatch ei ole associative (`HPASSOC`
  oli 0 hatchatessa) tai sitä ei lisätty Stretch-actionin
  selection-settiin.
- **Parametrin keltainen huutomerkki jää** → parametriin ei ole
  liitetty yhtään actionia. Lisää Stretch/Array.
