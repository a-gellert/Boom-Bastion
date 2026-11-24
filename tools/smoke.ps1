# Bastion Blast - headless browser smoke test (loads the build, captures frames, counts errors)
# Usage: powershell -ExecutionPolicy Bypass -File tools/smoke.ps1 [-Steps "wait:5;shot:boot"] [-Size 1280x720]
param(
    [string]$Steps = "wait:6;shot:boot",
    [string]$Size = "1280x720",
    [string]$Out = "captures\smoke",
    [string]$Cfg = "",
    [switch]$Poki
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$base = Join-Path $root "bundle\web"
$index = Get-ChildItem $base -Recurse -Filter "index.html" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $index) {
    throw "No build found. Run: powershell -File tools/build.ps1"
}

$args = @(
    (Join-Path $PSScriptRoot "web_smoke.js"),
    $index.DirectoryName,
    (Join-Path $root $Out),
    "--size=$Size",
    "--steps=$Steps"
)
if ($Cfg -ne "") { $args += "--cfg=$Cfg" }
if ($Poki) { $args += "--poki=1" }

Push-Location $root
try {
    & node @args
    $code = $LASTEXITCODE
}
finally {
    Pop-Location
}
exit $code
