import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig, type Plugin, type ViteDevServer } from 'vite'

function apkDownloadHeaders(): Plugin {
  const headers = (server: Pick<ViteDevServer, 'middlewares'>) => {
    server.middlewares.use('/downloads/nextleads.apk', (_request, response, next) => {
      response.setHeader('Content-Type', 'application/vnd.android.package-archive')
      response.setHeader('Content-Disposition', 'attachment; filename=nextleads.apk')
      response.setHeader('Cache-Control', 'no-cache')
      next()
    })
  }
  return { name: 'apk-download-headers', configureServer: headers, configurePreviewServer: headers }
}

export default defineConfig({
  server: { port: 5174, strictPort: true },
  plugins: [react(), tailwindcss(), apkDownloadHeaders()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
