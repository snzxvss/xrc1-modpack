# 📤 Guía: Cómo Subir Mods a GitHub

Esta guía te enseñará paso a paso cómo subir tus mods a GitHub para que el instalador funcione.

---

## 📋 Lo que Necesitas

- [ ] Cuenta de GitHub (gratis)
- [ ] GitHub CLI instalado
- [ ] Los mods en la carpeta `mods/`

---

## Paso 1: Crear Cuenta en GitHub

Si ya tienes cuenta, salta al Paso 2.

1. Ve a https://github.com/
2. Haz clic en "Sign up"
3. Sigue los pasos para crear tu cuenta
4. Verifica tu email

---

## Paso 2: Crear un Repositorio Nuevo

1. Inicia sesión en GitHub
2. Haz clic en el `+` (arriba a la derecha) → "New repository"

3. Configura el repositorio:
   - **Repository name:** `xrc1-modpack` (o el nombre que quieras)
   - **Description:** "XRC1 Crew Modpack para Minecraft 1.20.1"
   - **Visibility:**
     - ✅ **Public** (recomendado para que todos puedan descargar)
     - ❌ Private (si lo haces privado, solo tú y colaboradores podrán descargar)
   - **NO** marques "Add a README file"
   - **NO** marques "Add .gitignore"
   - **NO** marques "Choose a license"

4. Haz clic en "Create repository"

5. **IMPORTANTE:** Guarda la URL de tu repositorio, se verá así:
   ```
   https://github.com/TU-USUARIO/xrc1-modpack
   ```

---

## Paso 3: Instalar GitHub CLI

### Descargar GitHub CLI

1. Ve a: https://cli.github.com/
2. Haz clic en "Download for Windows"
3. Ejecuta el instalador
4. Sigue el asistente (deja todo por defecto)
5. **Reinicia** tu terminal/PowerShell

### Verificar Instalación

Abre una nueva ventana de PowerShell o CMD y escribe:

```bash
gh --version
```

Deberías ver algo como: `gh version 2.40.0`

---

## Paso 4: Autenticar GitHub CLI

1. En PowerShell o CMD, escribe:

```bash
gh auth login
```

2. Responde las preguntas:

```
? What account do you want to log into?
→ GitHub.com

? What is your preferred protocol for Git operations?
→ HTTPS

? Authenticate Git with your GitHub credentials?
→ Yes

? How would you like to authenticate GitHub CLI?
→ Login with a web browser
```

3. Te dará un código de 8 dígitos
4. Presiona Enter para abrir el navegador
5. Pega el código en la página web
6. Haz clic en "Authorize"
7. Verás "✓ Logged in as TU-USUARIO"

---

## Paso 5: Configurar el Script de Subida

1. Abre el archivo `upload-to-github.py` con un editor de texto (Notepad, VSCode, etc.)

2. Encuentra estas líneas al inicio:

```python
GITHUB_USER = "TU_USUARIO"  # Tu usuario de GitHub
GITHUB_REPO = "TU_REPO"     # Nombre del repositorio
RELEASE_TAG = "v1.0.0"      # Tag de la release
```

3. Cámbialas por tu información. Por ejemplo:

```python
GITHUB_USER = "juanperez"      # Tu usuario de GitHub
GITHUB_REPO = "xrc1-modpack"   # El nombre que pusiste en Paso 2
RELEASE_TAG = "v1.0.0"         # Déjalo así
```

4. Guarda el archivo

---

## Paso 6: Subir los Mods

### Verificar que Python está instalado

Abre PowerShell y escribe:

```bash
python --version
```

Si no está instalado, descárgalo de: https://www.python.org/downloads/

### Ejecutar el Script

1. Abre PowerShell
2. Navega a la carpeta del proyecto:

```bash
cd "C:\Users\opc\Downloads\modsTest"
```

3. Ejecuta el script:

```bash
python upload-to-github.py
```

4. Verás algo como:

```
============================================================
  XRC1 CREW - GITHUB RELEASE UPLOADER
============================================================

📋 Configuración:
   Usuario: juanperez
   Repositorio: xrc1-modpack
   Tag: v1.0.0

⏸  Presiona ENTER para continuar o CTRL+C para cancelar...
```

5. Presiona **ENTER** para continuar

6. El script comenzará a subir los mods. Verás:

```
📦 Creando release...
✓ Release creada

📤 Subiendo 98 mods...

[1/98] Subiendo: ad_astra-forge-1.20.1-1.15.20.jar
✓ Subido
[2/98] Subiendo: alexscaves-2.0.2.jar
✓ Subido
...
```

**⏱ IMPORTANTE:** Este proceso puede tardar 30-60 minutos dependiendo de tu velocidad de internet. **No cierres la ventana.**

---

## Paso 7: Verificar que los Mods se Subieron

1. Ve a tu repositorio en GitHub:
   ```
   https://github.com/TU-USUARIO/xrc1-modpack
   ```

2. Haz clic en "Releases" (lado derecho de la página)

3. Deberías ver tu release "v1.0.0" con los 98 mods listados

4. Haz clic en algún mod para verificar que se puede descargar

---

## Paso 8: Actualizar el Archivo de Configuración

### Generar mods-config.json

1. En PowerShell, ejecuta:

```bash
python generate-mods-json.py
```

