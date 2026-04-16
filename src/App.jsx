import { useState, useEffect } from 'react'
import { DAYS } from './data/plan'
import { useHistory } from './hooks/useHistory'
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
  const [doneBlocks, setDoneBlocks] = useState({ 1: new Set(), 2: new Set(), 3: new Set(), 4: new Set(), 5: new Set() })
  const [modal, setModal] = useState(null)
  const { history, saveHistory } = useHistory()

  // Apply theme to <html>
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', DAYS[currentDay].theme)
  }, [currentDay])

  function handleDayChange(n) {
    setCurrentDay(n)
  }

  function handleStartBlock(blockIdx) {
    setActiveBlock(blockIdx)
    setScreen('workout')
  }

  function handleFinishBlock(entry, pr) {
    // Save to history
    const updated = [entry, ...history]
    saveHistory(updated)

    // Mark block done
    setDoneBlocks(prev => {
      const next = { ...prev }
      next[currentDay] = new Set(prev[currentDay])
      next[currentDay].add(DAYS[currentDay].blocks[activeBlock].id)
      return next
    })

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

  function navTo(name) {
    if (screen === 'workout' && name !== 'workout') {
      // leaving workout — just go back
    }
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
          onStartBlock={handleStartBlock}
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
