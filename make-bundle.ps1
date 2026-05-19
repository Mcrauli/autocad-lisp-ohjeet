# make-bundle.ps1 — Build files/suunnittelutyokalut.zip for distribution.
#
# ZIP-rakenne loppukayttajalle:
#   suunnittelutyokalut.zip
#   ├── Asenna.cmd              (kaksoisklikkaa tata)
#   ├── Asenna.ps1              (varsinainen asennus)
#   ├── LUEMINUT.txt            (kayttoohje)
#   ├── Tools/                  (LSP + DWG, asentuu %APPDATA%\Radika\Tools\)
#   │   ├── *.lsp  (9 tyokalua)
#   │   └── *.dwg  (block-kirjastot LSP-INSERT-komennoille)
#   └── RadikaTools.bundle/     (asentuu ApplicationPlugins-kansioon CUIX-ribbonia varten)
#       ├── PackageContents.xml
#       └── Contents/
#           ├── radika-tools.cuix
#           └── icons/*.png
#
# Asentaja:
#   - Kopioi Tools/* polkuun %APPDATA%\Radika\Tools\
#   - Kirjoittaa acaddoc.lsp molempien CAD:ien Support-kansioihin
#     (acaddoc.lsp lataa LSP:t %APPDATA%\Radika\Tools\:sta — SECURELOAD ei
#      estä koska acaddoc.lsp asuu CAD:n omassa Support-kansiossa, joka on
#      implicitly trusted)
#   - Kopioi bundle:n ApplicationPlugins-kansioon ribbon-CUIX:ia varten
#
# Miksi LSP/DWG ei ole bundle:ssa:
#   Yritys autoloadata LSP:ita bundle:sta tormaa AutoCAD:n SECURELOAD-
#   esto:on (per-user TRUSTEDPATHS-rekisteri). acaddoc.lsp Support-kansiossa
#   ohittaa taman koko ongelman, joten LSP/DWG asetetaan neutraaliin
#   %APPDATA%\Radika\Tools\-polkuun ja bundle keskittyy vain ribbonin
#   CUIX:in autoloadaamiseen (CUIX ei kuulu SECURELOAD-piiriin).

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$repoRoot = (Get-Location).Path
$filesDir = Join-Path $repoRoot 'files'
$iconsDir = Join-Path $filesDir 'icons'
$installerDir = Join-Path $repoRoot 'installer'
$out = 'files/suunnittelutyokalut.zip'

# Staging area
$staging        = Join-Path ([System.IO.Path]::GetTempPath()) ('radika-bundle-' + [Guid]::NewGuid().ToString('N'))
$toolsStaging   = Join-Path $staging 'Tools'
$bundleDir      = Join-Path $staging 'RadikaTools.bundle'
$contentsDir    = Join-Path $bundleDir 'Contents'
$bundleIconsDir = Join-Path $contentsDir 'icons'

New-Item -ItemType Directory -Path $toolsStaging   | Out-Null
New-Item -ItemType Directory -Path $bundleDir      | Out-Null
New-Item -ItemType Directory -Path $contentsDir    | Out-Null
New-Item -ItemType Directory -Path $bundleIconsDir | Out-Null

# ============================================================
# Tools/ — LSP + DWG (neutraali install-paketti)
# ============================================================
$lspFiles = @('hoyrystin.lsp','kaato.lsp','klhylly.lsp','positio.lsp',
              'putkityokalu.lsp','varusteet.lsp',
              'kotelo.lsp','koneikko.lsp','lauhdutin.lsp')
foreach ($f in $lspFiles) {
  Copy-Item (Join-Path $filesDir $f) $toolsStaging -Force
}

# DWG:t — kaikki paitsi vputki* ja klhylly-tikaspp* (legacy/arkisto)
Get-ChildItem -LiteralPath $filesDir -Filter '*.dwg' | Where-Object {
  $_.Name -notmatch '^vputki' -and $_.Name -notmatch '^klhylly-tikaspp'
} | ForEach-Object {
  Copy-Item $_.FullName $toolsStaging -Force
}

# ============================================================
# RadikaTools.bundle/ — vain CUIX-ribbon + ikonit
# ============================================================
# Ribbon (CUIX)
Copy-Item (Join-Path $filesDir 'radika-tools.cuix') $contentsDir -Force

