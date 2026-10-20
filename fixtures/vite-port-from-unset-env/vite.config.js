export default defineConfig({
  server: {
    port: Number(process.env.VITE_PORT),
    allowedHosts: ['x.test'],
  },
})
