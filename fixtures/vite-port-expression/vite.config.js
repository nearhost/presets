export default defineConfig({
  server: {
    host: 'localhost',
    port: Number(process.env.VITE_DEV_SERVER_PORT) || 5291,
    strictPort: true,
    allowedHosts: ['x.test'],
  },
})
