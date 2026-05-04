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
