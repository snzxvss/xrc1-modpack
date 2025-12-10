@echo off
title XRC1 Mod Manager - Advanced Tool
color 0E

:MENU
cls
echo.
echo ===============================================================
echo    XRC1 MOD MANAGER - ADVANCED TOOL
echo ===============================================================
echo.
echo  OPERACIONES BASICAS:
echo  [1] Listar todos los mods en GitHub
echo  [2] Subir un mod
echo  [3] Subir todos los mods de la carpeta local
echo  [4] Eliminar un mod
echo  [5] Eliminar multiples mods
echo  [6] ELIMINAR TODOS LOS MODS (peligroso!)
echo.
echo  HERRAMIENTAS DE AYUDA:
echo  [7] Detectar conflictos entre servidor/local/GitHub
echo  [8] Limpiar nombres de archivos (quitar caracteres especiales)
echo  [9] Sincronizar servidor -> local -> GitHub
echo  [10] Regenerar metadata manualmente
echo  [11] Ver informacion del release
echo.
echo  [0] Salir
echo.
echo ===============================================================
echo.
set /p choice="Selecciona una opcion: "

if "%choice%"=="1" goto LIST_MODS
if "%choice%"=="2" goto UPLOAD_ONE
if "%choice%"=="3" goto UPLOAD_ALL
if "%choice%"=="4" goto DELETE_ONE
if "%choice%"=="5" goto DELETE_MANY
if "%choice%"=="6" goto DELETE_ALL
if "%choice%"=="7" goto DETECT_CONFLICTS
if "%choice%"=="8" goto CLEAN_NAMES
if "%choice%"=="9" goto FULL_SYNC
if "%choice%"=="10" goto REGEN_METADATA
if "%choice%"=="11" goto VIEW_INFO
if "%choice%"=="0" goto END
goto MENU

:LIST_MODS
cls
echo.
echo ===============================================================
echo    LISTANDO MODS EN GITHUB
echo ===============================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 list
echo.
echo ===============================================================
echo.
pause
goto MENU

:UPLOAD_ONE
cls
echo.
echo ===============================================================
echo    SUBIR UN MOD
echo ===============================================================
echo.
echo  Arrastra el archivo .jar aqui y presiona Enter
echo  (o escribe la ruta completa)
echo.
set /p modfile="Archivo: "
set modfile=%modfile:"=%
echo.
if not exist "%modfile%" (
    echo  ERROR: El archivo no existe
    pause
    goto MENU
)
echo  Subiendo %modfile%...
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 upload -Files "%modfile%"
echo.
echo ===============================================================
echo.
pause
goto MENU

:UPLOAD_ALL
cls
echo.
echo ===============================================================
echo    SUBIR TODOS LOS MODS DE LA CARPETA LOCAL
echo ===============================================================
echo.
if not exist "mods\*.jar" (
    echo  ERROR: No se encontraron archivos .jar en la carpeta 'mods'
    pause
    goto MENU
)
echo  Buscando mods en carpeta local...
powershell.exe -ExecutionPolicy Bypass -Command "$count = (Get-ChildItem 'mods\*.jar').Count; Write-Host \"  Se encontraron $count mods\""
echo.
set /p confirm="Subir todos los mods? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -Command "$files = Get-ChildItem 'mods\*.jar' | ForEach-Object { $_.FullName }; .\manage-mods.ps1 upload -Files $files"
echo.
echo ===============================================================
echo.
pause
goto MENU

:DELETE_ONE
cls
echo.
echo ===============================================================
echo    ELIMINAR UN MOD
echo ===============================================================
echo.
echo  Mods disponibles:
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 list
echo.
echo ---------------------------------------------------------------
echo.
set /p modname="Nombre del mod a eliminar (con extension .jar): "
echo.
echo  ADVERTENCIA: Esto eliminara permanentemente el mod del release
set /p confirm="Estas seguro? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 delete -Files "%modname%"
echo.
echo ===============================================================
echo.
pause
goto MENU

