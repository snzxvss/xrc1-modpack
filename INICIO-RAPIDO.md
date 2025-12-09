# ⚡ Inicio Rápido - XRC1 Mod Installer

Este es el resumen ultra-rápido para poner tu instalador en funcionamiento.

---

## 🎯 Checklist de 5 Minutos

```
[ ] 1. Crear cuenta en GitHub
[ ] 2. Crear repositorio público
[ ] 3. Instalar GitHub CLI y autenticar
[ ] 4. Editar upload-to-github.py con tu info
[ ] 5. Ejecutar: python upload-to-github.py
[ ] 6. Ejecutar: python generate-mods-json.py
[ ] 7. Editar mods-config.json (reemplazar TU_USUARIO/TU_REPO)
[ ] 8. Editar src/main.js (reemplazar TU_USUARIO/TU_REPO)
[ ] 9. Subir a GitHub: git init && git add . && git commit -m "Initial" && git push
[ ] 10. Compilar: npm install && npm run build:win
[ ] 11. Distribuir: dist/XRC1 Mod Installer Setup.exe
```

---

## 📝 Comandos Rápidos

### Configuración Inicial

```bash
# 1. Instalar GitHub CLI
# Descargar de: https://cli.github.com/

# 2. Autenticar
gh auth login

# 3. Navegar al proyecto
cd "C:\Users\opc\Downloads\modsTest"

# 4. Editar archivos de configuración
# - upload-to-github.py → GITHUB_USER, GITHUB_REPO
# - mods-config.json → Reemplazar TU_USUARIO y TU_REPO
# - src/main.js → Línea 68, reemplazar URL

# 5. Subir mods a GitHub
python upload-to-github.py

# 6. Generar configuración
python generate-mods-json.py

# 7. Subir repositorio
git init
git add .
git commit -m "XRC1 Mod Installer inicial"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/TU-REPO.git
git push -u origin main

# 8. Instalar dependencias
npm install

# 9. Compilar instalador
npm run build:win

# 10. El instalador estará en: dist/XRC1 Mod Installer Setup.exe
```

---

## 🔄 Agregar Mods Nuevos

```bash
# 1. Agregar archivos .jar a carpeta mods/

# 2. Editar upload-to-github.py
# Cambiar: RELEASE_TAG = "v1.1.0"

# 3. Subir
python upload-to-github.py
python generate-mods-json.py

# 4. Editar mods-config.json (reemplazar TU_USUARIO/TU_REPO)

# 5. Actualizar repo
git add .
git commit -m "Nuevos mods v1.1.0"
git push

# 6. Recompilar
npm run build:win

# 7. Distribuir nueva versión
gh release create v1.1.0-installer "dist/XRC1 Mod Installer Setup.exe"
```

---

## 📋 Archivos que DEBES Editar

### 1. `upload-to-github.py`

```python
GITHUB_USER = "tu-usuario"      # <-- CAMBIAR
GITHUB_REPO = "xrc1-modpack"    # <-- CAMBIAR
RELEASE_TAG = "v1.0.0"
```

### 2. `mods-config.json`

Buscar y reemplazar:
- `TU_USUARIO` → `tu-usuario-real`
- `TU_REPO` → `xrc1-modpack`

### 3. `src/main.js` (línea 68)

```javascript
const configUrl = 'https://raw.githubusercontent.com/tu-usuario/xrc1-modpack/main/mods-config.json';
// Cambiar: tu-usuario y xrc1-modpack
```

---

## 🎨 Personalizar Logos (Opcional)

Colocar en carpeta `assets/`:
- `xrc1-logo.png` (400x400px) - Logo principal
- `xrc1-logo-small.png` (64x64px) - Logo barra de título
- `icon.ico` - Ícono Windows
- `icon.png` - Ícono Linux

**Tip:** Usa https://icoconvert.com/ para convertir PNG a ICO

---

## 🚀 Distribución

### Opción 1: GitHub Releases (Recomendado)

```bash
gh release create v1.0.0-installer \
  --title "XRC1 Mod Installer v1.0.0" \
  --notes "Instalador oficial" \
  "dist/XRC1 Mod Installer Setup.exe"
```

**Link para compartir:**
```
https://github.com/tu-usuario/xrc1-modpack/releases/latest
```

### Opción 2: Archivo Directo

Sube `dist/XRC1 Mod Installer Setup.exe` a:
- Google Drive
- Mega
- MediaFire
- Discord

---

## ❗ Puntos Críticos

### ✅ El instalador funcionará si:

1. ✓ Los mods están en GitHub Releases
2. ✓ El repositorio es **público**
3. ✓ `mods-config.json` tiene las URLs correctas
4. ✓ `src/main.js` apunta al archivo correcto en GitHub
5. ✓ Los usuarios tienen Internet al usar el instalador

### ❌ NO funcionará si:

1. ✗ El repositorio es privado
2. ✗ Las URLs en `mods-config.json` son incorrectas
3. ✗ No subiste los cambios a GitHub (`git push`)
4. ✗ Los archivos .jar no están en la release

---

## 🔍 Verificar que Todo Funciona

### Test 1: Verificar Mods en GitHub

```
https://github.com/tu-usuario/xrc1-modpack/releases/tag/v1.0.0
```

Deberías ver los 98 mods listados.

### Test 2: Verificar Configuración

```
https://raw.githubusercontent.com/tu-usuario/xrc1-modpack/main/mods-config.json
```

Deberías ver el JSON con la lista de mods.

### Test 3: Probar Instalador

1. Ejecuta el instalador compilado
2. Selecciona una carpeta de prueba
3. Verifica que se conecte a GitHub
4. Intenta descargar un mod

---

## 📞 Enlaces Útiles

- **Guía Completa:** [GUIA-SUBIR-MODS.md](GUIA-SUBIR-MODS.md)
- **README Usuarios:** [README.md](README.md)
- **GitHub CLI:** https://cli.github.com/
- **Node.js:** https://nodejs.org/
- **Python:** https://www.python.org/downloads/

---

## 💡 Tips Pro

1. **Usa Git para versionar:** Cada cambio importante, haz commit
2. **Incrementa versiones:** v1.0.0 → v1.1.0 → v1.2.0
3. **Prueba antes de distribuir:** Siempre prueba el .exe compilado
4. **Mantén el JSON actualizado:** Cada mod nuevo debe estar en mods-config.json
5. **Documenta cambios:** En cada release, explica qué cambió

---

## 🎉 Resultado Final

Tus usuarios podrán:

1. ✅ Descargar el instalador (.exe)
2. ✅ Ejecutarlo
3. ✅ Seleccionar su carpeta .minecraft
4. ✅ Ver qué mods tienen y cuáles les faltan
5. ✅ Descargar SOLO los mods que necesitan
6. ✅ Actualizar automáticamente cuando agregues mods nuevos

**Todo desde una interfaz bonita con la temática XRC1 🚗❄️**

---

**¿Listo? ¡Comienza con el checklist de arriba!** 🚀
