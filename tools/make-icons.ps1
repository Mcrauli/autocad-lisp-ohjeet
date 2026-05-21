# Generate ribbon icons for the Radika AutoCAD tools.
# Run from the repo root: pwsh -File tools/make-icons.ps1
# Produces files/icons/<id>-16.png and <id>-32.png (32-bit ARGB).
# Each command gets a tool-specific glyph (not just a text label).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$outDir = Join-Path (Get-Location) 'files\icons'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# id         -> filename stem
# glyph      -> drawing routine name
# color      -> background color
$commands = @(
  @{ id='klhl';        glyph='shelf';      color='#8B5A2B' },
  @{ id='klht';        glyph='ladder';     color='#8B5A2B' },
  @{ id='klhv';        glyph='ladder';     color='#8B5A2B' },
  @{ id='korko';       glyph='elevation';  color='#8B5A2B' },
  @{ id='3ptk';        glyph='triplepipe'; color='#1F75D9' },
  # LTI/MTI/MTN — yksittaiset putkityokalut: kuvakkeen taustavari
  # vastaa AutoCAD-piirtovaria (LT IMU ACI 4 cyan, MT IMU ACI 5 sin,
  # MT NESTE ACI 42 amber). Auttaa erottamaan putkityypin yhdella silmayksellaan.
  @{ id='lti';         glyph='pipe1';      color='#22d3ee' },
  @{ id='mti';         glyph='pipe2';      color='#3b82f6' },
  @{ id='mtn';         glyph='pipe3';      color='#f59e0b' },
  @{ id='hy1';         glyph='fan1';       color='#2E8B57' },
  @{ id='hy2';         glyph='fan2';       color='#2E8B57' },
  @{ id='hy3';         glyph='fan3';       color='#2E8B57' },
  @{ id='positio';     glyph='posball';    color='#E0B400' },
  @{ id='asetanumero'; glyph='setnum';     color='#E0B400' },
  @{ id='kaato3d';     glyph='tilt';       color='#555555' },
  @{ id='varusteet';   glyph='bolt';       color='#555555' },
  # VARUSTEET-alivariantit (ribbon-dropdown): kukin oma laite-glyph
  @{ id='varusteet-anturi';      glyph='sensor';   color='#555555' },
  @{ id='varusteet-sireeni';     glyph='siren';    color='#555555' },
  @{ id='varusteet-pc';          glyph='monitor';  color='#555555' },
  @{ id='varusteet-ryhmakeskus'; glyph='cabinet';  color='#555555' },
  @{ id='varusteet-keskus';      glyph='ctrlbox';  color='#555555' },
  @{ id='varusteet-hataseis';    glyph='estop';    color='#555555' },
  # Hyllyt-paneelin valikko-setterit (leveys / snap)
  @{ id='klh-w300';   glyph='label';   color='#8B5A2B'; label='300' },
  @{ id='klh-w400';   glyph='label';   color='#8B5A2B'; label='400' },
  @{ id='klh-w500';   glyph='label';   color='#8B5A2B'; label='500' },
  @{ id='klh-snapv';  glyph='label';   color='#8B5A2B'; label='V' },
  @{ id='klh-snapk';  glyph='label';   color='#8B5A2B'; label='K' },
  # Uudet: KOTELO (Hyllyt-paneeli, ruskea) + KONEIKKO/LAUHDUTIN (Laitteet, vihrea)
  @{ id='kotelo';     glyph='box';        color='#8B5A2B' },
  @{ id='koneikko';   glyph='koneikko';   color='#2E8B57' },
  @{ id='lauhdutin';  glyph='lauhdutin';  color='#2E8B57' }
)

function New-RoundedPath {
  param([int]$Size, [int]$Radius)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $Radius * 2
  $w = $Size - 1
  $path.AddArc(0,      0,      $d, $d, 180, 90)
  $path.AddArc($w - $d, 0,      $d, $d, 270, 90)
  $path.AddArc($w - $d, $w - $d, $d, $d, 0,   90)
  $path.AddArc(0,      $w - $d, $d, $d, 90,  90)
  $path.CloseFigure()
  return $path
}

