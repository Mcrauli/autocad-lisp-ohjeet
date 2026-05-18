# Build files/suunnittelutyokalut.zip from the current contents of files/.
# Run after positio.dwg or any .lsp changes. Excludes itself and the zip.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$out = 'files/suunnittelutyokalut.zip'
if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }

# LSP + DWG + CUIX at the root of files/. Exclude session/auto-generated debris:
# AutoCAD/BricsCAD lock files (.dwl/.dwl2), menu-resource caches (.mnr),
# the CUIX extraction cache the CAD writes next to the .cuix (radika-tools.cui
# + .resz), CUI backups (.bak.cuix), .bak files, and legacy block versions.
# Only radika-tools.cuix itself ships — the .cui/.resz are rebuilt by the CAD.
$rootItems = Get-ChildItem -LiteralPath 'files' -File | Where-Object {
  $_.Name -ne 'suunnittelutyokalut.zip' -and
  $_.Extension -ne '.bak' -and
  $_.Extension -ne '.dwl' -and
  $_.Extension -ne '.dwl2' -and
  $_.Extension -ne '.mnr' -and
  $_.Extension -ne '.resz' -and
  $_.Name -notmatch '\.bak\.cuix$' -and
  $_.Name -notmatch '^radika-tools\.cui$' -and
  $_.Name -notmatch '^klhylly-tikaspp\.' -and
  # VPUTKI poistettu kayttosta (viemarit BricsCAD-puolella). vputki.lsp +
  # vputki-*.dwg pysyvat files/-kansiossa arkistossa mutta eivat lahde
  # mukaan jaettavaan ZIP-pakettiin.
  $_.Name -notmatch '^vputki(\.lsp$|-)' -and
  $_.Name -notmatch '^[Vv]putki-'
}

$paths = @($rootItems.FullName)

# Include the icons/ subfolder as a folder (preserves the icons/ prefix in the zip)
$iconsDir = Join-Path (Get-Location) 'files\icons'
if (Test-Path $iconsDir) { $paths += $iconsDir }

Compress-Archive -Path $paths -DestinationPath $out -CompressionLevel Optimal
$z = Get-Item $out
'{0}  {1:N1} KB' -f $z.Name, ($z.Length / 1KB)
