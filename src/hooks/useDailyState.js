import { useState, useEffect, useCallback, useRef } from 'react'

const POLL_MS = 10000
const SAVE_DEBOUNCE_MS = 400

function toKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function todayKey() {
  return toKey(new Date())
}

/** Effective week-start: the stored value, or 6 days ago as a safe default. */
export function effectiveWeekStart(state) {
  if (state?.weekStartDate) return state.weekStartDate
  const d = new Date()
  d.setDate(d.getDate() - 6)
  return toKey(d)
}

/**
 * Daily state stored on the server as:
 *   { gtg: { "YYYY-MM-DD": { 1: n, 2: n, ... } }, weekStartDate: "YYYY-MM-DD" }
 * Polls every 10s and on window focus so devices stay in sync.
 */
export function useDailyState() {
  const [state, setState] = useState({ gtg: {}, weekStartDate: null })
  const saveTimer = useRef(null)
  const pendingRef = useRef(false)

  const refresh = useCallback(() => {
    if (pendingRef.current) return
    fetch('/api/state')
      .then(r => r.json())
      .then(data => setState(data && typeof data === 'object' ? data : { gtg: {}, weekStartDate: null }))
      .catch(() => {})
  }, [])

  useEffect(() => {
    refresh()
    const interval = setInterval(refresh, POLL_MS)
    const onFocus = () => refresh()
    window.addEventListener('focus', onFocus)
    return () => {
      clearInterval(interval)
      window.removeEventListener('focus', onFocus)
    }
  }, [refresh])

  const persist = useCallback((next) => {
    pendingRef.current = true
    clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(() => {
      fetch('/api/state', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(next)
      })
        .catch(console.error)
        .finally(() => { pendingRef.current = false })
    }, SAVE_DEBOUNCE_MS)
  }, [])

  const setGtg = useCallback((day, value) => {
    const key = todayKey()
    setState(prev => {
      const todaysGtg = { ...(prev.gtg?.[key] || {}) }
      const resolved = typeof value === 'function' ? value(todaysGtg[day] || 0) : value
      todaysGtg[day] = Math.max(0, resolved)
      // Prune old dates — keep only today's GtG entry.
      const next = { ...prev, gtg: { [key]: todaysGtg } }
      persist(next)
      return next
    })
  }, [persist])

  const startNewWeek = useCallback(() => {
    setState(prev => {
      const next = { ...prev, weekStartDate: todayKey(), gtg: {} }
      persist(next)
      return next
    })
  }, [persist])

  const gtgToday = state.gtg?.[todayKey()] || {}
  const weekStartDate = effectiveWeekStart(state)

  return { gtgToday, setGtg, weekStartDate, startNewWeek }
}
