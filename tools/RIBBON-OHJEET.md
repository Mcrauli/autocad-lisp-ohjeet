# Radika-ribbon-välilehden rakentaminen AutoCADissa

Tämä ohje kertoo miten luodaan `files/radika-tools.cuix` jonka käyttäjät
lataavat CUILOAD-komennolla saadakseen oman Radika-välilehden ribboniin.
Käytetään AutoCADin sisäänrakennettua CUI-editoria — CUIX on käytännössä
ZIP jonka sisällä on XML + ikonit, ja editori hoitaa formaatin oikein.

Tarvitset:

- AutoCAD (täysi, ei LT) — sama versio jolla työkalut on tarkoitus käyttää
- `files/icons/` -kansion 36 PNG:tä (luotu `tools/make-icons.ps1`:llä)
- ~30–45 min aikaa

## Pikareferenssi: ribbon-rakenne

| Paneeli      | Päänappi (32×32) | Dropdown-rivit (16×16)             |
|--------------|------------------|------------------------------------|
| Hyllyt       | KLH              | KLH, KLHV, KORKO                   |
| Putket       | 3PTK             | 3PTK, LTI, MTI, MTN                |
| Höyrystimet  | HY1              | HY1, HY2, HY3                      |
| Positio      | POSITIO          | POSITIO, ASETANUMERO               |
| Apuvälineet  | KAATO3D          | KAATO3D, VARUSTEET                 |

5 paneelia, 5 päänappia, 14 komentoa yhteensä.

## 1. Aloita uusi partial-CUIX

1. Käynnistä AutoCAD ja avaa **tyhjä piirustus**.
2. Komento: `CUI` → CUI-editori-ikkuna aukeaa.
3. Vasen yläpaneeli: oikealla klikkauksella **"Customizations in All Files"**
   → **Transfer**. Avautuu kahden puolen näkymä.
