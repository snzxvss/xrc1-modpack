// Esperar a que se cargue todo
window.addEventListener('DOMContentLoaded', async () => {
    // Obtener el API de Tauri
    const invoke = window.__TAURI_INVOKE__;

    // Estado global
    let minecraftPath = '';
    let modsData = [];
    let installedMods = [];
    let missingMods = [];

    // Elementos del DOM
    const steps = {
        select: document.getElementById('step-select'),
        analyze: document.getElementById('step-analyze'),
        progress: document.getElementById('step-progress'),
        complete: document.getElementById('step-complete')
    };

    // Utilidades
    function showStep(stepName) {
        Object.values(steps).forEach(step => step.classList.add('hidden'));
        steps[stepName].classList.remove('hidden');
    }

    function addConsoleLog(message, step) {
        const consoleId = step === 'analyze' ? 'console-output-analyze' : 'console-output-progress';
        const consoleElement = document.getElementById(consoleId);
        if (consoleElement) {
            const timestamp = new Date().toLocaleTimeString('es-ES', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
            consoleElement.innerHTML += `[${timestamp}] ${message}<br>`;
            consoleElement.scrollTop = consoleElement.scrollHeight;
        }
    }

    // Analizar mods
    async function analyzeMods() {
        showStep('analyze');
        addConsoleLog('🔍 Analizando mods instalados...', 'analyze');

        try {
            const analysis = await invoke('analyze_mods', { minecraftPath });

            // Actualizar contadores
            document.getElementById('installed-mods-count').textContent = analysis.installed;
            document.getElementById('missing-mods-count').textContent = analysis.missing;
            document.getElementById('total-mods-count').textContent = analysis.total;

            installedMods = analysis.installed_list || [];
            missingMods = analysis.missing_list || [];
            modsData = analysis.all_mods || [];

            addConsoleLog(`✅ Análisis completo: ${analysis.installed} instalados, ${analysis.missing} faltantes`, 'analyze');

            // Mostrar/ocultar botones según análisis
            const installMissingBtn = document.getElementById('install-missing-btn');
            const allUpdatedMsg = document.getElementById('all-updated-message');

            if (analysis.missing > 0) {
                installMissingBtn.classList.remove('hidden');
                allUpdatedMsg.classList.add('hidden');
            } else {
                installMissingBtn.classList.add('hidden');
                allUpdatedMsg.classList.remove('hidden');
            }
        } catch (error) {
            addConsoleLog(`❌ Error al analizar: ${error}`, 'analyze');
        }
    }

    // Instalar mods
    async function installMods(modsList) {
        if (modsList.length === 0) {
            addConsoleLog('⚠️ No hay mods para instalar', 'analyze');
            return;
        }

        showStep('progress');
        document.getElementById('progress-fill').style.width = '0%';
        document.getElementById('progress-percentage').textContent = '0%';
        document.getElementById('progress-text').textContent = `0/${modsList.length}`;

        let completed = 0;

        for (const mod of modsList) {
            try {
                document.getElementById('current-mod').textContent = `Descargando: ${mod.name}`;
                addConsoleLog(`📥 Descargando: ${mod.name}`, 'progress');

                await invoke('download_mod', {
                    modInfo: mod,
                    minecraftPath
                });

                completed++;
                const percentage = Math.round((completed / modsList.length) * 100);
                document.getElementById('progress-fill').style.width = percentage + '%';
                document.getElementById('progress-percentage').textContent = percentage + '%';
                document.getElementById('progress-text').textContent = `${completed}/${modsList.length}`;

                addConsoleLog(`✅ ${mod.name} instalado`, 'progress');
            } catch (error) {
                addConsoleLog(`❌ Error en ${mod.name}: ${error}`, 'progress');
            }
        }

        // Completado
        showStep('complete');
        document.getElementById('installed-count').textContent = completed;
        document.getElementById('final-path').textContent = minecraftPath + '\\mods';
    }

    // Controles de ventana
    document.getElementById('minimize-btn').addEventListener('click', async () => {
        try {
            await invoke('minimize_window');
        } catch (e) {
            console.error('Error minimizando:', e);
        }
    });

    document.getElementById('close-btn').addEventListener('click', async () => {
        try {
            const { appWindow } = window.__TAURI__.window;
            await appWindow.close();
        } catch (e) {
            window.close();
        }
    });

    // PASO 1: Selector de carpeta
    document.getElementById('select-folder-btn').addEventListener('click', async () => {
        try {
            const path = await invoke('select_minecraft_folder');
            if (path) {
                document.getElementById('minecraft-path').value = path;
                minecraftPath = path;
                await analyzeMods();
            }
        } catch (error) {
            addConsoleLog(`❌ Error al seleccionar carpeta: ${error}`, 'analyze');
        }
    });

    // PASO 2: Botones de acción
    document.getElementById('install-missing-btn').addEventListener('click', async () => {
        await installMods(missingMods);
    });

    document.getElementById('install-all-btn').addEventListener('click', async () => {
        await installMods(modsData);
    });

    document.getElementById('install-forge-btn').addEventListener('click', async () => {
        addConsoleLog('🔥 Descargando Forge 1.20.1-47.3.0...', 'analyze');
        try {
            const forgePath = await invoke('download_forge');
            addConsoleLog(`✅ Forge descargado y abierto: ${forgePath}`, 'analyze');
            addConsoleLog('🚀 Instalador de Forge abierto automáticamente', 'analyze');
        } catch (error) {
            addConsoleLog(`❌ Error al descargar Forge: ${error}`, 'analyze');
        }
    });

    document.getElementById('reanalyze-btn').addEventListener('click', async () => {
        document.getElementById('console-output-analyze').innerHTML = '';
        await analyzeMods();
    });

    // PASO 4: Finalizar
    document.getElementById('finish-btn').addEventListener('click', async () => {
        try {
            const { appWindow } = window.__TAURI__.window;
            await appWindow.close();
        } catch (e) {
            window.close();
        }
    });

    // Verificar actualizaciones al inicio
    async function checkForUpdates() {
        try {
            const updateInfo = await invoke('check_updates');
            if (updateInfo.available) {
                const updatePrompt = confirm(
                    `¡Nueva versión disponible!\n\n` +
                    `Versión actual: ${updateInfo.current_version}\n` +
                    `Versión nueva: ${updateInfo.latest_version}\n\n` +
                    `¿Deseas descargar la actualización?`
                );

                if (updatePrompt) {
                    try {
                        await invoke('download_update', { downloadUrl: updateInfo.download_url });
                        // Esperar un momento para que el usuario vea el mensaje
                        alert(
                            `✓ Actualización completada\n\n` +
                            `La aplicación se cerrará y se actualizará automáticamente.\n` +
                            `Espera unos segundos y se volverá a abrir con la nueva versión.`
                        );
                    } catch (error) {
                        alert(`Error al actualizar: ${error}`);
                        return;
                    }
                }
            }
        } catch (error) {
            console.error('Error verificando actualizaciones:', error);
        }
    }

    // Cargar versión de la app
    async function loadVersion() {
        try {
            const version = await invoke('get_version');
            document.getElementById('app-version').textContent = `v${version}`;
        } catch (error) {
            console.error('Error obteniendo versión:', error);
        }
    }

    // Inicialización
    console.log('XRC1 Mod Installer cargado');
    console.log('Tauri invoke disponible:', typeof invoke);

    // Cargar versión y verificar actualizaciones
    loadVersion();
    checkForUpdates();
});
