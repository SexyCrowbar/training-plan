import express from 'express'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import os from 'os'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const app = express()
const PORT = 3000
const DATA_FILE = path.join(__dirname, 'data', 'history.json')

app.use(express.json())
app.use(express.static(path.join(__dirname, 'dist')))

app.get('/api/history', (req, res) => {
  try {
    const data = fs.readFileSync(DATA_FILE, 'utf8')
    res.json(JSON.parse(data))
  } catch {
    res.json([])
  }
})

app.post('/api/history', (req, res) => {
  try {
    fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true })
    fs.writeFileSync(DATA_FILE, JSON.stringify(req.body, null, 2))
    res.json({ ok: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// SPA fallback
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'))
})

app.listen(PORT, '0.0.0.0', () => {
  const ifaces = os.networkInterfaces()
  const candidates = []
  for (const [name, addrs] of Object.entries(ifaces)) {
    for (const addr of addrs) {
      if (addr.family !== 'IPv4' || addr.internal) continue
      // Skip WSL/Hyper-V virtual adapters (172.16–172.31 range) and Docker bridges
      const isVirtual = /^172\.(1[6-9]|2\d|3[01])\./.test(addr.address)
      candidates.push({ name, address: addr.address, virtual: isVirtual })
    }
  }
  // Prefer real adapters (Wi-Fi / Ethernet) over virtual ones
  const best = candidates.find(c => !c.virtual) || candidates[0]
  const localIP = best?.address ?? 'localhost'

  console.log(`\n  Iron & Body Protocol running`)
  console.log(`  Local:   http://localhost:${PORT}`)
  if (candidates.length > 1) {
    candidates.forEach(c => {
      const tag = c.virtual ? ' (virtual — skip)' : ' ← use this'
      console.log(`  ${c.name.padEnd(20)} http://${c.address}:${PORT}${tag}`)
    })
  } else {
    console.log(`  Network: http://${localIP}:${PORT}`)
  }
  console.log()
})
