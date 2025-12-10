// Inyectar el API de Tauri
if (!window.__TAURI_INVOKE__) {
    window.__TAURI_INVOKE__ = function(cmd, args = {}) {
        return new Promise((resolve, reject) => {
            const callback = window.__TAURI_IPC__.transformCallback((result) => {
                resolve(result);
            }, true);
            const error = window.__TAURI_IPC__.transformCallback((err) => {
                reject(err);
            }, true);

            window.__TAURI_IPC__.postMessage({
                cmd,
                callback,
                error,
                ...args
            });
        });
    };
}
