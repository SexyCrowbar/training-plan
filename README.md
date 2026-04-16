# Iron & Body Protocol

A mobile-first training companion for the 5-day distributed micro-dose protocol. Runs as a local server so every device on your home network shares the same workout history.

## Stack

- **Frontend**: React 18 + Vite + Tailwind CSS
- **Backend**: Node.js + Express
- **Storage**: `data/history.json` (file-based, no database)

## Installation

Requires [Node.js](https://nodejs.org) 18+.

```bash
git clone https://github.com/SexyCrowbar/training-plan.git
cd training-plan
npm install
```

## Launch

### Development (hot reload)

```bash
npm run dev
```

Opens at `http://localhost:5173`. API calls proxy to Express on port 3001.

### Production (LAN server)

```bash
npm run build
npm start
```

The server starts on port 3000 and prints your local IP address:

```
  Iron & Body Protocol running
  Local:   http://localhost:3000
  Network: http://192.168.x.x:3000
```

Open the Network URL on any phone or tablet connected to the same Wi-Fi — all devices share one history file.

### Windows (double-click)

Run `start.bat`. It installs dependencies if needed, builds the app, and starts the server.

## Features

- **5-day rotating protocol** — 4 active days (iron/body theme) + 1 full rest day
- **Grease the Groove counter** — tracks daily sub-maximal chin-up sets with dot visualisation
- **Three themes** — Iron (gold), Body (cyan), Rest (purple), auto-switching by day
- **Block structure** — Morning Prep → Morning Power → Afternoon Hypertrophy → Evening Endurance
- **Rest timer** — auto-starts between sets, duration set per exercise
- **1RM tracking** — estimated 1-rep max chart per lift using the Epley formula
- **Shared history** — workout log persisted to `data/history.json`, accessible from all LAN devices
- **Screen wake lock** — keeps display on during workouts
