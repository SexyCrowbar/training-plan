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
        name: 'Day 1: Horizontal Push',
        tag: 'Arms & Shoulders',
        exercises: [
            { id: 'warmup', name: 'Desk-to-Barbell Warmup', sets: 1, reps: '3m', rest: 0, note: 'Block 0: Arm circles, twists, deep squats.' },
            { id: 'bp', name: 'Barbell Bench Press', sets: 3, reps: '3-5', rest: 180, note: 'Block 1 (Power): 60-70% max effort.' },
            { id: 'dips', name: 'Parallel Bar Dips', sets: 3, reps: 'AMRAP', rest: 60, note: 'Block 2 (Hypertrophy): Superset 1.' },
            { id: 'skullcrushers', name: 'EZ-Bar Skullcrushers', sets: 3, reps: '8-12', rest: 90, note: 'Block 2: Superset 2.' },
            { id: 'kb_swing', name: 'KB Swings (16kg)', sets: 1, reps: '10m', rest: 0, note: 'Block 3 (Endurance): EMOM 15 reps/min.' }
        ]
    },
    2: {
        type: 'body',
        name: 'Day 2: Vertical Pull',
        tag: 'Bicep Focus',
        exercises: [
            { id: 'warmup', name: 'Desk-to-Barbell Warmup', sets: 1, reps: '3m', rest: 0, note: 'Block 0: Dead hangs, scap pull-ups.' },
            { id: 'pullup_weighted', name: 'Weighted Pull-Ups', sets: 3, reps: '3-5', rest: 180, note: 'Block 1 (Power): Use dip belt.' },
            { id: 'ez_curl', name: 'EZ-Bar Curls', sets: 3, reps: '8-12', rest: 60, note: 'Block 2 (Hypertrophy): Superset 1.' },
            { id: 'facepull', name: 'Ring Face Pulls', sets: 3, reps: '12-15', rest: 90, note: 'Block 2: Superset 2 (Rear delts).' },
            { id: 'amrap_circuit', name: 'Bodyweight AMRAP', sets: 1, reps: '10m', rest: 0, note: 'Block 3 (Endurance): 5 PU, 10 Push, 15 Squat.' }
        ]
    },
    3: {
        type: 'iron',
        name: 'Day 3: Heavy Legs',
        tag: 'Core Stability',
        exercises: [
            { id: 'warmup', name: 'Desk-to-Barbell Warmup', sets: 1, reps: '3m', rest: 0, note: 'Block 0: Hip openers, Cossack squats.' },
            { id: 'sq_zerch', name: 'Barbell Zercher Squats', sets: 3, reps: '3-5', rest: 180, note: 'Block 1 (Power): Core power & leg drive.' },
            { id: 'ohp', name: 'Barbell Overhead Press', sets: 3, reps: '8-10', rest: 90, note: 'Block 2 (Hypertrophy): Strict standing.' },
            { id: 'ez_rev_curl', name: 'EZ-Bar Reverse Curls', sets: 3, reps: '10-12', rest: 90, note: 'Block 2 (Hypertrophy): Target brachialis.' },
            { id: 'goblet_squat', name: 'KB Goblet Squats', sets: 3, reps: '15-20', rest: 0, note: 'Block 3 (Endurance): Superset w/ Planks.' },
            { id: 'plank', name: 'Planks', sets: 3, reps: '60s', rest: 60, note: 'Block 3: Superset.' }
        ]
    },
    4: {
        type: 'body',
        name: 'Day 4: Arm Annihilation',
        tag: 'Functional Flow',
        exercises: [
            { id: 'warmup', name: 'Desk-to-Barbell Warmup', sets: 1, reps: '3m', rest: 0, note: 'Block 0: Wrist circles, shoulder dislocates.' },
            { id: 'cg_bench', name: 'Close-Grip Bench', sets: 3, reps: '3-5', rest: 180, note: 'Block 1 (Power): Tricep focused.' },
            { id: 'ring_dips', name: 'Gymnastic Ring Dips', sets: 3, reps: 'AMRAP', rest: 90, note: 'Block 2 (Hypertrophy): Use parallel bars if needed.' },
            { id: 'kb_upright', name: 'KB Upright Rows', sets: 3, reps: '10-12', rest: 90, note: 'Block 2 (Hypertrophy).' },
            { id: 'unilateral_press', name: 'KB Clean & Press', sets: 2, reps: '5m', rest: 0, note: 'Block 3 (Endurance): 5m Right, then 5m Left.' }
        ]
    },
    5: {
        type: 'rest',
        name: 'Full Rest',
        tag: 'Recovery',
        exercises: []
    }
};

