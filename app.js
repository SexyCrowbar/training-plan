/**
 * DOM Elements
 */
const app = document.getElementById('app');

/**
 * CONSTANTS & DATA
 */
const PLAN = {
    1: {
        type: 'iron',
        name: 'Iron A: Squat Focus',
        tag: 'Force Output',
        exercises: [
            { id: 'sq_zerch', name: 'Zercher Squat', sets: 5, reps: '3', rest: 240, note: 'Heavy. Brace hard.' },
            { id: 'bp', name: 'Bench Press', sets: 4, reps: '8-10', rest: 180, note: 'Controlled eccentric. Explosive up.' },
            { id: 'hang', name: 'Active Hang', sets: 3, reps: '30-60s', rest: 60, note: 'Decompression.' }
        ]
    },
    2: {
        type: 'body',
        name: 'Body A: Pull & Hinge',
        tag: 'Endurance',
        exercises: [
            { id: 'af_warm', name: 'Animal Flow Warm-up', sets: 1, reps: '5-10m', rest: 0, note: 'Ape & Crab reach.' },
            { id: 'pullup', name: 'Pull-Ups', sets: 4, reps: 'AMRAP', rest: 90, note: 'Strict or Negatives.' },
            { id: 'kb_swing', name: 'Kettlebell Swings', sets: 1, reps: '100 Total', rest: 60, note: 'Sets of 15/20/25.' },
            { id: 'bear', name: 'Bear Crawl', sets: 3, reps: '60s', rest: 60, note: 'Fwd & Bwd.' }
        ]
    },
    3: {
        type: 'iron',
        name: 'Iron B: Deadlift Focus',
        tag: 'Posterior Power',
        exercises: [
            { id: 'dl_zerch', name: 'Zercher Deadlift', sets: 5, reps: '3', rest: 240, note: 'Protect bicep tendons.' },
            { id: 'ohp', name: 'Overhead Press', sets: 4, reps: '8-10', rest: 180, note: 'Strict military press.' },
            { id: 'facepull', name: 'Face Pulls', sets: 3, reps: '15', rest: 60, note: 'Prehab.' }
        ]
    },
    4: {
        type: 'body',
        name: 'Body B: Push & Core',
        tag: 'Pump & Density',
        exercises: [
            { id: 'af_warm2', name: 'Animal Flow Warm-up', sets: 1, reps: '5-10m', rest: 0, note: 'Scorpion & Beast.' },
            { id: 'dips', name: 'Parallel Bar Dips', sets: 4, reps: 'AMRAP', rest: 90, note: 'Lean forward.' },
            { id: 'pushups', name: 'Pushups', sets: 1, reps: '100 Total', rest: 60, note: 'Sets of 15-25.' },
            { id: 'situps', name: 'Sit-Ups', sets: 3, reps: 'AMRAP', rest: 60, note: 'Explosive up, 3s down.' }
        ]
    },
    5: {
        type: 'iron',
        name: 'Iron C: Squat Volume',
        tag: 'Leg Power',
        exercises: [
            { id: 'sq_zerch_vol', name: 'Zercher Squat', sets: 5, reps: '3', rest: 240, note: 'Focus on speed. -10% if fried.' },
            { id: 'bp_vol', name: 'Bench Press', sets: 4, reps: '8-10', rest: 180, note: 'Perfect technique.' }
        ]
    },
    6: {
        type: 'body',
        name: 'Body C: The Flow',
        tag: 'Active Recovery',
        exercises: [
            { id: 'af_combine', name: 'Animal Flow Combine', sets: 1, reps: '20m', rest: 0, note: 'Continuous movement.' },
            { id: 'chins', name: 'Chin-Ups', sets: 3, reps: 'AMRAP', rest: 90, note: 'Palms facing you.' },
            { id: 'kb_swing_p', name: 'Kettlebell Swings', sets: 5, reps: '20', rest: 60, note: 'Perfect hip snap.' }
        ]
    },
    7: {
        type: 'rest',
        name: 'Full Rest',
        tag: 'Recovery',
        exercises: []
    }
};

const WEEKLY_MAP = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/**
 * STATE MANAGEMENT
 */