:DELETE_MANY
cls
echo.
echo ===============================================================
echo    ELIMINAR MULTIPLES MODS
echo ===============================================================
echo.
echo  Mods disponibles:
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 list
echo.
echo ---------------------------------------------------------------
echo.
echo  Escribe los nombres de los mods separados por coma:
echo  Ejemplo: mod1.jar, mod2.jar, mod3.jar
echo.
set /p modnames="Mods a eliminar: "
echo.
echo  ADVERTENCIA: Esto eliminara permanentemente los mods del release
set /p confirm="Estas seguro? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -Command "$files = '%modnames%' -split ',' | ForEach-Object { $_.Trim() }; .\manage-mods.ps1 delete -Files $files"
echo.
echo ===============================================================
echo.
pause
goto MENU

:DELETE_ALL
cls
echo.
echo ===============================================================
echo    ELIMINAR TODOS LOS MODS
echo ===============================================================
echo.
echo  ADVERTENCIA CRITICA: Esto eliminara TODOS los mods del release!
echo  Esta operacion NO se puede deshacer!
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 list
echo.
echo ---------------------------------------------------------------
echo.
set /p confirm1="Seguro que quieres eliminar TODOS los mods? (S/N): "
if /i not "%confirm1%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
set /p confirm2="CONFIRMACION FINAL - Escribe 'ELIMINAR TODO' para continuar: "
if not "%confirm2%"=="ELIMINAR TODO" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
echo  Eliminando todos los mods...
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 delete-all
echo.
echo ===============================================================
echo.
pause
goto MENU

:DETECT_CONFLICTS
cls
echo.
echo ===============================================================
echo    DETECTAR CONFLICTOS
echo ===============================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 detect-conflicts
echo.
echo ===============================================================
echo.
pause
goto MENU

:CLEAN_NAMES
cls
echo.
echo ===============================================================
echo    LIMPIAR NOMBRES DE ARCHIVOS
echo ===============================================================
echo.
echo  Esta herramienta renombra archivos con caracteres especiales:
echo  - Corchetes [] se convierten en puntos .
echo  - Espacios se convierten en puntos .
echo  - Exclamaciones ! se mantienen
echo.
echo  Archivos afectados:
powershell.exe -ExecutionPolicy Bypass -Command "Get-ChildItem 'mods\*.jar' | Where-Object { $_.Name -match '[\[\] ]' } | ForEach-Object { Write-Host \"  - $($_.Name)\" }"
echo.
set /p confirm="Renombrar estos archivos? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -File manage-mods.ps1 clean-names
echo.
echo ===============================================================
echo.
pause
goto MENU

:FULL_SYNC
cls
echo.
echo ===============================================================
echo    SINCRONIZACION COMPLETA
echo ===============================================================
echo.
echo  Este proceso:
echo  1. Copia mods del servidor al proyecto local
echo  2. Sube mods faltantes a GitHub
echo  3. Actualiza metadata
echo.
set /p confirm="Iniciar sincronizacion? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -File server-start.ps1 -OnlySync
echo.
echo ===============================================================
echo.
pause
goto MENU

:REGEN_METADATA
cls
echo.
echo ===============================================================
echo    REGENERAR METADATA
echo ===============================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File generate-mods-metadata.ps1
echo.
set /p upload="Subir metadata a GitHub? (S/N): "
if /i "%upload%"=="S" (
    echo.
    "C:\Program Files\GitHub CLI\gh.exe" release delete-asset v1.0.0 "mods-metadata.json" --yes 2>nul
    "C:\Program Files\GitHub CLI\gh.exe" release upload v1.0.0 "mods-metadata.json"
    echo.
    echo  Metadata actualizado en GitHub
)
echo.
echo ===============================================================
echo.
pause
goto MENU

:VIEW_INFO
cls
echo.
echo ===============================================================
echo    INFORMACION DEL RELEASE v1.0.0
echo ===============================================================
echo.
"C:\Program Files\GitHub CLI\gh.exe" release view v1.0.0
echo.
echo ===============================================================
echo.
pause
goto MENU

:END
cls
echo.
echo  Saliendo...
echo.
timeout /t 1 >nul
exit
