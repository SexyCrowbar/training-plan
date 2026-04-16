export default function Nav({ screen, onNav }) {
  return (
    <nav className="nav-bar">
      <button className={`nav-btn${screen === 'home' ? ' active' : ''}`} onClick={() => onNav('home')}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="4" width="18" height="18" rx="2"/>
          <line x1="16" y1="2" x2="16" y2="6"/>
          <line x1="8" y1="2" x2="8" y2="6"/>
          <line x1="3" y1="10" x2="21" y2="10"/>
        </svg>
        Train
      </button>
      <button className={`nav-btn${screen === 'stats' ? ' active' : ''}`} onClick={() => onNav('stats')}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>
        </svg>
        Stats
      </button>
      <button className={`nav-btn${screen === 'history' ? ' active' : ''}`} onClick={() => onNav('history')}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M12 20v-6M6 20V10M18 20V4"/>
        </svg>
        History
      </button>
    </nav>
  )
}
