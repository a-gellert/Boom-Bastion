# Bastion Blast - store asset pack.
# Copies the best headless captures into store/screenshots, then composes a
# 1920x1080 key art cover (and a 1280x720 variant) with the Rubik title font.
#
#   powershell -ExecutionPolicy Bypass -File tools/gen_store.ps1

param(
    [string]$Captures = "captures\store",
    [string]$Out = "store",
    [string]$KeyArt = "captures\store\clean_night_1280x720.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$captures = Join-Path $root $Captures
$store = Join-Path $root $Out
$shotsDir = Join-Path $store "screenshots"
New-Item -ItemType Directory -Force -Path $shotsDir | Out-Null

$shots = @(
    @{ src = "01_battle_1280x720.png"; dst = "01_battle.png" },
    @{ src = "02_perks_1280x720.png"; dst = "02_perks.png" },
    @{ src = "03_frost_1280x720.png"; dst = "03_frost.png" },
    @{ src = "04_night_boss_1280x720.png"; dst = "04_night_boss.png" },
    @{ src = "05_hotseat_1280x720.png"; dst = "05_hotseat.png" },
    @{ src = "06_endless_boss_1280x720.png"; dst = "06_endless_boss.png" },
    @{ src = "07_meta_1280x720.png"; dst = "07_meta.png" }
)
foreach ($s in $shots) {
    $from = Join-Path $captures $s.src
    if (-not (Test-Path $from)) { throw "Missing capture: $from" }
    Copy-Item $from (Join-Path $shotsDir $s.dst) -Force
}
Copy-Item (Join-Path $root "main\assets\icon.png") (Join-Path $store "icon.png") -Force

# ---------------------------------------------------------------- key art
$fontPath = Join-Path $root "main\assets\fonts\Rubik-Black.ttf"
$fonts = [System.Drawing.Text.PrivateFontCollection]::new()
$fonts.AddFontFile($fontPath)
$family = $fonts.Families[0]

$basePath = Join-Path $root $KeyArt
if (-not (Test-Path $basePath)) { throw "Missing key art base: $basePath" }
$base = [System.Drawing.Image]::FromFile($basePath)
$W = 1920
$H = 1080
$bmp = [System.Drawing.Bitmap]::new($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.DrawImage($base, 0, 0, $W, $H)
$base.Dispose()

# Dark wash so the gold title reads over the night battle.
$wash = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(118, 5, 9, 20))
$g.FillRectangle($wash, 0, 0, $W, $H)
$band = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.Point]::new(0, [int]($H * 0.52)),
    [System.Drawing.Point]::new(0, $H),
    [System.Drawing.Color]::FromArgb(20, 5, 9, 20),
    [System.Drawing.Color]::FromArgb(225, 5, 9, 20)
)
$g.FillRectangle($band, 0, [int]($H * 0.52), $W, [int]($H * 0.48))

# Gold frame.
$frame = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230, 245, 190, 66), 6)
$g.DrawRectangle($frame, 34, 34, $W - 68, $H - 68)
$inner = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(80, 255, 255, 255), 2)
$g.DrawRectangle($inner, 50, 50, $W - 100, $H - 100)

$center = [System.Drawing.StringFormat]::new()
$center.Alignment = [System.Drawing.StringAlignment]::Center
$center.LineAlignment = [System.Drawing.StringAlignment]::Center

$titleFont = [System.Drawing.Font]::new($family, 168, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$subFont = [System.Drawing.Font]::new($family, 44, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$lineFont = [System.Drawing.Font]::new($family, 30, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$titleRect = [System.Drawing.RectangleF]::new(0, 330, $W, 260)
$shadowRect = [System.Drawing.RectangleF]::new(10, 340, $W, 260)
$subRect = [System.Drawing.RectangleF]::new(0, 575, $W, 90)
$lineRect = [System.Drawing.RectangleF]::new(0, 885, $W, 70)

$shadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(190, 3, 6, 14))
$gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 205, 74))
$cream = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 246, 231, 201))
$soft = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 198, 212, 232))

$g.DrawString("BASTION BLAST", $titleFont, $shadow, $shadowRect, $center)
$g.DrawString("BASTION BLAST", $titleFont, $gold, $titleRect, $center)
$g.DrawString("PULL. RELEASE. COLLAPSE.", $subFont, $cream, $subRect, $center)
$g.DrawString("30 LEVELS  |  6 BIOMES  |  12 PERKS  |  2P HOTSEAT  |  ENDLESS", $lineFont, $soft, $lineRect, $center)

$cover1080 = Join-Path $store "cover_1920x1080.png"
$bmp.Save($cover1080, [System.Drawing.Imaging.ImageFormat]::Png)

$small = [System.Drawing.Bitmap]::new(1280, 720)
$sg = [System.Drawing.Graphics]::FromImage($small)
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sg.DrawImage($bmp, 0, 0, 1280, 720)
$cover720 = Join-Path $store "cover_1280x720.png"
$small.Save($cover720, [System.Drawing.Imaging.ImageFormat]::Png)

$sg.Dispose(); $small.Dispose(); $g.Dispose(); $bmp.Dispose()
$fonts.Dispose()

Write-Host "STORE OK  $store"
Get-ChildItem $store -Recurse -File | Select-Object Name, @{n = 'KB'; e = { [math]::Round($_.Length / 1KB, 1) } }
