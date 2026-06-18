import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Base path for GitHub Pages deployment (https://jagadeesht1.github.io/PDD-TradeMentor/)
  base: process.env.GITHUB_ACTIONS ? '/PDD-TradeMentor/' : '/',
  server: {
    port: 5173,
    host: true
  }
});