const WEEKLY_MAP = ['1', '2', '3', '4', 'R'];

/**
 * STATE MANAGEMENT
 */
const State = {
    currentDay: 1, // 1-7
    activeSession: null,
    editIndex: null, // Index of log being edited, or null
    history: [],

    init() {
        const storedHistory = localStorage.getItem('wp_history');
        if (storedHistory) this.history = JSON.parse(storedHistory);

        const daysCount = Object.keys(PLAN).length;

        if (this.history.length > 0) {
            const lastLog = this.history[0];
            const today = new Date().toDateString();
            if (new Date(lastLog.date).toDateString() === today) {
                this.currentDay = lastLog.dayId || 1;
            } else {
                this.currentDay = ((lastLog.dayId || 1) % daysCount) + 1;
            }
        } else {
            this.currentDay = 1;
        }

        if (this.currentDay < 1 || this.currentDay > daysCount) this.currentDay = 1;

        this.updateTheme();
    },

    setDay(day) {
        // Debug/Manual override only
        this.currentDay = day;
        this.updateTheme();
        Render.home();
    },

    nextDay() {
        // No-op in auto mode
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
        Modal.confirm('Delete History?', 'This cannot be undone.', () => {
            this.history.splice(index, 1);
            localStorage.setItem('wp_history', JSON.stringify(this.history));
            Render.history();
        });
    },

    isTodayComplete() {
        if (this.history.length === 0) return false;
        const lastLog = this.history[0];
        const today = new Date().toDateString();
        return new Date(lastLog.date).toDateString() === today;
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
        // Advanced: Check history for this week
        // Find log where dayId == dayIdx AND date is within this week?
        // Simpler: Just rely on Current Day

        if (dayIdx === State.currentDay) {
            return State.isTodayComplete() ? (PLAN[dayIdx].type === 'iron' ? 'done-iron' : 'done-body') : 'current';
        }

        // Past days in the week... complicated without exact week boundaries.
        // We'll stick to: If < currentDay, assume done? No, that was the old way.
        // New way: We just highlight Today. The heatmap is becoming less useful without calendar logic.
        // Let's at least highlight Today properly.

        return dayIdx === State.currentDay ? 'current' : '';
    }
};

/**
 * RENDER ENGINE
 */
