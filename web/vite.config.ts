import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  // '.' — папка web, где лежит .env (Vite запускается из неё).
  const env = loadEnv(mode, '.', '');
  // Локальный бэкенд без CORS: веб ходит на свой же адрес, а Vite пересылает /api на бэкенд — как nginx на сервере.
  // Включается в web/.env: VITE_API_PROXY=http://127.0.0.1:8000 и VITE_API_BASE_URL=http://localhost:5173
  const proxy = env.VITE_API_PROXY ? { '/api': { target: env.VITE_API_PROXY, changeOrigin: true } } : undefined;
  return {
    plugins: [react()],
    server: { port: 5173, host: true, proxy },
  };
});