# Icons — CUIX viittaa underscore-nimilla, normalisoidaan
Get-ChildItem -LiteralPath $iconsDir -Filter '*.png' | ForEach-Object {
  $dst = Join-Path $bundleIconsDir ($_.Name -replace '-','_')
  Copy-Item $_.FullName $dst -Force
}

# PackageContents.xml — vain CUIX-component, ei LSP-entrya
# Bundle:n CUIX latautuu autoloader:lla, ei tarvitse TRUSTEDPATHS-asetusta.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$pkg = @"
<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0"
                    ProductType="Application"
                    AutodeskProduct="AutoCAD"
                    ProductCode="{7A2B1E4F-3C5D-4E6F-8A9B-1C2D3E4F5A6B}"
                    UpgradeCode="{5F9E8D7C-6B5A-4938-8271-6F5E4D3C2B1A}"
                    Name="RadikaTools"
                    Description="Kylmalaite-suunnittelun Radika-ribbon"
                    Author="Lauri Rekola"
                    Helpfile="https://mcrauli.github.io/autocad-lisp-ohjeet/"
                    AppVersion="1.1.0"
                    FriendlyVersion="1.1.0"
                    SupportedLocales="*"
                    Icon="./Contents/icons/klh_32.png">
  <CompanyDetails Name="Lauri Rekola" />
  <RuntimeRequirements OS="Win32|Win64" Platform="AutoCAD*" SeriesMin="R23.0" SeriesMax="R25.0" />
  <Components Description="Radika-ribbon">
    <ComponentEntry AppName="RadikaTools-CUIX" Version="1.1.0"
                    ModuleName="./Contents/radika-tools.cuix"
                    AppDescription="Radika-ribbon (kylmalaite-tyokalut)" />
  </Components>
</ApplicationPackage>
"@
[System.IO.File]::WriteAllText((Join-Path $bundleDir 'PackageContents.xml'), $pkg, $utf8NoBom)

# ============================================================
# Asentaja + lueminut ZIP-juureen
# ============================================================
Copy-Item (Join-Path $installerDir 'Asenna.cmd') $staging -Force
Copy-Item (Join-Path $installerDir 'Asenna.ps1') $staging -Force

$readme = @"
RadikaTools — AutoCAD/BricsCAD LISP-tyokalut + Radika-ribbon
=============================================================

ASENNUS:
  1. Pura tama ZIP minne tahansa kansioon
  2. Kaksoisklikkaa Asenna.cmd
  3. Skripti tunnistaa AutoCAD:n ja/tai BricsCAD:n ja asentaa molempiin
  4. Kaynnista CAD uudelleen

KAYTTO:
  Komennot toimivat suoraan komentorivilta jokaisessa piirustuksessa:

    KLH KLHV KOTELO KORKO     - hyllyt ja kotelot
    MTI LTI MTN               - putket
    HOYRYSTIN KONEIKKO        - kylmakoneikko-laitteet
    LAUHDUTIN                 -   "    "
    POSITIO ASETANUMERO       - merkinta
    KAATO VARUSTEET           - apuvalineet (sahkokomponentit)

  AutoCAD:lla Radika-ribbon-valilehti ilmestyy automaattisesti.

  BricsCAD:lla ribbon vaatii kerran:
    1. Komentoriville: CUILOAD
    2. Browse -> kirjoita radika-tools.cuix
    3. Load -> Close
    Tab pysyy nakyvilla seuraavissa sessioissa.

PAIVITYS:
  Lataa uusi ZIP, aja Asenna.cmd uudelleen. Idempotentti.

POISTO:
  Poista kansiot:
    %APPDATA%\Radika\Tools
    %APPDATA%\Autodesk\ApplicationPlugins\RadikaTools.bundle
  Ja CAD:ien Support-kansiosta tiedostot:
    acaddoc.lsp, on_doc_load.lsp, radika-tools.cuix, Icons\*

DOKUMENTAATIO:
  https://mcrauli.github.io/autocad-lisp-ohjeet/
"@
[System.IO.File]::WriteAllText((Join-Path $staging 'LUEMINUT.txt'), $readme, $utf8NoBom)

# ============================================================
# Pakkaa ZIP
# ============================================================
if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $out -CompressionLevel Optimal

Remove-Item -LiteralPath $staging -Recurse -Force

$z = Get-Item $out
'{0}  {1:N1} KB  (asentaja + Tools + ribbon-bundle)' -f $z.Name, ($z.Length / 1KB)
