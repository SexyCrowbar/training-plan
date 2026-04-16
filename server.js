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
  let localIP = 'localhost'
  for (const iface of Object.values(ifaces)) {
    for (const addr of iface) {
      if (addr.family === 'IPv4' && !addr.internal) {
        localIP = addr.address
        break
      }
    }
  }
  console.log(`\n  Iron & Body Protocol running`)
  console.log(`  Local:   http://localhost:${PORT}`)
  console.log(`  Network: http://${localIP}:${PORT}\n`)
})
