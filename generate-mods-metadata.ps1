# Script para generar mods-metadata.json con side info
$GITHUB_RELEASE_TAG = "v1.0.0"
$OUTPUT_FILE = "mods-metadata.json"

Write-Host "Obteniendo lista de mods desde GitHub..." -ForegroundColor Cyan

# Obtener lista de mods
$jsonOutput = gh release view $GITHUB_RELEASE_TAG --json assets | ConvertFrom-Json
$mods = $jsonOutput.assets | Where-Object { $_.name -like "*.jar" } | Select-Object -ExpandProperty name | Sort-Object

# Mods que solo van en cliente (client-only)
$clientOnlyMods = @(
    "oculus-mc1.20.1-1.8.0.jar",
    "embeddium-0.3.31+mc1.20.1.jar",
    "journeymap-1.20.1-5.10.3-forge.jar",
    "appleskin-forge-mc1.20.1-2.5.1.jar",
    "jei-1.20.1-forge-15.20.0.127.jar",
    "ImmediatelyFast-Forge-1.5.2+1.20.4.jar",
    "Jade-1.20.1-Forge-11.13.2.jar"
)

# Crear array de objetos
$modsMetadata = @()

foreach ($mod in $mods) {
    $side = if ($clientOnlyMods -contains $mod) { "client" } else { "both" }

    $modsMetadata += [PSCustomObject]@{
        filename = $mod
        side = $side
    }
}

# Crear objeto final
$finalObject = [PSCustomObject]@{
    minecraftVersion = "1.20.1"
    forgeVersion = "1.20.1-47.3.0"
    forgeDownloadUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar"
    githubRepo = "snzxvss/xrc1-modpack"
    releaseTag = $GITHUB_RELEASE_TAG
    mods = $modsMetadata
}

# Guardar JSON
$finalObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $OUTPUT_FILE -Encoding UTF8

Write-Host "Generado: $OUTPUT_FILE" -ForegroundColor Green
Write-Host "Total de mods: $($mods.Count)" -ForegroundColor Yellow
Write-Host "Client-only: $($clientOnlyMods.Count)" -ForegroundColor Yellow
Write-Host "Both sides: $($mods.Count - $clientOnlyMods.Count)" -ForegroundColor Yellow
