# Script para renombrar mods con caracteres problematicos
$SERVER_MODS = "C:\Users\opc\Desktop\Server-2025-2026\mods"

Write-Host "Renombrando mods con caracteres especiales..." -ForegroundColor Cyan
Write-Host ""

Get-ChildItem $SERVER_MODS -Filter "*.jar" | Where-Object { $_.Name -match '[\[\] ]' } | ForEach-Object {
    $oldName = $_.Name
    $newName = $oldName -replace '[\[\] ]', '.'

    Write-Host "  $oldName" -ForegroundColor Yellow
    Write-Host "  -> $newName" -ForegroundColor Green

    Rename-Item -Path $_.FullName -NewName $newName -Force
}

Write-Host ""
Write-Host "Completado" -ForegroundColor Green