const Render = {
    home() {
        ScreenLock.release();
        State.editIndex = null; // Clear edit state on home
        const dayData = PLAN[State.currentDay];
        const isRest = dayData.type === 'rest';
        const isComplete = State.isTodayComplete();

        // Generate Heatmap
        let heatmapHTML = `<div class="heatmap-container fade-in">`;
        const daysCount = Object.keys(PLAN).length;
        for (let i = 1; i <= daysCount; i++) {
            let statusClass = '';
            if (i === State.currentDay) {
                statusClass = isComplete ? (PLAN[i].type === 'iron' ? 'done-iron' : 'done-body') : 'current';
            }
            const letter = WEEKLY_MAP[i - 1];
            heatmapHTML += `<div class="heatmap-bubble ${statusClass}">${letter}</div>`;
        }
        heatmapHTML += `</div>`;

        let content = '';

        if (isComplete) {
            content = `
                <div class="card fade-in slide-up text-center py-12">
                     <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-green-500/20 text-green-400 mb-6">
                        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                     </div>
                     <h2 class="text-primary mb-2">Session Complete</h2>
                     <p class="text-secondary">Good work today. Recover and prepare for tomorrow.</p>
                </div>
                
                <div class="mt-8 fade-in">
                    <h3 class="text-secondary text-sm mb-4">Post-Workout</h3>
                    <div class="card p-4">
                        <ul class="text-sm list-disc pl-4 space-y-2 text-secondary">
                            <li>Hydrate immediately (500ml+).</li>
                            <li>Protein within 2 hours.</li>
                            <li>Sleep 7-8 hours tonight.</li>
                        </ul>
                    </div>
                </div>
            `;
        } else {
            content = `
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
                    `<button class="btn btn-ghost cursor-default">Rest Day</button>` :
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
        }

        let html = `
            <header class="fade-in">
                ${heatmapHTML}
                <div class="flex justify-between items-center mb-6">
                    <div>
                        <div class="badge ${dayData.type === 'iron' ? 'active' : ''} mb-2 flex justify-between items-center w-36 cursor-pointer" onclick="State.setDay(State.currentDay === ${daysCount} ? 1 : State.currentDay + 1)" title="Skip to next day">
                             <span>Cycle Day ${State.currentDay}</span>
                             <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m9 18 6-6-6-6"/></svg>
                        </div>
                        <h1>${isRest ? 'Recovery Mode' : 'Ready to Train?'}</h1>
                    </div>
                </div>
            </header>
            ${content}
        `;

        app.innerHTML = html;
        this.updateNav('train');
    },

    workout(prefillSets = null) {
        ScreenLock.request();
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
            const statsBtn = document.createElement('button');
            statsBtn.className = 'nav-item';
            statsBtn.dataset.tab = 'stats';
            statsBtn.onclick = () => Render.stats();
            statsBtn.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/></svg><span>Stats</span>`;
            const historyBtn = nav.querySelector('[data-tab="history"]');
            nav.insertBefore(statsBtn, historyBtn);
        }

        document.querySelectorAll('.nav-item').forEach(el => {
            el.classList.remove('active');
            if (el.dataset.tab === activeTab) el.classList.add('active');
        });
    },

    celebratePR(records) {
        // Create full screen overlay
        const rec = records[0]; // Just show the first one if multiple for simplicity/focus

        let html = `
            <div class="pr-overlay" onclick="Render.home()">
                <div class="pr-content">
                    <span class="pr-badge">NEW RECORD</span>
                    <h1 class="pr-title">${rec.label}</h1>
                    <div class="pr-value">${rec.value} KG</div>
                    <p class="text-secondary text-sm mt-4">Estimated 1 Rep Max</p>
                    <button class="btn btn-primary mt-8 w-48 mx-auto">AWESOME</button>
                </div>
            </div>
        `;

        // Add minimal confetti logic
        for (let i = 0; i < 30; i++) {
            const left = Math.random() * 100;
            const delay = Math.random() * 2;
            const dur = 2 + Math.random() * 3;
            html += `<div class="confetti" style="left:${left}%; animation-delay:${delay}s; animation-duration:${dur}s"></div>`;
        }

        app.innerHTML += html; // Append to top
        Utils.vibrate([100, 100, 100, 100, 200]);
    }
};

/**
 * LOGIC MODULES
 */

