# Script para gestionar mods en GitHub
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("upload", "delete", "list")]
    [string]$Action,
    [Parameter(Mandatory=$false)]
    [string[]]$Files
)

$RELEASE_TAG = "v1.0.0"
$MODS_FOLDER = "mods"

function List-Mods {
    Write-Host ""
    Write-Host "Listando mods en release $RELEASE_TAG..." -ForegroundColor Cyan
    Write-Host ""

    $jsonOutput = gh release view $RELEASE_TAG --json assets 2>&1 | Out-String
    $release = $jsonOutput | ConvertFrom-Json
    $modList = $release.assets | Where-Object { $_.name -like "*.jar" } | Select-Object -ExpandProperty name

    if (-not $modList -or $modList.Count -eq 0) {
        Write-Host "No hay mods en el release." -ForegroundColor Yellow
    } else {
        Write-Host "Mods encontrados ($($modList.Count)):" -ForegroundColor Green
        $i = 1
        foreach ($mod in $modList) {
            Write-Host "  $i. $mod"
            $i++
        }
    }
    Write-Host ""
}

function Update-Metadata {
    Write-Host ""
    Write-Host "Regenerando mods-metadata.json..." -ForegroundColor Cyan

    # Regenerar metadata
    & powershell.exe -ExecutionPolicy Bypass -File generate-mods-metadata.ps1 | Out-Null

    if (Test-Path "mods-metadata.json") {
        # Eliminar metadata anterior si existe
        gh release delete-asset $RELEASE_TAG "mods-metadata.json" --yes 2>&1 | Out-Null

        # Subir nuevo metadata
        Write-Host "[>] Subiendo metadata actualizado..." -ForegroundColor Yellow
        gh release upload $RELEASE_TAG "mods-metadata.json"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Metadata actualizado" -ForegroundColor Green
        } else {
            Write-Host "[X] ERROR: Fallo al subir metadata" -ForegroundColor Red
        }
    }
    Write-Host ""
}

function Upload-Mods {
    param([string[]]$ModFiles)

    if (-not $ModFiles -or $ModFiles.Count -eq 0) {
        Write-Host "ERROR: No se especificaron archivos para subir" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Subiendo mods a release $RELEASE_TAG..." -ForegroundColor Cyan
    Write-Host ""

    $uploaded = 0
    $failed = 0

    foreach ($file in $ModFiles) {
        # Si es ruta absoluta, usarla directamente; si no, buscar en carpeta mods
        if ([System.IO.Path]::IsPathRooted($file)) {
            $filePath = $file
        } else {
            $filePath = Join-Path $MODS_FOLDER $file
        }

        if (-not (Test-Path $filePath)) {
            Write-Host "[X] ERROR: No existe '$filePath'" -ForegroundColor Red
            $failed++
            continue
        }

        $fileName = [System.IO.Path]::GetFileName($filePath)
        Write-Host "[>] Subiendo: $fileName" -ForegroundColor Yellow
        gh release upload $RELEASE_TAG $filePath

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Subido: $fileName" -ForegroundColor Green
            $uploaded++
        } else {
            Write-Host "[X] ERROR: Fallo $fileName" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host ""
    Write-Host "Resultado: $uploaded subidos, $failed fallidos"

    # Actualizar metadata automaticamente
    if ($uploaded -gt 0) {
        Update-Metadata
    }

    Write-Host ""
}

function Delete-Mods {
    param([string[]]$ModFiles)

    if (-not $ModFiles -or $ModFiles.Count -eq 0) {
        Write-Host "ERROR: No se especificaron archivos para eliminar" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Eliminando mods del release $RELEASE_TAG..." -ForegroundColor Cyan
    Write-Host ""

    $deleted = 0
    $failed = 0

    foreach ($file in $ModFiles) {
        Write-Host "[>] Eliminando: $file" -ForegroundColor Yellow
        gh release delete-asset $RELEASE_TAG $file --yes

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Eliminado: $file" -ForegroundColor Green
            $deleted++
        } else {
            Write-Host "[X] ERROR: Fallo $file (no existe?)" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host ""
    Write-Host "Resultado: $deleted eliminados, $failed fallidos"

    # Actualizar metadata automaticamente
    if ($deleted -gt 0) {
        Update-Metadata
    }

    Write-Host ""
}

switch ($Action) {
    "list" { List-Mods }
    "upload" { Upload-Mods -ModFiles $Files }
    "delete" { Delete-Mods -ModFiles $Files }
}
