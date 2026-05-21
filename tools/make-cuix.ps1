# Generate files/radika-tools.cuix from the command list.
# Run from the repo root: pwsh -File tools/make-cuix.ps1
# Uses the same command/icon list as make-icons.ps1.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$repoRoot = (Get-Location).Path
$filesDir = Join-Path $repoRoot 'files'
$iconsDir = Join-Path $filesDir 'icons'
$cuixPath = Join-Path $filesDir 'radika-tools.cuix'

if (-not (Test-Path $iconsDir)) {
  throw "files/icons/ not found. Run tools/make-icons.ps1 first."
}

# Each command: id (matches png stem), name (display), command (macro target),
# help (tooltip text), panel (which ribbon panel it belongs to).
$commands = @(
  # KLHL/KLHT ovat omat piirtokomennot per hyllytyyppi — ei tyyppipromptia,
  # nappi itse paattaa tyypin ja komento siirtyy suoraan pisteiden valintaan.
  # KLHV-makro syottaa ";"-Enterit jotta leveys-prompti hyvaksyy valikon
  # oletuksen (kaynnistys + leveys = 2 ";").
  @{ id='klhl';        name='Levyhylly';   command='KLHL';        help='Piirra levyhylly (leveys/aloituspiste valikosta)';  panel='Hyllyt' },
  @{ id='klht';        name='Tikashylly';  command='KLHT';        help='Piirra tikashylly (leveys/aloituspiste valikosta)'; panel='Hyllyt' },
  @{ id='klhv';        name='KLHV';        command='KLHV;;';      help='Kylmalaitehylly TIKAS (pysty / 3D)';          panel='Hyllyt' },
  @{ id='korko';       name='KORKO';       command='KORKO';       help='Siirra valitut absoluuttiselle Z-korolle';    panel='Hyllyt' },
  # Hyllyt-valikon setterit: asettavat oletuksen, eivat piirra.
  @{ id='klh-w300';    name='300';         command='KLH-W300';    help='Aseta hyllyleveys: 300 mm' },
  @{ id='klh-w400';    name='400';         command='KLH-W400';    help='Aseta hyllyleveys: 400 mm' },
  @{ id='klh-w500';    name='500';         command='KLH-W500';    help='Aseta hyllyleveys: 500 mm' },
  @{ id='klh-snapv';   name='V (vasen paa)'; command='KLH-SNAPV'; help='Aloituspiste: vasen paa' },
  @{ id='klh-snapk';   name='K (keski)';     command='KLH-SNAPK'; help='Aloituspiste: keski' },
  @{ id='3ptk';        name='3PTK';        command='3PTK';        help='Kolme putkea kerralla (LT IMU + MT NESTE + MT IMU)'; panel='Putket' },
  @{ id='lti';         name='LTI';         command='LTI';         help='LT IMU -putki';                                panel='Putket' },
  @{ id='mti';         name='MTI';         command='MTI';         help='MT IMU -putki';                                panel='Putket' },
  @{ id='mtn';         name='MTN';         command='MTN';         help='MT NESTE -putki';                              panel='Putket' },
  @{ id='hy1';         name='HY1';         command='HY1';         help='Hoyrystin, 1 puhallin';                        panel='Laitteet' },
  @{ id='hy2';         name='HY2';         command='HY2';         help='Hoyrystin, 2 puhallinta';                      panel='Laitteet' },
  @{ id='hy3';         name='HY3';         command='HY3';         help='Hoyrystin, 3 puhallinta';                      panel='Laitteet' },
  @{ id='koneikko';    name='KONEIKKO';    command='KONEIKKO';    help='Kylmakoneikko';                                panel='Laitteet' },
  @{ id='lauhdutin';   name='LAUHDUTIN';   command='LAUHDUTIN';   help='Lauhdutin';                                    panel='Laitteet' },
  @{ id='kotelo';      name='KOTELO';      command='KOTELO';      help='Kylmakotelo (suljettu kaapelireitti)';         panel='Hyllyt' },
  @{ id='positio';     name='POSITIO';     command='POSITIO';     help='Numerointiblokki, auto-incrementti';           panel='Positio' },
  @{ id='asetanumero'; name='ASETANUMERO'; command='ASETANUMERO'; help='Aseta seuraava positionumero';                 panel='Positio' },
  @{ id='kaato3d';     name='KAATO3D';     command='KAATO3D';     help='Kallista kappale 3D-pivot-pisteesta';          panel='Apuvalineet' },
  @{ id='varusteet';   name='VARUSTEET';   command='VARUSTEET';   help='Kylmakoneikon sahkovarustelu (kysyy laitteen)'; panel='Apuvalineet' },
  # VARUSTEET-alivariantit: makro syottaa keyword-valinnan suoraan,
  # joten ribbon-dropdownista voi valita laitteen ilman erillista promptia.
  @{ id='varusteet-anturi';      name='CO2-anturi';    command='VARUSTEET Anturi;';      help='CO2-vuotoanturi' },
  @{ id='varusteet-sireeni';     name='CO2-sireeni';   command='VARUSTEET Sireeni;';     help='CO2-halytinsireeni' },
  @{ id='varusteet-pc';          name='Huolto-PC';     command='VARUSTEET Pc;';          help='Huolto-PC / valvomotyoasema' },
  @{ id='varusteet-ryhmakeskus'; name='Ryhmakeskus';   command='VARUSTEET Ryhmakeskus;'; help='Ryhmakeskus (RK-JK10)' },
  @{ id='varusteet-keskus';      name='Saadinkeskus';  command='VARUSTEET Keskus;';      help='Saadinkeskus (KU)' },
  @{ id='varusteet-hataseis';    name='Hataseis';      command='VARUSTEET Hataseis;';    help='Hataseispainike' }
)