function White {
  return [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
}

function New-WhitePen {
  param([single]$Width)
  $pen = New-Object System.Drawing.Pen((White), $Width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  return $pen
}

# --- Glyph routines: each receives ($g, $s) where $s is the icon edge size.
# Coordinates use the full $s×$s box; padding ~10% inside.

function Draw-Shelf { param($g, [int]$s)
  # 3 horizontal shelf bars stacked
  $brush = New-Object System.Drawing.SolidBrush((White))
  $left = [int]($s * 0.18); $right = $s - $left
  $w = $right - $left
  $thick = [Math]::Max(2, [int]($s * 0.10))
  for ($i = 0; $i -lt 3; $i++) {
    $y = [int]($s * (0.25 + $i * 0.22))
    $g.FillRectangle($brush, $left, $y, $w, $thick)
  }
  $brush.Dispose()
}

function Draw-Ladder { param($g, [int]$s)
  # 2 vertical rails + horizontal rungs
  $pen = New-WhitePen ([single][Math]::Max(1.5, $s * 0.06))
  $top = [int]($s * 0.14); $bot = $s - $top
  $leftX = [int]($s * 0.32); $rightX = $s - $leftX
  $g.DrawLine($pen, $leftX, $top, $leftX, $bot)
  $g.DrawLine($pen, $rightX, $top, $rightX, $bot)
  $rungs = if ($s -ge 32) { 4 } else { 3 }
  for ($i = 0; $i -lt $rungs; $i++) {
    $y = [int]($top + ($bot - $top) * (($i + 0.5) / $rungs))
    $g.DrawLine($pen, $leftX, $y, $rightX, $y)
  }
  $pen.Dispose()
}

function Draw-Elevation { param($g, [int]$s)
  # Surveyor elevation marker: filled triangle pointing down with a horizontal line at its base
  $brush = New-Object System.Drawing.SolidBrush((White))
  $pen = New-WhitePen ([single][Math]::Max(1.5, $s * 0.07))
  $cx = $s / 2.0
  $top = [single]($s * 0.30); $bot = [single]($s * 0.62)
  $half = [single]($s * 0.18)
  $pts = @(
    (New-Object System.Drawing.PointF([single]($cx - $half), $top)),
    (New-Object System.Drawing.PointF([single]($cx + $half), $top)),
    (New-Object System.Drawing.PointF([single]$cx,            $bot))
  )
  $g.FillPolygon($brush, $pts)
  $lineY = [int]($s * 0.74)
  $g.DrawLine($pen, [int]($s * 0.18), $lineY, [int]($s * 0.82), $lineY)
  $brush.Dispose(); $pen.Dispose()
}

function Draw-TriplePipe { param($g, [int]$s)
  # 3 parallel horizontal pipe lines
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.10))
  $left = [int]($s * 0.14); $right = $s - $left
  for ($i = 0; $i -lt 3; $i++) {
    $y = [int]($s * (0.30 + $i * 0.20))
    $g.DrawLine($pen, $left, $y, $right, $y)
  }
  $pen.Dispose()
}

function Draw-SinglePipe { param($g, [int]$s, [int]$markerStyle)
  # One thick horizontal line with a small marker at the left end indicating variant
  $pen = New-WhitePen ([single][Math]::Max(2.0, $s * 0.14))
  $left = [int]($s * 0.18); $right = $s - $left; $y = [int]($s / 2)
  $g.DrawLine($pen, $left, $y, $right, $y)
  $pen.Dispose()
  # Marker glyph (1=dot, 2=hollow circle, 3=square)
  $mr = [Math]::Max(2, [int]($s * 0.16))
  $brush = New-Object System.Drawing.SolidBrush((White))
  $markerPen = New-WhitePen ([single][Math]::Max(1.2, $s * 0.05))
  switch ($markerStyle) {
    1 { $g.FillEllipse($brush, $left - $mr, $y - $mr, $mr * 2, $mr * 2) }
    2 {
      # Filled ring: white ring with darker hole (use background-color fill in glyph caller? no — leave hollow via DrawEllipse)
      $g.DrawEllipse($markerPen, $left - $mr, $y - $mr, $mr * 2, $mr * 2)
    }
    3 {
      $g.FillRectangle($brush, $left - $mr, $y - $mr, $mr * 2, $mr * 2)
    }
  }
  $brush.Dispose(); $markerPen.Dispose()
}
function Draw-Pipe1 { param($g, [int]$s) Draw-SinglePipe $g $s 1 }
function Draw-Pipe2 { param($g, [int]$s) Draw-SinglePipe $g $s 2 }
function Draw-Pipe3 { param($g, [int]$s) Draw-SinglePipe $g $s 3 }

