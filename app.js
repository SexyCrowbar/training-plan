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
    activeSession: null, // If user is currently workout out
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

    saveLog(log) {
        this.history.unshift(log);
        localStorage.setItem('wp_history', JSON.stringify(this.history));
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
                    ${!isRest && dayData.type === 'iron' ?
                `<button onclick="PlateCalc.open()" class="p-3 bg-white/10 rounded-full text-primary border border-white/10 shadow-sm active:scale-95 transition-transform" aria-label="Plate Calculator">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 8v8"/><path d="M8 12h8"/></svg>
                        </button>`
                : ''}
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

            <!-- PLATE CALC MODAL -->
            <div id="plate-modal" class="modal-overlay">
                <div class="card w-full max-w-sm relative" onclick="event.stopPropagation()">
                    <button onclick="PlateCalc.close()" class="absolute top-4 right-4 text-secondary p-2">✕</button>
                    <h3 class="text-primary mb-4">Plate Calculator</h3>
                    
                    <div class="mb-4">
                        <label class="text-xs text-secondary uppercase font-bold">Target Weight (kg)</label>
                        <div class="flex gap-2 mt-2">
                            <input type="number" id="calc-input" placeholder="e.g. 100" class="text-2xl font-bold text-center" oninput="PlateCalc.calculate()">
                        </div>
                    </div>

                    <div id="plate-visual" class="plate-stack">
                        <span class="text-xs text-secondary">Enter weight...</span>
                    </div>
                    
                    <div class="text-center text-sm text-secondary font-mono" id="plate-text">Per Side: -</div>
                </div>
            </div>
        `;

        app.innerHTML = html;
        this.updateNav('train');
    },

    workout() {
        const dayData = PLAN[State.currentDay];

        let html = `
            <div class="fade-in">
                <div class="flex items-center justify-between mb-6">
                    <div class="flex items-center">
                        <button onclick="Render.home()" class="mr-4 text-secondary"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m15 18-6-6 6-6"/></svg></button>
                        <h2>${dayData.name}</h2>
                    </div>
                    ${dayData.type === 'iron' ?
                `<button onclick="PlateCalc.open()" class="text-secondary p-2"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 8v8"/><path d="M8 12h8"/></svg></button>`
                : ''}
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
                            ${Array(ex.sets).fill(0).map((_, setIdx) => `
                                <div class="set-grid">
                                    <div class="check-circle" id="check-${exIdx}-${setIdx}" onclick="Session.toggleSet(${exIdx}, ${setIdx}, ${ex.rest})">
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" class="opacity-0 transition-opacity"><polyline points="20 6 9 17 4 12"/></svg>
                                    </div>
                                    <input type="number" placeholder="kg" class="bg-black/20 text-center text-sm p-3">
                                    <input type="number" placeholder="Reps" value="${ex.reps.includes('-') ? '' : ex.reps}" class="bg-black/20 text-center text-sm p-3">
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `).join('')}

                <div class="pb-24">
                    <button onclick="Session.finish()" class="btn btn-primary">Finish Workout</button>
                </div>

                <!-- RE-ADD MODAL TO WORKOUT VIEW TOO -->
                 <div id="plate-modal" class="modal-overlay">
                    <div class="card w-full max-w-sm relative" onclick="event.stopPropagation()">
                        <button onclick="PlateCalc.close()" class="absolute top-4 right-4 text-secondary p-2">✕</button>
                        <h3 class="text-primary mb-4">Plate Calculator</h3>
                        
                        <div class="mb-4">
                            <label class="text-xs text-secondary uppercase font-bold">Target Weight (kg)</label>
                            <div class="flex gap-2 mt-2">
                                <input type="number" id="calc-input" placeholder="e.g. 100" class="text-2xl font-bold text-center" oninput="PlateCalc.calculate()">
                            </div>
                        </div>

                        <div id="plate-visual" class="plate-stack">
                            <span class="text-xs text-secondary">Enter weight...</span>
                        </div>
                        
                        <div class="text-center text-sm text-secondary font-mono" id="plate-text">Per Side: -</div>
                    </div>
                </div>
            </div>
        `;

        app.innerHTML = html;
        window.scrollTo(0, 0);
    },

    history() {
        const hist = State.history;
        let html = `
            <div class="fade-in">
                <h1 class="mb-6">History</h1>
                ${hist.length === 0 ? `<p class="text-secondary text-center">No workouts logged yet.</p>` : ''}
                ${hist.map(entry => `
                    <div class="card">
                        <div class="flex justify-between mb-2">
                            <span class="font-bold text-lg">${entry.name}</span>
                            <span class="text-xs text-secondary">${new Date(entry.date).toLocaleDateString()}</span>
                        </div>
                        <div class="text-sm text-secondary">
                            Completed ${entry.completedSets} sets
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
        app.innerHTML = html;
        this.updateNav('history');
    },

    updateNav(activeTab) {
        document.querySelectorAll('.nav-item').forEach(el => {
            el.classList.remove('active');
            if (el.dataset.tab === activeTab) el.classList.add('active');
        });
    }
};

/**
 * LOGIC MODULES
 */

const PlateCalc = {
    plates: [25, 20, 15, 10, 5, 2.5, 1.25],

    open() {
        document.getElementById('plate-modal').classList.add('open');
        setTimeout(() => document.getElementById('calc-input').focus(), 100);
    },

    close() {
        document.getElementById('plate-modal').classList.remove('open');
    },

    calculate() {
        const val = parseFloat(document.getElementById('calc-input').value);
        const visual = document.getElementById('plate-visual');
        const text = document.getElementById('plate-text');

        if (!val || val < 20) {
            visual.innerHTML = '<span class="text-xs text-secondary">Enter >20kg</span>';
            text.innerText = "Per Side: -";
            return;
        }

        let weightPerSide = (val - 20) / 2;
        let remainder = weightPerSide;
        let stack = [];

        this.plates.forEach(p => {
            while (remainder >= p) {
                stack.push(p);
                remainder -= p;
            }
        });

        // Render Stack
        visual.innerHTML = stack.map(p =>
            `<div class="plate" data-weight="${p}" title="${p}kg"></div>`
        ).join('');

        // Render Text
        text.innerHTML = `Per Side: <span class="text-primary font-bold">${weightPerSide}kg</span><br><span class="text-xs text-secondary">[${stack.join(', ')}]</span>`;
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

    finish() {
        if (!confirm('Finish and mark day as complete?')) return;

        const log = {
            date: new Date().toISOString(),
            name: PLAN[State.currentDay].name,
            completedSets: document.querySelectorAll('.check-circle.checked').length
        };

        State.saveLog(log);
        State.nextDay();
        Timer.stop();
        // Trigger longer vibration on finish
        Utils.vibrate([100, 50, 100]);
        Render.home();
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
