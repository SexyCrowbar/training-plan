import { useState, useRef, useEffect } from 'react'
import { DAYS } from '../data/plan'
import Timer from './Timer'

function calcE1RM(weight, reps) {
  const w = parseFloat(weight)
  const r = parseInt(reps)
  if (!w || !r || r <= 0) return null
  return Math.round(w * (1 + r / 30) * 10) / 10
}

export default function WorkoutScreen({ currentDay, blockIdx, onFinish, onBack, showModal }) {
  const d = DAYS[currentDay]
  const block = d.blocks[blockIdx]
  const timerRef = useRef(null)

  // checked[exIdx][setIdx]
  const [checked, setChecked] = useState(() =>
    block.exercises.map(ex => Array(ex.sets).fill(false))
  )
  const [weights, setWeights] = useState(() =>
    block.exercises.map(ex => Array(ex.sets).fill(''))
  )
  const [reps, setReps] = useState(() =>
    block.exercises.map(ex => Array(ex.sets).fill(''))
  )

  // Screen wake lock
  useEffect(() => {
    let lock = null
    if ('wakeLock' in navigator) {
      navigator.wakeLock.request('screen').then(l => { lock = l }).catch(() => {})
    }
    return () => { lock?.release() }
  }, [])

  function toggleSet(exIdx, setIdx, rest) {
    setChecked(prev => {
      const next = prev.map(r => [...r])
      next[exIdx][setIdx] = !next[exIdx][setIdx]
      if (next[exIdx][setIdx] && rest > 0) {
        timerRef.current?.start(rest)
      }
      return next
    })
    if (navigator.vibrate) navigator.vibrate(10)
  }

  function finish() {
    const exercises = block.exercises.map((ex, ei) => ({
      name: ex.name,
      sets: checked[ei].map((done, si) => ({
        done,
        weight: weights[ei][si] || '—',
        reps: reps[ei][si] || '—'
      }))
    }))

    // PR detection
    let pr = null
    exercises.forEach(ex => {
      ex.sets.forEach(s => {
        const e1rm = calcE1RM(s.weight, s.reps)
        if (e1rm && (!pr || e1rm > pr.value)) {
          pr = { exercise: ex.name, value: e1rm, weight: s.weight, reps: s.reps }
        }
      })
    })

    const entry = {
      date: new Date().toISOString(),
      day: currentDay,
      dayName: d.name,
      blockId: block.id,
      blockName: block.name,
      blockIcon: block.icon,
      theme: d.theme,
      exercises,
      totalSets: exercises.reduce((a, ex) => a + ex.sets.filter(s => s.done).length, 0)
    }

    timerRef.current?.stop()
    onFinish(entry, pr)
  }

  if (!block) return null

  return (
    <div className="screen animate-fadeUp">
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 20 }}>
        <button className="btn btn-icon" onClick={onBack} style={{ marginTop: 2 }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <path d="m15 18-6-6 6-6"/>
          </svg>
        </button>
        <div>
          <p className="text-p" style={{ fontSize: 11, fontWeight: 800, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 3 }}>
            {block.icon}  {block.name}
          </p>
          <h2 style={{ fontSize: 19, fontWeight: 900, letterSpacing: '-0.02em', lineHeight: 1.2 }}>{block.name}</h2>
          <p className="text-m" style={{ fontSize: 12, marginTop: 3 }}>
            {d.name} · {d.theme[0].toUpperCase()}{d.theme.slice(1)} day
          </p>
        </div>
      </div>

      {/* Timer */}
      <Timer ref={timerRef} />

      {/* Exercise cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {block.exercises.map((ex, ei) => {
          const restLabel = ex.rest === 0 ? 'No rest'
            : ex.rest >= 60 ? `${ex.rest / 60}m rest`
            : `${ex.rest}s rest`

          return (
            <div key={ei} className="card">
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 3 }}>
                <h3 style={{ fontSize: 15, fontWeight: 800, flex: 1, paddingRight: 10 }}>{ex.name}</h3>
                <span style={{
                  flexShrink: 0, fontSize: 11, fontWeight: 800, padding: '3px 10px',
                  borderRadius: 99, background: 'var(--p-dim)', color: 'var(--p)'
                }}>
                  {restLabel}
                </span>
              </div>
              <p className="text-m" style={{ fontSize: 12, marginBottom: 4 }}>
                Target: {ex.sets} × {ex.target}
              </p>
              {ex.note && <div className="note">{ex.note}</div>}

              <div style={{ marginTop: 10 }}>
                {/* Column headers */}
                <div className="set-row" style={{ marginBottom: 4, opacity: 0.5 }}>
                  <div />
                  <div style={{ fontSize: 10, fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--muted)', textAlign: 'center' }}>kg</div>
                  <div style={{ fontSize: 10, fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--muted)', textAlign: 'center' }}>Reps</div>
                  <div />
                </div>

                {/* Set rows */}
                {Array.from({ length: ex.sets }).map((_, si) => (
                  <div key={si} className="set-row" style={{ marginBottom: 8 }}>
                    <div
                      className={`check${checked[ei][si] ? ' on' : ''}`}
                      onClick={() => toggleSet(ei, si, ex.rest)}
                    >
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                        <polyline points="20 6 9 17 4 12"/>
                      </svg>
                    </div>
                    <input
                      className="set-input"
                      type="text"
                      inputMode="decimal"
                      placeholder="—"
                      value={weights[ei][si]}
                      onChange={e => setWeights(prev => {
                        const n = prev.map(r => [...r])
                        n[ei][si] = e.target.value
                        return n
                      })}
                    />
                    <input
                      className="set-input"
                      type="number"
                      inputMode="numeric"
                      placeholder="—"
                      value={reps[ei][si]}
                      onChange={e => setReps(prev => {
                        const n = prev.map(r => [...r])
                        n[ei][si] = e.target.value
                        return n
                      })}
                    />
                    <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--muted)', textAlign: 'center' }}>
                      S{si + 1}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )
        })}
      </div>

      {/* Finish */}
      <div style={{ marginTop: 24 }}>
        <button
          className="btn btn-primary"
          style={{ width: '100%', padding: 16, fontSize: 15, borderRadius: 14, letterSpacing: '0.03em' }}
          onClick={finish}
        >
          Finish Block
        </button>
      </div>
    </div>
  )
}
