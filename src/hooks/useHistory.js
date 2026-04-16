import { useState, useEffect, useCallback, useRef } from 'react'

const POLL_MS = 10000

export function useHistory() {
  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)
  // Tracks the latest in-flight POST so we don't clobber it with a stale GET result
  const localSeqRef = useRef(0)
  const lastPushedSeqRef = useRef(0)

  const refresh = useCallback(() => {
    // Skip refresh if a local save is pending — avoid overwriting unflushed state
    if (localSeqRef.current !== lastPushedSeqRef.current) return
    fetch('/api/history')
      .then(r => r.json())
      .then(data => setHistory(data))
      .catch(() => {})
  }, [])

  useEffect(() => {
    fetch('/api/history')
      .then(r => r.json())
      .then(data => { setHistory(data); setLoading(false) })
      .catch(() => setLoading(false))

    const interval = setInterval(refresh, POLL_MS)
    const onFocus = () => refresh()
    window.addEventListener('focus', onFocus)
    return () => {
      clearInterval(interval)
      window.removeEventListener('focus', onFocus)
    }
  }, [refresh])

  const saveHistory = useCallback((updated) => {
    setHistory(updated)
    const seq = ++localSeqRef.current
    fetch('/api/history', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    })
      .catch(console.error)
      .finally(() => { lastPushedSeqRef.current = seq })
  }, [])

  return { history, loading, saveHistory }
}
