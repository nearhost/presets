export default { server: { hmr: { port: 24678 }, proxy: { '/api': { target: 'http://x' } }, port: 3001, allowedHosts: true } }
