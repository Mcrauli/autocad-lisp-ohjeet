# Suunnittelutyökalut — projektimuistio

Tämä tiedosto on Claudelle. Lue tämä aina kun jatkat sivustoa, niin
pääset nopeasti kiinni kontekstiin ja vältyt menemästä väärään
suuntaan.

## Mikä tämä on

Staattinen neljän sivun HTML-sivusto joka esittelee ja tarjoaa
lataukseen Lauri'n suunnittelutyökaluja kylmälaitesuunnitteluun:
AutoCAD LISP -komennot piirustustyöhön sekä dxf2ifc DXF→IFC4
-konvertteri Solibri-tason BIM-mallin tuottamiseen.

**Sivuston nimi muutettu 2026-05-04**: aiemmin "AutoCAD LISP -työkalut"
→ nyt **"Suunnittelutyökalut"** kun dxf2ifc nostettiin omalle sivulle
ja ei ole enää LISP-only-sivusto. Brand-text topnavissa, title-tagit,
og-tagit ja JSON-LD `WebSite.name` on päivitetty.

- **Tekijä:** Lauri Rekola
- **Käyttäjäkunta:** kylmälaite- ja putkikaaviosuunnittelijat
- **Hosting:** GitHub Pages — `https://mcrauli.github.io/autocad-lisp-ohjeet/`
- **Repo:** `https://github.com/Mcrauli/autocad-lisp-ohjeet`
- **Oletushaara:** `main` (suora push sallittu, ei PR-flowta)

## Sivut

| Tiedosto         | Sisältö                                                    |
|------------------|------------------------------------------------------------|
| `index.html`     | Hero (kicker + h1 "Suunnittelutyökalut" + subtitle) · `.spotlight` dxf2ifc-blokki (amber gradient-border, "BIM-konvertteri · uusi" -badge, "Tutustu projektiin →" -linkki) · `.lisp-heading` divider ("AutoCAD LISP -komennot") · 4 feature-korttia · info-osio + highlight-boksit · footer |
| `ohjeet.html`    | Topnav + sidebar (numeroidut ryhmät) · 7 `.section`-lohkoa: Johdanto · Käyttöönotto · Putkityökalu · Positio · Kaato · Kylmälaitehylly · Usein kysyttyä. Neljä tuotetta (Putki/Positio/Kaato/KLHylly) aloittavat animoidulla SVG-demolla. FAQ käyttää `<details>`-accordionia (`.faq-item` + `.faq-body`, +/− -merkki). |
| `lataukset.html` | Topnav + 3 kuvauskorttia · 4 latauskorttia (LSP- ja DWG-badge, tiedostokoko, "Lataa ↓" -nappi) · footer |
| `dxf2ifc.html`   | Topnav (dxf2ifc aktiivinen) · hero kicker+h1+subtitle · 4 `.block`-lohkoa (Mitä se tekee, Avain-ominaisuudet `.feature-list`, Asennus + `.req-tag`-chipit, `.block.warning` SmartScreen-varoitus) · `.file primary` Setup-installer-latauskortti (WIN/SETUP-badge, GitHub Releases asset-URL pinnattu **v0.1.9-alpha1**:een) · footer. Linkki menee `https://github.com/Mcrauli/dxf2ifc/releases/download/v0.1.9-alpha1/dxf2ifc-Setup-0.1.9a1.exe` (yksi klikki → lataus). |

## Jaetut resurssit

- `style.css` — topnav (brändi, linkit, underline, version), crosshair-
  kulmamerkit, `.site-footer`, `.back-to-top`, `.scroll-progress`,
  `.reveal`, `.toast`, `prefers-reduced-motion`
- `script.js` — scroll-progress-bar, IntersectionObserver-reveal,
  toast() + kytkennät `.file-action[download]`-klikkeihin. Feature-
  detected, no-ops jos DOM puuttuu.
