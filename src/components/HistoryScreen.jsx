export default function HistoryScreen({ history, onDelete }) {
  if (history.length === 0) {
    return (
      <div className="screen animate-fadeUp">
        <h1 style={{ fontSize: 20, fontWeight: 900, letterSpacing: '-0.02em', marginBottom: 20 }}>History</h1>
        <p className="text-m" style={{ textAlign: 'center', padding: '48px 0', fontSize: 13 }}>
          No workouts logged yet.<br />Complete a block to see it here.
        </p>
      </div>
    )
  }

  return (
    <div className="screen animate-fadeUp">
      <h1 style={{ fontSize: 20, fontWeight: 900, letterSpacing: '-0.02em', marginBottom: 20 }}>History</h1>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {history.map((entry, idx) => {
          const date = new Date(entry.date)
          const dateStr = date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })
          const timeStr = date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })

          return (
            <div key={idx} className="card">
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 10 }}>
                <div>
                  <p style={{ fontSize: 14, fontWeight: 800 }}>{entry.dayName}</p>
                  <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                    padding: '2px 8px', borderRadius: 99,
                    fontSize: 10, fontWeight: 800, letterSpacing: '0.06em', textTransform: 'uppercase',
                    background: 'var(--p-dim)', color: 'var(--p)', marginTop: 5
                  }}>
                    {entry.blockIcon} {entry.blockName}
                  </span>
                  <p className="text-m" style={{ fontSize: 11, marginTop: 6 }}>{dateStr} · {timeStr}</p>
                </div>
                <button
                  className="btn btn-icon"
                  onClick={() => onDelete(idx)}
                  title="Delete"
                  style={{ color: '#f87171', background: 'rgba(248,113,113,0.1)' }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <polyline points="3 6 5 6 21 6"/>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </div>
              <div className="divider" style={{ marginBottom: 10 }} />
              <div className="text-m" style={{ fontSize: 12, lineHeight: 1.8 }}>
                <span className="text-p" style={{ fontWeight: 800 }}>{entry.totalSets}</span> sets completed
                {entry.exercises.map((ex, i) => {
                  const best = ex.sets.find(s => s.done && s.weight !== '—' && s.reps !== '—')
                  return (
                    <div key={i}>
                      {ex.name}
                      {best && (
                        <> — <strong style={{ color: 'var(--text)', fontFamily: 'monospace' }}>{best.weight}kg × {best.reps}</strong></>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
