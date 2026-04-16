import { useState, useEffect, useCallback } from 'react'

export function useHistory() {
  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/history')
      .then(r => r.json())
      .then(data => {
        setHistory(data)
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }, [])

  const saveHistory = useCallback((updated) => {
    setHistory(updated)
    fetch('/api/history', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    }).catch(console.error)
  }, [])

  return { history, loading, saveHistory }
}
