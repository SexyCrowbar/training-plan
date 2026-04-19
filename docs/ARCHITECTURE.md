# Architecture: Protocol — Android App

## Stack

| Layer | Technology |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose + Material 3 |
| Architecture | MVVM (Model-View-ViewModel) |
| Database | Room (SQLite, on-device) |
| State | ViewModel + StateFlow |
| Navigation | Jetpack Compose Navigation |
| Charts | Vico (Compose-native charting library) |
| Reminders | AlarmManager + BroadcastReceiver |
| Settings | Jetpack DataStore (Preferences) |
| Build | Gradle (Kotlin DSL) |

All data is stored on-device in a Room database. No server, no network required.

---

## Project Structure

```
app/src/main/java/com/protocol/app/
│
├── data/
│   ├── db/
│   │   ├── AppDatabase.kt          ← Room database, singleton
│   │   ├── WorkoutLogDao.kt        ← queries: insert, getAll, getByDay, delete
│   │   ├── ExerciseSetDao.kt       ← queries: insert, getByLog
│   │   └── GtgLogDao.kt            ← queries: getTodayCount, upsert
│   ├── model/
│   │   ├── WorkoutLog.kt           ← @Entity: id, date, dayId, blockId, blockName
│   │   ├── ExerciseSet.kt          ← @Entity: id, logId, exerciseId, weight, reps, done
│   │   └── GtgLog.kt               ← @Entity: id, date, dayId, count
│   └── repository/
│       └── WorkoutRepository.kt    ← single source of truth; wraps DAOs
│
├── domain/
│   └── plan/
│       └── TrainingPlan.kt         ← the PLAN data as Kotlin data classes (no DB)
│
├── ui/
│   ├── theme/
│   │   ├── Color.kt                ← Iron (gold) + Body (cyan) color palettes
│   │   ├── Theme.kt                ← dynamic MaterialTheme switching by day type
│   │   └── Type.kt                 ← typography scale
│   ├── screens/
│   │   ├── train/
│   │   │   ├── TrainScreen.kt      ← home: day tabs, GTG counter, block cards
│   │   │   └── TrainViewModel.kt
│   │   ├── workout/
│   │   │   ├── WorkoutScreen.kt    ← active block: set rows, rest timer, finish
│   │   │   └── WorkoutViewModel.kt
│   │   ├── history/
│   │   │   ├── HistoryScreen.kt    ← logged sessions list, edit, delete
│   │   │   └── HistoryViewModel.kt
│   │   └── stats/
│   │       ├── StatsScreen.kt      ← 1RM progress chart per lift
│   │       └── StatsViewModel.kt
│   ├── screens/
│   │   └── settings/
│   │       ├── SettingsScreen.kt   ← reminders toggle, active hours picker, preview
│   │       └── SettingsViewModel.kt
│   └── components/
│       ├── BlockCard.kt            ← reusable block card (done / active states)
│       ├── GtgCounter.kt           ← big number + +/- buttons + dots
│       ├── SetRow.kt               ← checkbox + weight input + reps input
│       ├── RestTimer.kt            ← sticky countdown bar
│       ├── DayTabs.kt              ← horizontal scrollable day selector
│       └── BottomNav.kt            ← Train / Stats / History nav bar
│
├── notifications/
│   ├── GtgReminderReceiver.kt      ← BroadcastReceiver: fires notification, schedules next
│   ├── BootReceiver.kt             ← restores alarms after device reboot
│   ├── NotificationHelper.kt       ← builds and posts the GTG notification
│   └── ReminderScheduler.kt        ← schedules / cancels AlarmManager alarms
│
├── settings/
│   └── ReminderPreferences.kt      ← DataStore schema: enabled, startHour, endHour
│
└── MainActivity.kt                 ← single activity, hosts NavHost
```

---

## Data Model

### `WorkoutLog`
```kotlin
@Entity
data class WorkoutLog(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val date: Long,          // epoch millis
    val dayId: Int,          // 1–5
    val blockId: String,     // "power", "hypertrophy", etc.
    val blockName: String,
    val completedSets: Int
)
```

### `ExerciseSet`
```kotlin
@Entity
data class ExerciseSet(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val logId: Long,         // FK → WorkoutLog.id
    val exerciseId: String,  // "bp", "dips", etc.
    val setNumber: Int,
    val weightKg: Float?,
    val reps: Int?,
    val completed: Boolean
)
```

### `GtgLog`
```kotlin
@Entity(indices = [Index(value = ["date", "dayId"], unique = true)])
data class GtgLog(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val date: String,        // "2026-04-16"
    val dayId: Int,
    val count: Int
)
```

---

## MVVM Flow

```
Composable Screen
      ↕  collectAsState()
  ViewModel  (StateFlow<UiState>)
      ↕  suspend fun / Flow
  Repository
      ↕
  Room DAO  →  SQLite on device
```

Each screen has a matching `UiState` data class. ViewModels expose `StateFlow<UiState>` that screens observe with `collectAsState()`. Side effects (timer, haptics, screen lock) live in the ViewModel or a composable `LaunchedEffect`.

---

## Theming

Two Material 3 dark color schemes — switched dynamically based on `dayType`:

```kotlin
// Color.kt
val IronPrimary  = Color(0xFFF0C040)  // gold
val IronSurface  = Color(0xFF1A1F2E)
val IronBg       = Color(0xFF0F1117)

val BodyPrimary  = Color(0xFF22D3EE)  // cyan
val BodySurface  = Color(0xFF0D2535)
val BodyBg       = Color(0xFF081520)

// Theme.kt
@Composable
fun ProtocolTheme(dayType: DayType, content: @Composable () -> Unit) {
    val colors = if (dayType == DayType.IRON) ironDarkColors else bodyDarkColors
    MaterialTheme(colorScheme = colors, content = content)
}
```

