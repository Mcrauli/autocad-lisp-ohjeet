# Asenna.ps1 — RadikaTools-asentaja AutoCAD + BricsCAD:lle.
#
# Tama skripti:
#   1. Kopioi LSP- ja DWG-tyokalut polkuun %APPDATA%\Radika\Tools\
#   2. Kirjoittaa acaddoc.lsp jokaisen lyodetyn CAD-asennuksen Support-
#      kansioon. acaddoc.lsp lataa LSP:t kohdasta 1 jokaisen piirustuksen
#      avauksen yhteydessa. Koska acaddoc.lsp itse asuu CAD:in omassa
#      Support-kansiossa, AutoCAD:n SECURELOAD pitaa sita implisiittisesti
#      trusted:na — ei tarvita TRUSTEDPATHS-rekisterimuutoksia.
#   3. AutoCAD: kopioi RadikaTools.bundle ApplicationPlugins-kansioon.
#      Bundle sisaltaa vain CUIX-ribbonin (ei LSP:ita) — ribbon
#      autoloadataan, LSP:t tulee Support-acaddoc-loaderista.
#   4. BricsCAD: kopioi CUIX + ikonit BricsCAD:n Support-kansioon, ja
#      kayttaja saa ohjeen ajaa kerran CUILOAD-komennon (BricsCAD ei
#      autoloadaa CUIX:ia samalla tavalla kuin AutoCAD).
#   5. Idempotentti — saman skriptin ajaminen uudelleen paivittaa
#      kaikki tiedostot.
#
# Kayttotapa: Asenna.cmd kaksoisklikkauksella.

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " RadikaTools — AutoCAD/BricsCAD asentaja" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Tarkista lahdetiedostot
# ------------------------------------------------------------
$toolsSrc  = Join-Path $PSScriptRoot 'Tools'
$bundleSrc = Join-Path $PSScriptRoot 'RadikaTools.bundle'

if (-not (Test-Path -LiteralPath $toolsSrc)) {
  Write-Host "VIRHE: Tools-kansiota ei loydy:" -ForegroundColor Red
  Write-Host "  $toolsSrc" -ForegroundColor Red
  Write-Host "Pura ladattu ZIP kokonaisuudessaan ja yrita uudelleen." -ForegroundColor Yellow
  Read-Host "Paina ENTER"
  exit 1
}
if (-not (Test-Path -LiteralPath $bundleSrc)) {
  Write-Host "VIRHE: RadikaTools.bundle ei loydy:" -ForegroundColor Red
  Write-Host "  $bundleSrc" -ForegroundColor Red
  Read-Host "Paina ENTER"
  exit 1
}

Write-Host "Lahde: $PSScriptRoot" -ForegroundColor Gray
Write-Host ""

# ------------------------------------------------------------
# Kopioi LSP + DWG neutraaliin polkuun
# ------------------------------------------------------------
$toolsDst = Join-Path $env:APPDATA 'Radika\Tools'
if (-not (Test-Path -LiteralPath $toolsDst)) {
  New-Item -ItemType Directory -Path $toolsDst -Force | Out-Null
}
$lspCount = 0
$dwgCount = 0
Get-ChildItem -LiteralPath $toolsSrc -File | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $toolsDst -Force
  if ($_.Extension -eq '.lsp') { $lspCount++ }
  elseif ($_.Extension -eq '.dwg') { $dwgCount++ }
}
Write-Host "[Tools] $toolsDst" -ForegroundColor Gray
Write-Host "  $lspCount LSP + $dwgCount DWG kopioitu"
Write-Host ""

# ------------------------------------------------------------
# Generoi acaddoc.lsp-sisalto
# ------------------------------------------------------------
$lspList = @('hoyrystin.lsp','kaato.lsp','klhylly.lsp','positio.lsp',
             'putkityokalu.lsp','varusteet.lsp',
             'kotelo.lsp','koneikko.lsp','lauhdutin.lsp')

