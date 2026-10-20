const port = 5300
export default defineConfig({
  server: { host: 'localhost', port, allowedHosts: ['x.test'] },
})
