@echo off
title XRC1 Mod Manager - GitHub Release Tool
color 0E

:MENU
cls
echo.
echo ===============================================================
echo    XRC1 MOD MANAGER - GITHUB RELEASE TOOL
echo ===============================================================
echo.
echo  [1] Listar todos los mods
echo  [2] Subir un mod (.jar)
echo  [3] Subir multiples mods
echo  [4] Eliminar un mod
echo  [5] Eliminar multiples mods
echo  [6] Ver informacion del release
echo  [7] Salir
echo.
echo ===============================================================
echo.
set /p choice="Selecciona una opcion [1-7]: "

if "%choice%"=="1" goto LIST_MODS
if "%choice%"=="2" goto UPLOAD_ONE
if "%choice%"=="3" goto UPLOAD_MANY
if "%choice%"=="4" goto DELETE_ONE
if "%choice%"=="5" goto DELETE_MANY
if "%choice%"=="6" goto VIEW_INFO
if "%choice%"=="7" goto END
goto MENU

:LIST_MODS
cls
echo.
echo ===============================================================
echo    LISTANDO MODS EN RELEASE v1.0.0
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

:UPLOAD_MANY
cls
echo.
echo ===============================================================
echo    SUBIR MULTIPLES MODS
echo ===============================================================
echo.
echo  Opciones:
echo   1. Subir todos los .jar de la carpeta 'mods'
echo   2. Especificar archivos manualmente
echo.
set /p uploadchoice="Selecciona [1-2]: "

if "%uploadchoice%"=="1" (
    echo.
    echo  Buscando archivos .jar en la carpeta 'mods'...
    echo.
    if not exist "mods\*.jar" (
        echo  ERROR: No se encontraron archivos .jar en la carpeta 'mods'
        pause
        goto MENU
    )
    powershell.exe -ExecutionPolicy Bypass -Command "$files = Get-ChildItem 'mods\*.jar' | ForEach-Object { $_.FullName }; .\manage-mods.ps1 upload -Files $files"
) else (
    echo.
    echo  Escribe las rutas de los archivos separadas por coma:
    echo  Ejemplo: mod1.jar, mod2.jar, mod3.jar
    echo.
    set /p modfiles="Archivos: "
    echo.
    powershell.exe -ExecutionPolicy Bypass -Command "$files = '%modfiles%' -split ',' | ForEach-Object { $_.Trim().Trim('\"') }; .\manage-mods.ps1 upload -Files $files"
)
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

:VIEW_INFO
cls
echo.
echo ===============================================================
echo    INFORMACION DEL RELEASE v1.0.0
echo ===============================================================
echo.
gh release view v1.0.0
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
