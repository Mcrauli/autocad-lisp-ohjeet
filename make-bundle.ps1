# Build files/suunnittelutyokalut.zip from the current contents of files/.
# Run after positio.dwg or any .lsp changes. Excludes itself and the zip.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$out = 'files/suunnittelutyokalut.zip'
if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }
$items = Get-ChildItem -LiteralPath 'files' -File | Where-Object { $_.Name -ne 'suunnittelutyokalut.zip' }
Compress-Archive -Path $items.FullName -DestinationPath $out -CompressionLevel Optimal
$z = Get-Item $out
'{0}  {1:N1} KB' -f $z.Name, ($z.Length / 1KB)
