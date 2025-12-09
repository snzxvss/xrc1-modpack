const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs-extra');
const axios = require('axios');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1000,
    height: 700,
    frame: false,
    transparent: true,
    resizable: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    icon: path.join(__dirname, '../assets/icon.png')
  });

  mainWindow.loadFile('src/index.html');

  // Abrir DevTools en desarrollo
  // mainWindow.webContents.openDevTools();
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// IPC Handlers

ipcMain.handle('select-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openDirectory'],
    title: 'Selecciona tu carpeta .minecraft'
  });

  if (!result.canceled) {
    return result.filePaths[0];
  }
  return null;
});

ipcMain.handle('close-app', () => {
  app.quit();
});

ipcMain.handle('minimize-app', () => {
  mainWindow.minimize();
});

// Obtener configuración de mods desde GitHub
ipcMain.handle('fetch-mods-config', async () => {
  try {
    // URL del raw de GitHub donde está el mods-config.json
    const configUrl = 'https://raw.githubusercontent.com/snzxvss/xrc1-modpack/main/mods-config.json';

    const response = await axios.get(configUrl);
    return { success: true, config: response.data };
  } catch (error) {
    console.error('Error obteniendo configuración:', error);
    return { success: false, error: error.message };
  }
});

// Analizar qué mods faltan
ipcMain.handle('analyze-mods', async (event, minecraftPath, modsConfig) => {
  try {
    const modsFolder = path.join(minecraftPath, 'mods');
    await fs.ensureDir(modsFolder);

    // Obtener mods instalados
    const installedFiles = await fs.readdir(modsFolder);
    const installedMods = installedFiles.filter(f => f.endsWith('.jar'));

    // Comparar con la lista de GitHub
    const missingMods = [];
    const outdatedMods = [];
    const upToDateMods = [];

    for (const mod of modsConfig.mods) {
      const isInstalled = installedMods.includes(mod.fileName);

      if (!isInstalled) {
        missingMods.push(mod);
      } else {
        upToDateMods.push(mod);
      }
    }

    return {
      success: true,
      installed: upToDateMods.length,
      missing: missingMods.length,
      total: modsConfig.mods.length,
      missingMods,
      upToDateMods
    };
  } catch (error) {
    console.error('Error analizando mods:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('install-mods', async (event, minecraftPath, modsToInstall) => {
  try {
    const modsFolder = path.join(minecraftPath, 'mods');
    await fs.ensureDir(modsFolder);

    const totalMods = modsToInstall.length;
    let installed = 0;
    let skipped = 0;

    for (const mod of modsToInstall) {
      try {
        const modPath = path.join(modsFolder, mod.fileName);

        // Verificar si ya existe
        if (await fs.pathExists(modPath)) {
          event.sender.send('download-progress', {
            current: installed + skipped + 1,
            total: totalMods,
            modName: mod.name,
            status: 'skipped'
          });
          skipped++;
          continue;
        }

        event.sender.send('download-progress', {
          current: installed + skipped + 1,
          total: totalMods,
          modName: mod.name,
          status: 'downloading'
        });

        // Descargar mod desde GitHub Release
        const response = await axios({
          method: 'GET',
          url: mod.downloadUrl,
          responseType: 'stream',
          onDownloadProgress: (progressEvent) => {
            const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
            event.sender.send('mod-download-progress', {
              modName: mod.name,
              percent: percentCompleted
            });
          }
        });

        const writer = fs.createWriteStream(modPath);
        response.data.pipe(writer);

        await new Promise((resolve, reject) => {
          writer.on('finish', resolve);
          writer.on('error', reject);
        });

        installed++;

        event.sender.send('download-progress', {
          current: installed + skipped,
          total: totalMods,
          modName: mod.name,
          status: 'completed'
        });

      } catch (error) {
        console.error(`Error descargando ${mod.name}:`, error);
        event.sender.send('download-progress', {
          current: installed + skipped,
          total: totalMods,
          modName: mod.name,
          status: 'error',
          error: error.message
        });
      }
    }

    return { success: true, installed, skipped, total: totalMods };

  } catch (error) {
    console.error('Error en instalación:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('install-forge', async (event, minecraftPath, forgeUrl) => {
  try {
    event.sender.send('forge-status', { status: 'downloading' });

    const tempPath = path.join(app.getPath('temp'), 'forge-installer.jar');

    const response = await axios({
      method: 'GET',
      url: forgeUrl,
      responseType: 'stream',
      onDownloadProgress: (progressEvent) => {
        const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total);
        event.sender.send('forge-progress', { percent: percentCompleted });
      }
    });

    const writer = fs.createWriteStream(tempPath);
    response.data.pipe(writer);

    await new Promise((resolve, reject) => {
      writer.on('finish', resolve);
      writer.on('error', reject);
    });

    event.sender.send('forge-status', { status: 'completed', path: tempPath });

    return { success: true, installerPath: tempPath };

  } catch (error) {
    console.error('Error descargando Forge:', error);
    event.sender.send('forge-status', { status: 'error', error: error.message });
    return { success: false, error: error.message };
  }
});
