# Bastion Blast - release web bundle.
# Builds release, patches the web bundle (icon/favicon/Poki) and zips it for upload.
#
#   powershell -ExecutionPolicy Bypass -File tools/package.ps1
#
# Output: dist/BastionBlast-web.zip

param(
    [string]$Out = "dist"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
    & (Join-Path $PSScriptRoot "build.ps1") -Variant release
    if ($LASTEXITCODE -ne 0) { throw "release build failed" }

    $index = Get-ChildItem (Join-Path $root "bundle\web") -Recurse -Filter "index.html" |
        Select-Object -First 1
    if (-not $index) { throw "index.html not found after build" }

    $dist = Join-Path $root $Out
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    $zip = Join-Path $dist "BastionBlast-web.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }

    Compress-Archive -Path (Join-Path $index.DirectoryName "*") -DestinationPath $zip -CompressionLevel Optimal
    $sizeMb = [math]::Round((Get-Item $zip).Length / 1MB, 2)
    Write-Host ""
    Write-Host "PACKAGE OK  ($sizeMb MB)" -ForegroundColor Green
    Write-Host "ZIP:        $zip"
    Write-Host "APP DIR:    $($index.DirectoryName)"
}
finally {
    Pop-Location
}
