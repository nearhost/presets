export default defineConfig({
  // Not the VITE_PORT that docker-compose.yml publishes: the host dev server
  // takes its own port.
  server: {
    host: 'localhost',
    port: Number(process.env.VITE_DEV_SERVER_PORT) || 5291,
    allowedHosts: ['x.test'],
  },
})
