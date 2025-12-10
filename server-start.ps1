# Script de inicio del servidor Minecraft con sincronizacion de mods
param(
    [switch]$OnlySync = $false,
    [switch]$NoUpload = $false
)

$SERVER_PATH = "C:\Users\opc\Desktop\Server-2025-2026"
$SERVER_MODS = Join-Path $SERVER_PATH "mods"
$LOCAL_MODS = "mods"
$RELEASE_TAG = "v1.0.0"

function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  XRC1 Server - Sincronizacion de Mods" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que existe el servidor
if (-not (Test-Path $SERVER_PATH)) {
    Write-Error "ERROR: No existe el servidor en $SERVER_PATH"
    exit 1
}

if (-not (Test-Path $SERVER_MODS)) {
    Write-Warning "No existe carpeta mods en servidor, creando..."
    New-Item -ItemType Directory -Path $SERVER_MODS | Out-Null
}

# 2. Escanear mods del servidor
Write-Info "Escaneando mods del servidor..."
$serverModFiles = Get-ChildItem -Path $SERVER_MODS -Filter "*.jar" | Select-Object -ExpandProperty Name | Sort-Object

if ($serverModFiles.Count -eq 0) {
    Write-Warning "No hay mods en el servidor"
} else {
    Write-Success "Se encontraron $($serverModFiles.Count) mods en el servidor"
}

# 3. Escanear mods locales (proyecto)
Write-Info "Escaneando mods locales..."
if (-not (Test-Path $LOCAL_MODS)) {
    New-Item -ItemType Directory -Path $LOCAL_MODS | Out-Null
}
$localModFiles = Get-ChildItem -Path $LOCAL_MODS -Filter "*.jar" | Select-Object -ExpandProperty Name | Sort-Object
Write-Host "Mods locales: $($localModFiles.Count)"

# 4. Comparar y copiar mods faltantes del servidor al local
Write-Info "Sincronizando mods del servidor al proyecto local..."
$copiedCount = 0
foreach ($serverMod in $serverModFiles) {
    if ($serverMod -notin $localModFiles) {
        Write-Host "  [+] Copiando: $serverMod" -ForegroundColor Yellow
        Copy-Item -Path (Join-Path $SERVER_MODS $serverMod) -Destination $LOCAL_MODS -Force
        $copiedCount++
    }
}

if ($copiedCount -eq 0) {
    Write-Success "Todos los mods del servidor ya estan en el proyecto local"
} else {
    Write-Success "Se copiaron $copiedCount mods nuevos al proyecto local"
}

# 5. Escanear mods en GitHub
Write-Info "Escaneando mods en GitHub Release..."
$jsonOutput = gh release view $RELEASE_TAG --json assets 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: No se pudo consultar GitHub Release"
    exit 1
}

$release = $jsonOutput | ConvertFrom-Json
$githubModFiles = $release.assets | Where-Object { $_.name -like "*.jar" } | Select-Object -ExpandProperty name
Write-Host "Mods en GitHub: $($githubModFiles.Count)"

# 6. Subir mods faltantes a GitHub
if (-not $NoUpload) {
    Write-Info "Verificando mods faltantes en GitHub..."
    $toUpload = @()
    foreach ($serverMod in $serverModFiles) {
        if ($serverMod -notin $githubModFiles) {
            $toUpload += $serverMod
        }
    }

    if ($toUpload.Count -eq 0) {
        Write-Success "Todos los mods del servidor estan en GitHub"
    } else {
        Write-Warning "Faltan $($toUpload.Count) mods en GitHub, subiendo..."
        foreach ($mod in $toUpload) {
            $modPath = Join-Path $LOCAL_MODS $mod
            Write-Host "  [>] Subiendo: $mod" -ForegroundColor Yellow
            gh release upload $RELEASE_TAG $modPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Subido: $mod" -ForegroundColor Green
            } else {
                Write-Host "  [X] ERROR: Fallo $mod" -ForegroundColor Red
            }
        }

        # Regenerar metadata
        Write-Info "Regenerando mods-metadata.json..."
        & powershell.exe -ExecutionPolicy Bypass -File generate-mods-metadata.ps1 | Out-Null

        # Subir metadata actualizado
        gh release delete-asset $RELEASE_TAG "mods-metadata.json" --yes 2>&1 | Out-Null
        gh release upload $RELEASE_TAG "mods-metadata.json"
        Write-Success "Metadata actualizado"
    }
} else {
    Write-Warning "Sincronizacion de GitHub omitida (-NoUpload)"
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "  SINCRONIZACION COMPLETADA" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumen:" -ForegroundColor Yellow
Write-Host "  Mods en servidor: $($serverModFiles.Count)"
Write-Host "  Mods en proyecto: $($localModFiles.Count + $copiedCount)"
Write-Host "  Mods en GitHub: $($githubModFiles.Count)"
Write-Host ""

# 7. Iniciar servidor (si no es solo sync)
if (-not $OnlySync) {
    Write-Info "Iniciando servidor Minecraft..."
    Write-Host ""

    Push-Location $SERVER_PATH

    # Buscar el archivo de inicio del servidor
    if (Test-Path "start.bat") {
        & .\start.bat
    } elseif (Test-Path "run.bat") {
        & .\run.bat
    } elseif (Test-Path "forge*.jar") {
        $forgeJar = Get-ChildItem -Filter "forge*.jar" | Select-Object -First 1 -ExpandProperty Name
        Write-Host "Ejecutando: java -jar $forgeJar nogui"
        java -jar $forgeJar nogui
    } else {
        Write-Error "No se encontro archivo de inicio del servidor"
        Write-Host "Archivos disponibles:"
        Get-ChildItem | Select-Object Name
    }

    Pop-Location
}
