const fs = require('fs');
const path = require('path');

const modsFolder = './mods';
const outputFile = './mods-config.json';

const githubUser = 'snzxvss';
const githubRepo = 'xrc1-modpack';
const releaseTag = 'v1.0.0';

console.log('Generando mods-config.json...\n');

// Leer archivos .jar de la carpeta mods
const files = fs.readdirSync(modsFolder).filter(f => f.endsWith('.jar')).sort();

const mods = files.map(fileName => {
  // Extraer nombre del mod (simplificado)
  const modName = fileName
    .replace('.jar', '')
    .replace(/-forge/gi, '')
    .replace(/-\d+\.\d+.*$/i, '')
    .replace(/[_-]/g, ' ')
    .trim();

  return {
    name: modName,
    fileName: fileName,
    downloadUrl: `https://github.com/${githubUser}/${githubRepo}/releases/download/${releaseTag}/${encodeURIComponent(fileName)}`,
    version: "1.0.0",
    required: true
  };
});

const config = {
  minecraftVersion: "1.20.1",
  forgeVersion: "1.20.1-47.3.0",
  forgeDownloadUrl: "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar",
  mods: mods,
  _comment: `Auto-generado. Total de mods: ${mods.length}`
};

fs.writeFileSync(outputFile, JSON.stringify(config, null, 2));

console.log(`✓ Archivo generado: ${outputFile}`);
console.log(`✓ Total de mods: ${mods.length}`);
console.log('\n✅ ¡Listo!');
