# 🛠️ Herramientas de Desarrollo

## 📦 Build & Release Tool

**Archivo:** `build-release.bat`

Herramienta con menú interactivo para compilar y publicar nuevas versiones del instalador.

### Opciones:

1. **Compilar nueva versión (sin subir)**
   - Compila la app y genera el .exe en `releases/vX.Y.Z/`
   - Incrementa automáticamente la versión
   - NO sube a GitHub

2. **Compilar y subir a GitHub**
   - Compila la app
   - Sube el .exe a GitHub
   - Actualiza la descripción del release con la plantilla
   - Elimina versiones anteriores automáticamente

3. **Ver versión actual**
   - Muestra la versión actual desde `VERSION.txt`

4. **Editar notas del release**
   - Abre `RELEASE-TEMPLATE.txt` en el Bloc de notas
   - Edita las novedades de la versión
   - El texto `{VERSION}` se reemplaza automáticamente

### Plantilla de Release

**Archivo:** `RELEASE-TEMPLATE.txt`

```
🎮 **XRC1 Crew Mod Installer**

Instalador automatizado de mods para el servidor de Minecraft XRC1 Crew (v1.20.1).
Descarga e instala todos los mods necesarios para conectarte al servidor sin complicaciones.
Incluye instalador de Forge y detección automática de mods faltantes.

---

## 🆕 Novedades v{VERSION}

✅ **Arreglado:** Descripción del bug corregido
✅ **Agregado:** Nueva funcionalidad implementada
✅ **Mejorado:** Optimización o mejora realizada

---

📥 **Descarga:** [XRC1-Mod-Installer-v{VERSION}.exe](...)
```

**Uso:**
1. Ejecuta `build-release.bat`
2. Selecciona opción 4 (Editar notas del release)
3. Modifica las líneas de "Novedades" con los cambios reales
4. Guarda y cierra
5. Compila y sube (opción 2)

---

## 🎮 Mod Manager Tool

**Archivo:** `manage-mods.bat`

Herramienta con menú interactivo para gestionar los mods en el release de GitHub.

### Opciones:

1. **Listar todos los mods**
   - Muestra todos los .jar en el release v1.0.0
   - Incluye contador de mods

2. **Subir un mod (.jar)**
   - Arrastra el archivo .jar o escribe la ruta
   - Sube el mod al release v1.0.0

3. **Subir múltiples mods**
   - Opción 1: Sube todos los .jar de la carpeta `mods/`
   - Opción 2: Especifica archivos manualmente (separados por coma)

4. **Eliminar un mod**
   - Primero muestra la lista de mods
   - Pide el nombre del mod a eliminar
   - Confirmación de seguridad

5. **Eliminar múltiples mods**
   - Especifica varios mods separados por coma
   - Confirmación de seguridad

6. **Ver información del release**
   - Muestra info completa del release v1.0.0
   - Fecha, tamaño, assets, etc.

### Ejemplos de uso:

**Subir un mod:**
```
1. Ejecuta manage-mods.bat
2. Selecciona opción 2
3. Arrastra el archivo mod.jar
4. Presiona Enter
```

**Subir todos los mods de una carpeta:**
```
1. Coloca todos los .jar en la carpeta mods/
2. Ejecuta manage-mods.bat
3. Selecciona opción 3
4. Selecciona opción 1
```

**Eliminar mods:**
```
1. Ejecuta manage-mods.bat
2. Selecciona opción 1 para ver lista
3. Selecciona opción 4 o 5
4. Escribe el/los nombre(s)
5. Confirma con S
```

---

## 📋 Flujo de Trabajo Recomendado

### Para publicar una nueva versión:

1. **Editar código fuente** (arreglar bugs, agregar features)

2. **Editar notas del release:**
   - Ejecuta `build-release.bat`
   - Opción 4: Editar notas
   - Describe los cambios en `RELEASE-TEMPLATE.txt`

3. **Compilar y publicar:**
   - Opción 2: Compilar y subir a GitHub
   - Confirma con S
   - Espera la compilación (~10 segundos)
   - ¡Listo! Nueva versión publicada

### Para gestionar mods:

1. **Ver mods actuales:**
   - Ejecuta `manage-mods.bat`
   - Opción 1: Listar mods

2. **Agregar mods:**
   - Descarga los .jar
   - Opción 2 o 3: Subir

3. **Actualizar un mod:**
   - Opción 4: Eliminar mod viejo
   - Opción 2: Subir mod nuevo

---

## 🔧 Requisitos

- **Rust/Cargo** instalado (para compilar)
- **GitHub CLI** (`gh`) configurado
- **PowerShell** habilitado
- **Git** configurado

---

## ⚠️ Notas Importantes

- El build incrementa la versión automáticamente (patch +1)
- Solo hay un .exe en GitHub a la vez (elimina el anterior)
- Los mods se gestionan en el release `v1.0.0`
- El instalador se gestiona en el release `installer`
- Siempre confirma antes de eliminar o subir

---

## 📞 Soporte

Si algo falla:
1. Verifica que `gh` esté autenticado: `gh auth status`
2. Verifica que Cargo funcione: `cargo --version`
3. Revisa los logs en el instalador: `installer.log`