- `favicon.svg` — (λ) amber neliössä
- `apple-touch-icon.png` — 180×180 iOS kotinäyttöikoni, sama λ-aiheinen
  tyyli (generoitu PowerShell System.Drawingilla, fontti Segoe UI Bold)
- `robots.txt`, `sitemap.xml` — github.io-URL pohjalla
- **JSON-LD structured data** (`<script type="application/ld+json">`):
  `index.html` sisältää WebSite + Person + 5 SoftwareApplication -entryä
  (Putkityökalu/Positio/Kaato/Kylmälaitehylly/dxf2ifc) @graph-rakenteessa.
  `ohjeet.html` sisältää FAQPage-schemin FAQ-osion kysymyksistä.
  `dxf2ifc.html` sisältää oman SoftwareApplication-entryn (downloadUrl
  osoittaa GitHub Releases asset-URLiin, ei github.io/files-polkuun).
- `files/` — varsinaiset `.lsp` ja `.dwg` -tiedostot

## Visuaalinen identiteetti

### Värit

| Rooli               | Hex         | Käyttö |
|---------------------|-------------|--------|
| Aksentti (primääri) | `#f59e0b`   | napit, aktiivinen topnav, highlight-border, pivot-merkit, kicker |
| Aksentti (sekundääri) | `#60a5fa` | `<code>`-pätkät ohjeissa, sidebar-numerot, LSP-badge, version-badge |
| Cyan (vain putket)  | `#22d3ee`   | LT IMU (AutoCAD color 4) — **vain** 3PTK-animaatiossa |
| Deep blue (vain putket) | `#3b82f6` | MT IMU (AutoCAD color 5) — **vain** 3PTK-animaatiossa |
| Tausta              | `radial-gradient(circle at top, #0f172a, #020617)` |
| Blueprint-ristikko  | `rgba(148,163,184,0.04)` 40×40px |
| Leipäteksti         | `#e2e8f0` / `#cbd5f5` |
| Heikko teksti       | `#94a3b8` / `#64748b` |

**Tärkeää:** Värit eivät saa muuttua ilman keskustelua. Jos tarvitaan
uusi aksentti jossakin, mieti ensin voiko käyttää jo olemassa olevaa.

### Fontit (ladataan Google Fontsista, importti jokaisessa HTML:ssä)

- **Inter** 400/500/600/700 — leipäteksti, napit
- **Space Grotesk** 500/600/700 — kaikki otsikot ja brand
- **JetBrains Mono** 500 — koodit, versiot, numerot, labels
- Body käyttää `font-feature-settings: "cv11", "ss01", "ss03"`

### Typografinen hierarkia

- H1: Space Grotesk 700, `letter-spacing: -0.02em`, `line-height: 1.15`
- H2: Space Grotesk 600, `letter-spacing: -0.01em`, `line-height: 1.3`
- Paragrafit: `line-height: 1.75`, max-width `62ch` info-osiossa

### Toistuvat patternit

- **Blueprint-ruudukko** body-taustalla kaikkialla (40×40 px, 4% opacity)
- **Kulma-crosshairit** (`<span class="crosshair tl/tr/bl/br">`) — neljä
  amber "+"-merkkiä sivun nurkissa, yläkulmat topnavin alapuolella
  (78px top). Piilossa <600px.
- **Topnav** — kiinteä, blurred: `(λ)`-brand vasemmalla, linkit
  keskellä animoidulla alaviivalla, `v1.1` oikealla (cyan
  JetBrains Mono, mobiilissa piilossa)
