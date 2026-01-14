# Protocol Training App

A premium, localized training companion for the Iron/Body split protocol.

## How to Deploy to GitHub Pages

1.  **Push to GitHub**:
    - Commit `index.html`, `style.css`, and `app.js` to your repository.
    
2.  **Enable Pages**:
    - Go to your Repository Settings > **Pages**.
    - under **Build and deployment**, select **Source** -> **Deploy from a branch**.
    - Select `main` (or `master`) branch and `/ (root)` folder.
    - Click **Save**.

3.  **Visit App**:
    - Wait about 1-2 minutes.
    - Your app will be live at `https://<username>.github.io/<repo-name>/`.

## Features

- **Dual Theme System**: Automatically switches between "Iron" (Gold/Slate) and "Body" (Cyan) themes based on the day.
- **Smart Timers**: Auto-starts rest timers appropriate for the session type (3-5m for Strength, 60s for Hypertrophy).
- **Offline Capable**: Uses LocalStorage to save your progress and history on your device.
