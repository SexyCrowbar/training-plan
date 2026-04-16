import { useState, useMemo } from 'react'

const LIFTS = [
  { label: 'Bench', name: 'Barbell Bench Press' },
  { label: 'Squat', name: 'Barbell Zercher Squats' },
  { label: 'OHP', name: 'Barbell Overhead Press' },
  { label: 'Pull-Up', name: 'Weighted Pull-Ups' },
  { label: 'Close-Grip', name: 'Close-Grip Bench' },
]

function calcE1RM(weight, reps) {
  const w = parseFloat(weight)
  const r = parseInt(reps)
  if (!w || !r || r <= 0) return null
  return Math.round(w * (1 + r / 30) * 10) / 10
}

export default function StatsScreen({ history }) {
  const [activeLift, setActiveLift] = useState(LIFTS[0])

  const liftData = useMemo(() => {
    const sessions = []
    ;[...history].reverse().forEach(entry => {
      entry.exercises?.forEach(ex => {
        if (ex.name === activeLift.name) {
          let max = null
          ex.sets?.forEach(s => {
            if (s.done && s.weight !== '—' && s.reps !== '—') {
              const e1rm = calcE1RM(s.weight, s.reps)
              if (e1rm && (!max || e1rm > max.e1rm)) {
                max = { e1rm, weight: s.weight, reps: s.reps }
              }
            }
          })
          if (max) {
            sessions.push({ date: new Date(entry.date), ...max })
          }
        }
      })
    })
    return sessions
  }, [history, activeLift])

  const current1RM = liftData.length > 0 ? liftData[liftData.length - 1].e1rm : null

  // Build SVG path from data
  const chartPath = useMemo(() => {
    if (liftData.length < 2) return null
    const vals = liftData.map(d => d.e1rm)
    const min = Math.min(...vals)
    const max = Math.max(...vals)
    const range = max - min || 1
    const W = 300, H = 100, pad = 10
    const points = vals.map((v, i) => {
      const x = pad + (i / (vals.length - 1)) * (W - pad * 2)
      const y = H - pad - ((v - min) / range) * (H - pad * 2)
      return [x, y]
    })
    const d = points.map(([x, y], i) => `${i === 0 ? 'M' : 'L'}${x},${y}`).join(' ')
    const fill = `${d} L${points[points.length - 1][0]},${H} L${points[0][0]},${H} Z`
    const last = points[points.length - 1]
    return { d, fill, last }
  }, [liftData])

  return (
    <div className="screen animate-fadeUp">
      <h1 style={{ fontSize: 20, fontWeight: 900, letterSpacing: '-0.02em', marginBottom: 20 }}>Progress</h1>

      {/* Lift tabs */}
      <div className="tabs" style={{ marginBottom: 16 }}>
        {LIFTS.map(lift => (
          <button
            key={lift.name}
            className={`tab${lift.name === activeLift.name ? ' active' : ''}`}
            onClick={() => setActiveLift(lift)}
          >
            {lift.label}
          </button>
        ))}
      </div>

      {/* Chart card */}
      <div className="card" style={{ marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 16 }}>
          <div>
            <h3 style={{ fontSize: 15, fontWeight: 800 }}>{activeLift.name}</h3>
            <p className="text-m" style={{ fontSize: 11, marginTop: 2 }}>Estimated 1-Rep Max</p>
          </div>
          <div style={{ textAlign: 'right' }}>
            {current1RM ? (
              <>
                <p className="text-p" style={{ fontSize: 24, fontWeight: 900, lineHeight: 1 }}>{current1RM} kg</p>
                <p className="text-m" style={{ fontSize: 10, marginTop: 2 }}>Current 1RM</p>
              </>
            ) : (
              <p className="text-m" style={{ fontSize: 12 }}>No data yet</p>
            )}
          </div>
        </div>

        <div className="chart-wrap">
          {chartPath ? (
            <svg viewBox="0 0 300 100" preserveAspectRatio="none" style={{ width: '100%', height: '100%' }}>
              <defs>
                <linearGradient id="cg" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="var(--p)" stopOpacity="0.25"/>
                  <stop offset="100%" stopColor="var(--p)" stopOpacity="0"/>
                </linearGradient>
              </defs>
              <path d={chartPath.fill} fill="url(#cg)"/>
              <path d={chartPath.d} fill="none" stroke="var(--p)" strokeWidth="2.5" vectorEffect="non-scaling-stroke"/>
              <circle cx={chartPath.last[0]} cy={chartPath.last[1]} r="5" fill="var(--p)" vectorEffect="non-scaling-stroke"/>
            </svg>
          ) : (
            <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <p className="text-m" style={{ fontSize: 12 }}>
                {liftData.length === 0 ? 'Log sets to see your progress' : 'Need at least 2 sessions for a chart'}
              </p>
            </div>
          )}
          {chartPath && (
            <>
              <p className="text-m" style={{ position: 'absolute', bottom: 2, left: 0, fontSize: 10 }}>
                {liftData[0]?.date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
              </p>
              <p className="text-m" style={{ position: 'absolute', bottom: 2, right: 0, fontSize: 10 }}>Today</p>
            </>
          )}
        </div>
      </div>

      {/* Session table */}
      {liftData.length > 0 && (
        <div className="card">
          <p className="sec-label" style={{ marginBottom: 12 }}>Recent Sessions</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
            {[...liftData].reverse().slice(0, 8).map((s, i) => (
              <div key={i}>
                <div className="divider" />
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '9px 0', fontSize: 13 }}>
                  <span className="text-m">
                    {s.date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })}
                  </span>
                  <div>
                    <span style={{ fontFamily: 'monospace', fontWeight: 800 }}>{s.weight} kg × {s.reps}</span>
                    <span className="text-p" style={{ fontSize: 11, marginLeft: 6 }}>est. {s.e1rm}kg</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