const Stats = {
    // Return array of { date, value }
    getProgress(key, mode = 'load') {
        const history = State.history;
        const data = [];

        // Exercise ID mapping
        const map = {
            'sq': ['sq_zerch', 'sq_zerch_vol'],
            'bp': ['bp', 'bp_vol', 'cg_bench'],
            'dl': ['dl_zerch'],
            'ohp': ['ohp'],
            'pullup': ['pullup', 'chins', 'pullup_weighted'],
            'dips': ['dips', 'ring_dips'],
            'pushups': ['pushups']
        };
        const targets = map[key];
        if (!targets) return [];

        // Process history chronological (must reverse first as history is new->old)
        [...history].reverse().forEach(log => {
            if (!log.exercises) return;

            let maxVal = 0;

            log.exercises.forEach(ex => {
                if (targets.includes(ex.id)) {
                    if (mode === 'load') {
                        // Calculate 1RM
                        const w = parseFloat(ex.weight) || 0;
                        const r = parseFloat(ex.reps) || 0;
                        if (w > 0 && r > 0) {
                            const e1rm = w * (1 + r / 30);
                            if (e1rm > maxVal) maxVal = e1rm;
                        }
                    } else if (mode === 'reps') {
                        // Max Reps
                        const r = parseFloat(ex.reps) || 0;
                        if (r > maxVal) maxVal = r;
                    }
                }
            });

            if (maxVal > 0) {
                data.push({ date: log.date, value: maxVal });
            }
        });

        return data;
    },

    // Identify category for exercise ID
    getCategory(exId) {
        if (['sq_zerch', 'sq_zerch_vol'].includes(exId)) return 'sq';
        if (['bp', 'bp_vol', 'cg_bench'].includes(exId)) return 'bp';
        if (['dl_zerch'].includes(exId)) return 'dl';
        if (['ohp'].includes(exId)) return 'ohp';
        if (['pullup', 'chins', 'pullup_weighted'].includes(exId)) return 'pullup';
        if (['dips', 'ring_dips'].includes(exId)) return 'dips';
        if (['pushups'].includes(exId)) return 'pushups';
        return null;
    },

    getDisplayMode(catKey) {
        if (['pullup', 'dips', 'pushups'].includes(catKey)) return 'reps';
        return 'load';
    },

    // Get max previous record 
    getPersonalRecord(catKey) {
        const mode = this.getDisplayMode(catKey);
        const data = this.getProgress(catKey, mode);
        if (data.length === 0) return 0;
        return Math.max(...data.map(d => d.value));
    }
};