---

## Navigation

Single `NavHost` in `MainActivity`. Three bottom nav destinations + a transient workout route + settings:

```
train  (start destination)
  └─ workout/{dayId}/{blockIndex}
stats
history
settings  (reachable via gear icon in Train top bar)
```

---

## Key Android Integrations

**Screen wake lock** — keeps screen on during an active workout block:
```kotlin
// WorkoutViewModel.kt
window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
```

**Haptic feedback** — on set completion and GTG tap:
```kotlin
view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
```

**Rest timer** — coroutine-based countdown in ViewModel:
```kotlin
viewModelScope.launch {
    repeat(seconds) { elapsed ->
        delay(1000)
        _uiState.update { it.copy(timerRemaining = seconds - elapsed - 1) }
    }
}
```

**1RM calculation** — Epley formula, same as current JS:
```kotlin
fun estimatedOneRepMax(weight: Float, reps: Int) = weight * (1 + reps / 30f)
```

---

## GTG Hourly Reminders

### How it works

`ReminderScheduler` uses `AlarmManager.setExactAndAllowWhileIdle()` to schedule a single alarm one hour ahead. When the alarm fires, `GtgReminderReceiver` decides what to do next:

1. Is the current time within the user's active window? → post notification + schedule next alarm for `now + 1 hour`
2. Is the current time past `endHour`? → schedule next alarm for tomorrow at `startHour`
3. Is today a rest day (Day 5)? → skip notification, still schedule next check

This "chain scheduling" approach is more reliable than `PeriodicWorkRequest` (which has a 15-minute minimum and drifts) and more battery-friendly than a constant background service.

```
[Alarm fires at 10:00]
       ↓
GtgReminderReceiver.onReceive()
       ↓
  within active hours?  ──yes──→  post notification
  & not rest day?                 schedule alarm for 11:00
       │
      no
       ↓
  past end hour?  ──yes──→  schedule alarm for tomorrow 09:00
       │
      no (before start hour)
       ↓
  schedule alarm for startHour today
```

### Settings stored in DataStore

```kotlin
// ReminderPreferences.kt
object ReminderPreferences {
    val ENABLED     = booleanPreferencesKey("reminders_enabled")   // default: true
    val START_HOUR  = intPreferencesKey("start_hour")              // default: 9  (09:00)
    val END_HOUR    = intPreferencesKey("end_hour")                 // default: 18 (18:00)
}
```

### Notification content

```kotlin
// NotificationHelper.kt
NotificationCompat.Builder(context, CHANNEL_ID)
    .setSmallIcon(R.drawable.ic_dumbbell)
    .setContentTitle("Grease the Groove")
    .setContentText("Time for a set of chin-ups. Keep it easy — no sweat.")
    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
    .setAutoCancel(true)
    .build()
```

### AndroidManifest additions

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Receivers -->
<receiver android:name=".notifications.GtgReminderReceiver"
          android:exported="false" />
<receiver android:name=".notifications.BootReceiver"
          android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

### Settings screen (SettingsScreen.kt)

Accessible via a gear icon `⚙` in the top bar of `TrainScreen`. Contains:

- **Reminders toggle** — enables/disables the entire system; cancels all pending alarms when turned off
- **Start hour picker** — hour of day when reminders begin (e.g. 09:00)
- **End hour picker** — hour of day when reminders stop (e.g. 18:00)
- **Preview row** — shows the list of hours that will fire given the current config: `09:00 · 10:00 · 11:00 · ... · 18:00`
- Any change immediately calls `ReminderScheduler.reschedule()` to apply the new window

### Gradle additions

```kotlin
// DataStore
implementation("androidx.datastore:datastore-preferences:1.1.1")
```

`AlarmManager` and `BroadcastReceiver` are part of the Android SDK — no extra dependency needed.

---

## Gradle Dependencies

```kotlin
// build.gradle.kts (app)
dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2025.04.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.0")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // Charts
    implementation("com.patrykandpatrick.vico:compose-m3:1.13.1")

    // DataStore (reminder settings persistence)
    implementation("androidx.datastore:datastore-preferences:1.1.1")
}
```

---

## What Carries Over from the Mockup

The `ui-mockup.html` is the direct design reference for all Compose screens. Every screen, component, and interaction maps 1:1:

| HTML mockup | Compose equivalent |
|---|---|
| Day tabs | `DayTabs.kt` — `LazyRow` of `FilterChip` |
| GTG counter card | `GtgCounter.kt` composable |
| Block cards | `BlockCard.kt` composable |
| Set rows (checkbox + inputs) | `SetRow.kt` composable |
| Sticky timer bar | `RestTimer.kt` — `Box` with `Modifier.zIndex` |
| Bottom nav | `BottomNav.kt` — `NavigationBar` |
| Iron / Body themes | `ProtocolTheme` with dynamic `colorScheme` |

---

## What Changes vs the Web Architecture

| Web (previous) | Android (current) |
|---|---|
| React + Vite | Jetpack Compose |
| Tailwind CSS | Material 3 + custom ColorScheme |
| Express server | No server — on-device only |
| JSON file storage | Room SQLite database |
| Browser localStorage | Room DAO + Repository |
| `node server.js` to run | Install APK on phone |
| LAN access from phone | App runs natively on phone |
