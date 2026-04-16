import { useState, useRef, useEffect } from 'react'
import { DAYS } from '../data/plan'

export default function HomeScreen({ currentDay, onDayChange, doneBlocks, onStartBlock }) {
  const [gtg, setGtg] = useState({ 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 })
  const numRef = useRef(null)
  const d = DAYS[currentDay]
  const isRest = d.theme === 'rest'
  const target = d.gtgTarget
  const count = gtg[currentDay]
  const done = doneBlocks.size
  const total = d.blocks.length

  function adjustGtg(delta) {
    if (target === 0) return
    setGtg(prev => {
      const next = Math.max(0, (prev[currentDay] || 0) + delta)
      return { ...prev, [currentDay]: next }
    })
    if (numRef.current) {
      numRef.current.classList.remove('pop')
      void numRef.current.offsetWidth
      numRef.current.classList.add('pop')
    }
  }

  const dayLabel = (n) => n === 5 ? 'Rest' : `Day ${n}`
  const themeLabels = { iron: 'IRON DAY', body: 'BODY DAY', rest: 'REST DAY' }

  return (
    <div className="screen animate-fadeUp">
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 900, letterSpacing: '-0.02em' }}>Protocol</h1>
          <p className="text-m" style={{ fontSize: 12, marginTop: 1 }}>
            {new Date().toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' })}
          </p>
        </div>
        <span className="badge">
          <span className="badge-dot" />
          {themeLabels[d.theme]}
        </span>
      </div>

      {/* Day tabs */}
      <div className="tabs" style={{ marginBottom: 20 }}>
        {Object.keys(DAYS).map(k => {
          const n = parseInt(k)
          return (
            <button
              key={n}
              className={`tab${n === currentDay ? ' active' : ''}`}
              onClick={() => onDayChange(n)}
            >
              {dayLabel(n)}
            </button>
          )
        })}
      </div>

      {/* Day title */}
      <div style={{ marginBottom: 18 }}>
        <h2 style={{ fontSize: 22, fontWeight: 900, letterSpacing: '-0.02em', lineHeight: 1.2 }}>{d.name}</h2>
        <p className="text-m" style={{ fontSize: 13, marginTop: 3 }}>{d.tag}</p>
      </div>

      {/* GtG card */}
      <div className="card" style={{ marginBottom: 16, opacity: target === 0 ? 0.4 : 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div>
            <p className="sec-label">Grease the Groove</p>
            <p className="text-m" style={{ fontSize: 12, marginTop: 3 }}>{d.gtgEx}</p>
          </div>
          <span className="text-p" style={{ fontSize: 11, fontWeight: 700 }}>Today</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16 }}>
          <button className="gtg-btn" onClick={() => adjustGtg(-1)}>−</button>
          <div style={{ textAlign: 'center', flex: 1 }}>
            <div
              ref={numRef}
              className="text-p"
              style={{ fontSize: 56, fontWeight: 900, lineHeight: 1, letterSpacing: '-0.03em' }}
            >
              {count}
            </div>
            <p className="text-m" style={{ fontSize: 12, marginTop: 5 }}>
              of <span>{target || 5}</span> sets
            </p>
          </div>
          <button className="gtg-btn gtg-add" onClick={() => adjustGtg(1)}>+</button>
        </div>
        {/* Dots */}
        <div style={{ display: 'flex', gap: 7, justifyContent: 'center', flexWrap: 'wrap', marginTop: 14 }}>
          {Array.from({ length: Math.max(target || 5, count) }).map((_, i) => (
            <div
              key={i}
              className={`gtg-dot${i < count ? (i < (target || 5) ? ' on' : ' ov') : ''}`}
            />
          ))}
        </div>
      </div>

      {/* Progress header */}
      {!isRest && (
        <div style={{ marginBottom: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
            <span className="sec-label">Today's Blocks</span>
            <span className="text-p" style={{ fontSize: 11, fontWeight: 800 }}>{done} / {total} done</span>
          </div>
          <div className="prog-track">
            <div className="prog-fill" style={{ width: total > 0 ? `${(done / total) * 100}%` : '0%' }} />
          </div>
        </div>
      )}

      {/* Block list */}
      {!isRest && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 14 }}>
          {d.blocks.map((block, idx) => {
            const isDone = doneBlocks.has(block.id)
            return (
              <div key={block.id} className={`card${isDone ? ' card-done' : ''}`}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{ fontSize: 26, lineHeight: 1 }}>{block.icon}</span>
                    <div>
                      <p style={{ fontSize: 14, fontWeight: 800 }}>{block.name}</p>
                      <p className="text-m" style={{ fontSize: 11, marginTop: 2 }}>
                        {block.exercises.length} exercise{block.exercises.length !== 1 ? 's' : ''}
                      </p>
                    </div>
                  </div>
                  {isDone ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--p)' }}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                        <polyline points="20 6 9 17 4 12"/>
                      </svg>
                      <span style={{ fontSize: 11, fontWeight: 800 }}>Done</span>
                    </div>
                  ) : (
                    <button className="btn btn-primary" style={{ fontSize: 12, padding: '8px 14px' }} onClick={() => onStartBlock(idx)}>
                      Start
                    </button>
                  )}
                </div>
                <div className="divider" style={{ marginBottom: 10 }} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {block.exercises.map((ex, i) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--muted)' }}>
                      <span style={{
                        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                        minWidth: 24, height: 22, padding: '0 5px',
                        background: 'var(--p-dim)', color: 'var(--p)',
                        fontSize: 11, fontWeight: 800, borderRadius: 6
                      }}>
                        {ex.sets}×
                      </span>
                      {ex.name}
                    </div>
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Rest card */}
      {isRest && (
        <div className="card" style={{ textAlign: 'center', padding: '40px 20px', marginTop: 14 }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>😴</div>
          <h3 style={{ fontSize: 18, fontWeight: 800, marginBottom: 6 }}>Rest Day</h3>
          <p className="text-m" style={{ fontSize: 13, lineHeight: 1.6 }}>
            Light walking or stretching only.<br />Let the CNS fully recover.
          </p>
        </div>
      )}
    </div>
  )
}