4. Oikealla **New** -ikoni (sininen ☆-symboli yläreunassa) → **New Customization File**.
5. Tallennusdialogi: navigoi
   `C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet\files\`
   ja anna nimeksi `radika-tools.cuix`. **Save**.
6. Oikealla puolella näkyy nyt tyhjä `RADIKA-TOOLS` -puurakenne.

## 2. Lisää komennot (18 kpl)

**Tärkeää:** kaikki seuraavat askeleet tehdään **oikealla puolella**,
"Customizations in New File" -puurakenteen (`RADIKA-TOOLS`) sisällä.
Älä koske vasempaan puoleen ("Customizations in Main File" / `acad.cuix`)
— sieltä löytyvät AutoCADin sisäänrakennetut komennot, joita ei haluta
muokata. Jos huomaat että uusi komento ilmestyy vasemmalle, peruuta (Ctrl+Z)
ja varmista että `RADIKA-TOOLS` on aktiivinen oikealla.

Oikealla puolella laajenna **`RADIKA-TOOLS` → Commands**. Oikealla klikkauksella
**"Commands"** → **New Command**. Toista alla olevan taulukon mukaan.

Jokaiselle komennolle määritä Properties-paneelissa (oikea reuna):

- **Name**: ks. taulukko, sarake "Name"
- **Description**: ks. taulukko, sarake "Description"
- **Macro**: ks. taulukko, sarake "Macro"
- **Small image** ja **Large image**: klikkaa "..." → Browse → valitse
  `files/icons/<id>-16.png` (small) ja `<id>-32.png` (large)

| Name              | Macro          | Description                                | Icon id      |
|-------------------|----------------|--------------------------------------------|--------------|
| Hylly KLH         | `^C^CKLH`      | Kylmälaitehylly (LEVY tai TIKAS, vaaka)    | klh          |
| Hylly KLHV        | `^C^CKLHV`     | Kylmälaitehylly TIKAS (pysty / 3D)         | klhv         |
| Korko KORKO       | `^C^CKORKO`    | Siirrä valitut absoluuttiselle Z-korolle   | korko        |
| Putket 3PTK       | `^C^C3PTK`     | Kolme putkea kerralla (LT IMU + MT + N)    | 3ptk         |
| Putki LTI         | `^C^CLTI`      | LT IMU -putki                              | lti          |
| Putki MTI         | `^C^CMTI`      | MT IMU -putki                              | mti          |
| Putki MTN         | `^C^CMTN`      | MT NESTE -putki                            | mtn          |
| Hoyrystin HY1     | `^C^CHY1`      | Höyrystin, 1 puhallin                      | hy1          |
| Hoyrystin HY2     | `^C^CHY2`      | Höyrystin, 2 puhallinta                    | hy2          |
| Hoyrystin HY3     | `^C^CHY3`      | Höyrystin, 3 puhallinta                    | hy3          |
| Positio POSITIO   | `^C^CPOSITIO`  | Numerointiblokki, auto-incrementti         | positio      |
| Positio NUMERO    | `^C^CASETANUMERO` | Aseta seuraava positionumero            | asetanumero  |
| Kaato KAATO3D     | `^C^CKAATO3D`  | Kallista kappale 3D-pivot-pisteestä        | kaato3d      |
| Varusteet         | `^C^CVARUSTEET`| Kylmäkoneikon sähkövarustelu               | varusteet    |

**Vinkki**: jos icons-kansiossa olevat polut näkyvät "embedded"-statuksella
(CUIX kopio kuvan sisäänsä), se on hyvä — ikonit kulkevat CUIX:n mukana
eivätkä häviä jos käyttäjä siirtää tiedoston.

## 3. Tee ribbon-paneelit (6 kpl)

Oikealla puolella: laajenna **`RADIKA-TOOLS` → Ribbon → Panels**.
Oikealla klikkauksella → **New Panel**. Toista 6 kertaa.

Jokainen paneeli sisältää **Row 1** -rivin. Klikkaa rivi auki.

### 3.1. Suuri päänappi (Split Button)

Klikkaa **Row 1** -rivillä hiiren oikealla → **New Split Button**.
Vedä Commands-listasta **päänappi**-komento Split Buttonin sisään
(esim. "Hylly KLH" → Hyllyt-paneelin Split Buttoniin).
Properties: **Button Style** = `Large with Text (Vertical)`.

### 3.2. Dropdown-rivit

Vedä jokainen alapainike Commands-listasta **saman Split Buttonin sisään**
(esim. KLH, KLHV, KORKO). Properties: **Button Style** = `Small with Text` tai
`Small without Text` (kapeampi). Päänappi tulee Split Buttonin "Primary
button" -kohtaan, ja muut listautuvat dropdowniksi.

Paneelien sisällöt:

| Paneeli nimi (Panel Name) | Title bar text | Päänappi  | Dropdownissa lisäksi          |
|---------------------------|----------------|-----------|-------------------------------|
| Hyllyt                    | Hyllyt         | KLH       | KLHV, KORKO                   |
| Putket                    | Putket         | 3PTK      | LTI, MTI, MTN                 |
| Höyrystimet               | Höyrystimet    | HY1       | HY2, HY3                      |
| Positio                   | Positio        | POSITIO   | ASETANUMERO                   |
| Apuvälineet               | Apuvälineet    | KAATO3D   | VARUSTEET                     |

## 4. Tee Ribbon-välilehti

1. Laajenna **`RADIKA-TOOLS` → Ribbon → Tabs**.
2. Oikealla klikkauksella **Tabs** → **New Tab**.
3. Nimeksi: `Radika`. Aliakseksi: `RADIKA_TAB`.
4. Properties: **Display Text** = `Radika`.
5. Vedä 5 paneelia (Panels-listasta) tabin sisään yksitellen, siinä
   järjestyksessä jossa haluat ne näkyvän: Hyllyt → Putket → Höyrystimet
   → Positio → Apuvälineet.

## 5. Tallenna ja sulje editori

1. Paina **Apply** → **OK**. AutoCAD tallentaa `radika-tools.cuix`-tiedoston
   `files/`-kansioon.
2. Sulje CUI-editori.

## 6. Aktivoi välilehti omassa AutoCADissasi (kerran)

Jotta välilehti näkyy heti omassa AutoCADissasi:

1. Komento `CUILOAD`. Jos `radika-tools.cuix` ei vielä ole listassa, Browse
   → valitse se → Load → Close.
2. Komento `CUI` → **Customize**-välilehdellä:
   - **Workspaces** → klikkaa nykyistä workspaceasi (esim. *Drafting & Annotation*)
   - Sen alta laajenna **Ribbon Tabs** → drag-and-drop `Radika`-tab listaan
     halutulle paikalle.
   - **Apply** → **OK**.
3. `Radika`-tab tulee näkyviin ribbonin yläreunaan.

Käyttäjille jaeltaessa vain `CUILOAD`-vaihe riittää — partial CUIX
tarjoaa oman tabin joka aktivoituu workspaceen automaattisesti (riippuu
AutoCAD-versiosta; jos ei, käyttäjän pitää toistaa kohta 6.2).

## 7. Päivitä paketti ja sivusto

Kun `radika-tools.cuix` on tallennettu `files/`-kansioon:

```powershell
cd "C:\Users\LauriRekola\OneDrive - RADIKA OY\Työpöytä\work\autocad-lisp-ohjeet"
.\make-bundle.ps1
```

Tarkista uusi paketin koko ulostulosta ja päivitä `lataukset.html`-tiedoston
ZIP-kortin koko + sisältömäärät. Ribbon-osio ja CUILOAD-asennusvaihe ovat
jo valmiina sivuilla.

## Päivitykset jälkikäteen

Jos komento muuttuu (esim. uusi macro tai nimi), avaa AutoCAD →
`CUI` → **Customize** → laajenna `RADIKA-TOOLS` → tee muutos →
Apply → OK. CUIX-tiedosto päivittyy automaattisesti `files/`-kansiossa.
Aja `make-bundle.ps1` uudelleen.

Uutta komentoa lisätessäsi: tee Command + lisää sen ikoni `make-icons.ps1`:n
`$commands`-taulukkoon, aja skripti, valitse uusi ikoni CUI-editorissa.
