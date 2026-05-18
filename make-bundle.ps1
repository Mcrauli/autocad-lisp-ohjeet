# Build files/suunnittelutyokalut.zip as an AutoCAD/BricsCAD plug-in bundle.
#
# End-user install:
#   1. Lataa ja pura ZIP
#   2. Raahaa RadikaTools.bundle -kansio:
#      %APPDATA%\Autodesk\ApplicationPlugins\
#   3. Kaynnista AutoCAD -> ribbon + LSPit latautuvat automaattisesti
#
# No APPLOAD, no CUILOAD, no scripts.
#
# Bundle structure produced:
#   RadikaTools.bundle/
#   ├── PackageContents.xml
#   └── Contents/
#       ├── radika-tools.cuix     (ribbon)
#       ├── _loader.lsp           (autoloader)
#       ├── *.lsp                 (9 LSP tools)
#       ├── *.dwg                 (block DWGs the LSPs INSERT)
#       └── icons/                (PNG icons with underscore naming)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$repoRoot = (Get-Location).Path
$filesDir = Join-Path $repoRoot 'files'
$iconsDir = Join-Path $filesDir 'icons'
$out      = 'files/suunnittelutyokalut.zip'

# Staging area we ZIP up
$staging        = Join-Path ([System.IO.Path]::GetTempPath()) ('radika-bundle-' + [Guid]::NewGuid().ToString('N'))
$bundleDir      = Join-Path $staging 'RadikaTools.bundle'
$contentsDir    = Join-Path $bundleDir 'Contents'
$bundleIconsDir = Join-Path $contentsDir 'icons'

New-Item -ItemType Directory -Path $bundleDir      | Out-Null
New-Item -ItemType Directory -Path $contentsDir    | Out-Null
New-Item -ItemType Directory -Path $bundleIconsDir | Out-Null

# 9 LSP tools auto-loaded by _loader.lsp
$lspFiles = @('hoyrystin.lsp','kaato.lsp','klhylly.lsp','positio.lsp',
              'putkityokalu.lsp','varusteet.lsp',
              'kotelo.lsp','koneikko.lsp','lauhdutin.lsp')
foreach ($f in $lspFiles) {
  Copy-Item (Join-Path $filesDir $f) $contentsDir -Force
}

# DWGs — kaikki paitsi vputki* (poistettu kaytosta) ja klhylly-tikaspp* (legacy)
Get-ChildItem -LiteralPath $filesDir -Filter '*.dwg' | Where-Object {
  $_.Name -notmatch '^vputki' -and $_.Name -notmatch '^klhylly-tikaspp'
} | ForEach-Object {
  Copy-Item $_.FullName $contentsDir -Force
}

# Ribbon (CUIX)
Copy-Item (Join-Path $filesDir 'radika-tools.cuix') $contentsDir -Force

# Icons — CUIX viittaa underscore-nimilla (klh_snapk_32.png) sisaisesti,
# pidetaan sama konventio bundlen icons/ -kansiossa Support-haun varalle.
Get-ChildItem -LiteralPath $iconsDir -Filter '*.png' | ForEach-Object {
  $dst = Join-Path $bundleIconsDir ($_.Name -replace '-','_')
  Copy-Item $_.FullName $dst -Force
}

# PackageContents.xml — kertoo AutoCADille mita ladata.
# - Jokainen LSP omana ComponentEntry-rivina (LoadOnAutoCADStartup="True")
#   jotta AutoCAD lataa ne suoraan full path:lla, ei findfile-tempun kautta.
# - CUIX-rivi sisaltaa MenuGroup-attribuutin jotta AutoCAD tietaa kayttaa
#   sita partial-CUI:na ja ribbon-valilehti ilmestyy.
# - ProductCode = pysyva GUID taman paketin identifierina (sama paivityksissakin).
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Build LSP ComponentEntries dynamically
$lspEntries = ($lspFiles | ForEach-Object {
  $appName = ($_ -replace '\.lsp$','')
  "    <ComponentEntry AppName=`"RadikaTools-$appName`" Version=`"1.0.0`" ModuleName=`"./Contents/$_`" AppType=`".lsp`" LoadOnAutoCADStartup=`"True`" />"
}) -join "`r`n"

$pkg = @"
<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0"
                    ProductType="Application"
                    AutodeskProduct="AutoCAD"
                    ProductCode="{7A2B1E4F-3C5D-4E6F-8A9B-1C2D3E4F5A6B}"
                    UpgradeCode="{5F9E8D7C-6B5A-4938-8271-6F5E4D3C2B1A}"
                    Name="RadikaTools"
                    Description="Kylmalaite-suunnittelun LISP-tyokalut + Radika-ribbon"
                    Author="Lauri Rekola"
                    Helpfile="https://mcrauli.github.io/autocad-lisp-ohjeet/"
                    AppVersion="1.0.0"
                    FriendlyVersion="1.0.0"
                    SupportedLocales="*"
                    Icon="./Contents/icons/klh_32.png">
  <CompanyDetails Name="Lauri Rekola" />
  <!-- RuntimeRequirements pitaa olla ApplicationPackage:n lapsena, EI
       Components:n sisalla. Toimivat Autodesk-bundlet (esim. App Manager)
       seuraavat tata. Vaarin sijoitettuna AutoCAD hylkaa koko bundlen. -->
  <RuntimeRequirements OS="Win32|Win64" Platform="AutoCAD*" SeriesMin="R23.0" SeriesMax="R25.0" />
  <Components Description="Radika ribbon + LSP-tyokalut">
    <!-- SupportPath lisaa Contents/ ja Contents/icons/ AutoCAD:n support
         file search path:iin niin etta:
           - CUIX loytaa ikonit pelkalla nimella (klh_32.png)
           - LSP findfile loytaa Kotelo.dwg / Koneikko.dwg / Lauhdutin.dwg
             yms. blokit joita LSP-komennot INSERT:aavat
         Ilman tata LSP:t lataavat mutta kaatuvat ekassa komennossa kun
         block-haku ei loyda DWG:ta (FILEDIA/CMDDIA jaavat 0:lle). -->
    <RuntimeRequirements SupportPath="./Contents;./Contents/icons" OS="Win32|Win64" Platform="AutoCAD*" />
    <!-- CUIX: Autodeskin omat ribbon-bundlet eivat kayta AppType/MenuGroup
         -attribuutteja taalla — AutoCAD tunnistaa CUIX:n paatteesta ja
         lukee MenuGroup-nimen CUIX-tiedoston sisalta. -->
    <ComponentEntry AppName="RadikaTools-CUIX" Version="1.0.0"
                    ModuleName="./Contents/radika-tools.cuix"
                    AppDescription="Radika-ribbon (kylmalaite-tyokalut)" />
$lspEntries
  </Components>
</ApplicationPackage>
"@
[System.IO.File]::WriteAllText((Join-Path $bundleDir 'PackageContents.xml'), $pkg, $utf8NoBom)

# Pakkaa: ZIP-paketin juuressa on RadikaTools.bundle -kansio.
if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }
Compress-Archive -Path $bundleDir -DestinationPath $out -CompressionLevel Optimal

Remove-Item -LiteralPath $staging -Recurse -Force

$z = Get-Item $out
'{0}  {1:N1} KB  (RadikaTools.bundle)' -f $z.Name, ($z.Length / 1KB)