const State = {
    currentDay: 1, // 1-7
    activeSession: null,
    editIndex: null, // Index of log being edited, or null
    history: [],

    init() {
        const storedDay = localStorage.getItem('wp_day');
        if (storedDay) this.currentDay = parseInt(storedDay);

        const storedHistory = localStorage.getItem('wp_history');
        if (storedHistory) this.history = JSON.parse(storedHistory);

        this.updateTheme();
    },

    setDay(day) {
        this.currentDay = day;
        localStorage.setItem('wp_day', day);
        this.updateTheme();
        Render.home();
    },

    nextDay() {
        this.currentDay = this.currentDay < 7 ? this.currentDay + 1 : 1;
        this.setDay(this.currentDay);
    },

    updateTheme() {
        const dayData = PLAN[this.currentDay];
        document.body.setAttribute('data-theme', dayData ? dayData.type : 'iron');
    },

    saveLog(log, index = null) {
        if (index !== null) {
            this.history[index] = log; // Update
        } else {
            this.history.unshift(log); // Create
        }
        localStorage.setItem('wp_history', JSON.stringify(this.history));
    },

    deleteLog(index) {
        if (!confirm('Delete this log permanently?')) return;
        this.history.splice(index, 1);
        localStorage.setItem('wp_history', JSON.stringify(this.history));
        Render.history();
    }
};

/**
 * UTILS
 */
const Utils = {
    vibrate(pattern = 50) {
        if (navigator.vibrate) navigator.vibrate(pattern);
    },

    // Check if a specific cycle day is completed in history (basic logic: assumes ideal week)
    // For a real app, you'd match dates. Here we just mock visually based on current day progression.
    getDayStatus(dayIdx) {
        // Simple logic for the heatmap: 
        // If dayIdx < currentDay, it's done. 
        // If dayIdx == currentDay, it's current.
        // We use the PLAN to determine color.

        if (dayIdx < State.currentDay) {
            return PLAN[dayIdx].type === 'iron' ? 'done-iron' : (PLAN[dayIdx].type === 'body' ? 'done-body' : 'done-rest');
        } else if (dayIdx === State.currentDay) {
            return 'current';
        }
        return '';
    }
};

/**
 * RENDER ENGINE
 */