$lspDirFwd = ($toolsDst -replace '\\', '/')
if (-not $lspDirFwd.EndsWith('/')) { $lspDirFwd += '/' }
$loadLines = ($lspList | ForEach-Object { "(radika-load-lsp `"$_`")" }) -join "`r`n"
$acaddocBody = @"
;; RadikaTools-tyokalujen automaattinen lataus.
;; Generoitu Asenna.ps1:lla. Ala muokkaa kasin — aja Asenna.cmd
;; uudelleen paivittaaksesi LSP-listan tai polun.

(setq *radika-lsp-dir* "$lspDirFwd")

(defun radika-load-lsp (filename / path)
  (setq path (strcat *radika-lsp-dir* filename))
  (if (findfile path)
    (load path nil)
    (princ (strcat "\nRadika: ei loydy " path))))

$loadLines

(princ)
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ------------------------------------------------------------
# AutoCAD
# ------------------------------------------------------------
$autocadInstalled = $false
$acadRoots = @()
$acBase = Join-Path $env:APPDATA 'Autodesk'
if (Test-Path -LiteralPath $acBase) {
  $acadRoots = Get-ChildItem -LiteralPath $acBase -Directory -Filter 'AutoCAD *' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem -LiteralPath $_.FullName -Directory -Filter 'R*' -ErrorAction SilentlyContinue |
        ForEach-Object {
          Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'Support' } |
            Where-Object { Test-Path -LiteralPath $_ }
        }
    }
}

if ($acadRoots) {
  Write-Host "[AutoCAD] havaittu" -ForegroundColor Green
  foreach ($support in $acadRoots) {
    Write-Host "  Support: $support" -ForegroundColor Gray
    # acaddoc.lsp -> autoload LSP-tyokalut
    [System.IO.File]::WriteAllText((Join-Path $support 'acaddoc.lsp'), $acaddocBody, $utf8NoBom)
    Write-Host "    + acaddoc.lsp" -ForegroundColor Gray
    # Ikonit Support\Icons -> CUIX-ribbonin ikonit
    $iconDst = Join-Path $support 'Icons'
    if (-not (Test-Path -LiteralPath $iconDst)) {
      New-Item -ItemType Directory -Path $iconDst -Force | Out-Null
    }
    $bundleIcons = Join-Path $bundleSrc 'Contents\icons'
    $iconN = 0
    if (Test-Path -LiteralPath $bundleIcons) {
      Get-ChildItem -LiteralPath $bundleIcons -Filter '*.png' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $iconDst $_.Name) -Force
        $iconN++
      }
    }
    Write-Host "    + $iconN ikonia Support\Icons" -ForegroundColor Gray
  }
  # Bundle ApplicationPlugins -> CUIX-ribbon automaattisesti
  $acadPluginDir = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins'
  if (-not (Test-Path -LiteralPath $acadPluginDir)) {
    New-Item -ItemType Directory -Path $acadPluginDir -Force | Out-Null
  }
  $bundleDst = Join-Path $acadPluginDir 'RadikaTools.bundle'
  if (Test-Path -LiteralPath $bundleDst) {
    Remove-Item -LiteralPath $bundleDst -Recurse -Force
  }
  Copy-Item -LiteralPath $bundleSrc -Destination $acadPluginDir -Recurse -Force
  Write-Host "  $bundleDst" -ForegroundColor Gray
  Write-Host "  + bundle (CUIX-ribbon)" -ForegroundColor Gray
  $autocadInstalled = $true
} else {
  Write-Host "[AutoCAD] ei havaittu" -ForegroundColor DarkGray
}
Write-Host ""

# ------------------------------------------------------------
# BricsCAD
# ------------------------------------------------------------
$bricscadInstalled = $false
$brixRoots = @()
$bcBase = Join-Path $env:APPDATA 'Bricsys\BricsCAD'
if (Test-Path -LiteralPath $bcBase) {
  $brixRoots = Get-ChildItem -LiteralPath $bcBase -Directory -Filter 'V*' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'Support' } |
        Where-Object { Test-Path -LiteralPath $_ }
    }
}

if ($brixRoots) {
  Write-Host "[BricsCAD] havaittu" -ForegroundColor Green
  foreach ($support in $brixRoots) {
    Write-Host "  Support: $support" -ForegroundColor Gray
    # acaddoc.lsp + on_doc_load.lsp -> autoload LSP-tyokalut joka DWG:hen
    [System.IO.File]::WriteAllText((Join-Path $support 'acaddoc.lsp'),     $acaddocBody, $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $support 'on_doc_load.lsp'), $acaddocBody, $utf8NoBom)
    Write-Host "    + acaddoc.lsp + on_doc_load.lsp" -ForegroundColor Gray
    # CUIX -> Support-kansioon jotta CUILOAD loytaa sen
    Copy-Item -LiteralPath (Join-Path $bundleSrc 'Contents\radika-tools.cuix') (Join-Path $support 'radika-tools.cuix') -Force
    Write-Host "    + radika-tools.cuix" -ForegroundColor Gray
    # Ikonit Support-juureen (BricsCAD etsii niita sielta CUIX:lle)
    $bundleIcons = Join-Path $bundleSrc 'Contents\icons'
    $iconN = 0
    if (Test-Path -LiteralPath $bundleIcons) {
      Get-ChildItem -LiteralPath $bundleIcons -Filter '*.png' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $support $_.Name) -Force
        $iconN++
      }
    }
    Write-Host "    + $iconN ikonia" -ForegroundColor Gray
  }
  $bricscadInstalled = $true
} else {
  Write-Host "[BricsCAD] ei havaittu" -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# Yhteenveto
# ------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($autocadInstalled -or $bricscadInstalled) {
  Write-Host " Asennus valmis!" -ForegroundColor Green
  Write-Host "============================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "LSP-tyokalut: $toolsDst" -ForegroundColor Gray
  Write-Host ""
  Write-Host "Seuraavaksi:"
  if ($autocadInstalled) {
    Write-Host "  AutoCAD:  Kaynnista uudelleen. Ribbon + komennot toimivat" -ForegroundColor White
    Write-Host "            automaattisesti. Ei lisaaskelia." -ForegroundColor White
  }
  if ($bricscadInstalled) {
    Write-Host "  BricsCAD: Kaynnista uudelleen. Komennot toimivat heti." -ForegroundColor White
    Write-Host "            Ribbon-valilehden saa nakyviin yhden kerran:" -ForegroundColor White
    Write-Host "              1. Komentoriville: CUILOAD" -ForegroundColor White
    Write-Host "              2. Klikkaa Browse, kirjoita: radika-tools.cuix" -ForegroundColor White
    Write-Host "              3. Klikkaa Load -> Close" -ForegroundColor White
  }
  Write-Host ""
  Write-Host "Komennot: KLH KLHV KOTELO KORKO MTI LTI MTN POSITIO" -ForegroundColor Gray
  Write-Host "          KAATO VARUSTEET HOYRYSTIN KONEIKKO LAUHDUTIN" -ForegroundColor Gray
} else {
  Write-Host " AutoCAD eika BricsCAD havaittu" -ForegroundColor Red
  Write-Host "============================================" -ForegroundColor Cyan
}
Write-Host ""
Read-Host "Paina ENTER suljellaksesi"
