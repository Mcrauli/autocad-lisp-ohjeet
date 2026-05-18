# Install (or refresh) the Radika ribbon for AutoCAD and/or BricsCAD.
#
# Run this:
#   * after changing commands or icons (regenerates the CUIX + icons)
#   * on a new machine to set everything up from scratch
#
# What it does, per detected CAD:
#   1. Regenerates files/icons/*.png and files/radika-tools.cuix
#   2. Copies the icons into the CAD's Support\Icons folder so the ribbon
#      buttons resolve their images
#   3. Writes acaddoc.lsp (+ on_doc_load.lsp for BricsCAD) into the CAD's
#      Support folder so every LISP tool auto-loads on each drawing. The
#      path inside points straight at this repo's files/ folder, so editing
#      a .lsp here takes effect on the next drawing without reinstalling.
#   4. BricsCAD only: adds files/ to TRUSTEDPATHS so SECURELOAD allows the
#      auto-load.
#   5. Clears the stale AutoCAD CUIX cache (radika-tools.cui/.resz/.mnr)
#      so the CAD re-reads the fresh CUIX.
#   6. Rebuilds files/suunnittelutyokalut.zip
#
# The CUIX itself only references command names (^C^CKLH ...), so plain
# LISP code edits never need a reinstall - only command/icon changes do.
#
# ASCII-only on purpose: Windows PowerShell 5.1 mis-decodes UTF-8 scripts.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$repoRoot = (Get-Location).Path
$filesDir = Join-Path $repoRoot 'files'
$iconsDir = Join-Path $filesDir 'icons'
$toolsDir = $PSScriptRoot

# LISP files that auto-load on every drawing.
$lspFiles = @('hoyrystin.lsp','kaato.lsp','klhylly.lsp','positio.lsp',
              'putkityokalu.lsp','varusteet.lsp',
              'kotelo.lsp','koneikko.lsp','lauhdutin.lsp')
# Huom: vputki.lsp tarkoituksella poissa — viemariputkien piirto siirretty
# BricsCAD-puolelle. files/vputki.lsp sailyy talletettuna mahdollista
# tulevaa kayttoa varten, mutta sita ei auto-loadata enaa.