function Draw-Fan { param($g, [int]$s, [int]$count)
  $r = [int]($s * 0.18)
  $totalW = $count * ($r * 2) + ($count - 1) * [int]($s * 0.05)
  $startX = [int](($s - $totalW) / 2 + $r)
  $cy = [int]($s / 2)
  $pen = New-WhitePen ([single][Math]::Max(1.2, $s * 0.05))
  $brush = New-Object System.Drawing.SolidBrush((White))
  for ($i = 0; $i -lt $count; $i++) {
    $cx = $startX + $i * ($r * 2 + [int]($s * 0.05))
    # Outer circle
    $g.DrawEllipse($pen, $cx - $r, $cy - $r, $r * 2, $r * 2)
    # Hub
    $hr = [Math]::Max(1, [int]($r * 0.30))
    $g.FillEllipse($brush, $cx - $hr, $cy - $hr, $hr * 2, $hr * 2)
    # 3 blades as short radial lines
    for ($a = 0; $a -lt 3; $a++) {
      $ang = $a * (2 * [Math]::PI / 3) - [Math]::PI / 2
      $x2 = $cx + [Math]::Cos($ang) * ($r * 0.85)
      $y2 = $cy + [Math]::Sin($ang) * ($r * 0.85)
      $g.DrawLine($pen, [single]$cx, [single]$cy, [single]$x2, [single]$y2)
    }
  }
  $pen.Dispose(); $brush.Dispose()
}
function Draw-Fan1 { param($g, [int]$s) Draw-Fan $g $s 1 }
function Draw-Fan2 { param($g, [int]$s) Draw-Fan $g $s 2 }
function Draw-Fan3 { param($g, [int]$s) Draw-Fan $g $s 3 }

function Draw-TJoint { param($g, [int]$s)
  # T-shaped pipe junction
  $pen = New-WhitePen ([single][Math]::Max(2.5, $s * 0.16))
  $cx = $s / 2; $cy = $s / 2
  $left = [int]($s * 0.16); $right = $s - $left; $bot = [int]($s * 0.84)
  # Horizontal bar
  $g.DrawLine($pen, $left, $cy, $right, $cy)
  # Vertical drop
  $g.DrawLine($pen, $cx, $cy, $cx, $bot)
  $pen.Dispose()
}

function Draw-NumberedPipe { param($g, [int]$s, [string]$num)
  # Horizontal pipe with the diameter number below it
  $pen = New-WhitePen ([single][Math]::Max(1.8, $s * 0.10))
  $left = [int]($s * 0.14); $right = $s - $left
  $y = [int]($s * 0.30)
  $g.DrawLine($pen, $left, $y, $right, $y)
  $pen.Dispose()

  # Number text
  $fontSize = if ($s -ge 32) { [single]($s * 0.44) } else { [single]($s * 0.55) }
  $font = New-Object System.Drawing.Font('Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush((White))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rectF = [System.Drawing.RectangleF]::new(0.0, [single]($s * 0.42), [single]$s, [single]($s * 0.55))
  $g.DrawString($num, $font, $brush, $rectF, $format)
  $font.Dispose(); $brush.Dispose(); $format.Dispose()
}
function Draw-Pipe32 { param($g, [int]$s) Draw-NumberedPipe $g $s '32' }
function Draw-Pipe50 { param($g, [int]$s) Draw-NumberedPipe $g $s '50' }
function Draw-Pipe75 { param($g, [int]$s) Draw-NumberedPipe $g $s '75' }

function Draw-PosBall { param($g, [int]$s)
  # White-outlined circle with a "1" inside (position ball / number)
  $r = [int]($s * 0.34)
  $cx = [int]($s / 2); $cy = [int]($s / 2)
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.08))
  $g.DrawEllipse($pen, $cx - $r, $cy - $r, $r * 2, $r * 2)
  $pen.Dispose()
  $fontSize = if ($s -ge 32) { [single]($s * 0.42) } else { [single]($s * 0.55) }
  $font = New-Object System.Drawing.Font('Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush((White))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rectF = [System.Drawing.RectangleF]::new(0.0, 0.0, [single]$s, [single]$s)
  $g.DrawString('1', $font, $brush, $rectF, $format)
  $font.Dispose(); $brush.Dispose(); $format.Dispose()
}

