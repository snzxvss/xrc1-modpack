# 🚀 Guía de Instalación Rápida - XRC1 Mod Installer

Esta guía te llevará paso a paso para configurar y distribuir tu instalador de mods.

---

## 📋 Checklist Rápido

- [ ] Node.js instalado
- [ ] GitHub CLI instalado y autenticado
- [ ] Repositorio creado en GitHub
- [ ] Logos preparados
- [ ] Mods en la carpeta `mods/`

---

## Paso 1: Instalar Node.js

1. Descarga Node.js desde: https://nodejs.org/ (versión LTS)
2. Instala siguiendo el asistente
3. Verifica la instalación:
   ```bash
   node --version
   npm --version
   ```

---

## Paso 2: Instalar Dependencias del Proyecto

```bash
# Navega a la carpeta del proyecto
cd C:\Users\opc\Downloads\modsTest

# Instala las dependencias
npm install
```

---

## Paso 3: Preparar los Logos

### Opción A: Usar la imagen de XRC1 que ya tienes

1. Abre `unnamed.jpg` en un editor de imágenes
2. Recorta el logo del crew
3. Guárdalo en diferentes tamaños:
   - `assets/xrc1-logo.png` (400x400px)
   - `assets/xrc1-logo-small.png` (64x64px)

### Opción B: Usar herramientas online

1. Sube `unnamed.jpg` a un editor online como:
   - https://www.photopea.com/
   - https://pixlr.com/

2. Recorta y redimensiona el logo

3. Exporta los archivos necesarios

### Crear íconos de aplicación

**Para Windows (icon.ico):**
- Ve a: https://icoconvert.com/
- Sube tu logo PNG
- Descarga el `.ico` y guárdalo en `assets/icon.ico`

**Para otros sistemas:**
- `icon.png` (512x512px) - Linux
- `icon.icns` - macOS (opcional)

---

## Paso 4: Crear Repositorio en GitHub

### 4.1 Crear el repositorio

1. Ve a: https://github.com/new
2. Nombre del repo: `xrc1-modpack` (o el que prefieras)
3. Descripción: "XRC1 Crew Minecraft Modpack Installer"
4. Público o Privado (según prefieras)
5. Click en "Create repository"

### 4.2 Conectar tu proyecto local

```bash
# Inicializar git (si no lo has hecho)
git init

# Agregar archivos
git add .

# Hacer commit
git commit -m "Initial commit - XRC1 Mod Installer"

# Conectar con GitHub (reemplaza con tu info)
git remote add origin https://github.com/TU_USUARIO/xrc1-modpack.git
git branch -M main
git push -u origin main
```

---

## Paso 5: Instalar y Configurar GitHub CLI

### 5.1 Instalar GitHub CLI

**Windows:**
- Descarga desde: https://cli.github.com/
- Ejecuta el instalador
- Reinicia el terminal

**Verificar instalación:**
```bash
gh --version
```

### 5.2 Autenticarse

```bash
gh auth login

# Selecciona:
# - GitHub.com
# - HTTPS
# - Login with a web browser
```

---

## Paso 6: Subir los Mods a GitHub Releases

### 6.1 Editar el script de subida

Abre `upload-to-github.py` y modifica:

```python
GITHUB_USER = "tu-usuario"        # Tu usuario de GitHub
GITHUB_REPO = "xrc1-modpack"      # Nombre de tu repo
RELEASE_TAG = "v1.0.0"            # Versión inicial
```

### 6.2 Ejecutar el script

```bash
python upload-to-github.py
```

Este proceso puede tardar dependiendo de tu conexión, ya que subirá los 98 mods.

**Tiempo estimado:** 10-30 minutos (dependiendo de tu conexión)

---

## Paso 7: Generar la Configuración de Mods

```bash
# Genera el archivo mods-config.json automáticamente
python generate-mods-json.py
```

Luego abre `mods-config.json` y verifica que las URLs sean correctas.

---

## Paso 8: Probar el Instalador

```bash
npm start
```

Esto abrirá el instalador. Prueba:
1. Seleccionar una carpeta
2. Ver que la interfaz se vea correctamente
3. Cerrar y hacer ajustes si es necesario

---

## Paso 9: Compilar el Instalador

### Para Windows:

```bash
npm run build:win
```

El instalador se generará en `dist/XRC1 Mod Installer Setup.exe`

### Para otros sistemas:

```bash
# macOS
npm run build:mac

# Linux
npm run build:linux

# Todos
npm run build
```

---

## Paso 10: Distribuir

### Opción A: Subir a GitHub Releases

```bash
# Crear una nueva release para el instalador
gh release create v1.0.0-installer \
  --title "XRC1 Mod Installer v1.0.0" \
  --notes "Instalador oficial del XRC1 Modpack" \
  "dist/XRC1 Mod Installer Setup.exe"
```

### Opción B: Compartir directamente

Comparte el archivo `.exe` de la carpeta `dist/` por:
- Discord
- Google Drive
- Dropbox
- etc.

---

## 🎉 ¡Listo!

Ahora tus amigos pueden:

1. Descargar el instalador
2. Ejecutarlo
3. Seleccionar su carpeta `.minecraft`
4. Instalar todos los mods automáticamente

---

## 🔄 Actualizar Mods en el Futuro

Cuando quieras agregar o actualizar mods:

1. **Agrega los nuevos mods** a la carpeta `mods/`

2. **Edita el script** `upload-to-github.py`:
   ```python
   RELEASE_TAG = "v1.1.0"  # Incrementa la versión
   ```

3. **Sube los mods**:
   ```bash
   python upload-to-github.py
   ```

4. **Regenera la config**:
   ```bash
   python generate-mods-json.py
   ```

5. **Recompila el instalador**:
   ```bash
   npm run build:win
   ```

6. **Sube la nueva versión**:
   ```bash
   gh release create v1.1.0-installer \
     "dist/XRC1 Mod Installer Setup.exe"
   ```

---

## ❓ Problemas Comunes

### "gh: command not found"
- Reinstala GitHub CLI y reinicia el terminal

### "Permission denied" al subir
- Ejecuta: `gh auth login` nuevamente

### Los mods no se descargan
- Verifica que las URLs en `mods-config.json` sean correctas
- Asegúrate de que la release sea pública

### El instalador no compila
- Verifica que todas las dependencias estén instaladas: `npm install`
- Elimina `node_modules` y reinstala: `rm -rf node_modules && npm install`

---

## 📞 Soporte

Si tienes problemas:
1. Revisa el archivo `README.md`
2. Verifica los logs en la consola
3. Abre un issue en GitHub

---

**Made with ❄️ by XRC1 Crew**
