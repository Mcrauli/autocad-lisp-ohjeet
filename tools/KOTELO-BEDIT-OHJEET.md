# KOTELO-BEDIT-OHJEET

Step-by-step ohjeet `files/Kotelo.dwg`-block-kirjaston tekemiseen
**parametriseksi dynamic blockiksi**. Tehdään **kerran**. Kun tämä on
tehty, `files/kotelo.lsp`:n `KOTELO`-komento toimii.

> ## ⚠ TÄRKEÄÄ — geometria EI saa olla 3D-soliditeetteja
>
> AutoCADin dynamic blockin **Stretch-action ei venytä 3D-soliditeetteja**
> (BOX / EXTRUDE / PRESSPULL). 3D-solidilla ei ole liikuteltavia
> vertexejä, joten Stretch vain **siirtää** koko kappaleen — ei venytä.
> Sama seinä johon KLHYLLY-projekti törmäsi (testattu 5.5.2026).
>
> Siksi kotelon geometria rakennetaan **2D-LWPOLYLINE-paloista joilla on
> thickness** (Z-extrudointi) + **3DFACE-kansista**. LWPOLYLINE:n ja
> 3DFACE:n vertexit liikkuvat Stretchissä → kotelo venyy oikein.
>
> `tools/build-kotelo-blocks.lsp` rakentaa geometrian oikein. **Älä
> käytä käsin 3D-soliditeeteilla piirrettyä koteloa** — se vain liikkuu,
> ei veny.

Tämä ohje on kevyt versio `KLHYLLY-BEDIT-OHJEET.md`:stä: yksi blocki,
yksi parametri (`Pituus`), yksi action (Stretch).

---

## Periaate — orientaatio

`kotelo.lsp` sijoittaa `KOTELO`-blockin WCS-origoon ja kääntää sen
`vla-TransformBy`-matriisilla haluttuun 3D-suuntaan. Matriisi olettaa
block-koordinaatiston **kanonisen orientaation** — jonka
`build-kotelo-blocks.lsp` tuottaa automaattisesti:

| Block-akseli | Merkitys              | kotelo.lsp |
|--------------|-----------------------|------------|
| **+X**       | pituus                | `Pituus`-parametrin suunta |
| **+Y**       | leveys                | kiinteä    |
| **+Z**       | korkeus               | kiinteä    |
| origo (0,0,0)| kotelon **alkupää**   | base point |

---

## Vaihe 0 — KOTELO-geometrian luonti

> Vanha `Kotelo.dwg` (käsin 3D-soliditeeteilla piirretty) korvataan tässä
> kokonaan. Jos haluat tietää nykyisen kotelon mitat, avaa se ja mittaa
> `DIST`-komennolla — syötä samat mitat alla.

1. Avaa AutoCAD, **tyhjä DWG** (File → New → acadiso.dwt-pohja).
2. Varmista yksiköt: `UNITS` → Length: Decimal, Insertion units:
   Millimeters → OK.
3. APPLOAD → valitse `tools/build-kotelo-blocks.lsp` repon polusta.
4. Komentorivillä: `KOTELO-BUILD` ↵
   - Syötä **pituus** mm (oletus 1000) ↵
   - Syötä **leveys** mm (oletus 200) ↵
   - Syötä **korkeus** mm (oletus 150) ↵
   - Syötä **seinämävahvuus** mm (oletus 2) ↵
   - Konsoliin: *"KOTELO block-maaritys luotu (12 entiteettia)."*
   - Modelspace pysyy tyhjänä (block-määritys on block-tablessa).

> Geometria: 4 LWPOLYLINE+thickness -seinää (pohja, kansi, vasen, oikea)
> + 8 3DFACE-kantta = **12 entiteettiä**, kaikki layerilla `0`/BYBLOCK.
> Poikkileikkaus on suljettu suorakaide, kotelo on päistä auki.

---

## Vaihe 1 — Block Authoring Palettes käyttöön

Kirjoita komentoriville: `BAUTHORPALETTE` ↵. Oikealle reunalle ilmestyy
paletti välilehdillä **Parameters**, **Actions**, **Parameter Sets**.
Pidä se näkyvissä koko BEDIT-vaiheen ajan.

---

## Vaihe 2 — KOTELO: Pituus-parametri

1. Komentorivillä: `BEDIT` ↵ → valitse listalta `KOTELO` → OK. Block
   Editor avautuu, näet kotelon geometrian (12 entiteettiä).
2. **Lisää Pituus-parametri:**
   - Block Authoring Palettes → **Parameters**-välilehti → vedä
     **Linear** parametri canvasille.
   - *Specify start point:* kirjoita `0,0,0` ↵ (kotelon alkupää).
   - *Specify endpoint:* kirjoita `<pituus>,0,0` ↵ — käytä samaa
     pituutta jonka annoit `KOTELO-BUILD`:lle (esim. `1000,0,0`).
   - *Specify label location:* `<pituus/2>,-50,0` ↵ (esim. `500,-50,0`).
   - **Klikkaa Linear-parametri** valituksi → Properties-paletti
     (Ctrl+1):
     - **Distance name:** `Pituus`
     - **Default Distance:** = `KOTELO-BUILD`:lle antamasi pituus
     - **Value Set** *(tai "Dist value set")* **= `None`** (continuous)
     - **Number of Grips:** `1`

