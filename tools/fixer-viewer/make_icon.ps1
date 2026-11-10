# Draws the Bug fixer icon (white bug on an orange tile) -> app.png (256 px) + app.ico (PNG inside, Windows Vista+).
# Run by BUILD.bat only when app.ico is missing: powershell -ExecutionPolicy Bypass -File make_icon.ps1
Add-Type -AssemblyName System.Drawing
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$S = 256
$bmp = New-Object System.Drawing.Bitmap $S, $S
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, $r, $r, 180, 90); $p.AddArc($x + $w - $r, $y, $r, $r, 270, 90)
  $p.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90); $p.AddArc($x, $y + $h - $r, $r, $r, 90, 90); $p.CloseFigure(); return $p
}
$tile = RoundRect 8 8 240 240 70
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point 256, 256), ([System.Drawing.Color]::FromArgb(255, 255, 166, 77)), ([System.Drawing.Color]::FromArgb(255, 226, 74, 40))
$g.FillPath($grad, $tile)
$white = [System.Drawing.Color]::White
$pen = New-Object System.Drawing.Pen $white, 13
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'
# legs
foreach ($y in 112, 146, 180) {
  $g.DrawLine($pen, 88, $y, 52, ($y - 14 + ($y - 146) / 3)); $g.DrawLine($pen, 168, $y, 204, ($y - 14 + ($y - 146) / 3))
}
# antennae
$g.DrawLine($pen, 112, 74, 92, 46); $g.DrawLine($pen, 144, 74, 164, 46)
# head + body
$br = New-Object System.Drawing.SolidBrush $white
$g.FillEllipse($br, 100, 62, 56, 46)
$g.FillEllipse($br, 78, 94, 100, 124)
# the line down the back (tile colour)
$cut = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 238, 105, 52)), 8
$g.DrawLine($cut, 128, 104, 128, 210)
$g.Dispose()
$png = Join-Path $dir 'app.png'
$bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
$bytes = [System.IO.File]::ReadAllBytes($png)
$ms = New-Object System.IO.MemoryStream
$w = New-Object System.IO.BinaryWriter $ms
$w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]1)          # ICONDIR: one image
$w.Write([Byte]0); $w.Write([Byte]0); $w.Write([Byte]0); $w.Write([Byte]0) # 256x256, no palette
$w.Write([UInt16]1); $w.Write([UInt16]32); $w.Write([UInt32]$bytes.Length); $w.Write([UInt32]22)
$w.Write($bytes); $w.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $dir 'app.ico'), $ms.ToArray())
"icon written"
