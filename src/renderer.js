const { ipcRenderer } = require('electron');

// Variables globales
let minecraftPath = '';
let modsConfig = null;
let analysisResult = null;

// Cargar configuración de mods desde GitHub
async function loadModsConfig() {
    try {
        addConsoleLog('Conectando con GitHub...', 'info');
        const result = await ipcRenderer.invoke('fetch-mods-config');

        if (result.success) {
            modsConfig = result.config;
            document.getElementById('mods-count').textContent = `${modsConfig.mods.length} mods disponibles`;
            addConsoleLog(`✓ ${modsConfig.mods.length} mods encontrados en GitHub`, 'success');
        } else {
            addConsoleLog(`✗ Error conectando a GitHub: ${result.error}`, 'error');
            document.getElementById('mods-count').textContent = 'Error cargando mods';
        }
    } catch (error) {
        console.error('Error cargando configuración:', error);
        addConsoleLog('✗ Error de conexión', 'error');
    }
}

// Crear efecto de nieve
function createSnowflakes() {
    const container = document.getElementById('snow-container');
    const snowflakeCount = 50;

    for (let i = 0; i < snowflakeCount; i++) {
        const snowflake = document.createElement('div');
        snowflake.className = 'snowflake';
        snowflake.textContent = '❄';
        snowflake.style.left = Math.random() * 100 + '%';
        snowflake.style.animationDuration = (Math.random() * 3 + 2) + 's';
        snowflake.style.animationDelay = Math.random() * 5 + 's';
        snowflake.style.fontSize = (Math.random() * 10 + 10) + 'px';
        snowflake.style.opacity = Math.random() * 0.6 + 0.4;
        container.appendChild(snowflake);
    }
}

// Cambiar entre pasos
function showStep(stepId) {
    document.querySelectorAll('.step').forEach(step => {
        step.classList.add('hidden');
    });
    document.getElementById(stepId).classList.remove('hidden');
}

// Agregar log a la consola
function addConsoleLog(message, type = 'info') {
    const consoleOutput = document.getElementById('console-output');
    if (!consoleOutput) return;

    const timestamp = new Date().toLocaleTimeString();
    const colors = {
        info: '#00d9ff',
        success: '#00ff88',
        error: '#ff4757',
        warning: '#fffa65'
    };

    const logEntry = document.createElement('div');
    logEntry.style.color = colors[type];
    logEntry.textContent = `[${timestamp}] ${message}`;
    consoleOutput.appendChild(logEntry);
    consoleOutput.scrollTop = consoleOutput.scrollHeight;
}

// Actualizar barra de progreso
function updateProgress(current, total) {
    const percent = Math.round((current / total) * 100);
    document.getElementById('progress-fill').style.width = percent + '%';
    document.getElementById('progress-percentage').textContent = percent + '%';
    document.getElementById('progress-text').textContent = `${current}/${total}`;
}

// Analizar mods instalados
async function analyzeMods() {
    if (!modsConfig) {
        alert('Error: No se pudo cargar la configuración de mods');
        return;
    }

    showStep('step-analyze');
    addConsoleLog('Analizando mods instalados...', 'info');

    const result = await ipcRenderer.invoke('analyze-mods', minecraftPath, modsConfig);

    if (result.success) {
        analysisResult = result;

        addConsoleLog(`✓ Análisis completado`, 'success');
        addConsoleLog(`  - Mods instalados: ${result.installed}/${result.total}`, 'info');
        addConsoleLog(`  - Mods faltantes: ${result.missing}`, result.missing > 0 ? 'warning' : 'success');

        // Actualizar interfaz con resultados
        document.getElementById('installed-mods-count').textContent = result.installed;
        document.getElementById('missing-mods-count').textContent = result.missing;
        document.getElementById('total-mods-count').textContent = result.total;

        // Mostrar botón según el estado
        if (result.missing > 0) {
            document.getElementById('install-missing-btn').classList.remove('hidden');
            document.getElementById('all-updated-message').classList.add('hidden');
        } else {
            document.getElementById('install-missing-btn').classList.add('hidden');
            document.getElementById('all-updated-message').classList.remove('hidden');
        }
    } else {
        addConsoleLog(`✗ Error: ${result.error}`, 'error');
    }
}

// Event Listeners

// Botones de la barra de título
document.getElementById('minimize-btn').addEventListener('click', () => {
    ipcRenderer.invoke('minimize-app');
});

document.getElementById('close-btn').addEventListener('click', () => {
    ipcRenderer.invoke('close-app');
});

// Seleccionar carpeta
document.getElementById('select-folder-btn').addEventListener('click', async () => {
    const selectedPath = await ipcRenderer.invoke('select-folder');
    if (selectedPath) {
        minecraftPath = selectedPath;
        document.getElementById('minecraft-path').value = selectedPath;

        // Analizar mods automáticamente
        await analyzeMods();
    }
});