- **Mobile TOC dropdown** (vain `ohjeet.html`, vain <900px):
  chevron-nappi `(▾)` "Ohjeet"-linkin vieressä topnavissa avaa
  alasvetovalikon (`#mobile-toc`) joka sisältää sidebarin
  `.menu`-rakenteen kopion (3 ryhmää, numeroidut linkit). Käyttää
  desktop `.menu`-tyylejä suoraan — mobile breakpoint piilottaa
  `.sidebar` kokonaan, joten ei chip-rivi-CSS:ää joka tarvitsisi
  override:a mobile-tocissa. Sulkeminen: linkin klikkaus, ESC,
  ulkopuolen klikkaus, resize ≥900px. Scroll-spy `.menu a`
  -selektori valaisee active-tilan sekä desktop-sidebarin että
  mobile-tocin linkkeihin samanaikaisesti.
- **Footer** — `© 2026 Lauri Rekola`, heikko erotinviiva yläpuolella
- **Section bead** (vain ohjeet.html): viivojen välissä hehkuva amber
  pallo. Huom: käytä aina `.section + .section` -selektoria, EI
  `:first-child`, koska h1 on wrapperin ensimmäinen lapsi.
- **`.block:has(code)`** — terminaali-chrome (3 slate-pistettä +
  "commands.lsp") automaattisesti jokaiselle blokille jossa on
  `<code>`.

## Animaatiot

Neljä puhtaasti CSS:llä tehtyä SVG-animaatiota ohjeissa. Jokainen 6s
looppi, respektoi `prefers-reduced-motion`:

1. **3PTK** (Putkityökalu) — kolme viivaa (cyan LT IMU, amber MT
   NESTE, blue MT IMU) piirtyvät start→end. Värit matchaavat
   `files/putkityokalu.lsp`:n `make-layer` -komentojen colorindexit
   (4, 42, 5). Vertikaalinen järjestys vastaa LISP vecL/vecR -logiikkaa
   vasen→oikea-piirtovektorilla.
2. **POSITIO** — viisi numeroitua amber-outline-palloa pop-in-
   sekvenssinä scattered-pisteissä. (Työkalun nimi muutettu
   NPALLOsta POSITIOon LSP-lähdön myötä; komento nyt `POSITIO`,
   `ASETANUMERO` ennallaan. CSS-luokat `.positio-demo__*`.)
3. **KAATO3D** — sininen palkki kaatuu 6° amber-pivotilta,
   dashed-viiva näyttää alkuperäisen asennon. Käyttää
   `transform-box: view-box` (muuten SVG-transform-origin ei toimi).
4. **KLHYLLY** — LEVY-tyyppinen demo: p1 amber-pallo → p2 amber-pallo
   → dashed length-axis piirtyy → sininen shelf-outline traceytyy
   stroke-dashoffsetillä (perimeter 760) → DASH-hatch-pattern
   (`<pattern>` 45° kulmassa) täyttyy → label "LEVY · 400" fadaa.
   Käyttää sekundääristä sinistä (`#60a5fa`), ei uutta väriä. Omat
   `@keyframes klhylly-*` koska vaiheet tarvitsevat yksilölliset
   delay-sekvenssit yhden 6s duration:n sisällä (animation-delay
   katkaisisi syklin).

Yhteinen CSS: `.pipe-demo-block` wrapper + `.pipe-demo-caption`
(amber pallo + "Command: XXX").

## Content-rakenne

- **index hero:** kicker (`Kylmälaitesuunnittelu · v1.0`, amber
  JetBrains Mono uppercase) → h1 → subtitle (slate, 17px) → alkuperäinen
  kuvausteksti. Ei nappeja hero:ssa — feature-kortit ja topnav
  riittää CTA:ksi.
- **CAD backdrop** hero:n takana: dimensio-viiva "1000 mm" yläreunassa,
  compass rose yläoikealla, häipynyt iso (λ) keskellä. EI scale
  baria (pidetty kevyenä) eikä mini-terminaalia (käyttäjän pyynnöstä).
- **Feature cards** — 3-column grid, sininen badge (PUTKI / MERKINTÄ /
  3D), amber otsikko, kuvaus, "Katso ohjeet →" -linkki. Linkittävät
  `ohjeet.html#putket` / `#positio` / `#kaato` / `#klhylly` -ankkureihin.
