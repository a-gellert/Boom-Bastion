# Bastion Blast - local static server for the HTML5 build
# Usage: powershell -ExecutionPolicy Bypass -File tools/serve.ps1 [-Port 8080]
param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$base = Join-Path $root "bundle\web"
if (-not (Test-Path $base)) {
    throw "No build found. Run: powershell -File tools/build.ps1"
}
$index = Get-ChildItem $base -Recurse -Filter "index.html" | Select-Object -First 1
if (-not $index) {
    throw "No index.html under $base. Run: powershell -File tools/build.ps1"
}

Write-Host "Serving $($index.DirectoryName)" -ForegroundColor Cyan
Write-Host "Open http://127.0.0.1:$Port/" -ForegroundColor Green
node (Join-Path $PSScriptRoot "serve.js") $index.DirectoryName $Port