# Ribbon layout. Each panel holds one or more items:
#   @{ kind='split';  cmds=@(id, id, ...) } -> RibbonSplitButton, first cmd is
#       the visible primary button, the rest drop down. Behavior=SplitFollow
#       so the last-used command stays as the primary.
#   @{ kind='button'; cmd=id }              -> a plain large RibbonCommandButton.
$panels = @(
  # Hyllyt: Levyhylly/Tikashylly-piirtopainike (split, SplitFollow muistaa
  # viimeisimman), leveys- ja snap-dropdownit asettavat oletukset,
  # sitten KLHV + KORKO + KOTELO.
  @{ name='Hyllyt'; items=@(
      @{ kind='split';  cmds=@('klhl','klht') }
      @{ kind='split';  cmds=@('klh-w300','klh-w400','klh-w500') }
      @{ kind='split';  cmds=@('klh-snapv','klh-snapk') }
      @{ kind='button'; cmd='klhv' }
      @{ kind='button'; cmd='korko' }
      @{ kind='button'; cmd='kotelo' }
  ) },
  @{ name='Putket';      items=@( @{ kind='split'; cmds=@('3ptk','lti','mti','mtn') } ) },
  # Laitteet: oli ennen "Hoyrystimet"-paneeli. Sisaltaa nyt myos
  # KONEIKKO + LAUHDUTIN (isompi kylmalaitos-kalusto), siksi yleisempi nimi.
  @{ name='Laitteet'; items=@(
      @{ kind='split';  cmds=@('hy1','hy2','hy3') }
      @{ kind='button'; cmd='koneikko' }
      @{ kind='button'; cmd='lauhdutin' }
  ) },
  @{ name='Positio';     items=@( @{ kind='split'; cmds=@('positio','asetanumero') } ) },
  @{ name='Apuvalineet'; items=@(
      @{ kind='button'; cmd='kaato3d' },
      @{ kind='split';  cmds=@('varusteet','varusteet-anturi','varusteet-sireeni','varusteet-pc','varusteet-ryhmakeskus','varusteet-keskus','varusteet-hataseis') }
  ) }
)

# Build temp folder.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('radika-cuix-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmp '_rels') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmp 'Images') | Out-Null

# Icon reference key: all hyphens in the id become underscores. This is the
# single naming convention shared by the cuix Images/ folder, the cuix XML
# references, and install-radika.ps1's copy into the CAD Support folders —
# ids like "varusteet-anturi" must resolve identically everywhere.
function Get-IconKey([string]$id) { return ($id -replace '-', '_') }

# Copy icons into Images/ inside the cuix
$imagesDir = Join-Path $tmp 'Images'
foreach ($cmd in $commands) {
  $iconKey = Get-IconKey $cmd.id
  foreach ($size in 16, 32) {
    $src = Join-Path $iconsDir ("{0}-{1}.png" -f $cmd.id, $size)
    $dst = Join-Path $imagesDir ("{0}_{1}.png" -f $iconKey, $size)
    Copy-Item -LiteralPath $src -Destination $dst
  }
}