- **TIETOA-kicker** info-osion yläpuolella (cyan, pieni uppercase).

## Kehitys ja testaus

### Paikallinen serveri (file:// ei toimi fonttien kanssa)

```bash
cd /c/Users/LauriRekola/work/autocad-lisp-ohjeet
npx --yes http-server -p 8765 -s
```

Pysäytys: `taskkill //F //PID $(netstat -ano | grep ":8765" | awk '{print $5}' | head -1)`

### Playwright-screenshotit

Cache-busting on tärkeä — selain cachettaa CSS:ää. Käytä
`?v=N`-parametria URLissa kun tarkistat muutoksia:

```
http://localhost:8765/index.html?v=17
```

Tai nosta `style.css?v=N` ja `script.js?v=N` kaikissa kolmessa
HTML:ssä. Nykyiset versionumerot: `style.css?v=3`, `script.js?v=2`.

Animoitujen elementtien screenshot: pysäytä CSS-animaatio
`element.style.animationPlayState = 'paused'` ja tarvittaessa pakota
lopputila manuaalisesti, muuten kuva osuu usein fade-hetkeen.

### Git ja deployment

- Push suoraan mainiin (ei PR-reviewtä, käyttäjä on antanut
  permission `~/.claude/settings.json` -asetuksiin)