const Modal = {
    show({ title, message, confirmText = 'Confirm', cancelText = 'Cancel', onConfirm, isAlert = false }) {
        const existing = document.querySelector('.modal-backdrop');
        if (existing) existing.remove();

        const backdrop = document.createElement('div');
        backdrop.className = 'modal-backdrop';
        backdrop.onclick = (e) => {
            if (e.target === backdrop && !isAlert) this.close();
        };

        const buttonsHTML = isAlert
            ? `<button class="modal-btn confirm full" onclick="Modal.close()">${confirmText}</button>`
            : `
                <button class="modal-btn cancel" onclick="Modal.close()">${cancelText}</button>
                <button class="modal-btn confirm" id="modal-confirm">${confirmText}</button>
              `;

        backdrop.innerHTML = `
            <div class="modal-card">
                <h3 class="modal-title">${title}</h3>
                <p class="modal-message">${message}</p>
                <div class="modal-actions">
                    ${buttonsHTML}
                </div>
            </div>
        `;

        app.appendChild(backdrop);

        if (!isAlert) {
            document.getElementById('modal-confirm').onclick = () => {
                onConfirm();
                this.close();
            };
        }

        Utils.vibrate(20);
    },

    confirm(title, message, onConfirm) {
        this.show({ title, message, onConfirm });
    },

    alert(title, message) {
        this.show({ title, message, confirmText: 'Got it', isAlert: true });
    },

    close() {
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) {
            backdrop.style.opacity = '0';
            setTimeout(() => backdrop.remove(), 200);
        }
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
            Modal.alert('Legacy Log', 'This log cannot be edited (Legacy format).');
            return;
        }

        State.editIndex = index;
        State.currentDay = log.dayId;
        State.updateTheme();
        Render.workout(log.completedSets);
    },

    finish() {
        const isEditing = State.editIndex !== null;

        Modal.confirm(
            isEditing ? 'Update Log?' : 'Finish Workout?',
            isEditing ? 'Update this entry with new data?' : 'Log this session and mark today as complete?',
            () => {
                // Scrape Data
                const dayData = PLAN[State.currentDay];
                const capturedExercises = [];
                let totalSets = 0;
                const newPRs = [];

                dayData.exercises.forEach((ex, exIdx) => {
                    const catKey = Stats.getCategory(ex.id);
                    let sessionMax1RM = 0;

                    for (let setIdx = 0; setIdx < ex.sets; setIdx++) {
                        const checkEl = document.getElementById(`check-${exIdx}-${setIdx}`);
                        const isChecked = checkEl.classList.contains('checked');

                        if (isChecked) totalSets++;

                        const parent = checkEl.parentElement;
                        const inputs = parent.querySelectorAll('input');
                        const weight = parseFloat(inputs[0].value) || 0;
                        const reps = parseFloat(inputs[1].value) || 0;

                        if (isChecked || weight || reps) {
                            capturedExercises.push({
                                id: ex.id,
                                set: setIdx + 1,
                                weight: inputs[0].value,
                                reps: inputs[1].value,
                                completed: isChecked
                            });

                            // PR Check Logic
                            const mode = Stats.getDisplayMode(catKey);
                            if (catKey) {
                                if (mode === 'load' && weight > 0 && reps > 0) {
                                    const e1rm = weight * (1 + reps / 30);
                                    if (e1rm > sessionMax1RM) sessionMax1RM = e1rm;
                                } else if (mode === 'reps' && reps > 0) {
                                    if (reps > sessionMax1RM) sessionMax1RM = reps;
                                }
                            }
                        }
                    }

                    // Did we beat previous best?
                    if (catKey && sessionMax1RM > 0) {
                        const currentRecord = Stats.getPersonalRecord(catKey);
                        const minThreshold = Stats.getDisplayMode(catKey) === 'load' ? 20 : 5;

                        if (sessionMax1RM > currentRecord && sessionMax1RM > minThreshold) {
                            if (!newPRs.find(p => p.cat === catKey)) {
                                const labels = {
                                    'sq': 'Squat', 'bp': 'Bench', 'dl': 'Deadlift', 'ohp': 'Press',
                                    'pullup': 'Pull-Up', 'dips': 'Dips', 'pushups': 'Push-Ups'
                                };
                                newPRs.push({ cat: catKey, label: labels[catKey], value: Math.round(sessionMax1RM) });
                            }
                        }
                    }
                });

                const log = {
                    date: new Date().toISOString(),
                    dayId: State.currentDay,
                    name: dayData.name,
                    completedSets: totalSets,
                    exercises: capturedExercises
                };

                if (isEditing) {
                    const originalDate = State.history[State.editIndex].date;
                    log.date = originalDate;
                    State.saveLog(log, State.editIndex);
                    State.editIndex = null;
                    Render.history();
                } else {
                    State.saveLog(log);

                    if (newPRs.length > 0) {
                        Render.celebratePR(newPRs);
                    } else {
                        Render.home();
                    }
                }

                Timer.stop();
                Utils.vibrate([100, 50, 100]);
                ScreenLock.release();
            }
        );
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

const ScreenLock = {
    wakeLock: null,

    async request() {
        if ('wakeLock' in navigator) {
            try {
                this.wakeLock = await navigator.wakeLock.request('screen');
                this.wakeLock.addEventListener('release', () => {
                    console.log('Wake Lock released');
                });
            } catch (err) {
                console.error(`${err.name}, ${err.message}`);
            }
        }
    },

    release() {
        if (this.wakeLock !== null) {
            this.wakeLock.release()
                .then(() => {
                    this.wakeLock = null;
                });
        }
    }
};

// Handle visibility change to re-acquire lock
document.addEventListener('visibilitychange', async () => {
    if (ScreenLock.wakeLock !== null && document.visibilityState === 'visible') {
        await ScreenLock.request();
    }
});

// Start
State.init();
Render.home();