function Write-Utf8 {
  param([string]$Path, [string]$Content)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-RandomId {
  # Generate R + 16 hex digits, similar to AutoCAD's relationship IDs
  return 'R' + ((1..16 | ForEach-Object { '{0:x}' -f (Get-Random -Min 0 -Max 16) }) -join '')
}

$warn = @"
<?xml version="1.0" encoding="utf-8"?>
<!--
Warning! Do not edit the contents of this file.
If you attempt to edit this file using an XML editor, you could lose
customization and migration functionality. If you need to change
information in the customization file, use the Customize User Interface
dialog in the product.
To access the Customize User Interface dialog, click the Tools menu,
Customization panel, User Interface button, or enter CUI on the command line.
-->
"@

# 1. Header.cui (minimal partial header)
$header = @"
$warn
<CustSection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <FileVersion MajorVersion="0" MinorVersion="6" IncrementalVersion="1" UserVersion="0" />
  <Header>
    <CommonConfiguration>
      <CommonItems>
        <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />
      </CommonItems>
    </CommonConfiguration>
  </Header>
</CustSection>
"@
Write-Utf8 (Join-Path $tmp 'Header.cui') $header

# 2. MenuGroup.cui — commands
function HtmlEscape([string]$s) {
  return ($s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

$macroSb = New-Object System.Text.StringBuilder
foreach ($cmd in $commands) {
  $null = $macroSb.AppendLine("    <MenuMacro UID=`"RADIKA_$($cmd.id)`">")
  $null = $macroSb.AppendLine('      <Macro type="Any">')
  $null = $macroSb.AppendLine('        <Revision MajorVersion="1" MinorVersion="0" UserVersion="0" />')
  $null = $macroSb.AppendLine('        <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
  $null = $macroSb.AppendLine("        <Name>$(HtmlEscape $cmd.name)</Name>")
  # A trailing space is the macro's Enter that launches a plain command.
  # Commands that already end in ';' (e.g. "KLH;;;;", "VARUSTEET Anturi;")
  # carry their own explicit Enters - appending a space there would feed an
  # extra Enter into the first pick prompt and cancel the command. So only
  # append the launching space when the command does not already end in ';'.
  $macroCmd = $cmd.command
  if (-not $macroCmd.EndsWith(';')) { $macroCmd = $macroCmd + ' ' }
  $null = $macroSb.AppendLine("        <Command>^C^C$macroCmd</Command>")
  $null = $macroSb.AppendLine("        <HelpString>$(HtmlEscape $cmd.help)</HelpString>")
  $iconKey = Get-IconKey $cmd.id
  $null = $macroSb.AppendLine("        <SmallImage Name=`"${iconKey}_16.png`" />")
  $null = $macroSb.AppendLine("        <LargeImage Name=`"${iconKey}_32.png`" />")
  $null = $macroSb.AppendLine('      </Macro>')
  $null = $macroSb.AppendLine('    </MenuMacro>')
}

$menuGroup = @"
$warn
<MenuGroup xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Name="RADIKA" DisplayName="Radika">
  <MacroGroup Name="RadikaCommands">
$($macroSb.ToString().TrimEnd())
  </MacroGroup>
</MenuGroup>
"@
Write-Utf8 (Join-Path $tmp 'MenuGroup.cui') $menuGroup

# 3. RibbonRoot.cui — panels + tab
# Look up a command record by id.
function Get-Cmd([string]$id) {
  $c = $commands | Where-Object { $_.id -eq $id } | Select-Object -First 1
  if (-not $c) { throw "Unknown command id in panel layout: $id" }
  return $c
}

$panelSb = New-Object System.Text.StringBuilder
$panelIdMap = @{}
$panelCounter = 1000
$splitCounter = 5000
foreach ($panel in $panels) {
  $panelName = $panel.name
  $panelId = "RADIKA_PANEL_$panelCounter"
  $panelIdMap[$panelName] = $panelId
  $rowId = "RADIKA_ROW_$panelCounter"
  $breakId = "RADIKA_BREAK_$panelCounter"

  $null = $panelSb.AppendLine("    <RibbonPanelSource UID=`"$panelId`" Text=`"$panelName`" HiddenInEditor=`"false`">")
  $null = $panelSb.AppendLine('      <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
  $null = $panelSb.AppendLine("      <Name>$panelName</Name>")
  $null = $panelSb.AppendLine("      <RibbonRow UID=`"$rowId`">")
  $null = $panelSb.AppendLine('        <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')

  foreach ($item in $panel.items) {
    if ($item.kind -eq 'button') {
      $cmd = Get-Cmd $item.cmd
      $btnId = "RADIKA_BTN_$($cmd.id)"
      $title = HtmlEscape $cmd.name
      $null = $panelSb.AppendLine("        <RibbonCommandButton UID=`"$btnId`" Id=`"AcRibbonCommandButton`" Text=`"$title`" ButtonStyle=`"LargeWithText`" MenuMacroID=`"RADIKA_$($cmd.id)`" KeyTip=`"`">")
      $null = $panelSb.AppendLine("          <TooltipTitle>$title</TooltipTitle>")
      $null = $panelSb.AppendLine('          <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
      $null = $panelSb.AppendLine('        </RibbonCommandButton>')
    }
    elseif ($item.kind -eq 'split') {
      $primary = Get-Cmd $item.cmds[0]
      $splitId = "RADIKA_SPLIT_$splitCounter"
      $splitCounter++
      $splitTitle = HtmlEscape $primary.name
      $primaryIconKey = Get-IconKey $primary.id
      # SplitButton's own image = the primary command's icon. Behavior
      # SplitFollow keeps the last-picked command as the visible button.
      $null = $panelSb.AppendLine("        <RibbonSplitButton UID=`"$splitId`" Id=`"AcRibbonSplitButton`" Text=`"$splitTitle`" KeyTip=`"`" SmallImage=`"${primaryIconKey}_16.png`" LargeImage=`"${primaryIconKey}_32.png`" Behavior=`"SplitFollow`" ListStyle=`"IconText`" ButtonStyle=`"LargeWithText`" Grouping=`"false`">")
      $null = $panelSb.AppendLine('          <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
      foreach ($id in $item.cmds) {
        $cmd = Get-Cmd $id
        $btnId = "RADIKA_BTN_$($cmd.id)"
        $title = HtmlEscape $cmd.name
        $null = $panelSb.AppendLine("          <RibbonCommandButton UID=`"$btnId`" Id=`"AcRibbonCommandButton`" Text=`"$title`" ButtonStyle=`"SmallWithText`" MenuMacroID=`"RADIKA_$($cmd.id)`">")
        $null = $panelSb.AppendLine("            <TooltipTitle>$title</TooltipTitle>")
        $null = $panelSb.AppendLine('            <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
        $null = $panelSb.AppendLine('          </RibbonCommandButton>')
      }
      $null = $panelSb.AppendLine('        </RibbonSplitButton>')
    }
  }

  $null = $panelSb.AppendLine('      </RibbonRow>')
  $null = $panelSb.AppendLine("      <RibbonPanelBreak UID=`"$breakId`" Id=`"AcRibbonPanelBreak`">")
  $null = $panelSb.AppendLine('        <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
  $null = $panelSb.AppendLine('      </RibbonPanelBreak>')
  $null = $panelSb.AppendLine('    </RibbonPanelSource>')

  $panelCounter++
}

$tabSb = New-Object System.Text.StringBuilder
$refCounter = 2000
foreach ($panel in $panels) {
  $refId = "RADIKA_REF_$refCounter"
  $panelId = $panelIdMap[$panel.name]
  $null = $tabSb.AppendLine("      <RibbonPanelSourceReference UID=`"$refId`" PanelId=`"$panelId`" ResizeStyle=`"Default`">")
  $null = $tabSb.AppendLine('        <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />')
  $null = $tabSb.AppendLine('      </RibbonPanelSourceReference>')
  $refCounter++
}

$ribbon = @"
$warn
<RibbonRoot>
  <RibbonPanelSourceCollection xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
$($panelSb.ToString().TrimEnd())
  </RibbonPanelSourceCollection>
  <RibbonTabSourceCollection>
    <RibbonTabSource Text="Radika" UID="RADIKA_TAB" KeyTip="RA">
      <ModifiedRev MajorVersion="1" MinorVersion="0" UserVersion="0" />
      <Name>Radika</Name>
$($tabSb.ToString().TrimEnd())
    </RibbonTabSource>
  </RibbonTabSourceCollection>
</RibbonRoot>
"@
Write-Utf8 (Join-Path $tmp 'RibbonRoot.cui') $ribbon

# 4. Empty placeholder .cui files
$placeholders = @{
  'AcceleratorRoot.cui'      = '<AcceleratorRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'DigitizerButtonRoot.cui'  = '<DigitizerButtonRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'DoubleClickRoot.cui'      = '<DoubleClickRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'ImageMenuRoot.cui'        = '<ImageMenuRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'LSPFiles.cui'             = '<LSPFiles xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'MouseButtonRoot.cui'      = '<MouseButtonRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'OverrideRoot.cui'         = '<OverrideRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'PanelSetRoot.cui'         = '<PanelSetRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><PanelSet UID="PSTU_0001" /></PanelSetRoot>'
  'PopMenuRoot.cui'          = '<PopMenuRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'QuickAccessToolbarRoot.cui' = '<QuickAccessToolbarRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'QuickPropertiesRoot.cui'  = '<QuickPropertiesRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'RolloverTooltipRoot.cui'  = '<RolloverTooltipRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'ScreenMenuRoot.cui'       = '<ScreenMenuRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'TabletMenuRoot.cui'       = '<TabletMenuRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'ToolPanelRoot.cui'        = '<ToolPanelRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'ToolbarRoot.cui'          = '<ToolbarRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" />'
  'WorkspaceRoot.cui'        = '<WorkspaceRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><WorkspaceConfigRoot /></WorkspaceRoot>'
}
foreach ($file in $placeholders.Keys) {
  $content = $warn + "`r`n" + $placeholders[$file]
  Write-Utf8 (Join-Path $tmp $file) $content
}

# 5. Menu_Package_Info.xml
$now = (Get-Date).ToString('o')
$partsSb = New-Object System.Text.StringBuilder
$cuiFiles = @('Header.cui', 'WorkspaceRoot.cui', 'MenuGroup.cui', 'AcceleratorRoot.cui', 'OverrideRoot.cui',
  'MouseButtonRoot.cui', 'PopMenuRoot.cui', 'ToolbarRoot.cui', 'DoubleClickRoot.cui', 'QuickPropertiesRoot.cui',
  'RolloverTooltipRoot.cui', 'RibbonRoot.cui', 'QuickAccessToolbarRoot.cui', 'ToolPanelRoot.cui',
  'PanelSetRoot.cui', 'ScreenMenuRoot.cui', 'ImageMenuRoot.cui', 'TabletMenuRoot.cui',
  'DigitizerButtonRoot.cui', 'LSPFiles.cui')
foreach ($f in $cuiFiles) {
  $null = $partsSb.AppendLine("  <PartData PartData_Name=`"/$f`" PartData_Modified=`"$now`" />")
}
$null = $partsSb.AppendLine("  <PartData PartData_Name=`"/Menu_Package_Info.xml`" PartData_Modified=`"$now`" />")

$pkgInfo = @"
<?xml version="1.0" encoding="utf-8"?>
<MenuPackageParts>
$($partsSb.ToString().TrimEnd())
</MenuPackageParts>
"@
Write-Utf8 (Join-Path $tmp 'Menu_Package_Info.xml') $pkgInfo

# 6. [Content_Types].xml
$contentTypes = @'
<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="cui" ContentType="text/xml" /><Default Extension="xml" ContentType="text/xml" /><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" /><Default Extension="png" ContentType="image/png" /></Types>
'@
Write-Utf8 (Join-Path $tmp '[Content_Types].xml') $contentTypes

# 7. _rels/.rels — relationship list
$relsSb = New-Object System.Text.StringBuilder
foreach ($f in $cuiFiles) {
  $rid = New-RandomId
  $null = $relsSb.Append("<Relationship Type=`"CUI`" Target=`"/$f`" Id=`"$rid`" />")
}
$rels = '<?xml version="1.0" encoding="utf-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + $relsSb.ToString() + '</Relationships>'
Write-Utf8 (Join-Path $tmp '_rels\.rels') $rels

# 8. Zip up everything via System.IO.Compression (Compress-Archive rejects .cuix extension)
if (Test-Path $cuixPath) { Remove-Item -LiteralPath $cuixPath -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $cuixPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Cleanup
Remove-Item -Recurse -Force -LiteralPath $tmp

$z = Get-Item $cuixPath
Write-Output ("{0}  {1:N1} KB" -f $z.Name, ($z.Length / 1KB))
