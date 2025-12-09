import os
import json

def generate_mods_config():
    """
    Genera el archivo mods-config.json basándose en los archivos .jar de la carpeta mods
    """
    mods_folder = "mods"
    github_user = "TU_USUARIO"  # Cambia esto
    github_repo = "TU_REPO"     # Cambia esto
    release_version = "v1.0.0"  # Cambia esto según tu versión

    if not os.path.exists(mods_folder):
        print(f"Error: La carpeta '{mods_folder}' no existe")
        return

    mods = []

    # Listar todos los archivos .jar
    for filename in sorted(os.listdir(mods_folder)):
        if filename.endswith('.jar'):
            # Extraer nombre del mod (sin versión)
            mod_name = filename.replace('.jar', '').split('-')[0]
            mod_name = mod_name.replace('_', ' ').title()

            mod_entry = {
                "name": mod_name,
                "fileName": filename,
                "downloadUrl": f"https://github.com/{github_user}/{github_repo}/releases/download/{release_version}/{filename}",
                "version": "unknown",
                "required": True
            }

            mods.append(mod_entry)

    config = {
        "minecraftVersion": "1.20.1",
        "forgeVersion": "1.20.1-47.3.0",
        "forgeDownloadUrl": "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar",
        "mods": mods,
        "_comment": f"Auto-generado. Total de mods: {len(mods)}"
    }

    # Guardar JSON
    with open('mods-config.json', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

    print(f"✓ Archivo generado exitosamente")
    print(f"✓ Total de mods: {len(mods)}")
    print(f"\nRECUERDA:")
    print(f"1. Editar el archivo y cambiar 'TU_USUARIO' y 'TU_REPO'")
    print(f"2. Subir los mods a GitHub Releases con el tag '{release_version}'")

if __name__ == "__main__":
    generate_mods_config()