function Draw-SetNum { param($g, [int]$s)
  # "1 → 2" indicating the increment / starting number setter
  $fontSize = if ($s -ge 32) { [single]($s * 0.40) } else { [single]($s * 0.50) }
  $font = New-Object System.Drawing.Font('Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush((White))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rectF = [System.Drawing.RectangleF]::new(0.0, 0.0, [single]$s, [single]$s)
  if ($s -ge 32) {
    $g.DrawString("1`u{2192}n", $font, $brush, $rectF, $format)
  } else {
    $g.DrawString("`u{2192}n", $font, $brush, $rectF, $format)
  }
  $font.Dispose(); $brush.Dispose(); $format.Dispose()
}

function Draw-Tilt { param($g, [int]$s)
  # Tilted bar pivoting from a base point — represents the KAATO3D rotation
  $pen = New-WhitePen ([single][Math]::Max(2.2, $s * 0.13))
  # Base pivot point (lower-left)
  $px = [int]($s * 0.24); $py = [int]($s * 0.74)
  # End point (upper-right)
  $ex = [int]($s * 0.82); $ey = [int]($s * 0.34)
  $g.DrawLine($pen, $px, $py, $ex, $ey)
  $pen.Dispose()
  # Pivot dot
  $brush = New-Object System.Drawing.SolidBrush((White))
  $dr = [Math]::Max(2, [int]($s * 0.10))
  $g.FillEllipse($brush, $px - $dr, $py - $dr, $dr * 2, $dr * 2)
  # Reference dashed baseline (horizontal at $py)
  $dashPen = New-WhitePen ([single][Math]::Max(1.0, $s * 0.04))
  $dashPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
  $g.DrawLine($dashPen, $px, $py, [int]($s * 0.86), $py)
  $brush.Dispose(); $dashPen.Dispose()
}

function Draw-Bolt { param($g, [int]$s)
  # Lightning bolt — represents VARUSTEET (electrical fittings)
  $brush = New-Object System.Drawing.SolidBrush((White))
  # 6-vertex bolt
  $pts = @(
    (New-Object System.Drawing.PointF([single]($s * 0.52), [single]($s * 0.10))),
    (New-Object System.Drawing.PointF([single]($s * 0.24), [single]($s * 0.54))),
    (New-Object System.Drawing.PointF([single]($s * 0.44), [single]($s * 0.54))),
    (New-Object System.Drawing.PointF([single]($s * 0.32), [single]($s * 0.92))),
    (New-Object System.Drawing.PointF([single]($s * 0.72), [single]($s * 0.42))),
    (New-Object System.Drawing.PointF([single]($s * 0.52), [single]($s * 0.42)))
  )
  $g.FillPolygon($brush, $pts)
  $brush.Dispose()
}

# --- VARUSTEET sub-device glyphs (ribbon dropdown) ---

function Draw-Sensor { param($g, [int]$s)
  # CO2 sensor: a wall-mounted box with "CO2" text inside.
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.07))
  $left = [int]($s * 0.16); $top = [int]($s * 0.26)
  $w = [int]($s * 0.68); $h = [int]($s * 0.48)
  $g.DrawRectangle($pen, $left, $top, $w, $h)
  $pen.Dispose()
  # "CO2" label centered in the box, font auto-fitted so it never clips
  $font = $null
  $maxPx = if ($s -ge 32) { 14 } else { 9 }
  for ($pt = $maxPx; $pt -ge 4; $pt--) {
    $candidate = New-Object System.Drawing.Font('Segoe UI', $pt, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $measured = $g.MeasureString('CO2', $candidate)
    if ($measured.Width -le ($w - 2) -and $measured.Height -le ($h - 2)) {
      $font = $candidate; break
    }
    $candidate.Dispose()
  }
  if (-not $font) { $font = New-Object System.Drawing.Font('Segoe UI', 4, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel) }
  $brush = New-Object System.Drawing.SolidBrush((White))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rectF = [System.Drawing.RectangleF]::new([single]$left, [single]$top, [single]$w, [single]$h)
  $g.DrawString('CO2', $font, $brush, $rectF, $format)
  $font.Dispose(); $brush.Dispose(); $format.Dispose()
}