// Instalar mods faltantes
document.getElementById('install-missing-btn').addEventListener('click', async () => {
    if (!analysisResult || !analysisResult.missingMods) {
        alert('Error: No hay mods para instalar');
        return;
    }

    showStep('step-progress');
    addConsoleLog(`Instalando ${analysisResult.missing} mods faltantes...`, 'info');

    const result = await ipcRenderer.invoke('install-mods', minecraftPath, analysisResult.missingMods);

    if (result.success) {
        addConsoleLog(`✓ Instalación completada`, 'success');
        addConsoleLog(`  - Descargados: ${result.installed}`, 'success');
        addConsoleLog(`  - Omitidos: ${result.skipped}`, 'info');

        document.getElementById('installed-count').textContent = result.installed;
        document.getElementById('final-path').textContent = minecraftPath;

        setTimeout(() => {
            showStep('step-complete');
        }, 1000);
    } else {
        addConsoleLog(`✗ Error en la instalación: ${result.error}`, 'error');
    }
});

// Instalar todos los mods
document.getElementById('install-all-btn').addEventListener('click', async () => {
    if (!modsConfig) {
        alert('Error: No se pudo cargar la configuración de mods');
        return;
    }

    showStep('step-progress');
    addConsoleLog(`Instalando todos los mods (${modsConfig.mods.length})...`, 'info');

    const result = await ipcRenderer.invoke('install-mods', minecraftPath, modsConfig.mods);

    if (result.success) {
        addConsoleLog(`✓ Instalación completada`, 'success');
        addConsoleLog(`  - Descargados: ${result.installed}`, 'success');
        addConsoleLog(`  - Ya instalados: ${result.skipped}`, 'info');

        document.getElementById('installed-count').textContent = result.installed;
        document.getElementById('final-path').textContent = minecraftPath;

        setTimeout(() => {
            showStep('step-complete');
        }, 1000);
    } else {
        addConsoleLog(`✗ Error en la instalación: ${result.error}`, 'error');
    }
});

// Descargar Forge
document.getElementById('install-forge-btn').addEventListener('click', async () => {
    if (!minecraftPath) {
        alert('Por favor selecciona una carpeta primero');
        return;
    }

    if (!modsConfig || !modsConfig.forgeDownloadUrl) {
        alert('URL de Forge no configurada');
        return;
    }

    showStep('step-progress');
    document.getElementById('current-mod').textContent = 'Descargando Forge...';
    addConsoleLog('Iniciando descarga de Forge...', 'info');

    const result = await ipcRenderer.invoke('install-forge', minecraftPath, modsConfig.forgeDownloadUrl);

    if (result.success) {
        addConsoleLog('✓ Forge descargado correctamente', 'success');
        addConsoleLog(`✓ Ubicación: ${result.installerPath}`, 'info');
        addConsoleLog('⚠ Por favor ejecuta el instalador de Forge manualmente', 'warning');

        setTimeout(() => {
            showStep('step-analyze');
        }, 3000);
    } else {
        addConsoleLog(`✗ Error descargando Forge: ${result.error}`, 'error');
    }
});

// Botón finalizar
document.getElementById('finish-btn').addEventListener('click', () => {
    ipcRenderer.invoke('close-app');
});

// Botón volver a analizar
document.getElementById('reanalyze-btn').addEventListener('click', async () => {
    await analyzeMods();
});

// Listeners para progreso de descarga
ipcRenderer.on('download-progress', (event, data) => {
    updateProgress(data.current, data.total);

    if (data.status === 'downloading') {
        document.getElementById('current-mod').textContent = `Descargando: ${data.modName}`;
        addConsoleLog(`⬇ Descargando ${data.modName}...`, 'info');
    } else if (data.status === 'completed') {
        addConsoleLog(`✓ ${data.modName} instalado`, 'success');
    } else if (data.status === 'skipped') {
        addConsoleLog(`⊘ ${data.modName} ya existe`, 'info');
    } else if (data.status === 'error') {
        addConsoleLog(`✗ Error con ${data.modName}: ${data.error}`, 'error');
    }
});

ipcRenderer.on('forge-status', (event, data) => {
    if (data.status === 'downloading') {
        addConsoleLog('⬇ Descargando Forge installer...', 'info');
    } else if (data.status === 'completed') {
        addConsoleLog(`✓ Forge descargado: ${data.path}`, 'success');
    } else if (data.status === 'error') {
        addConsoleLog(`✗ Error: ${data.error}`, 'error');
    }
});

ipcRenderer.on('forge-progress', (event, data) => {
    updateProgress(data.percent, 100);
});

// Inicialización
window.addEventListener('DOMContentLoaded', () => {
    createSnowflakes();
    loadModsConfig();
});
