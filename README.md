# Freestyler

A modern full-stack freestyle music creation app with a SwiftUI iOS frontend and Node.js/Express/MongoDB backend.

## Features
- 🎵 **Beat Selection**: Browse, filter, and select beats to freestyle over.
- 🎤 **Recording**: Record your vocals in sync with the beat, with countdown and metronome support.
- 🥁 **Metronome**: Adjustable tempo (BPM), volume, and time signature. Plays independently of beat playback.
- 📂 **Session Management**: Save, list, rename, and delete your freestyle sessions.
- 👤 **User Authentication**: Secure signup/login with JWT, auto-login, and logout.
- 🖼️ **Profile Image**: Upload and display your profile image.
- ⚙️ **Settings**: Dark mode, metronome, and countdown customization.
- 💎 **Modern UI/UX**: Glassmorphism, gradients, and smooth controls for a premium feel.

## Screenshots
<!-- Add screenshots here -->

## Getting Started

### Backend Setup (Node.js/Express)
1. `cd backend`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure MongoDB connection in `backend/config/db.js`.
4. Start the backend server:
   ```bash
   node app.js
   ```
5. (Optional) Use [ngrok](https://ngrok.com/) to expose your backend for iOS development:
   ```bash
   ngrok http 5000
   ```

### iOS App Setup (SwiftUI)
1. Open `Freestyler.xcodeproj` in Xcode.
2. Ensure the backend URL in `BeatSelectorView.swift` matches your ngrok/public backend URL.
3. Add `metronome.mp3` to the Xcode project (already included in `Resources`).
4. Build and run on a simulator or device (iOS 16+ recommended).

## Usage Notes
- **Profile Image**: Tap your profile image in Settings to upload a new one.
- **Metronome**: Configure BPM, volume, and time signature in Settings. Metronome works independently of beat playback.
- **Sessions**: All recordings are saved as sessions and can be managed from the Sessions screen.
- **Authentication**: JWT is securely stored; auto-login is supported.
- **Audio**: Uses AVPlayer for remote beats, AVAudioPlayer for local files and metronome.

## Backend Endpoints
- `/api/auth/signup` — User registration
- `/api/auth/login` — User login
- `/api/auth/me` — Fetch user profile
- `/api/auth/profile/image` — Upload profile image
- `/api/beats` — List beats
- `/api/beats/upload` — Upload new beat (admin)

## License
MIT 