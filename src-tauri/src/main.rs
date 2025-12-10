// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use tauri::api::dialog::FileDialogBuilder;
use reqwest::blocking::Client;

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

// FunciÃ³n para escribir en el log
fn write_log(message: &str) {
    let exe_path = std::env::current_exe().ok();
    if let Some(exe_dir) = exe_path.and_then(|p| p.parent().map(|p| p.to_path_buf())) {
        let log_path = exe_dir.join("installer.log");
        if let Ok(mut file) = OpenOptions::new()
            .create(true)
            .append(true)
            .open(log_path)
        {
            let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
            let _ = writeln!(file, "[{}] {}", timestamp, message);
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct ModInfo {
    name: String,
    #[serde(rename = "fileName")]
    file_name: String,
    #[serde(rename = "downloadUrl")]
    download_url: String,
    version: String,
    required: bool,
}

#[derive(Debug, Deserialize)]
struct GitHubAsset {
    name: String,
    browser_download_url: String,
}

#[derive(Debug, Deserialize)]
struct GitHubRelease {
    tag_name: String,
    assets: Vec<GitHubAsset>,
}

// ConfiguraciÃ³n hardcodeada (no necesita archivo externo)
const MINECRAFT_VERSION: &str = "1.20.1";
const FORGE_VERSION: &str = "1.20.1-47.3.0";
const FORGE_DOWNLOAD_URL: &str = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar";
const GITHUB_REPO: &str = "snzxvss/xrc1-modpack";
const MODS_RELEASE_TAG: &str = "v1.0.0";
const INSTALLER_RELEASE_TAG: &str = "installer";
const CURRENT_VERSION: &str = "1.0.14";

#[derive(Debug, Serialize)]
struct UpdateInfo {
    available: bool,
    current_version: String,
    latest_version: String,
    download_url: String,
}

#[derive(Debug, Serialize)]
struct ModAnalysis {
    installed: usize,
    missing: usize,
    total: usize,
    installed_list: Vec<ModInfo>,
    missing_list: Vec<ModInfo>,
    all_mods: Vec<ModInfo>,
}

#[tauri::command]
fn get_version() -> String {
    CURRENT_VERSION.to_string()
}

#[tauri::command]
async fn select_minecraft_folder() -> Result<String, String> {
    write_log("Iniciando selección de carpeta .minecraft");
    let (tx, rx) = std::sync::mpsc::channel();

    FileDialogBuilder::new()
        .set_title("Selecciona tu carpeta .minecraft")
        .pick_folder(move |folder_path| {
            tx.send(folder_path).ok();
        });

    match rx.recv() {
        Ok(Some(path)) => {
            let path_str = path.to_string_lossy().to_string();
            write_log(&format!("Carpeta seleccionada: {}", path_str));
            Ok(path_str)
        },
        Ok(None) => {
            write_log("ERROR: No se seleccionÃ³ carpeta");
            Err("No se seleccionÃ³ carpeta".to_string())
        },
        Err(e) => {
            write_log(&format!("ERROR: Error al recibir respuesta: {:?}", e));
            Err("Error al recibir respuesta".to_string())
        },
    }
}

#[tauri::command]
async fn analyze_mods(minecraft_path: String) -> Result<ModAnalysis, String> {
    write_log(&format!("Analizando mods en: {}", minecraft_path));

    // Obtener mods dinÃ¡micamente desde GitHub
    write_log(&format!("Obteniendo lista de mods desde GitHub: {}/releases/tag/{}", GITHUB_REPO, MODS_RELEASE_TAG));
    let client = Client::new();
    let github_api_url = format!(
        "https://api.github.com/repos/{}/releases/tags/{}",
        GITHUB_REPO, MODS_RELEASE_TAG
    );

    let release: GitHubRelease = client
        .get(&github_api_url)
        .header("User-Agent", "XRC1-Mod-Installer")
        .send()
        .map_err(|e| {
            write_log(&format!("ERROR: Error consultando GitHub API: {}", e));
            format!("Error consultando GitHub API: {}", e)
        })?
        .json()
        .map_err(|e| {
            write_log(&format!("ERROR: Error parseando respuesta de GitHub: {}", e));
            format!("Error parseando respuesta de GitHub: {}", e)
        })?;

    // Convertir assets de GitHub a lista de mods
    let all_mods: Vec<ModInfo> = release
        .assets
        .iter()
        .filter(|asset| asset.name.ends_with(".jar"))
        .map(|asset| ModInfo {
            name: asset.name.trim_end_matches(".jar").to_string(),
            file_name: asset.name.clone(),
            download_url: asset.browser_download_url.clone(),
            version: release.tag_name.clone(),
            required: true,
        })
        .collect();

    write_log(&format!("Se encontraron {} mods en GitHub", all_mods.len()));

    // Verificar carpeta mods
    let mods_folder = PathBuf::from(&minecraft_path).join("mods");

    if !mods_folder.exists() {
        write_log(&format!("Creando carpeta mods: {:?}", mods_folder));
        fs::create_dir_all(&mods_folder)
            .map_err(|e| {
                write_log(&format!("ERROR: Error creando carpeta mods: {}", e));
                format!("Error creando carpeta mods: {}", e)
            })?;
    }

    // Listar archivos instalados
    let installed_files: Vec<String> = fs::read_dir(&mods_folder)
        .map_err(|e| {
            write_log(&format!("ERROR: Error leyendo carpeta mods: {}", e));
            format!("Error leyendo carpeta mods: {}", e)
        })?
        .filter_map(|entry| {
            entry.ok().and_then(|e| {
                e.file_name().to_str().map(|s| s.to_string())
            })
        })
        .collect();

    // Clasificar mods
    let mut installed_list = Vec::new();
    let mut missing_list = Vec::new();

    for mod_info in &all_mods {
        if installed_files.contains(&mod_info.file_name) {
            installed_list.push(mod_info.clone());
        } else {
            missing_list.push(mod_info.clone());
        }
    }

    write_log(&format!("AnÃ¡lisis completo: {} instalados, {} faltantes de {} totales",
        installed_list.len(), missing_list.len(), all_mods.len()));

    Ok(ModAnalysis {
        installed: installed_list.len(),
        missing: missing_list.len(),
        total: all_mods.len(),
        installed_list,
        missing_list,
        all_mods,
    })
}

#[tauri::command]
async fn download_mod(mod_info: ModInfo, minecraft_path: String) -> Result<(), String> {
    write_log(&format!("Descargando mod: {} desde {}", mod_info.name, mod_info.download_url));

    let mods_folder = PathBuf::from(&minecraft_path).join("mods");
    let file_path = mods_folder.join(&mod_info.file_name);

    // Descargar archivo
    let response = reqwest::blocking::get(&mod_info.download_url)
        .map_err(|e| {
            write_log(&format!("ERROR: Error descargando {}: {}", mod_info.name, e));
            format!("Error descargando {}: {}", mod_info.name, e)
        })?;

    if !response.status().is_success() {
        let error_msg = format!("Error HTTP {}: {}", response.status(), mod_info.name);
        write_log(&format!("ERROR: {}", error_msg));
        return Err(error_msg);
    }

    let bytes = response.bytes()
        .map_err(|e| {
            write_log(&format!("ERROR: Error obteniendo bytes de {}: {}", mod_info.name, e));
            format!("Error obteniendo bytes de {}: {}", mod_info.name, e)
        })?;

    fs::write(&file_path, &bytes)
        .map_err(|e| {
            write_log(&format!("ERROR: Error guardando {}: {}", mod_info.name, e));
            format!("Error guardando {}: {}", mod_info.name, e)
        })?;

    write_log(&format!("âœ“ Mod instalado exitosamente: {} ({} bytes)", mod_info.name, bytes.len()));
    Ok(())
}

#[tauri::command]
async fn download_forge() -> Result<String, String> {
    write_log("Iniciando descarga de Forge");

    // Descargar a Downloads
    let downloads_folder = dirs::download_dir()
        .ok_or_else(|| {
            write_log("ERROR: No se pudo obtener carpeta Downloads");
            "No se pudo obtener carpeta Downloads".to_string()
        })?;

    let forge_filename = format!("forge-{}-installer.jar", FORGE_VERSION);
    let forge_path = downloads_folder.join(&forge_filename);

    write_log(&format!("Descargando Forge {} desde {}", FORGE_VERSION, FORGE_DOWNLOAD_URL));

    let response = reqwest::blocking::get(FORGE_DOWNLOAD_URL)
        .map_err(|e| {
            write_log(&format!("ERROR: Error descargando Forge: {}", e));
            format!("Error descargando Forge: {}", e)
        })?;

    if !response.status().is_success() {
        let error_msg = format!("Error HTTP {}", response.status());
        write_log(&format!("ERROR: {}", error_msg));
        return Err(error_msg);
    }

    let bytes = response.bytes()
        .map_err(|e| {
            write_log(&format!("ERROR: Error obteniendo bytes: {}", e));
            format!("Error obteniendo bytes: {}", e)
        })?;

    fs::write(&forge_path, bytes)
        .map_err(|e| {
            write_log(&format!("ERROR: Error guardando Forge: {}", e));
            format!("Error guardando Forge: {}", e)
        })?;

    let result_path = forge_path.to_string_lossy().to_string();
    write_log(&format!("✓ Forge descargado exitosamente en: {}", result_path));

    // Abrir el instalador de Forge automáticamente
    write_log("Abriendo instalador de Forge...");
    std::process::Command::new("cmd")
        .args(&["/C", "start", "", forge_path.to_str().unwrap()])
        .spawn()
        .map_err(|e| {
            write_log(&format!("ERROR: Error abriendo Forge: {}", e));
            format!("Error abriendo Forge: {}", e)
        })?;

    write_log("✓ Instalador de Forge abierto");
    Ok(result_path)
}

#[tauri::command]
async fn check_updates() -> Result<UpdateInfo, String> {
    write_log("Verificando actualizaciones del instalador");

    let client = Client::new();
    let github_api_url = format!(
        "https://api.github.com/repos/{}/releases/tags/{}",
        GITHUB_REPO, INSTALLER_RELEASE_TAG
    );

    let release: GitHubRelease = client
        .get(&github_api_url)
        .header("User-Agent", "XRC1-Mod-Installer")
        .send()
        .map_err(|e| {
            write_log(&format!("ERROR: Error consultando actualizaciones: {}", e));
            format!("Error consultando actualizaciones: {}", e)
        })?
        .json()
        .map_err(|e| {
            write_log(&format!("ERROR: Error parseando respuesta de actualizaciones: {}", e));
            format!("Error parseando respuesta de actualizaciones: {}", e)
        })?;

    // Buscar el .exe en los assets
    let exe_asset = release
        .assets
        .iter()
        .find(|asset| asset.name.ends_with(".exe"))
        .ok_or_else(|| {
            write_log("ERROR: No se encontrÃ³ .exe en el release");
            "No se encontrÃ³ .exe en el release".to_string()
        })?;

    // Extraer versiÃ³n del nombre del asset (ej: "XRC1-Mod-Installer-v1.0.1.exe")
    // Si no tiene versiÃ³n en el nombre, usar el tag del release
    let latest_version = if exe_asset.name.contains("-v") {
        exe_asset.name
            .split("-v")
            .nth(1)
            .and_then(|s| s.strip_suffix(".exe"))
            .unwrap_or("1.0.0")
    } else {
        CURRENT_VERSION // Si no hay versiÃ³n en el nombre, asumir que es la misma
    };

    write_log(&format!("DEBUG: Nombre del asset en GitHub: '{}'", exe_asset.name));
    write_log(&format!("DEBUG: VersiÃ³n extraÃ­da del asset: '{}'", latest_version));
    write_log(&format!("DEBUG: VersiÃ³n actual (CURRENT_VERSION): '{}'", CURRENT_VERSION));

    let available = latest_version != CURRENT_VERSION;

    if available {
        write_log(&format!("Nueva versiÃ³n disponible: {} (actual: {})", latest_version, CURRENT_VERSION));
    } else {
        write_log("El instalador estÃ¡ actualizado");
    }

    Ok(UpdateInfo {
        available,
        current_version: CURRENT_VERSION.to_string(),
        latest_version: latest_version.to_string(),
        download_url: exe_asset.browser_download_url.clone(),
    })
}

#[tauri::command]
async fn download_update(window: tauri::Window, download_url: String) -> Result<String, String> {
    write_log("========================================");
    write_log("INICIANDO PROCESO DE ACTUALIZACION");
    write_log("Usuario confirmo la actualizacion");
    write_log(&format!("Descargando actualizacion desde: {}", download_url));

    let exe_path = std::env::current_exe()
        .map_err(|e| {
            write_log(&format!("ERROR: Error obteniendo ruta del ejecutable: {}", e));
            format!("Error obteniendo ruta del ejecutable: {}", e)
        })?;

    let exe_dir = exe_path.parent()
        .ok_or_else(|| {
            write_log("ERROR: No se pudo obtener directorio padre");
            "No se pudo obtener directorio padre".to_string()
        })?;

    let old_exe_name = exe_path.file_name()
        .ok_or_else(|| {
            write_log("ERROR: No se pudo obtener nombre del ejecutable");
            "No se pudo obtener nombre del ejecutable".to_string()
        })?
        .to_string_lossy()
        .to_string();

    // Extraer el nombre del nuevo .exe desde la URL
    // URL: https://github.com/.../releases/download/installer/XRC1-Mod-Installer-v1.0.6.exe
    let new_exe_name = download_url
        .split('/')
        .last()
        .unwrap_or("XRC1-Mod-Installer.exe")
        .to_string();

    write_log(&format!("DEBUG: Ejecutable actual: {}", old_exe_name));
    write_log(&format!("DEBUG: Nuevo ejecutable: {}", new_exe_name));

    let new_exe_path = exe_dir.join("update-temp.exe");

    // Descargar nuevo .exe
    write_log("Descargando archivo de actualizacion...");
    let response = reqwest::blocking::get(&download_url)
        .map_err(|e| {
            write_log(&format!("ERROR: Error descargando actualizacion: {}", e));
            format!("Error descargando actualizacion: {}", e)
        })?;

    if !response.status().is_success() {
        let error_msg = format!("Error HTTP {}", response.status());
        write_log(&format!("ERROR: {}", error_msg));
        return Err(error_msg);
    }

    let bytes = response.bytes()
        .map_err(|e| {
            write_log(&format!("ERROR: Error obteniendo bytes: {}", e));
            format!("Error obteniendo bytes: {}", e)
        })?;

    fs::write(&new_exe_path, bytes)
        .map_err(|e| {
            write_log(&format!("ERROR: Error guardando actualizacion: {}", e));
            format!("Error guardando actualizacion: {}", e)
        })?;

    write_log("Actualizacion descargada, creando script de actualizacion...");

    // Obtener el PID del proceso actual
    let current_pid = std::process::id();
    
    // Crear script PowerShell para reemplazar el ejecutable
    let ps_script_path = exe_dir.join("update.ps1");
    let old_exe_path = exe_dir.join(&old_exe_name);
    let new_exe_final_path = exe_dir.join(&new_exe_name);
    let temp_exe_path = exe_dir.join("update-temp.exe");

    let ps_content = format!(
        "$ErrorActionPreference = 'Stop'\r\n\
        Write-Host 'Esperando cierre de aplicacion (PID {})...'\r\n\
        Start-Sleep -Seconds 2\r\n\
        \r\n\
        # Esperar a que el proceso termine\r\n\
        $maxAttempts = 10\r\n\
        $attempt = 0\r\n\
        while ($attempt -lt $maxAttempts) {{\r\n\
            $process = Get-Process -Id {} -ErrorAction SilentlyContinue\r\n\
            if (-not $process) {{\r\n\
                break\r\n\
            }}\r\n\
            Start-Sleep -Milliseconds 500\r\n\
            $attempt++\r\n\
        }}\r\n\
        \r\n\
        Write-Host 'Eliminando version anterior...'\r\n\
        if (Test-Path '{}') {{\r\n\
            Remove-Item -Path '{}' -Force\r\n\
        }}\r\n\
        \r\n\
        Write-Host 'Instalando nueva version...'\r\n\
        Move-Item -Path '{}' -Destination '{}' -Force\r\n\
        \r\n\
        Write-Host 'Iniciando nueva version...'\r\n\
        Start-Process -FilePath '{}'\r\n\
        \r\n\
        Write-Host 'Limpiando archivos temporales...'\r\n\
        Start-Sleep -Seconds 1\r\n\
        Remove-Item -Path $PSCommandPath -Force\r\n",
        current_pid,
        current_pid,
        old_exe_path.display(),
        old_exe_path.display(),
        temp_exe_path.display(),
        new_exe_final_path.display(),
        new_exe_final_path.display()
    );

    fs::write(&ps_script_path, ps_content)
        .map_err(|e| {
            write_log(&format!("ERROR: Error creando script de actualizacion: {}", e));
            format!("Error creando script de actualizacion: {}", e)
        })?;

    write_log("Actualizacion lista. Ejecutando script de reemplazo...");

    // Ejecutar PowerShell de forma oculta
    std::process::Command::new("powershell")
        .args(&[
            "-WindowStyle", "Hidden",
            "-ExecutionPolicy", "Bypass",
            "-File", ps_script_path.to_str().unwrap()
        ])
        .spawn()
        .map_err(|e| {
            write_log(&format!("ERROR: Error ejecutando script de actualizacion: {}", e));
            format!("Error ejecutando script de actualizacion: {}", e)
        })?;

    write_log("Script de actualizacion iniciado. Cerrando aplicacion...");

    // Cerrar la ventana automáticamente después de 1 segundo
    std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_secs(1));
        let _ = window.close();
    });

    Ok("La aplicacion se cerrara y se actualizara automaticamente".to_string())
}

// Minimizar ventana
#[tauri::command]
fn minimize_window(window: tauri::Window) -> Result<(), String> {
    window.minimize().map_err(|e| format!("Error minimizando ventana: {}", e))?;
    Ok(())
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            get_version,
            select_minecraft_folder,
            analyze_mods,
            download_mod,
            download_forge,
            check_updates,
            download_update,
            minimize_window
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
