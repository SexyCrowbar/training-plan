import { useState, useEffect, useRef, useImperativeHandle, forwardRef } from 'react'

const Timer = forwardRef(function Timer(_, ref) {
  const [secs, setSecs] = useState(0)
  const [visible, setVisible] = useState(false)
  const ivRef = useRef(null)

  const stop = () => {
    if (ivRef.current) { clearInterval(ivRef.current); ivRef.current = null }
    setVisible(false)
    setSecs(0)
  }

  const start = (seconds) => {
    if (!seconds || seconds <= 0) return
    stop()
    setSecs(seconds)
    setVisible(true)
    ivRef.current = setInterval(() => {
      setSecs(prev => {
        if (prev <= 1) { stop(); return 0 }
        return prev - 1
      })
    }, 1000)
  }

  useImperativeHandle(ref, () => ({ start, stop }))

  useEffect(() => () => { if (ivRef.current) clearInterval(ivRef.current) }, [])

  if (!visible) return null

  const m = String(Math.floor(secs / 60)).padStart(2, '0')
  const s = String(secs % 60).padStart(2, '0')

  return (
    <div style={{ position: 'sticky', top: 10, zIndex: 50, marginBottom: 14 }}>
      <div className="timer-bar">
        <div>
          <p style={{ fontSize: 10, fontWeight: 800, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--muted)' }}>
            Rest Timer
          </p>
        </div>
        <span className="text-p" style={{ fontFamily: 'monospace', fontSize: 28, fontWeight: 900, letterSpacing: '0.04em' }}>
          {m}:{s}
        </span>
        <button
          onClick={stop}
          style={{ fontSize: 11, fontWeight: 800, textTransform: 'uppercase', color: '#f87171', background: 'none', border: 'none', cursor: 'pointer', letterSpacing: '0.06em' }}
        >
          Stop
        </button>
      </div>
    </div>
  )
})

export default Timer