function Draw-Siren { param($g, [int]$s)
  # Alarm siren: a horn / megaphone shape with sound waves coming out.
  $brush = New-Object System.Drawing.SolidBrush((White))
  # Horn body: small rectangle (driver) on the left + flaring cone to the right
  $bx = [int]($s * 0.14); $byTop = [int]($s * 0.40); $bh = [int]($s * 0.20)
  $g.FillRectangle($brush, $bx, $byTop, [int]($s * 0.12), $bh)
  # Cone (trapezoid) flaring right
  $coneL = [int]($s * 0.26); $coneR = [int]($s * 0.52)
  $pts = @(
    (New-Object System.Drawing.PointF([single]$coneL, [single]($s * 0.42))),
    (New-Object System.Drawing.PointF([single]$coneR, [single]($s * 0.22))),
    (New-Object System.Drawing.PointF([single]$coneR, [single]($s * 0.78))),
    (New-Object System.Drawing.PointF([single]$coneL, [single]($s * 0.58)))
  )
  $g.FillPolygon($brush, $pts)
  $brush.Dispose()
  # Sound waves: two arcs to the right of the cone mouth
  $arcPen = New-WhitePen ([single][Math]::Max(1.4, $s * 0.06))
  $cx = [int]($s * 0.52); $cy = [int]($s * 0.50)
  $r1 = [int]($s * 0.16)
  $g.DrawArc($arcPen, $cx - $r1, $cy - $r1, $r1 * 2, $r1 * 2, -55, 110)
  $r2 = [int]($s * 0.28)
  $g.DrawArc($arcPen, $cx - $r2, $cy - $r2, $r2 * 2, $r2 * 2, -55, 110)
  $arcPen.Dispose()
}

function Draw-Monitor { param($g, [int]$s)
  # Service PC: monitor screen rectangle with a small stand
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.07))
  $brush = New-Object System.Drawing.SolidBrush((White))
  $left = [int]($s * 0.18); $top = [int]($s * 0.22)
  $w = [int]($s * 0.64); $h = [int]($s * 0.42)
  $g.DrawRectangle($pen, $left, $top, $w, $h)
  # Stand
  $cx = [int]($s / 2)
  $g.FillRectangle($brush, $cx - [int]($s * 0.04), $top + $h, [int]($s * 0.08), [int]($s * 0.10))
  $g.FillRectangle($brush, $cx - [int]($s * 0.16), $top + $h + [int]($s * 0.10), [int]($s * 0.32), [Math]::Max(2, [int]($s * 0.06)))
  $pen.Dispose(); $brush.Dispose()
}

function Draw-Cabinet { param($g, [int]$s)
  # Distribution board (RK): rectangle with horizontal switch rows
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.07))
  $left = [int]($s * 0.24); $top = [int]($s * 0.14)
  $w = [int]($s * 0.52); $h = [int]($s * 0.72)
  $g.DrawRectangle($pen, $left, $top, $w, $h)
  # 3 horizontal rows (breaker rails)
  $rowPen = New-WhitePen ([single][Math]::Max(1.2, $s * 0.05))
  for ($i = 1; $i -le 3; $i++) {
    $y = $top + [int]($h * $i / 4)
    $g.DrawLine($rowPen, $left + [int]($s * 0.06), $y, $left + $w - [int]($s * 0.06), $y)
  }
  $pen.Dispose(); $rowPen.Dispose()
}

function Draw-CtrlBox { param($g, [int]$s)
  # Controller (saadinkeskus): rectangle with a round dial in the centre
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.07))
  $left = [int]($s * 0.22); $top = [int]($s * 0.20)
  $w = [int]($s * 0.56); $h = [int]($s * 0.56)
  $g.DrawRectangle($pen, $left, $top, $w, $h)
  $cx = [int]($s / 2); $cy = [int]($top + $h / 2)
  $r = [int]($s * 0.13)
  $g.DrawEllipse($pen, $cx - $r, $cy - $r, $r * 2, $r * 2)
  # Dial pointer
  $g.DrawLine($pen, $cx, $cy, $cx, $cy - $r)
  $pen.Dispose()
}

function Draw-Estop { param($g, [int]$s)
  # Emergency-stop button: large filled circle inside a ring
  $pen = New-WhitePen ([single][Math]::Max(1.6, $s * 0.07))
  $brush = New-Object System.Drawing.SolidBrush((White))
  $cx = [int]($s / 2); $cy = [int]($s / 2)
  $ro = [int]($s * 0.34)
  $g.DrawEllipse($pen, $cx - $ro, $cy - $ro, $ro * 2, $ro * 2)
  $ri = [int]($s * 0.20)
  $g.FillEllipse($brush, $cx - $ri, $cy - $ri, $ri * 2, $ri * 2)
  $pen.Dispose(); $brush.Dispose()
}