function Write-Utf8 {
  param([string]$Path, [string]$Content)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# Build the auto-load LISP body. The lsp dir is derived from THIS repo's
# location so the install works on any machine / any folder.
function Get-AutoloadLisp {
  param([string]$CadName)
  $lspDirFwd = ($filesDir -replace '\\', '/')
  if (-not $lspDirFwd.EndsWith('/')) { $lspDirFwd += '/' }
  $loadLines = ($lspFiles | ForEach-Object { "(radika-load-lsp `"$_`")" }) -join "`r`n"
  return @"
;; Radika LISP-tyokalujen automaattinen lataus ($CadName).
;; Generoitu tools/install-radika.ps1:lla - ala muokkaa kasin, aja
;; install-radika.ps1 uudelleen jos polku tai LSP-lista muuttuu.

(setq *radika-lsp-dir* "$lspDirFwd")

(defun radika-load-lsp (filename / path)
  (setq path (strcat *radika-lsp-dir* filename))
  (if (findfile path)
    (load path nil)
    (princ (strcat "\nRadika: ei loydy " path))))

$loadLines

(princ)
"@
}

# --- Step 1: regenerate icons + CUIX --------------------------------------
Write-Output "== 1. Regeneroidaan ikonit + CUIX =="
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $toolsDir 'make-icons.ps1')
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $toolsDir 'make-cuix.ps1')

$installedAny = $false

# --- Step 2: AutoCAD ------------------------------------------------------
Write-Output ""
Write-Output "== 2. AutoCAD =="
$acRoots = @()
$acBase = Join-Path $env:APPDATA 'Autodesk'
if (Test-Path $acBase) {
  $acRoots = Get-ChildItem $acBase -Directory -Filter 'AutoCAD *' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem $_.FullName -Directory -Filter 'R*' -ErrorAction SilentlyContinue |
        ForEach-Object {
          Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'Support' } |
            Where-Object { Test-Path $_ }
        }
    }
}
if ($acRoots) {
  foreach ($support in $acRoots) {
    Write-Output ("  Support: " + $support)
    $iconDest = Join-Path $support 'Icons'
    if (-not (Test-Path $iconDest)) { New-Item -ItemType Directory -Path $iconDest | Out-Null }
    $n = 0
    Get-ChildItem $iconsDir -Filter '*.png' | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $iconDest ($_.Name -replace '-', '_')) -Force
      $n++
    }
    Write-Output ("    " + $n + " ikonia -> Support\Icons")
    Write-Utf8 (Join-Path $support 'acaddoc.lsp') (Get-AutoloadLisp 'AutoCAD')
    Write-Output "    acaddoc.lsp kirjoitettu"
    $installedAny = $true
  }
} else {
  Write-Output "  AutoCAD-asennusta ei loytynyt - ohitetaan."
}

# --- Step 3: BricsCAD -----------------------------------------------------
Write-Output ""
Write-Output "== 3. BricsCAD =="
$bcRoots = @()
$bcBase = Join-Path $env:APPDATA 'Bricsys\BricsCAD'
if (Test-Path $bcBase) {
  $bcRoots = Get-ChildItem $bcBase -Directory -Filter 'V*' -ErrorAction SilentlyContinue |
    ForEach-Object {
      Get-ChildItem $_.FullName -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'Support' } |
        Where-Object { Test-Path $_ }
    }
}
if ($bcRoots) {
  foreach ($support in $bcRoots) {
    Write-Output ("  Support: " + $support)
    $n = 0
    Get-ChildItem $iconsDir -Filter '*.png' | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $support ($_.Name -replace '-', '_')) -Force
      $n++
    }
    Write-Output ("    " + $n + " ikonia -> Support")
    Write-Utf8 (Join-Path $support 'on_doc_load.lsp') (Get-AutoloadLisp 'BricsCAD')
    Write-Utf8 (Join-Path $support 'acaddoc.lsp')     (Get-AutoloadLisp 'BricsCAD')
    Write-Output "    on_doc_load.lsp + acaddoc.lsp kirjoitettu"
    # TRUSTEDPATHS so SECURELOAD allows the auto-load from files/.
    $verRoot  = (Split-Path (Split-Path $support -Parent) -Parent)
    $verName  = Split-Path $verRoot -Leaf
    $langName = Split-Path (Split-Path $support -Parent) -Leaf
    $cfgKey = "HKCU:\Software\Bricsys\BricsCAD\$verName\$langName\Profiles\Default\Config"
    if (Test-Path $cfgKey) {
      $existing = (Get-ItemProperty $cfgKey -ErrorAction SilentlyContinue).TRUSTEDPATHS
      $want = @($filesDir, $support)
      $parts = @()
      if ($existing) { $parts = $existing -split ';' | Where-Object { $_ } }
      foreach ($w in $want) { if ($parts -notcontains $w) { $parts += $w } }
      Set-ItemProperty -Path $cfgKey -Name 'TRUSTEDPATHS' -Value ($parts -join ';') -Type String
      Write-Output ("    TRUSTEDPATHS paivitetty (" + $parts.Count + " polkua)")
    } else {
      Write-Output ("    HUOM: profiilin Config-avainta ei loytynyt: " + $cfgKey)
    }
    $installedAny = $true
  }
} else {
  Write-Output "  BricsCAD-asennusta ei loytynyt - ohitetaan."
}

# --- Step 4: clear AutoCAD CUIX cache in files/ ---------------------------
Write-Output ""
Write-Output "== 4. Puhdistetaan CUIX-valimuistit files/-kansiosta =="
$cleared = @()
Get-ChildItem $filesDir -Filter 'radika-tools.*' | Where-Object {
  $_.Name -ne 'radika-tools.cuix'
} | ForEach-Object {
  Remove-Item $_.FullName -Force
  $cleared += $_.Name
}
if ($cleared) { Write-Output ("  Poistettu: " + ($cleared -join ', ')) }
else { Write-Output "  Ei valimuisteja puhdistettavana." }

# --- Step 5: rebuild the zip ----------------------------------------------
Write-Output ""
Write-Output "== 5. Rebuildataan suunnittelutyokalut.zip =="
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'make-bundle.ps1')

Write-Output ""
if ($installedAny) {
  Write-Output "VALMIS. Kaynnista AutoCAD / BricsCAD uudelleen:"
  Write-Output "  - LSP-tyokalut latautuvat automaattisesti joka piirustukseen"
  Write-Output "  - Jos Radika-valilehti ei nay: komento CUILOAD -> radika-tools.cuix"
} else {
  Write-Output "Yhtaan CAD-asennusta ei loytynyt. ZIP on silti rebuildattu."
}
