@echo off
title XRC1 Mod Installer - Build and Release Tool
color 0B

:MENU
cls
echo.
echo ===============================================================
echo    XRC1 MOD INSTALLER - BUILD AND RELEASE TOOL
echo ===============================================================
echo.
echo  [1] Compilar nueva version (sin subir)
echo  [2] Compilar y subir a GitHub
echo  [3] Ver version actual
echo  [4] Editar notas del release
echo  [5] Salir
echo.
echo ===============================================================
echo.
set /p choice="Selecciona una opcion [1-5]: "

if "%choice%"=="1" goto BUILD_ONLY
if "%choice%"=="2" goto BUILD_UPLOAD
if "%choice%"=="3" goto VIEW_VERSION
if "%choice%"=="4" goto EDIT_NOTES
if "%choice%"=="5" goto END
goto MENU

:VIEW_VERSION
cls
echo.
echo ===============================================================
echo    VERSION ACTUAL
echo ===============================================================
echo.
if exist VERSION.txt (
    for /f "delims=" %%i in (VERSION.txt) do set current_version=%%i
    echo  Version actual: %current_version%
) else (
    echo  No se encontro VERSION.txt
)
echo.
echo ===============================================================
echo.
pause
goto MENU

:EDIT_NOTES
cls
echo.
echo ===============================================================
echo    EDITAR NOTAS DEL RELEASE
echo ===============================================================
echo.
echo  Abriendo RELEASE-TEMPLATE.txt en el editor...
echo  Edita las notas y guarda el archivo.
echo  La version {VERSION} se reemplazara automaticamente.
echo.
notepad RELEASE-TEMPLATE.txt
echo.
echo  Archivo guardado.
echo.
pause
goto MENU

:BUILD_ONLY
cls
echo.
echo ===============================================================
echo    COMPILANDO NUEVA VERSION
echo ===============================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File build-release.ps1
echo.
echo ===============================================================
echo.
pause
goto MENU

:BUILD_UPLOAD
cls
echo.
echo ===============================================================
echo    COMPILAR Y SUBIR A GITHUB
echo ===============================================================
echo.
echo  ADVERTENCIA: Esto subira la nueva version a GitHub
echo.
set /p confirm="Estas seguro? (S/N): "
if /i not "%confirm%"=="S" (
    echo  Operacion cancelada.
    pause
    goto MENU
)
echo.
powershell.exe -ExecutionPolicy Bypass -File build-release.ps1 -UploadToGitHub
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