function Draw-Box { param($g, [int]$s)
  # KOTELO: suljettu suorakaide-kotelo poikkileikkauksena — ulkokehys
  # + sisempi suorakaide (= ontto kaapelireitti). Lisaksi diagonaalinen
  # leikkausviiva-viite kotelon paadyssa.
  $pen = New-WhitePen ([single][Math]::Max(1.8, $s * 0.07))
  $left = [int]($s * 0.18); $right = $s - $left
  $top = [int]($s * 0.22); $bot = $s - $top
  $g.DrawRectangle($pen, $left, $top, $right - $left, $bot - $top)
  $iw = [Math]::Max(2, [int]($s * 0.10))
  $g.DrawRectangle($pen, $left + $iw, $top + $iw, $right - $left - 2 * $iw, $bot - $top - 2 * $iw)
  $pen.Dispose()
}

function Draw-Koneikko { param($g, [int]$s)
  # KONEIKKO: laatikko jossa grilli ylhaalla (3 pystyvakoa) + 2
  # tayttocirckle alhaalla (kompressorit). Antaa "mekaaninen laite"
  # -tunnelman.
  $pen = New-WhitePen ([single][Math]::Max(1.5, $s * 0.05))
  $brush = New-Object System.Drawing.SolidBrush((White))
  $left = [int]($s * 0.14); $right = $s - $left
  $top = [int]($s * 0.20); $bot = $s - $top
  $g.DrawRectangle($pen, $left, $top, $right - $left, $bot - $top)
  # Grilli ylhaalla — 3 pystyvakoa
  for ($i = 0; $i -lt 3; $i++) {
    $sx = $left + [int](($right - $left) * (0.25 + $i * 0.25))
    $sy1 = $top + [int](($bot - $top) * 0.12)
    $sy2 = $top + [int](($bot - $top) * 0.38)
    $g.DrawLine($pen, $sx, $sy1, $sx, $sy2)
  }
  # Alhaalla — 2 kompressori-symbolia
  $r = [Math]::Max(2, [int]($s * 0.08))
  $cy = $top + [int](($bot - $top) * 0.72)
  $cx1 = $left + [int](($right - $left) * 0.32)
  $cx2 = $left + [int](($right - $left) * 0.68)
  $g.FillEllipse($brush, $cx1 - $r, $cy - $r, $r * 2, $r * 2)
  $g.FillEllipse($brush, $cx2 - $r, $cy - $r, $r * 2, $r * 2)
  $pen.Dispose(); $brush.Dispose()
}

function Draw-Lauhdutin { param($g, [int]$s)
  # LAUHDUTIN: kehysboksi + horisontaaliset jaahdytysrivat (fins).
  # Erottaa koneikosta (= ei kompressori-symboleja, vain rivasto).
  $pen = New-WhitePen ([single][Math]::Max(1.5, $s * 0.05))
  $thinPen = New-WhitePen ([single][Math]::Max(1.0, $s * 0.03))
  $left = [int]($s * 0.14); $right = $s - $left
  $top = [int]($s * 0.22); $bot = $s - $top
  $g.DrawRectangle($pen, $left, $top, $right - $left, $bot - $top)
  $fins = if ($s -ge 32) { 5 } else { 3 }
  $margin = [Math]::Max(2, [int]($s * 0.04))
  $innerLeft = $left + $margin
  $innerRight = $right - $margin
  for ($i = 0; $i -lt $fins; $i++) {
    $fy = $top + $margin + [int]((($bot - $top) - 2 * $margin) * (($i + 0.5) / $fins))
    $g.DrawLine($thinPen, $innerLeft, $fy, $innerRight, $fy)
  }
  $pen.Dispose(); $thinPen.Dispose()
}