> Parametrissa näkyy keltainen **!** = "ei actionia". Korjautuu Vaihe 3:ssa.

---

## Vaihe 3 — KOTELO: Pituus-Stretch

1. Block Authoring Palettes → **Actions**-välilehti → vedä **Stretch**
   canvasille.
2. *"Select parameter:"* — klikkaa **Pituus**-parametria.
3. *"Specify parameter point to associate with action:"* — klikkaa
   **Pituus-parametrin loppupään grippiä** (X = pituus -pää).
4. *"Specify first corner of stretch frame:"* — kirjoita ensimmäinen
   nurkka **hieman pituuden alapuolelle**:
   `<pituus - 100>,-50` ↵ (esim. pituudella 1000 → `900,-50`).
5. *"Specify opposite corner of stretch frame:"* — toinen nurkka selvästi
   loppupään **ulkopuolelle ja leveyden yli**:
   `<pituus + 100>,<leveys + 50>` ↵ (esim. `1100,250`).
6. *"Select objects:"* — valitse **kaikki 12 entiteettiä** (window-
   tai crossing-valinta koko geometrian yli) → ↵.

> Stretch venyttää X-suunnassa kaikki entiteetit joiden **loppupään
> vertexit** ovat stretch frame:n sisällä. Koska kaikki 12 palaa
> kulkevat X-suunnassa, koko kotelo pitenee — alkupää (X=0) pysyy
> origossa.

---

## Vaihe 4 — Tallennus

1. Komentorivillä: `BSAVE` ↵ — tallentaa block-määrityksen muutokset.
2. Komentorivillä: `BCLOSE` ↵ — poistuu Block Editorista.
3. **Pikatesti modelspacessa:** `-INSERT KOTELO` ↵ → `0,0,0` ↵ →
   `1` ↵ → `1` ↵ → `0` ↵.
   - Klikkaa instanssia → Properties (Ctrl+1) → Custom-otsikon alla
     näkyy **Pituus**.
   - Vaihda Pituus esim. 1000 → 2000 → **kotelo pitenee** +X-suuntaan
     (ei vain siirry!).
   - Tartu Pituus-grippiin → vedä → kotelo venyy.
   - Realistic-tilassa (`VSCURRENT R`) kotelo näkyy umpiseinäisenä.
4. **Lopputallennus:**
   - `ERASE ALL` ↵ ↵ — poista testi-instanssi.
   - `SAVEAS` → Files of type **AutoCAD 2018 Drawing** → File name
     `Kotelo` → polku
     `C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files`
     → Save → **korvaa vanha `Kotelo.dwg`** (Yes).
5. **Sulje DWG** (älä tallenna muutoksia jos kysytään).

---

## Vaihe 5 — Yhteistesti (kotelo.lsp:n rinnalla)

Avaa **uusi tyhjä DWG**. APPLOAD `files/kotelo.lsp`. Aja:

1. `KOTELO` → base point → `N` → pituus esim. `1500` → leveyden suunta
   → block-instanssi syntyy.
   - Layer = `KYL-KOTELO` (color 175, RGB 63,63,127)
   - Properties: **Pituus** = 1500
2. `KOTELO` → base point → `P` → loppupiste → leveyden suunta → kotelo
   syntyy kahden pisteen väliin.
3. `KORKO` (klhylly.lsp) → valitse kotelo → kohdekorko → siirtyy Z:lle.

Jos toimii, block-kirjasto on valmis. Aja repon juuressa
`make-bundle.ps1` PowerShellissä → `files/suunnittelutyokalut.zip`
päivittyy.

---

## Yleisiä virheitä

- **Kotelo vain SIIRTYY, ei veny** → geometria on 3D-soliditeetteja.
  Stretch ei venytä 3D-solidia. Rakenna geometria uudelleen
  `KOTELO-BUILD`:llä (ks. Vaihe 0) — se tekee LWPOLYLINE+thickness
  -palat jotka venyvät.
- **Properties-paletissa ei näy Pituus** → block-määritys ei ole
  dynamic (parametri/action puuttuu). Tarkista `BEDIT KOTELO`.
- **Stretch venyttää väärää päätä** → parameter point on liitetty
  alkupään grippiin loppupään sijaan. `BEDIT` → klikkaa Stretch-actionia
  → tarkista että associated grip on Pituuden **loppupään** grippi.
- **Osa kotelosta jää paikalleen kun venytät** → stretch frame ei
  kattanut kaikkien palojen loppupäätä, tai *"Select objects:"*
  -vaiheessa jäi entiteetti valitsematta. Toista Vaihe 3, valitse
  **kaikki 12**.
- **`kotelo.lsp` antaa "Kotelo.dwg ei loydy"** → varmista että
  `Kotelo.dwg` ja `kotelo.lsp` ovat samassa kansiossa.
- **Kotelo tulee väärään 3D-suuntaan** → `KOTELO-BUILD` tuottaa
  kanonisen orientaation automaattisesti; jos olet muokannut geometriaa
  käsin, tarkista että pituus on +X, leveys +Y, korkeus +Z.
- **Väri ei periydy (kotelo ei ole värillä 175)** → geometria on
  kovakoodatulla layerilla. `KOTELO-BUILD` laittaa kaiken layerille `0`;
  jos olet muokannut, `BEDIT` → valitse kaikki → Layer `0`.
