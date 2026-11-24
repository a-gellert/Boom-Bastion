# Rebuild the store pack end-to-end: English headless captures -> store/.
#
#   powershell -ExecutionPolicy Bypass -File tools/store_capture.ps1
#
# Needs a debug build (chapters/win/HUD debug keys are debug-only).

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$steps = "wait:4;shot:01_battle;key:F10;wait:1.0;shot:02_perks;click:380,340;wait:1.2;" +
    ("key:F8;" * 9) + "wait:1.0;shot:03_frost;" +
    ("key:F8;" * 19) + "wait:1.0;shot:04_night_boss;" +
    "js:location.reload();wait:5;click:1150,34;wait:2.0;drag:400,400,300,480;wait:3.5;shot:05_hotseat;" +
    "js:location.reload();wait:5;key:5;wait:0.8;" + ("key:F8;" * 4) + "wait:1.0;shot:06_endless_boss;" +
    "js:location.reload();wait:5;key:F10;wait:0.9;click:380,340;wait:1.0;key:Escape;wait:0.4;click:640,390;wait:0.5;shot:07_meta;" +
    "js:location.reload();wait:5;" + ("key:F8;" * 29) + "wait:2.2;key:H;wait:0.5;shot:clean_night"

& (Join-Path $PSScriptRoot "smoke.ps1") -Lang en -Steps $steps -Out "captures\store"
if ($LASTEXITCODE -ne 0) { throw "store capture smoke failed" }

& (Join-Path $PSScriptRoot "gen_store.ps1")
if ($LASTEXITCODE -ne 0) { throw "store composition failed" }
