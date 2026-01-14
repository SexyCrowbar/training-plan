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
 * RENDER ENGINE
 */
const Render = {
    home() {
        const dayData = PLAN[State.currentDay];
        const isRest = dayData.type === 'rest';

        let html = `
            <header class="fade-in">
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
                    ${!isRest ? `<div class="p-3 rounded-full bg-white/5"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg></div>` : ''}
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

    workout() {
        const dayData = PLAN[State.currentDay];
        
        let html = `
            <div class="fade-in">
                <div class="flex items-center mb-6">
                    <button onclick="Render.home()" class="mr-4 text-secondary"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m15 18-6-6 6-6"/></svg></button>
                    <h2>${dayData.name}</h2>
                </div>

                <div id="active-timer" class="hidden sticky top-4 z-50 mb-4">
                    <div class="card p-3 flex justify-between items-center bg-slate-900 border-primary shadow-[0_0_15px_rgba(0,0,0,0.5)]">
                        <span class="text-sm text-secondary">Rest Timer</span>
                        <span class="font-mono text-xl font-bold text-primary" id="timer-display">00:00</span>
                        <button onclick="Timer.stop()" class="text-xs uppercase font-bold text-red-400">Stop</button>
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
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" class="opacity-0 transition-opacity"><polyline points="20 6 9 17 4 12"/></svg>
                                    </div>
                                    <input type="number" placeholder="kg" class="bg-black/20 text-center text-sm">
                                    <input type="number" placeholder="Reps" value="${ex.reps.includes('-') ? '' : ex.reps}" class="bg-black/20 text-center text-sm">
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `).join('')}

                <div class="pb-24">
                    <button onclick="Session.finish()" class="btn btn-primary">Finish Workout</button>
                </div>
            </div>
        `;

        app.innerHTML = html;
        window.scrollTo(0, 0);
    },

    history() {
        const hist = State.history;
        let html = `
            <h1 class="mb-6 fade-in">History</h1>
            <div class="fade-in">
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
            if(el.dataset.tab === activeTab) el.classList.add('active');
        });
    }
};

/**
 * SESSION LOGIC
 */
const Session = {
    toggleSet(exIdx, setIdx, restTime) {
        const el = document.getElementById(`check-${exIdx}-${setIdx}`);
        const isChecked = el.classList.contains('checked');
        
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
        if(!confirm('Finish and mark day as complete?')) return;
        
        const log = {
            date: new Date().toISOString(),
            name: PLAN[State.currentDay].name,
            completedSets: document.querySelectorAll('.check-circle.checked').length
        };
        
        State.saveLog(log);
        State.nextDay();
        Timer.stop();
        Render.home();
    }
};

/**
 * TIMER LOGIC
 */
const Timer = {
    interval: null,
    endTime: null,

    start(seconds) {
        this.stop();
        this.endTime = Date.now() + (seconds * 1000);
        
        const display = document.getElementById('active-timer');
        if(display) display.classList.remove('hidden');
        
        this.tick();
        this.interval = setInterval(() => this.tick(), 1000);
    },

    tick() {
        const left = Math.ceil((this.endTime - Date.now()) / 1000);
        if (left <= 0) {
            this.stop();
            // Could play sound here
            return;
        }
        
        const m = Math.floor(left / 60).toString().padStart(2, '0');
        const s = (left % 60).toString().padStart(2, '0');
        
        const el = document.getElementById('timer-display');
        if(el) el.innerText = `${m}:${s}`;
    },

    stop() {
        if (this.interval) clearInterval(this.interval);
        const display = document.getElementById('active-timer');
        if(display) display.classList.add('hidden');
    }
};

// Start
State.init();
Render.home();
