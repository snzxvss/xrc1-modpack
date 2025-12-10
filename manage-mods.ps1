# Script para gestionar mods en GitHub
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("upload", "delete", "list", "delete-all", "detect-conflicts", "clean-names")]
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

function Delete-All-Mods {
    Write-Host ""
    Write-Host "Eliminando TODOS los mods del release $RELEASE_TAG..." -ForegroundColor Red
    Write-Host ""

    $jsonOutput = gh release view $RELEASE_TAG --json assets 2>&1 | Out-String
    $release = $jsonOutput | ConvertFrom-Json
    $modList = $release.assets | Where-Object { $_.name -like "*.jar" } | Select-Object -ExpandProperty name

    if (-not $modList -or $modList.Count -eq 0) {
        Write-Host "No hay mods para eliminar." -ForegroundColor Yellow
        return
    }

    Write-Host "Total de mods a eliminar: $($modList.Count)" -ForegroundColor Yellow
    Write-Host ""

    $deleted = 0
    foreach ($mod in $modList) {
        Write-Host "[>] Eliminando: $mod" -ForegroundColor Yellow
        gh release delete-asset $RELEASE_TAG $mod --yes 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Eliminado: $mod" -ForegroundColor Green
            $deleted++
        } else {
            Write-Host "[X] ERROR: Fallo $mod" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Total eliminado: $deleted de $($modList.Count)" -ForegroundColor Green
    Write-Host ""
}

function Detect-Conflicts {
    $SERVER_PATH = "C:\Users\opc\Desktop\Server-2025-2026\mods"
    $LOCAL_MODS = "mods"

    Write-Host ""
    Write-Host "Escaneando servidor, local y GitHub..." -ForegroundColor Cyan
    Write-Host ""

    # Servidor
    if (Test-Path $SERVER_PATH) {
        $serverMods = Get-ChildItem -Path $SERVER_PATH -Filter "*.jar" | Select-Object -ExpandProperty Name | Sort-Object
        Write-Host "Mods en servidor: $($serverMods.Count)" -ForegroundColor Yellow
    } else {
        $serverMods = @()
        Write-Host "Servidor no encontrado" -ForegroundColor Red
    }

    # Local
    if (Test-Path $LOCAL_MODS) {
        $localMods = Get-ChildItem -Path $LOCAL_MODS -Filter "*.jar" | Select-Object -ExpandProperty Name | Sort-Object
        Write-Host "Mods en local: $($localMods.Count)" -ForegroundColor Yellow
    } else {
        $localMods = @()
        Write-Host "Carpeta local no encontrada" -ForegroundColor Red
    }

    # GitHub
    $jsonOutput = gh release view $RELEASE_TAG --json assets 2>&1 | Out-String
    $release = $jsonOutput | ConvertFrom-Json
    $githubMods = $release.assets | Where-Object { $_.name -like "*.jar" } | Select-Object -ExpandProperty name | Sort-Object
    Write-Host "Mods en GitHub: $($githubMods.Count)" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "---------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""

    # Detectar conflictos
    $conflicts = $false

    # Mods solo en servidor
    $onlyServer = $serverMods | Where-Object { $_ -notin $localMods -and $_ -notin $githubMods }
    if ($onlyServer.Count -gt 0) {
        $conflicts = $true
        Write-Host "MODS SOLO EN SERVIDOR ($($onlyServer.Count)):" -ForegroundColor Red
        foreach ($mod in $onlyServer) {
            Write-Host "  - $mod"
        }
        Write-Host ""
    }

    # Mods solo en local
    $onlyLocal = $localMods | Where-Object { $_ -notin $serverMods -and $_ -notin $githubMods }
    if ($onlyLocal.Count -gt 0) {
        $conflicts = $true
        Write-Host "MODS SOLO EN LOCAL ($($onlyLocal.Count)):" -ForegroundColor Yellow
        foreach ($mod in $onlyLocal) {
            Write-Host "  - $mod"
        }
        Write-Host ""
    }

    # Mods solo en GitHub
    $onlyGitHub = $githubMods | Where-Object { $_ -notin $serverMods -and $_ -notin $localMods }
    if ($onlyGitHub.Count -gt 0) {
        $conflicts = $true
        Write-Host "MODS SOLO EN GITHUB ($($onlyGitHub.Count)):" -ForegroundColor Magenta
        foreach ($mod in $onlyGitHub) {
            Write-Host "  - $mod"
        }
        Write-Host ""
    }

    if (-not $conflicts) {
        Write-Host "No se detectaron conflictos. Todos los mods estan sincronizados." -ForegroundColor Green
    }

    Write-Host ""
}

function Clean-Names {
    $LOCAL_MODS = "mods"

    Write-Host ""
    Write-Host "Limpiando nombres de archivos..." -ForegroundColor Cyan
    Write-Host ""

    Get-ChildItem $LOCAL_MODS -Filter "*.jar" | Where-Object { $_.Name -match '[\[\] ]' } | ForEach-Object {
        $oldName = $_.Name
        $newName = $oldName -replace '[\[\] ]', '.'

        Write-Host "  $oldName" -ForegroundColor Yellow
        Write-Host "  -> $newName" -ForegroundColor Green

        Rename-Item -Path $_.FullName -NewName $newName -Force
    }

    Write-Host ""
    Write-Host "Limpieza completada" -ForegroundColor Green
    Write-Host ""
}

switch ($Action) {
    "list" { List-Mods }
    "upload" { Upload-Mods -ModFiles $Files }
    "delete" { Delete-Mods -ModFiles $Files }
    "delete-all" { Delete-All-Mods }
    "detect-conflicts" { Detect-Conflicts }
    "clean-names" { Clean-Names }
}
