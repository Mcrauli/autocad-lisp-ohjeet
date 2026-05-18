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

# _loader.lsp — autoloader joka latautuu PackageContents.xml:n kautta
# (LoadOnAutoCADStartup="True"). Lataa muut LSPit Contents-kansiosta.
$loader = @"
;; Radika-tyokalujen autoloader (AutoCAD/BricsCAD bundle).
;; AutoCAD lataa taman LSP:n bundle-kaynnistyksen yhteydessa
;; PackageContents.xml:n LoadOnAutoCADStartup-direktiivilla.
;; Tama puolestaan lataa muut tyokalu-LSPit samasta Contents-kansiosta.

(defun radika-load-all ( / dir f )
  (setq dir (vl-filename-directory (findfile "_loader.lsp")))
  (if dir
    (foreach f '("hoyrystin.lsp" "kaato.lsp" "klhylly.lsp" "koneikko.lsp"
                 "kotelo.lsp" "lauhdutin.lsp" "positio.lsp"
                 "putkityokalu.lsp" "varusteet.lsp")
      (load (strcat dir "/" f) nil))))

(radika-load-all)
(princ "\nRadika-tyokalut ladattu (bundle).")
(princ)
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $contentsDir '_loader.lsp'), $loader, $utf8NoBom)

# PackageContents.xml — kertoo AutoCADille mita ladata.
# ProductCode = pysyva GUID taman paketin identifierina (sama paivityksissakin).
$pkg = @"
<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0"
                    ProductCode="{7A2B1E4F-3C5D-4E6F-8A9B-1C2D3E4F5A6B}"
                    Name="RadikaTools"
                    Description="Kylmalaite-suunnittelun LISP-tyokalut + Radika-ribbon"
                    Author="Lauri Rekola"
                    Helpfile="https://mcrauli.github.io/autocad-lisp-ohjeet/"
                    AppVersion="1.0.0"
                    AutodeskProduct="AutoCAD"
                    SupportedLocales="Enu">
  <CompanyDetails Name="Lauri Rekola" />
  <Components Description="Radika ribbon + LSP-tyokalut">
    <RuntimeRequirements OS="Win64" Platform="AutoCAD" SeriesMin="R23.0" />
    <ComponentEntry AppName="RadikaTools-CUIX" Version="1.0.0"
                    ModuleName="./Contents/radika-tools.cuix"
                    AppType=".cuix"
                    LoadOnAutoCADStartup="True" />
    <ComponentEntry AppName="RadikaTools-Lisp" Version="1.0.0"
                    ModuleName="./Contents/_loader.lsp"
                    AppType=".lsp"
                    LoadOnAutoCADStartup="True" />
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
