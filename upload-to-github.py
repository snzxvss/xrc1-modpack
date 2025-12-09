"""
Script para subir mods a GitHub Releases

REQUISITOS:
1. Instalar GitHub CLI: https://cli.github.com/
2. Autenticarse: gh auth login
3. Crear un repositorio en GitHub
4. Configurar las variables al inicio del script
"""

import os
import subprocess

# ====== CONFIGURACIÓN ======
GITHUB_USER = "snzxvss"  # Tu usuario de GitHub
GITHUB_REPO = "xrc1-modpack"     # Nombre del repositorio
RELEASE_TAG = "v1.0.0"      # Tag de la release
RELEASE_TITLE = "XRC1 Modpack v1.0.0"
RELEASE_NOTES = """
# XRC1 Crew Modpack v1.0.0

Modpack oficial del XRC1 Crew para Minecraft 1.20.1

## Contenido
- 98 mods cuidadosamente seleccionados
- Forge 1.20.1-47.3.0
- Instalador automático incluido

## Instalación
1. Descarga el XRC1 Mod Installer
2. Ejecuta el instalador
3. Selecciona tu carpeta .minecraft
4. ¡Listo!

---
Made with ❄️ by XRC1 Crew
"""

MODS_FOLDER = "mods"
# ==========================

def run_command(command):
    """Ejecuta un comando y muestra el output"""
    print(f"\n▶ Ejecutando: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Error: {result.stderr}")
        return False
    print(f"✓ Éxito: {result.stdout}")
    return True

def check_gh_cli():
    """Verifica si GitHub CLI está instalado"""
    result = subprocess.run("gh --version", shell=True, capture_output=True)
    return result.returncode == 0

def create_release():
    """Crea una nueva release en GitHub"""
    print("\n📦 Creando release...")

    # Crear release
    command = f'gh release create {RELEASE_TAG} --repo {GITHUB_USER}/{GITHUB_REPO} --title "{RELEASE_TITLE}" --notes "{RELEASE_NOTES}"'

    return run_command(command)

def upload_mods():
    """Sube todos los mods a la release"""
    if not os.path.exists(MODS_FOLDER):
        print(f"❌ Error: La carpeta '{MODS_FOLDER}' no existe")
        return False

    jar_files = [f for f in os.listdir(MODS_FOLDER) if f.endswith('.jar')]
    total = len(jar_files)

    print(f"\n📤 Subiendo {total} mods...")

    for i, filename in enumerate(jar_files, 1):
        filepath = os.path.join(MODS_FOLDER, filename)
        print(f"\n[{i}/{total}] Subiendo: {filename}")

        command = f'gh release upload {RELEASE_TAG} "{filepath}" --repo {GITHUB_USER}/{GITHUB_REPO} --clobber'

        if not run_command(command):
            print(f"⚠ Error subiendo {filename}, continuando...")

    return True

def main():
    print("=" * 60)
    print("  XRC1 CREW - GITHUB RELEASE UPLOADER")
    print("=" * 60)

    # Verificar configuración
    if GITHUB_USER == "TU_USUARIO" or GITHUB_REPO == "TU_REPO":
        print("\n❌ ERROR: Debes configurar GITHUB_USER y GITHUB_REPO en el script")
        return

    # Verificar GitHub CLI
    if not check_gh_cli():
        print("\n❌ ERROR: GitHub CLI no está instalado")
        print("   Descárgalo de: https://cli.github.com/")
        return

    print(f"\n📋 Configuración:")
    print(f"   Usuario: {GITHUB_USER}")
    print(f"   Repositorio: {GITHUB_REPO}")
    print(f"   Tag: {RELEASE_TAG}")

    input("\n⏸  Presiona ENTER para continuar o CTRL+C para cancelar...")

    # Crear release
    if not create_release():
        print("\n❌ Error creando la release")
        return

    # Subir mods
    if not upload_mods():
        print("\n❌ Error subiendo los mods")
        return

    print("\n" + "=" * 60)
    print("✅ ¡PROCESO COMPLETADO!")
    print("=" * 60)
    print(f"\n🔗 Release URL: https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/tag/{RELEASE_TAG}")
    print("\n📝 SIGUIENTE PASO:")
    print("   1. Ejecuta: python generate-mods-json.py")
    print("   2. Edita mods-config.json con tus URLs de GitHub")
    print("   3. Ejecuta: npm start")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠ Proceso cancelado por el usuario")
