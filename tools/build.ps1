# Bastion Blast - headless HTML5 build (Defold bob)
# Usage: powershell -ExecutionPolicy Bypass -File tools/build.ps1 [-Variant debug|release]
param(
    [string]$Variant = "debug"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
    $candidates = @(
        "C:\Program Files (x86)\Defold",
        "C:\Program Files\Defold",
        (Join-Path $env:LOCALAPPDATA "Defold")
    )
    $defold = $candidates | Where-Object { Test-Path (Join-Path $_ "packages") } | Select-Object -First 1
    if (-not $defold) {
        throw "Defold not found. Install Defold 1.14+ or set the path in tools/build.ps1"
    }

    $jdk = Get-ChildItem (Join-Path $defold "packages") -Directory -Filter "jdk-*" | Select-Object -First 1
    $jar = Get-ChildItem (Join-Path $defold "packages") -Filter "defold-*.jar" | Select-Object -First 1
    if (-not $jdk -or -not $jar) {
        throw "Defold packages are incomplete in $defold"
    }
    $java = Join-Path $jdk.FullName "bin\java.exe"

    $buildDir = Join-Path $root "bundle"
    $cacheDir = Join-Path $buildDir "default"
    $outDir = Join-Path $buildDir "web"
    if (Test-Path $cacheDir) { Remove-Item -Recurse -Force $cacheDir }
    if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    Write-Host "bob: $($jar.Name) | $Variant | wasm-web" -ForegroundColor Cyan
    & $java -cp $jar.FullName com.dynamo.bob.Bob `
        --root $root `
        --variant $Variant `
        --archive `
        --platform wasm-web `
        --architectures wasm-web `
        --bundle-output $outDir `
        resolve build bundle
    if ($LASTEXITCODE -ne 0) {
        throw "bob failed with exit code $LASTEXITCODE"
    }

    $index = Get-ChildItem $outDir -Recurse -Filter "index.html" | Select-Object -First 1
    if (-not $index) {
        throw "Build finished but index.html was not found under $outDir"
    }
    $sizeMb = [math]::Round(((Get-ChildItem $index.DirectoryName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
    Write-Host ""
    Write-Host "BUILD OK  ($sizeMb MB)" -ForegroundColor Green
    Write-Host "APP DIR:  $($index.DirectoryName)"
    Write-Host "RUN:      powershell -File tools/serve.ps1"
}
finally {
    Pop-Location
}
