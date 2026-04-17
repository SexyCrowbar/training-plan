import { useState, useEffect, useMemo, useRef } from 'react'
import { DAYS } from './data/plan'
import { useHistory } from './hooks/useHistory'
import { useDailyState } from './hooks/useDailyState'
import Nav from './components/Nav'
import Modal from './components/Modal'
import HomeScreen from './components/HomeScreen'
import WorkoutScreen from './components/WorkoutScreen'
import HistoryScreen from './components/HistoryScreen'
import StatsScreen from './components/StatsScreen'

export default function App() {
  const [screen, setScreen] = useState('home')
  const [currentDay, setCurrentDay] = useState(1)
  const [activeBlock, setActiveBlock] = useState(null)
  const [modal, setModal] = useState(null)
  const { history, saveHistory } = useHistory()
  const { gtgToday, setGtg, weekStartDate, startNewWeek } = useDailyState()

  // Apply theme to <html>
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', DAYS[currentDay].theme)
  }, [currentDay])

  // Derive done blocks for the current week from shared history.
  // A block is done if any entry for that day/blockId has a date >= weekStartDate.
  const doneBlocks = useMemo(() => {
    const map = { 1: new Set(), 2: new Set(), 3: new Set(), 4: new Set(), 5: new Set() }
    for (const entry of history) {
      if (!entry?.date) continue
      const entryDay = entry.date.slice(0, 10)
      if (entryDay < weekStartDate) continue
      if (map[entry.day] && entry.blockId) map[entry.day].add(entry.blockId)
    }
    return map
  }, [history, weekStartDate])

  // Auto-jump to the first incomplete day once on initial load.
  const autoAdvancedRef = useRef(false)
  useEffect(() => {
    if (autoAdvancedRef.current) return
    // Wait for history to be available (or confirmed empty)
    if (history.length === 0 && !weekStartDate) return
    autoAdvancedRef.current = true
    for (let n = 1; n <= 5; n++) {
      const day = DAYS[n]
      const total = day.blocks?.length || 0
      if (total === 0) continue // rest day — skip
      if ((doneBlocks[n]?.size || 0) < total) {
        setCurrentDay(n)
        return
      }
    }
  }, [history, doneBlocks, weekStartDate])

  function handleDayChange(n) {
    setCurrentDay(n)
  }

  function handleStartBlock(blockIdx) {
    setActiveBlock(blockIdx)
    setScreen('workout')
  }

  function handleFinishBlock(entry, pr) {
    // Save to history — doneBlocks derive from this automatically.
    const updated = [entry, ...history]
    saveHistory(updated)

    if (pr) {
      setModal({
        title: '🏆 New PR!',
        message: `${pr.exercise}: ${pr.weight}kg × ${pr.reps} reps — est. ${pr.value}kg 1RM`,
        confirmLabel: 'Let\'s go!',
        onConfirm: () => setModal(null)
      })
    }

    setScreen('home')
    setActiveBlock(null)
  }

  function handleDeleteEntry(idx) {
    setModal({
      title: 'Delete entry?',
      message: 'This workout log will be permanently removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      danger: true,
      onConfirm: () => {
        const updated = history.filter((_, i) => i !== idx)
        saveHistory(updated)
        setModal(null)
      },
      onCancel: () => setModal(null)
    })
  }

  function handleStartNewWeek() {
    setModal({
      title: 'Start a new week?',
      message: 'Completed-block checkmarks will reset. Your workout history is kept.',
      confirmLabel: 'Start fresh',
      cancelLabel: 'Cancel',
      onConfirm: () => {
        startNewWeek()
        setCurrentDay(1)
        autoAdvancedRef.current = true // don't re-jump after reset
        setModal(null)
      },
      onCancel: () => setModal(null)
    })
  }

  function navTo(name) {
    setScreen(name)
  }

  const navScreen = screen === 'workout' ? 'home' : screen

  return (
    <>
      {screen === 'home' && (
        <HomeScreen
          currentDay={currentDay}
          onDayChange={handleDayChange}
          doneBlocks={doneBlocks[currentDay]}
          allDoneBlocks={doneBlocks}
          onStartBlock={handleStartBlock}
          gtgToday={gtgToday}
          onGtgChange={setGtg}
          weekStartDate={weekStartDate}
          onStartNewWeek={handleStartNewWeek}
        />
      )}
      {screen === 'workout' && activeBlock !== null && (
        <WorkoutScreen
          currentDay={currentDay}
          blockIdx={activeBlock}
          onFinish={handleFinishBlock}
          onBack={() => setScreen('home')}
          showModal={setModal}
        />
      )}
      {screen === 'history' && (
        <HistoryScreen
          history={history}
          onDelete={handleDeleteEntry}
        />
      )}
      {screen === 'stats' && (
        <StatsScreen history={history} />
      )}

      <Nav screen={navScreen} onNav={navTo} />
      <Modal modal={modal} onClose={() => setModal(null)} />
    </>
  )
}
