# AutoCAD LISP -työkalut — projektimuistio

Tämä tiedosto on Claudelle. Lue tämä aina kun jatkat sivustoa, niin
pääset nopeasti kiinni kontekstiin ja vältyt menemästä väärään
suuntaan.

## Mikä tämä on

Staattinen kolmen sivun HTML-sivusto joka esittelee ja tarjoaa
lataukseen Laurin kirjoittamia AutoCAD LISP -työkaluja.

- **Tekijä:** Lauri Rekola
- **Käyttäjäkunta:** kylmälaite- ja putkikaaviosuunnittelijat
- **Hosting:** GitHub Pages — `https://mcrauli.github.io/autocad-lisp-ohjeet/`
- **Repo:** `https://github.com/Mcrauli/autocad-lisp-ohjeet`
- **Oletushaara:** `main` (suora push sallittu, ei PR-flowta)

## Sivut

| Tiedosto         | Sisältö                                                    |
|------------------|------------------------------------------------------------|
| `index.html`     | Hero (kicker + h1 + subtitle + teksti) · 3 feature-korttia · info-osio + highlight-boksit · footer |
| `ohjeet.html`    | Topnav + sidebar (numeroidut ryhmät) · 7 `.section`-lohkoa: Johdanto · Käyttöönotto · Putkityökalu · Positio · Kaato · Kylmälaitehylly · Usein kysyttyä. Neljä tuotetta (Putki/Positio/Kaato/KLHylly) aloittavat animoidulla SVG-demolla. FAQ käyttää `<details>`-accordionia (`.faq-item` + `.faq-body`, +/− -merkki). |
| `lataukset.html` | Topnav + 3 kuvauskorttia · 4 latauskorttia (LSP- ja DWG-badge, tiedostokoko, "Lataa ↓" -nappi) · footer |

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
  `index.html` sisältää WebSite + Person + 4 SoftwareApplication -entryä
  (Putkityökalu/Positio/Kaato/Kylmälaitehylly) @graph-rakenteessa.
  `ohjeet.html` sisältää FAQPage-schemin FAQ-osion kysymyksistä.
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
  `.menu`-rakenteen kopion (3 ryhmää, numeroidut linkit). CSS
  override mediakyselyn sisällä palauttaa vertical-tyylin koska
  `.menu` muutoin saisi chip-rivi-tyylin samassa breakpointissa.
  Sulkeminen: linkin klikkaus, ESC, ulkopuolen klikkaus, resize
  ≥900px. Scroll-spy `.menu a` -selektori valaisee active-tilan
  sekä sidebarin että mobile-tocin linkkeihin samanaikaisesti.
  Chip-rivi mobiilissa pysyi entisellään.
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
    (<900px). Sidebar-chip-rivi pysyi entisellään. Scroll-spy
    laajeni automaattisesti molemmille (`.menu a` matchaa kumpaankin).
    Versionumero topnavissa nostettu v1.0 → v1.1.

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
