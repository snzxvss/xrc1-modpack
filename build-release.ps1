# Script de compilacion automatica con versionado
param([switch]$UploadToGitHub = $false)

$CARGO_PATH = "C:\Users\opc\.cargo\bin\cargo.exe"
$SRC_TAURI = "src-tauri"
$RELEASES_DIR = "releases"
$VERSION_FILE = "VERSION.txt"
$GITHUB_RELEASE_TAG = "installer"

function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  XRC1 Mod Installer - Build & Release" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Leer version actual
if (-not (Test-Path $VERSION_FILE)) {
    Write-Warning "No existe $VERSION_FILE, creando con version 1.0.0"
    "1.0.0" | Out-File -FilePath $VERSION_FILE -Encoding ascii -NoNewline
    $currentVersion = "1.0.0"
} else {
    $currentVersion = Get-Content $VERSION_FILE -Raw
    $currentVersion = $currentVersion.Trim()
}

Write-Info "Version actual: $currentVersion"

# 2. Incrementar version
$versionParts = $currentVersion -split '\.'
if ($versionParts.Count -ne 3) {
    Write-Error "ERROR: Formato de version invalido (debe ser X.Y.Z)"
    exit 1
}

$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]
$patch++
$newVersion = "$major.$minor.$patch"

Write-Success "Nueva version: $newVersion"
Write-Host ""

# 3. Actualizar main.rs
$mainRsPath = Join-Path $SRC_TAURI "src\main.rs"
Write-Info "Actualizando CURRENT_VERSION en main.rs..."
$mainRsContent = Get-Content $mainRsPath -Raw
$mainRsContent = $mainRsContent -replace 'const CURRENT_VERSION: &str = ".*?";', "const CURRENT_VERSION: &str = `"$newVersion`";"
$mainRsContent | Out-File -FilePath $mainRsPath -Encoding utf8 -NoNewline

# 4. Compilar
Write-Info "Compilando aplicacion..."
Write-Host ""
Push-Location $SRC_TAURI
& $CARGO_PATH build --release
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Fallo la compilacion"
    exit 1
}

Write-Success ""
Write-Success "Compilacion exitosa"
Write-Host ""

# 5. Crear carpeta release
$releaseFolder = Join-Path $RELEASES_DIR "v$newVersion"
if (-not (Test-Path $RELEASES_DIR)) {
    New-Item -ItemType Directory -Path $RELEASES_DIR | Out-Null
}

if (Test-Path $releaseFolder) {
    Remove-Item -Path $releaseFolder -Recurse -Force
}

New-Item -ItemType Directory -Path $releaseFolder | Out-Null
Write-Info "Creada carpeta: $releaseFolder"

# 6. Copiar ejecutable
$exeName = "XRC1-Mod-Installer-v$newVersion.exe"
$sourceExe = Join-Path $SRC_TAURI "target\release\xrc1-mod-installer.exe"
$destExe = Join-Path $releaseFolder $exeName

Copy-Item -Path $sourceExe -Destination $destExe
$exeSize = (Get-Item $destExe).Length / 1MB
Write-Success "Copiado: $exeName ($([math]::Round($exeSize, 2)) MB)"

# 7. Crear info
$infoPath = Join-Path $releaseFolder "RELEASE-INFO.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$infoContent = @"
XRC1 Mod Installer - Release v$newVersion
========================================

Compilado: $timestamp
Tamanio: $([math]::Round($exeSize, 2)) MB

GitHub: https://github.com/snzxvss/xrc1-modpack
"@
$infoContent | Out-File -FilePath $infoPath -Encoding utf8
Write-Success "Creado: RELEASE-INFO.txt"
Write-Host ""

# 8. Guardar version
$newVersion | Out-File -FilePath $VERSION_FILE -Encoding ascii -NoNewline
Write-Success "Version actualizada a $newVersion"

# 9. Resumen
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Version: v$newVersion" -ForegroundColor Yellow
Write-Host "Ubicacion: $releaseFolder" -ForegroundColor Yellow
Write-Host "Ejecutable: $exeName ($([math]::Round($exeSize, 2)) MB)" -ForegroundColor Yellow
Write-Host ""

# 10. Upload a GitHub
if ($UploadToGitHub) {
    Write-Info "Subiendo a GitHub..."

    # Eliminar TODOS los .exe del release (versiones anteriores)
    Write-Warning "Eliminando versiones anteriores..."
    $jsonOutput = gh release view $GITHUB_RELEASE_TAG --json assets 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        $release = $jsonOutput | ConvertFrom-Json
        $exeAssets = $release.assets | Where-Object { $_.name -like "*.exe" }
        foreach ($asset in $exeAssets) {
            Write-Host "  Eliminando: $($asset.name)"
            gh release delete-asset $GITHUB_RELEASE_TAG $asset.name --yes 2>&1 | Out-Null
        }
    }

    # Subir nueva versión
    Write-Info "Subiendo $exeName..."
    gh release upload $GITHUB_RELEASE_TAG $destExe

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Subido a GitHub exitosamente"

        # Actualizar descripción del release con la plantilla
        Write-Info "Actualizando descripción del release..."
        if (Test-Path "RELEASE-TEMPLATE.txt") {
            $templateContent = Get-Content "RELEASE-TEMPLATE.txt" -Raw -Encoding UTF8
            $releaseNotes = $templateContent -replace '\{VERSION\}', $newVersion
            $releaseNotes | Out-File -FilePath "release-notes-temp.txt" -Encoding ASCII
            gh release edit $GITHUB_RELEASE_TAG --notes-file "release-notes-temp.txt"
            Remove-Item "release-notes-temp.txt" -Force
            Write-Success "Descripción actualizada"
        } else {
            Write-Warning "No se encontró RELEASE-TEMPLATE.txt"
        }
    } else {
        Write-Error "ERROR: Fallo la subida"
    }
} else {
    Write-Info "Para subir a GitHub:"
    Write-Host "  .\build-release.ps1 -UploadToGitHub"
}
Write-Host ""