const Render = {
    home() {
        State.editIndex = null; // Clear edit state on home
        const dayData = PLAN[State.currentDay];
        const isRest = dayData.type === 'rest';

        // Generate Heatmap
        let heatmapHTML = `<div class="heatmap-container fade-in">`;
        for (let i = 1; i <= 7; i++) {
            const statusClass = Utils.getDayStatus(i);
            const letter = WEEKLY_MAP[i - 1];
            heatmapHTML += `<div class="heatmap-bubble ${statusClass}">${letter}</div>`;
        }
        heatmapHTML += `</div>`;

        let html = `
            <header class="fade-in">
                ${heatmapHTML}
                <div class="flex justify-between items-center mb-6">
                    <div>
                        <div class="badge ${dayData.type === 'iron' ? 'active' : ''} mb-2">Cycle Day ${State.currentDay}</div>
                        <h1>${isRest ? 'Recovery Mode' : 'Ready to Train?'}</h1>
                    </div>
                </div>
            </header>

            <div class="card fade-in slide-up">
                <div class="flex justify-between items-start mb-4">
                    <div>
                        <h2 class="text-primary mb-1">${dayData.name}</h2>
                        <p class="text-secondary text-sm uppercase tracking-wide">${dayData.tag}</p>
                    </div>
                </div>
                
                ${isRest ?
                `<p class="mb-6 text-secondary">Mandatory rest. Light walking or stretching only. No heavy lifting.</p>` :
                `<div class="mb-6 space-y-2">
                        ${dayData.exercises.map(ex => `
                            <div class="flex items-center text-sm text-secondary">
                                <span class="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-xs mr-3">${ex.sets}</span>
                                <span>${ex.name}</span>
                            </div>
                        `).join('')}
                    </div>`
            }

                ${isRest ?
                `<button onclick="State.nextDay()" class="btn btn-primary">Complete Rest Day</button>` :
                `<button onclick="Render.workout()" class="btn btn-primary">Start Session</button>`
            }
            </div>
            
            ${!isRest ?
                `<div class="mt-8 fade-in">
                <h3 class="text-secondary text-sm mb-4">Pro Tips</h3>
                <div class="card p-4">
                    <ul class="text-sm list-disc pl-4 space-y-2 text-secondary">
                        ${dayData.type === 'iron' ?
                    `<li>Rest <strong>3-5 minutes</strong> between sets.</li><li>Leave 1-2 reps in the tank (RPE 8-9).</li><li>Focus on TENSION, not failing.</li>` :
                    `<li>Rest <strong>60-90 seconds</strong> only.</li><li>Go to technical failure.</li><li>Focus on SWEAT.</li>`
                }
                    </ul>
                </div>
            </div>` : ''
            }
        `;

        app.innerHTML = html;
        this.updateNav('train');
    },

    workout(prefillSets = null) {
        const dayData = PLAN[State.currentDay];
        const isEditing = State.editIndex !== null;

        let html = `
            <div class="fade-in">
                <div class="flex items-center justify-between mb-6">
                    <div class="flex items-center">
                        <button onclick="${isEditing ? 'Render.history()' : 'Render.home()'}" class="mr-4 text-secondary"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m15 18-6-6 6-6"/></svg></button>
                        <div>
                            ${isEditing ? '<span class="text-xs text-primary font-bold uppercase">Editing Mode</span>' : ''}
                            <h2>${dayData.name}</h2>
                        </div>
                    </div>
                </div>

                <div id="active-timer" class="hidden sticky top-4 z-50 mb-4 slide-up">
                    <div class="card p-3 flex justify-between items-center bg-slate-900 border-primary shadow-[0_0_15px_rgba(0,0,0,0.5)]">
                        <span class="text-sm text-secondary">Rest Timer</span>
                        <span class="font-mono text-xl font-bold text-primary" id="timer-display">00:00</span>
                        <button onclick="Timer.stop()" class="text-xs uppercase font-bold text-red-400 p-2">Stop</button>
                    </div>
                </div>

                ${dayData.exercises.map((ex, exIdx) => `
                    <div class="card mb-6">
                        <div class="mb-3">
                            <h3 class="text-lg">${ex.name}</h3>
                            <div class="flex justify-between text-xs text-secondary mt-1">
                                <span>Target: ${ex.sets} x ${ex.reps}</span>
                                <span class="text-primary">${ex.rest}s Rest</span>
                            </div>
                        </div>
                        
                        ${ex.note ? `<div class="coach-note">${ex.note}</div>` : ''}

                        <div class="space-y-3">
                            ${Array(ex.sets).fill(0).map((_, setIdx) => {
            // Auto-check logic if editing
            // Basic logic: if prefillSets > count of previous exercises sets?
            // Actually, simpler: history stores 'completedSets' total count.
            // We'll just check the first N circles.
            let shouldCheck = false;
            if (Number.isInteger(prefillSets) && prefillSets > 0) {
                shouldCheck = true;
                prefillSets--;
            }

            return `
                                <div class="set-grid">
                                    <div class="check-circle ${shouldCheck ? 'checked' : ''}" id="check-${exIdx}-${setIdx}" onclick="Session.toggleSet(${exIdx}, ${setIdx}, ${ex.rest})">
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" class="${shouldCheck ? '' : 'opacity-0'} transition-opacity"><polyline points="20 6 9 17 4 12"/></svg>
                                    </div>
                                    <input type="number" placeholder="kg" class="bg-black/20 text-center text-sm p-3">
                                    <input type="number" placeholder="Reps" value="${ex.reps.includes('-') ? '' : ex.reps}" class="bg-black/20 text-center text-sm p-3">
                                </div>`;
        }).join('')}
                        </div>
                    </div>
                `).join('')}

                <div class="pb-24">
                    <button onclick="Session.finish()" class="btn btn-primary">${isEditing ? 'Update Log' : 'Finish Workout'}</button>
                </div>
            </div>
        `;

        app.innerHTML = html;
        window.scrollTo(0, 0);
    },

    history() {
        State.editIndex = null;
        const hist = State.history;
        let html = `
            <div class="fade-in">
                <h1 class="mb-6">History</h1>
                ${hist.length === 0 ? `<p class="text-secondary text-center">No workouts logged yet.</p>` : ''}
                ${hist.map((entry, idx) => `
                    <div class="card">
                        <div class="flex justify-between items-start mb-2">
                            <div>
                                <span class="font-bold text-lg">${entry.name}</span>
                                <div class="text-xs text-secondary">${new Date(entry.date).toLocaleDateString()} ${new Date(entry.date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
                            </div>
                            <div class="flex gap-2">
                                <button onclick="Session.edit(${idx})" class="p-2 text-primary hover:bg-white/5 rounded" aria-label="Edit">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>
                                </button>
                                <button onclick="State.deleteLog(${idx})" class="p-2 text-red-400 hover:bg-white/5 rounded" aria-label="Delete">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                                </button>
                            </div>
                        </div>
                        <div class="text-sm text-secondary">
                            Completed <span class="text-primary font-bold">${entry.completedSets}</span> sets
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
        app.innerHTML = html;
        this.updateNav('history');
    },

    stats(activeKey = 'sq') {
        State.editIndex = null;

        // Stats Logic
        const keys = [
            { id: 'sq', label: 'Squat', display: 'Squat 1RM' },
            { id: 'bp', label: 'Bench', display: 'Bench 1RM' },
            { id: 'dl', label: 'Deadlift', display: 'Deadlift 1RM' },
            { id: 'ohp', label: 'Press', display: 'OHP 1RM' }
        ];

        const data = Stats.getProgress(activeKey);

        // Generate SVG Chart
        let chartHTML = '';
        if (data.length < 2) {
            chartHTML = `<div class="h-48 flex items-center justify-center text-secondary text-sm border border-dashed border-white/10 rounded-lg mt-4">Need 2+ logs to graph</div>`;
        } else {
            // Normalize data
            const values = data.map(d => d.value);
            const minV = Math.min(...values) * 0.9;
            const maxV = Math.max(...values) * 1.1;
            const range = maxV - minV;

            // Points
            const points = data.map((d, i) => {
                const x = (i / (data.length - 1)) * 100;
                const y = 100 - ((d.value - minV) / range) * 100;
                return `${x},${y}`;
            }).join(' ');

            chartHTML = `
                <div class="chart-container">
                    <svg viewBox="0 0 100 100" preserveAspectRatio="none" style="width:100%; height:100%;">
                        <polyline points="${points}" class="chart-line" vector-effect="non-scaling-stroke" />
                        ${data.map((d, i) => {
                const x = (i / (data.length - 1)) * 100;
                const y = 100 - ((d.value - minV) / range) * 100;
                return `<circle cx="${x}" cy="${y}" class="chart-dot" vector-effect="non-scaling-stroke" />`;
            }).join('')}
                    </svg>
                    <div class="absolute bottom-2 right-2 text-xs text-primary font-bold">Latest: ${Math.round(data[data.length - 1].value)}kg</div>
                </div>
            `;
        }

        let html = `
            <div class="fade-in">
                <h1 class="mb-6">Progress</h1>
                
                <div class="knob-container">
                    ${keys.map(k => `
                        <button onclick="Render.stats('${k.id}')" class="knob ${activeKey === k.id ? 'active' : ''}">${k.label}</button>
                    `).join('')}
                </div>

                <div class="card">
                    <h2 class="text-primary mb-1">${keys.find(k => k.id === activeKey).display}</h2>
                    <p class="text-xs text-secondary uppercase tracking-wide">Estimated One Rep Max</p>
                    ${chartHTML}
                </div>

                 <div class="card bg-white/5 mt-4">
                    <h3 class="text-sm text-secondary mb-2">History Log (${keys.find(k => k.id === activeKey).label})</h3>
                    <div class="space-y-2">
                        ${data.slice().reverse().map(d => `
                            <div class="flex justify-between text-sm border-b border-white/5 pb-1">
                                <span>${new Date(d.date).toLocaleDateString()}</span>
                                <span class="font-mono text-primary">${Math.round(d.value)}kg</span>
                            </div>
                        `).join('')}
                        ${data.length === 0 ? '<span class="text-xs text-secondary">No data found.</span>' : ''}
                    </div>
                </div>
            </div>
        `;

        app.innerHTML = html;
        this.updateNav('stats');
    },

    updateNav(activeTab) {
        // Inject Stats button if missing (runtime fix)
        const nav = document.querySelector('.nav-bar');
        if (nav && !nav.querySelector('[data-tab="stats"]')) {
            // Rebuild nav to be safe or append? Appending is easier.
            // But layout "space-around" handles it.
            const statsBtn = document.createElement('button');
            statsBtn.className = 'nav-item';
            statsBtn.dataset.tab = 'stats';
            statsBtn.onclick = () => Render.stats();
            statsBtn.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/></svg><span>Stats</span>`;
            // Insert before History
            const historyBtn = nav.querySelector('[data-tab="history"]');
            nav.insertBefore(statsBtn, historyBtn);
        }

        document.querySelectorAll('.nav-item').forEach(el => {
            el.classList.remove('active');
            if (el.dataset.tab === activeTab) el.classList.add('active');
        });
    }
};

/**
 * LOGIC MODULES
 */

const Stats = {
    // Return array of { date, value } for a given key string (sq, bp, dl, ohp)
    getProgress(key) {
        const history = State.history;
        const data = [];

        // Exercise ID mapping
        const map = {
            'sq': ['sq_zerch', 'sq_zerch_vol'],
            'bp': ['bp', 'bp_vol'],
            'dl': ['dl_zerch'],
            'ohp': ['ohp']
        };
        const targets = map[key];

        // Process history chronological (must reverse first as history is new->old)
        [...history].reverse().forEach(log => {
            // Old logs might not have 'exercises' array
            if (!log.exercises) return;

            let max1RM = 0;

            log.exercises.forEach(ex => {
                if (targets.includes(ex.id)) {
                    // Calculate 1RM for this set
                    // We need to parse weight/reps
                    const w = parseFloat(ex.weight) || 0;
                    const r = parseFloat(ex.reps) || 0;

                    if (w > 0 && r > 0) {
                        const e1rm = w * (1 + r / 30);
                        if (e1rm > max1RM) max1RM = e1rm;
                    }
                }
            });

            if (max1RM > 0) {
                data.push({ date: log.date, value: max1RM });
            }
        });

        return data;
    }
};

const Session = {
    toggleSet(exIdx, setIdx, restTime) {
        const el = document.getElementById(`check-${exIdx}-${setIdx}`);
        const isChecked = el.classList.contains('checked');

        Utils.vibrate(50); // Haptic

        if (isChecked) {
            el.classList.remove('checked');
            el.querySelector('svg').classList.add('opacity-0');
        } else {
            el.classList.add('checked');
            el.querySelector('svg').classList.remove('opacity-0');
            // Auto start timer if not last set
            Timer.start(restTime);
        }
    },

    edit(index) {
        const log = State.history[index];
        if (!log.dayId) {
            alert("This log cannot be edited (Legacy format).");
            return;
        }

        State.editIndex = index;
        State.currentDay = log.dayId;
        State.updateTheme();

        // Need to fully restore values if we want 'Editing' to be useful
        // But the previous implementation just did completedSets.
        // For enhanced logging, we need to try and fill inputs if they exist in the log.
        // This is complex for legacy logs vs new logs.
        // For now, we support the Context switch, user re-enters data.

        Render.workout(log.completedSets);
    },

    finish() {
        const isEditing = State.editIndex !== null;
        if (!confirm(isEditing ? 'Update this log entry?' : 'Finish and mark day as complete?')) return;

        // Scrape Data
        const dayData = PLAN[State.currentDay];
        const capturedExercises = [];

        // Iterate physical DOM cards to get inputs
        // Note: Relies on DOM structure remaining stable
        // card -> space-y-3 -> set-grid

        // We can map over dayData.exercises and query by indices
        let totalSets = 0;

        dayData.exercises.forEach((ex, exIdx) => {
            // Get all set grids for this exercise
            for (let setIdx = 0; setIdx < ex.sets; setIdx++) {
                const checkEl = document.getElementById(`check-${exIdx}-${setIdx}`);
                const isChecked = checkEl.classList.contains('checked');

                if (isChecked) totalSets++;

                // Find inputs: they are siblings to the check-circle
                // set-grid children: [check-circle, input(weight), input(reps)]
                const parent = checkEl.parentElement;
                const inputs = parent.querySelectorAll('input');
                const weight = inputs[0].value;
                const reps = inputs[1].value;

                if (isChecked || weight || reps) { // Save line if anything happened
                    capturedExercises.push({
                        id: ex.id,
                        set: setIdx + 1,
                        weight: weight,
                        reps: reps,
                        completed: isChecked
                    });
                }
            }
        });

        const log = {
            date: new Date().toISOString(),
            dayId: State.currentDay,
            name: dayData.name,
            completedSets: totalSets,
            exercises: capturedExercises // New Data Field
        };

        if (isEditing) {
            const originalDate = State.history[State.editIndex].date;
            log.date = originalDate;
            State.saveLog(log, State.editIndex);
            State.editIndex = null;
            Render.history();
        } else {
            State.saveLog(log);
            State.nextDay();
            Render.home();
        }

        Timer.stop();
        Utils.vibrate([100, 50, 100]);
    }
};

const Timer = {
    interval: null,
    endTime: null,

    start(seconds) {
        this.stop();
        Utils.vibrate(50);
        this.endTime = Date.now() + (seconds * 1000);

        const display = document.getElementById('active-timer');
        if (display) display.classList.remove('hidden');

        this.tick();
        this.interval = setInterval(() => this.tick(), 1000);
    },

    tick() {
        const left = Math.ceil((this.endTime - Date.now()) / 1000);
        if (left <= 0) {
            this.stop();
            Utils.vibrate([200, 100, 200]); // Alarm pattern
            return;
        }

        const m = Math.floor(left / 60).toString().padStart(2, '0');
        const s = (left % 60).toString().padStart(2, '0');

        const el = document.getElementById('timer-display');
        if (el) el.innerText = `${m}:${s}`;
    },

    stop() {
        if (this.interval) clearInterval(this.interval);
        const display = document.getElementById('active-timer');
        if (display) display.classList.add('hidden');
    }
};

// Start
State.init();
Render.home();