2. Verás:

```
✓ Archivo generado exitosamente
✓ Total de mods: 98

RECUERDA:
1. Editar el archivo y cambiar 'TU_USUARIO' y 'TU_REPO'
2. Subir el archivo a GitHub
```

### Editar mods-config.json

1. Abre `mods-config.json` con un editor de texto

2. Usa **Buscar y Reemplazar** (Ctrl+H):
   - **Buscar:** `TU_USUARIO`
   - **Reemplazar:** `tu-usuario-real` (tu usuario de GitHub)
   - Reemplazar todo

3. Repite para el repositorio:
   - **Buscar:** `TU_REPO`
   - **Reemplazar:** `xrc1-modpack` (tu nombre de repo)
   - Reemplazar todo

4. Guarda el archivo

---

## Paso 9: Subir el Repositorio a GitHub

### Primera vez - Inicializar Git

1. En PowerShell, en la carpeta del proyecto:

```bash
git init
git add .
git commit -m "Initial commit: XRC1 Mod Installer"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/xrc1-modpack.git
git push -u origin main
```

**IMPORTANTE:** Reemplaza `TU-USUARIO` con tu usuario real de GitHub.

2. Te pedirá tus credenciales de GitHub (usa las de tu cuenta)

---

## Paso 10: Actualizar main.js con tu Información

1. Abre el archivo `src/main.js`

2. Busca esta línea (aproximadamente línea 68):

```javascript
const configUrl = 'https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/mods-config.json';
```

3. Cámbiala por:

```javascript
const configUrl = 'https://raw.githubusercontent.com/tu-usuario/xrc1-modpack/main/mods-config.json';
```

4. Guarda el archivo

5. Sube los cambios a GitHub:

```bash
git add src/main.js
git commit -m "Actualizar URL de configuración"
git push
```

---

## Paso 11: Compilar el Instalador

1. Instala las dependencias (solo la primera vez):

```bash
npm install
```

2. Compila el instalador:

```bash
npm run build:win
```

3. Espera a que termine (puede tardar 2-5 minutos)

4. El instalador estará en: `dist/XRC1 Mod Installer Setup.exe`

---

## Paso 12: Distribuir el Instalador

### Opción A: Subir a GitHub Releases

```bash
gh release create v1.0.0-installer --title "XRC1 Mod Installer v1.0.0" --notes "Instalador oficial del XRC1 Modpack" "dist/XRC1 Mod Installer Setup.exe"
```

Luego comparte el link:
```
https://github.com/tu-usuario/xrc1-modpack/releases/latest
```

### Opción B: Compartir el Archivo Directamente

Comparte el archivo `dist/XRC1 Mod Installer Setup.exe` por:
- Discord
- Google Drive
- Mega
- MediaFire
- etc.

---

## 🔄 Agregar Más Mods en el Futuro

Cuando quieras agregar mods nuevos:

### 1. Agrega los archivos .jar a la carpeta `mods/`

### 2. Edita upload-to-github.py

Cambia la versión:
```python
RELEASE_TAG = "v1.1.0"  # Incrementa el número
```

### 3. Sube la nueva versión

```bash
python upload-to-github.py
```

### 4. Regenera la configuración

```bash
python generate-mods-json.py
```

### 5. Edita mods-config.json

Reemplaza `TU_USUARIO` y `TU_REPO` como en el Paso 8.

### 6. Sube los cambios

```bash
git add .
git commit -m "Agregar nuevos mods v1.1.0"
git push
```

### 7. Recompila el instalador

```bash
npm run build:win
```

### 8. Distribuye la nueva versión

```bash
gh release create v1.1.0-installer --title "XRC1 Mod Installer v1.1.0" --notes "Nuevos mods agregados" "dist/XRC1 Mod Installer Setup.exe"
```

**¡Listo!** Los usuarios solo necesitan abrir el instalador de nuevo y automáticamente verán los mods nuevos disponibles para descargar.

---

## ❓ Problemas Comunes

### "gh: command not found"

**Solución:**
1. Reinstala GitHub CLI
2. Reinicia PowerShell
3. Verifica con: `gh --version`

### "Permission denied" al subir

**Solución:**
```bash
gh auth login
```

Vuelve a autenticarte.

### "python: command not found"

**Solución:**
1. Instala Python desde https://www.python.org/downloads/
2. Durante la instalación, marca "Add Python to PATH"
3. Reinicia PowerShell

### "npm: command not found"

**Solución:**
1. Instala Node.js desde https://nodejs.org/
2. Reinicia PowerShell
3. Verifica con: `npm --version`

### Los mods no se descargan en el instalador

**Solución:**
1. Verifica que la release sea **pública**
2. Comprueba que las URLs en `mods-config.json` sean correctas
3. Verifica que `src/main.js` tenga la URL correcta

### Error: "Release already exists"

**Solución:**

Si necesitas resubir:
```bash
gh release delete v1.0.0 --yes
python upload-to-github.py
```

---

## 📞 ¿Necesitas Ayuda?

Si tienes problemas:
1. Revisa esta guía desde el inicio
2. Verifica que todos los pasos estén completos
3. Pregunta en el Discord del crew
4. Abre un issue en GitHub

---

**¡Éxito! Ahora tu instalador está listo para distribuir.** 🎉