function Draw-Label { param($g, [int]$s, [string]$text)
  # Plain centered text label — used by the Hyllyt menu setters
  # (300 / 400 / 500 / V / K).
  $maxWidth  = $s - [Math]::Max(2, [int]($s * 0.16))
  $maxHeight = $s - [Math]::Max(2, [int]($s * 0.20))
  $font = $null
  $maxPx = if ($s -ge 32) { 20 } else { 12 }
  for ($pt = $maxPx; $pt -ge 5; $pt--) {
    $candidate = New-Object System.Drawing.Font('Segoe UI', $pt, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $measured = $g.MeasureString($text, $candidate)
    if ($measured.Width -le $maxWidth -and $measured.Height -le $maxHeight) {
      $font = $candidate; break
    }
    $candidate.Dispose()
  }
  if (-not $font) { $font = New-Object System.Drawing.Font('Segoe UI', 6, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel) }
  $brush = New-Object System.Drawing.SolidBrush((White))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $rectF = [System.Drawing.RectangleF]::new(0.0, 0.0, [single]$s, [single]$s)
  $g.DrawString($text, $font, $brush, $rectF, $format)
  $font.Dispose(); $brush.Dispose(); $format.Dispose()
}

function New-Icon {
  param([string]$Glyph, [string]$ColorHex, [int]$Size, [string]$OutPath, [string]$Label = '')

  $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $radius = if ($Size -ge 32) { 5 } else { 3 }
    $path = New-RoundedPath -Size $Size -Radius $radius
    $bgColor = [System.Drawing.ColorTranslator]::FromHtml($ColorHex)
    $bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
    try { $g.FillPath($bgBrush, $path) } finally { $bgBrush.Dispose() }

    # Optional top highlight at large size
    if ($Size -ge 32) {
      $hlColor = [System.Drawing.Color]::FromArgb(28, 255, 255, 255)
      $hlBrush = New-Object System.Drawing.SolidBrush($hlColor)
      try {
        $hlW = $Size - 2
        $hlH = [int]($Size / 2.2)
        $g.FillRectangle($hlBrush, [single]1.0, [single]1.0, [single]$hlW, [single]$hlH)
      } finally { $hlBrush.Dispose() }
    }

    # Clip to rounded rect for the glyph too
    $g.SetClip($path)

    # Dispatch to the glyph routine
    switch ($Glyph) {
      'shelf'      { Draw-Shelf      $g $Size }
      'ladder'     { Draw-Ladder     $g $Size }
      'elevation'  { Draw-Elevation  $g $Size }
      'triplepipe' { Draw-TriplePipe $g $Size }
      'pipe1'      { Draw-Pipe1      $g $Size }
      'pipe2'      { Draw-Pipe2      $g $Size }
      'pipe3'      { Draw-Pipe3      $g $Size }
      'fan1'       { Draw-Fan1       $g $Size }
      'fan2'       { Draw-Fan2       $g $Size }
      'fan3'       { Draw-Fan3       $g $Size }
      'tjoint'     { Draw-TJoint     $g $Size }
      'pipe32'     { Draw-Pipe32     $g $Size }
      'pipe50'     { Draw-Pipe50     $g $Size }
      'pipe75'     { Draw-Pipe75     $g $Size }
      'posball'    { Draw-PosBall    $g $Size }
      'setnum'     { Draw-SetNum     $g $Size }
      'tilt'       { Draw-Tilt       $g $Size }
      'bolt'       { Draw-Bolt       $g $Size }
      'sensor'     { Draw-Sensor     $g $Size }
      'siren'      { Draw-Siren      $g $Size }
      'monitor'    { Draw-Monitor    $g $Size }
      'cabinet'    { Draw-Cabinet    $g $Size }
      'ctrlbox'    { Draw-CtrlBox    $g $Size }
      'estop'      { Draw-Estop      $g $Size }
      'box'        { Draw-Box        $g $Size }
      'koneikko'   { Draw-Koneikko   $g $Size }
      'lauhdutin'  { Draw-Lauhdutin  $g $Size }
      'label'      { Draw-Label      $g $Size $Label }
      default      { throw "Unknown glyph: $Glyph" }
    }

    $path.Dispose()
  } finally {
    $g.Dispose()
  }

  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$created = 0
foreach ($cmd in $commands) {
  foreach ($size in 16, 32) {
    $name = "{0}-{1}.png" -f $cmd.id, $size
    $dest = Join-Path $outDir $name
    $label = if ($cmd.ContainsKey('label')) { $cmd.label } else { '' }
    New-Icon -Glyph $cmd.glyph -ColorHex $cmd.color -Size $size -OutPath $dest -Label $label
    $created++
  }
}
Write-Output ("{0} icons -> {1}" -f $created, $outDir)