- Commit-viestit: englanniksi, imperatiivi, ja `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer
- GitHub Pages deployaa automaattisesti mainista ~1 min kuluttua
- Hidas CI-prosessi — älä yritä force-reloadata heti pushin jälkeen

## Tekijän preferenssit

- Puhuu suomea (sinuttelu, informaali tyyli)
- Haluaa **action yli planauksen** — auto-mode päällä
- Haluaa nähdä toteutuksen heti, ei pitkiä design-dokumentteja
- Pitää iteratiivisista parannuksista — pienet palautesilmukat
- Ei halua GitHub-linkkiä footeriin eikä muualla
- Hyväksyy terminaali-tyyliset chrome-detaljit ja tekniset
  CAD-viittaukset. Ei liikaa "hipster dev" -tyyliä (esim. macOS
  RGB-pisteet → slate-värisiksi).

## Mitä on tehty (tiivistelmä commiteista)

1. Typografia + välistykset + hover-polish + mobiilisidebar (ohjeet)
2. Footer + blueprint-tausta
3. Vaihto amber + cyan -palettiin, (λ) brand, v1.0-badge, sidebar-
   numerointi + ryhmät, favicon, meta-tagit
4. Kulma-crosshairit, hero-lambda, gradient-borderit, section bead,
   terminal chrome, download-kortit, typografian feature-settings
5. "Lataa"-nappi rajaa latauksen vain nappiin (ei koko korttiin)
6. 3PTK-animaatio, NPALLO-animaatio, KAATO3D-animaatio — matchaavat
   LISP-lähdekoodin värit ja logiikan
7. Hero-kicker + subtitle + CAD-backdrop (ei scale baria, ei
   mini-terminaalia käyttäjän palautteen jälkeen)
8. Jaettu `style.css` + `script.js`, scroll-progress, scroll-
   reveal-animaatiot, toast-järjestelmä, robots/sitemap
9. FAQ-osio ohjeet-sivulle (`<details>`-accordion): C:\AutoCADLisp
   -kansio + Trusted Locations, Startup Suite, LT ei tue LISPiä,
   komennon etsintä-vianhaku. Uusi sidebar-ryhmä "Lisätietoa".
10. Apple touch icon (180×180 PNG) + JSON-LD structured data:
    index.html:n WebSite + 3 SoftwareApplication -entryä,
    ohjeet.html:n FAQPage FAQ-osion kysymyksistä.
11. KLHYLLY-työkalu lisätty kaikille sivuille: ohjeet-section
    animoidulla SVG-demolla (LEVY-tyyppi, DASH-hatch-pattern),
    sidebar-linkki, FAQ-entry LEVY/TIKAS-erosta, index feature-card
    (4-col grid) + SoftwareApplication JSON-LD, lataukset .block
    + LSP-latauskortti (klhylly.lsp 15.8 KB).
12. Mobile TOC dropdown ohjeet-sivulle: chevron-nappi "Ohjeet"-linkin
    vieressä avaa fixed-positioidun alasvetovalikon mobiilissa
    (<900px). Aiempi sidebar-chip-rivi piilotettiin koska dropdown
    kattaa saman tarpeen ja chip-rivi olisi duplikaatti. Scroll-spy
    laajeni automaattisesti molemmille (`.menu a` matchaa desktop-
    sidebarin ja mobile-tocin linkit). Versionumero v1.0 → v1.1.
13. **dxf2ifc-projektisivu** lisätty (`dxf2ifc.html`) v0.1.8-alpha1
    Setup-installerin ja standalone-exe:n latauskorteilla. Linkit
    osoittavat suoraan GitHub Releases asset-URLeihin
    (`releases/download/v0.1.8-alpha1/...`) — yksi klikki → lataus.
    Topnav laajennettu 4 linkkiin kaikilla 4 sivulla, version v1.1
    → v1.2. Uusi `.feature-list` (▸-bullet, sininen), `.req-tag`-chipit
    järjestelmävaatimuksille, `.block.warning` SmartScreen-varoitukselle
    (amber vasen reuna). SoftwareApplication JSON-LD lisätty etusivun
    `@graph`:iin (5 entryä) sekä omana documenttina dxf2ifc.html:ssä.
    Sitemap.xml päivitetty.
15. **Sivun pinnaus v0.1.9-alpha1:een**: dxf2ifc-softan "Help → Käyttöohjeet"
    -menulinkki avaa nyt automaattisesti tämän sivun selaimessa, ja
    About-dialogissa on linkki samaan sivuun. Sivun lataus-URL bumpattu
    Setup-installerille (v0.1.8a1 → v0.1.9a1) sekä index.html:n
    SoftwareApplication-JSON-LD:n softwareVersion + downloadUrl.

16. **Sivun pinnaus v0.1.10-alpha1:een**: itsepäivityksen "Failed to start
    embedded python interpreter" -bootloader-bugi korjattu (3 s viive
    PowerShell-launcherilla + SHA-256-sidecar-verifiointi). Help-menun
    "Käyttöohjeet (selain)" -duplikaatti-action poistettu (About-dialogi
    riittää). dxf2ifc.html lataus-URL + index.html JSON-LD bumpattu
    Setup-installerille v0.1.9a1 → v0.1.10a1.

17. **positio.lsp portable + ZIP-paketti**: hardkoodattu polku
    `C:\Users\LauriRekola\CAD_LISP\positio.dwg` poistettu LSP:stä; uusi
    `positio-find-block-file` etsii DWG:n ensin Support Pathilta ja sitten
    samasta kansiosta josta `positio.lsp` ladattiin (haetaan APPLOADin
    `HKCU\...\Dialogs\Appload`-rekisterin MRU-arvoista). Tukee scenario:
    pura ZIP yhteen kansioon → APPLOAD → POSITIO toimii ilman OPTIONS-
    asetuksia. Lataus-sivulle uusi `.file.primary`-korostettu ZIP-kortti
    "Kaikki työkalut" (`files/suunnittelutyokalut.zip` 32.8 KB, sisältö
    4 LSP + positio.dwg). Repo-juuressa `make-bundle.ps1` rebuild-skripti
    joka ajetaan kun LSP/DWG muuttuu. Ohjeet-sivulle uusi FAQ-entry
    "POSITIO antaa virheen 'positio.dwg ei löydy'" + Käyttöönotto-osion
    huomautus + JSON-LD FAQPage-entry. Topnav v1.2 → v1.3.

14. **Sivuston rebrand + selkokielistys**:
    - Brand "AutoCAD LISP" → **"Suunnittelutyökalut"** kaikilla 4 sivulla
      (topnav, title-tagit, og-tagit, JSON-LD WebSite.name, etusivun h1).
    - Etusivulle uusi `.spotlight`-blokki dxf2ifc:lle (amber gradient
      border, isompi badge ja CTA, ennen LISP-feature-korttirivi:ä).
      LISP-cards saavat oman `.lisp-heading`-erottimen.
    - dxf2ifc.html: standalone-exe-latauskortti poistettu (Setup-only),
      Talo2000-maininnat poistettu (kylmälaitehomma käyttää vain RAVA3Pro:ta),
      ETRS-TM35FIN georeferointi -maininta poistettu (ei käyttäjälle
      relevantti). "Mitä se tekee" + "Avain-ominaisuudet" kirjoitettu
      uudelleen selkokielisesti — pois jargon ("FI_*-PSetit",
      "headless ACIS-tessellaatio", "RAVA-LVI/RAVA-TATE single-classification")
      ja sisään käyttäjäkohtainen kuvaus (mitä Solibrissa näkyy, mitä
      AutoCADissa tapahtuu).

18. **KLHYLLY → parametrinen dynamic block**: `files/klhylly.lsp` ei enää
    UNION:oi 5 slabia (LEVY) tai 2 kiskoa + N rungia (TIKAS) yhdeksi
    3DSOLIDiksi vaan INSERT:ää valmiit dynamic blockit uudesta
    `files/klhylly.dwg`-block-kirjastosta. Block-määritykset (`KLHYLLY-LEVY`,
    `KLHYLLY-TIKAS`) sisältävät Linear-parametrit Pituus (continuous) ja
    Leveys (Value Set = List 300/400/500), plus stretch-action-pareja ja
    TIKAS:lle Array-action joka arrayttaa rung-master:n 250 mm askeleella
    automaattisesti. KLHYLLYV käyttää samaa KLHYLLY-TIKAS-blockia ja
    soveltaa `vla-TransformBy` 4×4-matriisin haluttuun 3D-orientaatioon.
    KORKO (ent. HYLLYKORKO) toimii edelleen samalla pohjaperiaatteella —
    siirtää valitut kohteet MOVE-pohjaisesti annetulle Z:lle. Refaktoroitu
    käyttämään INSERT-pisteen Z:tä referenssinä INSERT-entiteeteille
    (AutoCAD-yhdenmukainen) ja bbox-min Z:tä muille (3DSOLID/REGION).
    - **Riippuvuus:** klhylly.lsp tarvitsee rinnalleen kaksi DWG:tä:
      `klhylly-levy.dwg` ja `klhylly-tikas.dwg`. Erilliset DWG:t per
      blocki välttää AutoCAD:n "Block X references itself" -virheet
      jotka voivat syntyä kun molemmat blockit ovat samassa lähde-DWG:ssä
      ja käyttäjän BEDIT-historia jättää orphan-referenssejä. Locator-
      pattern (`klhylly-self-folder` + `klhylly-find-block-file dwgName`)
      on kopioitu positio.lsp:stä `klhylly-`-prefiksillä.
    - **Block-kirjastojen rakentaminen:** `tools/build-klhylly-blocks.lsp`
      tarjoaa kaksi komentoa: `KLHYLLY-BUILD-LEVY` ja `KLHYLLY-BUILD-TIKAS`,
      jotka ajetaan erikseen tyhjissä DWG:issä. LEVY: 5 LWPOLYLINEa
      thickness:lla + 3DFACE pohjalle + outline + DASH-hatch.
      TIKAS: 2 rail + 1 rung-master + 3 3DFACEa ylakansiksi.
      Kaikki layerilla 0/BYBLOCK. Manuaalinen BEDIT lisää Linear-parametrit
      ja Stretch/Array-actionit step-by-step ohjeen
      `tools/KLHYLLY-BEDIT-OHJEET.md` mukaan. Lopuksi ERASE ALL + SAVEAS
      omiin DWG-tiedostoihin. Helper ei sisälly ZIP-pakettiin — vain
      files/-kansion sisältö.
    - **Geometria-valinta — KRIITTINEN:** block-määrityksessä geometria on
      **2D-LWPOLYLINEja joilla thickness** (Z-extrudointi vertikaalisesti),
      EI 3D-soliditeetteja. Syy: AutoCAD:n dynamic blockin stretch-action
      EI stretchaa 3D-soliditeetteja luotettavasti vaikka olisivat
      akseliyhdensuuntaisia primitiivi-BOXeja (testissa 5.5.2026: hatch +
      outline venyivät, mutta 5 BOX-soliditeettia jäivät paikalleen oikealla).
      Polyline+thickness rendaa visuaalisesti kuten ohut 3D-laatikko
      (4 pystyseinämää, ei ylä-/alapintaa) — peltihyllyssä thickness 1.25 mm
      tekee top/bottom näkymättömiksi. "Yks klikki valitsee" -ominaisuus
      säilyy block-instanssin kautta (yksi entiteetti vaikka sisällä on
      monta polylinea).
    - **dxf2ifc-yhteensovitus:** `~/dxf2ifc/src/dxf2ifc/core/preprocessing.py`
      Phase 2 INSERT-räjäytys-filteri laajennettu `KLHYLLY-*`:llä
      (`*yrystin*,*ahdutin*,*pressori*,KLHYLLY-*`) jotta klhylly-blockien
      sisältö (BOX-solidit) räjähtää ja tulee STL-louhituksi.
      `mapper.py`:n layer-pattern-säännöt (`KYL-LEVYHYLLY*`, `KYL-TIKASHYLLY*`)
      tunnistavat lopputuloksen → IfcCableCarrierSegment + CABLELADDERSEGMENT
      / CABLETRAYSEGMENT, sama IFC-lopputulos kuin ennen.
    - **Backward compat:** vanhat UNION-pohjaiset hyllyt eivät automaattisesti
      muutu parametrisiksi; piirustukset säilyttävät visuaalisen identtisyyden.
      Ei migraatio-työkalua (YAGNI).
    - Sivustolle: KLHYLLY-osioon "Muokkaaminen jälkikäteen" -block, kaksi
      uutta FAQ-entryä (klhylly.dwg-puuttuu-virhe, miksi vanha hylly ei
      muokkaannu), JSON-LD FAQPage päivitetty. Lataukset-sivulle uusi
      DWG-latauskortti klhylly.dwg:lle, ZIP-meta päivitetty 4 LSP + 2 DWG.

## Ideoita tulevaisuuteen (vielä pöydällä)

- **Kopioi-nappi `<code>`-pätkille** ohjeissa + toast-feedback.
  Järjestelmä ja toast-helperi on jo olemassa scriptissä.
- **Print-stylesheet** ohjeille (Ctrl+P → siisti manuaali)
- **Oikea screen-recording -GIF/MP4** AutoCADista SVG-animaatioiden
  rinnalle tai tilalle. SVG-wrapperin vaihtaminen `<video>`ksi on
  pieni työ.
- **Changelog / muutokset.html** — versiotiedot näkyville

## Tärkeimmät rajat

- **Ei uusia fontteja** — kolme riittää
- **Ei uusia aksenttivärejä** — amber + sininen, cyan/deep-blue
  varattu putket-animaatiolle
- **Ei JS-frameworkkiä** — staattinen sivu, puhdas CSS + vanilla JS
- **Ei tracking-scriptejä, analytics, yms.**
- **CLAUDE.md on aina ajantasalla** — jos teet isomman muutoksen,
  päivitä tätä tiedostoa samassa commitissa
