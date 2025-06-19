import SwiftUI
import AVFoundation

struct SessionPlayerView: View {
    let session: SessionModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Playback States
    @State private var beatPlayer: AVAudioPlayer?
    @State private var avPlayer: AVPlayer?
    @State private var avPlayerObserver: Any?
    @State private var isRemote: Bool = false
    @State private var vocalPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0.0
    @State private var totalDuration: TimeInterval = 0.0

    // MARK: - Sliders & Seeking
    @State private var beatProgressSliderValue: Double = 0.0
    @State private var isSeeking = false
    @State private var timer: Timer?

    // MARK: - Enhanced Recording States
    @StateObject private var recordingManager = RecordingManager()
    @ObservedObject private var settings = SettingsModel.shared
    @State private var showCountdown = false
    @State private var showDeleteAlert = false
    @State private var showSaveDialog = false
    @State private var recordingName = ""
    @State private var isRecordingInitiated = false
    @State private var recordingStartTime: TimeInterval = 0.0
    @State private var recordingPausedTime: TimeInterval = 0.0
    @State private var isRecordingPaused = false
    @State private var playBeatOnly = false // New state for beat-only playback
    @State private var hasUnsavedRecording = false
    @State private var showRecordingOptions = false

    // MARK: - Playback Control Constants
    let seekInterval: TimeInterval = 10.0

    // MARK: - Unified Accent Colors/Gradients
    let primaryAccentGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
    let secondaryAccentGradient = LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing)
    let successAccentGradient = LinearGradient(colors: [Color.green, Color.mint], startPoint: .leading, endPoint: .trailing)
    let warningAccentGradient = LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing)

    // MARK: - Metronome
    @StateObject private var metronomeManager = MetronomeManager()
    @State private var metronomeOn = false
    
    var body: some View {
        ZStack {
            // Modern glassy gradient background
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.4), Color.black.opacity(0.2)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                // Close Button (top right)
                HStack {
                    Spacer()
                    Button(action: {
                        if hasUnsavedRecording {
                            showSaveDialog = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.secondary)
                            .shadow(radius: 6)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)

                // MARK: - Player Card Background
                VStack(spacing: 28) {
                    // Session Info
                    VStack(spacing: 8) {
            Text(session.displayName ?? session.beatName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.primary, .purple], startPoint: .leading, endPoint: .trailing))
                            .multilineTextAlignment(.center)
                        Text("\(session.scale) | \(session.bpm) BPM")
                            .font(.headline)
                .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)

                    // MARK: - Enhanced Audio Control Options
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Toggle(isOn: $metronomeOn) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "metronome")
                                            .foregroundColor(.blue)
                                        Text("Metronome")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .onChange(of: metronomeOn) { value in
                                    if value {
                                        metronomeManager.start(bpm: session.bpm)
                                    } else {
                                        metronomeManager.stop()
                                    }
                                }
                                Spacer()
                            }
                            HStack {
                                Toggle(isOn: $playBeatOnly) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.orange)
                                        Text("Beat Only")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 8)
                    }

                    // MARK: - Beat Slider
                    VStack(spacing: 8) {
                        SliderSection(
                            title: "Beat",
                            progress: $beatProgressSliderValue,
                            totalDuration: totalDuration,
                            accentColor: .blue,
                            isSeeking: $isSeeking
                        ) { value in
                            funcseek(to: value)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    // MARK: - Vocal Waveform Visualization
                    VStack(spacing: 8) {
                        HStack {
                            Text("Vocal")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            // Recording Status Indicator
                            if recordingManager.isRecording {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: .red.opacity(0.7), radius: 8, x: 0, y: 0)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                        )
                                        .scaleEffect(isPlaying ? 1.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isPlaying)
                                    Text("REC")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                            } else if isRecordingPaused {
                                HStack(spacing: 4) {
                                    Image(systemName: "pause.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("PAUSED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        WaveformView(
                            progress: currentTime / totalDuration,
                            accentGradient: recordingManager.isRecording ? secondaryAccentGradient : primaryAccentGradient,
                            isPlaying: isPlaying && !playBeatOnly
                        )
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .cornerRadius(14)
                        .opacity(playBeatOnly ? 0.5 : 1.0)
                        .padding(.vertical, 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    guard !playBeatOnly else { return }
                                    isSeeking = true
                                    let percentage = gesture.location.x / (totalDuration > 0 ? CGFloat(totalDuration) : 1.0)
                                    let newTime = percentage * totalDuration
                                    self.currentTime = newTime
                                    self.beatProgressSliderValue = newTime
                                }
                                .onEnded { gesture in
                                    guard !playBeatOnly else { return }
                                    isSeeking = false
                                    let percentage = gesture.location.x / (totalDuration > 0 ? CGFloat(totalDuration) : 1.0)
                                    let seekTime = percentage * totalDuration
                                    funcseek(to: seekTime)
                                }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    // MARK: - Time Duration Display
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.primary)
                        Spacer()
                        if recordingManager.isRecording || isRecordingPaused {
                            Text("Rec: \(formatTime(currentTime - recordingStartTime))")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(recordingManager.isRecording ? .red : .orange)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text(formatTime(totalDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                    // MARK: - Playback Controls
                    VStack(spacing: 24) {
                        // Primary Recording Control Row
                        HStack(spacing: 24) {
                            // Main Record/Stop Button
                            Button(action: {
                                handlePrimaryRecordingAction()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: getRecordingButtonIcon())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    Text(getRecordingButtonText())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 32)
                                .background(getRecordingButtonGradient())
                                .cornerRadius(28)
                                .shadow(color: getRecordingButtonShadowColor(), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isPlaying && !recordingManager.isRecording && !isRecordingPaused)
                            // Pause/Resume Button (show when recording or paused)
                            if recordingManager.isRecording || isRecordingPaused {
                                Button(action: {
                                    if recordingManager.isRecording {
                                        pauseRecording()
                                    } else if isRecordingPaused {
                                        resumeRecording()
                                    }
                                }) {
                                    Image(systemName: isRecordingPaused ? "play.circle.fill" : "pause.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(isRecordingPaused ? .green : .orange)
                                        .shadow(color: isRecordingPaused ? .green.opacity(0.2) : .orange.opacity(0.2), radius: 8, x: 0, y: 2)
                                }
                            }
                            // Delete Button (only show if there's a recording)
                            if recordingManager.recordedFileURL != nil || hasUnsavedRecording {
                                Button(action: { showDeleteAlert = true }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                        .shadow(color: .red.opacity(0.15), radius: 6, x: 0, y: 2)
                                }
                            }
                        }
                        // Secondary Action Row
                        if hasUnsavedRecording || (recordingManager.recordedFileURL != nil) {
                            HStack(spacing: 16) {
                                // Save Button
                                if hasUnsavedRecording {
                                    Button(action: {
                                        recordingName = session.displayName ?? session.beatName
                                        showSaveDialog = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.arrow.down.fill")
                                                .font(.system(size: 18))
                                            Text("Save Recording")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(successAccentGradient)
                                        .cornerRadius(16)
                                        .shadow(color: .green.opacity(0.15), radius: 6, x: 0, y: 2)
                                    }
                                }
                                // Options Button
                                Button(action: { showRecordingOptions = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "ellipsis.circle.fill")
                                            .font(.system(size: 18))
                                        Text("Options")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(warningAccentGradient)
                                    .cornerRadius(16)
                                    .shadow(color: .orange.opacity(0.15), radius: 6, x: 0, y: 2)
                                }
                            }
                        }
                        // Recording Status Information
                        VStack(spacing: 6) {
                            if recordingManager.isRecording {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.red)
                                    Text("Recording in progress...")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                }
                            } else if isRecordingPaused {
                                HStack {
                                    Image(systemName: "pause.circle")
                                        .foregroundColor(.orange)
                                    Text("Recording paused - tap resume to continue")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            } else if let url = recordingManager.recordedFileURL {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Vocal saved: \(url.lastPathComponent)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if hasUnsavedRecording {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Unsaved recording - tap save to keep it")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 36)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
                )
                .padding(.horizontal, 16)
                Spacer()
            }

            // MARK: - Countdown Overlay
            if showCountdown {
                CountdownView(isShowing: $showCountdown, seconds: settings.countdownLength, onComplete: {
                    startRecording()
                })
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                .zIndex(1)
            }
        }
        .alert("Delete Recording?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteVocalRecording()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your vocal recording. This action cannot be undone.")
        }
        .alert("Save Recording", isPresented: $showSaveDialog) {
            TextField("Recording name", text: $recordingName)
            Button("Save") {
                saveRecording()
            }
            Button("Discard", role: .destructive) {
                discardRecording()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for your recording:")
        }
        .actionSheet(isPresented: $showRecordingOptions) {
            ActionSheet(
                title: Text("Recording Options"),
                message: Text("Choose an action for your recording"),
                buttons: [
                    .default(Text("Export Recording")) {
                        exportRecording()
                    },
                    .default(Text("Share Recording")) {
                        shareRecording()
                    },
                    .destructive(Text("Start New Recording")) {
                        startNewRecording()
                    },
                    .cancel()
                ]
            )
        }
        .onAppear(perform: setupAudioPlayers)
        .onDisappear {
            stop()
            metronomeManager.stop()
            if let observer = avPlayerObserver, let avPlayer = avPlayer {
                avPlayer.removeTimeObserver(observer)
                avPlayerObserver = nil
            }
        }
    }
    
    // MARK: - Enhanced Recording Methods
    private func handlePrimaryRecordingAction() {
        if recordingManager.isRecording {
            // Stop recording
            stopRecording()
        } else if isRecordingPaused {
            // Stop completely
            stopRecording()
        } else {
            // Start new recording
            isRecordingInitiated = true
            showCountdown = true
        }
    }
    
    private func handleRecordingPauseResume() {
        if recordingManager.isRecording {
            // Pause recording
            pauseRecording()
        } else if isRecordingPaused {
            // Resume recording and playback
            resumeRecording()
            // Always start playback when resuming recording, regardless of current state
            if !playBeatOnly {
                play()
            }
        }
    }
    private func startRecording() {
        recordingStartTime = currentTime
        recordingManager.startRecording()
        hasUnsavedRecording = true
        isRecordingPaused = false
        
        if !isPlaying && !playBeatOnly {
            play()
        }
    }
    
    private func pauseRecording() {
        recordingManager.pauseRecording()
        recordingPausedTime = currentTime
        isRecordingPaused = true
        // Optionally pause playback too
        if isPlaying {
            pause()
        }
    }
    
    private func resumeRecording() {
        print("[DEBUG] Resuming recording and playback")
        recordingManager.resumeRecording()
        isRecordingPaused = false
        // Ensure UI updates immediately
        DispatchQueue.main.async {
            // If you have a published isRecordingPaused or isRecording, update here
        }
        // Resume playback
        if !isPlaying && !playBeatOnly {
            play()
        }
    }
    
    private func stopRecording() {
        recordingManager.stopRecording()
        isRecordingPaused = false
        hasUnsavedRecording = true
    }
    
    private func saveRecording() {
        // Implement save logic here
        if let recordingURL = recordingManager.recordedFileURL {
            let documentsPath = getDocumentsDirectory()
            let savedURL = documentsPath.appendingPathComponent("\(recordingName).m4a")
            
            do {
                if FileManager.default.fileExists(atPath: savedURL.path) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.copyItem(at: recordingURL, to: savedURL)
                hasUnsavedRecording = false
                print("Recording saved as: \(recordingName)")
            } catch {
                print("Error saving recording: \(error)")
            }
        }
    }
    
    private func discardRecording() {
        deleteVocalRecording()
        hasUnsavedRecording = false
    }
    
    private func exportRecording() {
        // Implement export functionality
        print("Export recording functionality")
    }
    
    private func shareRecording() {
        // Implement share functionality
        print("Share recording functionality")
    }
    
    private func startNewRecording() {
        deleteVocalRecording()
        hasUnsavedRecording = false
        isRecordingInitiated = true
        showCountdown = true
    }
    
    // MARK: - Recording Button Helpers
    private func getRecordingButtonIcon() -> String {
        if recordingManager.isRecording {
            return "stop.circle.fill"
        } else if isRecordingPaused {
            return "stop.circle.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private func getRecordingButtonText() -> String {
        if recordingManager.isRecording {
            return "Stop"
        } else if isRecordingPaused {
            return "Stop"
        } else {
            return "Record"
        }
    }
    
    private func getRecordingButtonGradient() -> AnyShapeStyle {
        if recordingManager.isRecording {
            return AnyShapeStyle(secondaryAccentGradient)
        } else if isRecordingPaused {
            return AnyShapeStyle(warningAccentGradient)
        } else {
            return AnyShapeStyle(primaryAccentGradient)
        }
    }
    
    private func getRecordingButtonShadowColor() -> Color {
        if recordingManager.isRecording {
            return Color.red.opacity(0.3)
        } else if isRecordingPaused {
            return Color.orange.opacity(0.3)
        } else {
            return Color.blue.opacity(0.3)
        }
    }
    
    // MARK: - Audio Playback Methods (Enhanced)
    private func setupAudioPlayers() {
        let beatFile = session.beatFileName
        if beatFile.hasPrefix("http://") || beatFile.hasPrefix("https://") {
            // Remote file: use AVPlayer
            isRemote = true
            let url = URL(string: beatFile)!
            avPlayer = AVPlayer(url: url)
            avPlayer?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                let duration = self.avPlayer?.currentItem?.asset.duration
                let seconds = duration?.isIndefinite == false ? CMTimeGetSeconds(duration!) : 0.0
                DispatchQueue.main.async {
                    self.totalDuration = seconds
                }
            }
            avPlayerObserver = avPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { time in
                guard !self.isSeeking else { return }
                self.currentTime = CMTimeGetSeconds(time)
                self.beatProgressSliderValue = self.currentTime
            }
        } else {
            // Local file: use AVAudioPlayer
            isRemote = false
            let beatURL = Bundle.main.url(forResource: beatFile, withExtension: nil) ?? getDocumentsDirectory().appendingPathComponent(beatFile)
            print("Trying to load beat from: \(beatURL.path)")
            guard FileManager.default.fileExists(atPath: beatURL.path) else {
                print("Local beat file not found at: \(beatURL.path)")
                return
            }
            let vocalURL = getDocumentsDirectory().appendingPathComponent(session.vocalFileName)
        do {
            beatPlayer = try AVAudioPlayer(contentsOf: beatURL)
                if FileManager.default.fileExists(atPath: vocalURL.path) && !playBeatOnly {
            vocalPlayer = try AVAudioPlayer(contentsOf: vocalURL)
                } else {
                    vocalPlayer = nil
                }
            beatPlayer?.prepareToPlay()
            vocalPlayer?.prepareToPlay()
                totalDuration = beatPlayer?.duration ?? 0.0
            } catch {
                print("Failed to set up players: \(error.localizedDescription)")
            }
        }
    }

    private func play() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set AVAudioSession: \(error)")
        }
        
        if isRemote {
            avPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
            avPlayer?.play()
            isPlaying = true
        } else {
            guard let beatPlayer = beatPlayer else {
                setupAudioPlayers()
                return
            }
            beatPlayer.currentTime = currentTime
            
            // Only play vocal if not in beat-only mode
            if !playBeatOnly {
                vocalPlayer?.currentTime = currentTime
            }
            
            if !beatPlayer.isPlaying {
                beatPlayer.play()
            }
            
            if !playBeatOnly && !(vocalPlayer?.isPlaying ?? true) {
            vocalPlayer?.play()
            }
            
            isPlaying = true
            startTimer()
        }
    }
    
    private func pause() {
        if isRemote {
            avPlayer?.pause()
            isPlaying = false
        } else {
        beatPlayer?.pause()
            if !playBeatOnly {
        vocalPlayer?.pause()
            }
        isPlaying = false
        stopTimer()
        }
    }
    
    private func stop() {
        if isRemote {
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
            isPlaying = false
            currentTime = 0.0
            beatProgressSliderValue = 0.0
        } else {
        beatPlayer?.stop()
            if !playBeatOnly {
        vocalPlayer?.stop()
            }
        isPlaying = false
        stopTimer()
            currentTime = 0.0
            beatProgressSliderValue = 0.0
            isRecordingInitiated = false
        }
    }

    private func funcseek(to time: TimeInterval) {
        let newTime = max(0, min(time, totalDuration))
        if isRemote {
            avPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
            currentTime = newTime
            beatProgressSliderValue = newTime
        } else {
            beatPlayer?.currentTime = newTime
            if !playBeatOnly {
                vocalPlayer?.currentTime = newTime
            }
            currentTime = newTime
            beatProgressSliderValue = newTime
            if !isPlaying {
                play()
            }
        }
    }

    private func seek(by interval: TimeInterval) {
        let newTime = currentTime + interval
        funcseek(to: newTime)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !self.isSeeking, let beatPlayer = self.beatPlayer else { return }
            self.currentTime = beatPlayer.currentTime
            self.beatProgressSliderValue = beatPlayer.currentTime
            if self.currentTime >= self.totalDuration {
                self.stop()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func deleteVocalRecording() {
        stop()
        if let url = recordingManager.recordedFileURL {
            do {
                try FileManager.default.removeItem(at: url)
                recordingManager.recordedFileURL = nil
                vocalPlayer = nil
                hasUnsavedRecording = false
                isRecordingPaused = false
                print("Vocal recording deleted successfully.")
            } catch {
                print("Error deleting vocal recording: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - SliderSection Helper View (Unchanged)
struct SliderSection: View {
    let title: String
    @Binding var progress: Double
    let totalDuration: TimeInterval
    let accentColor: Color
    @Binding var isSeeking: Bool

    var onEditingChanged: (Double) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }

            Slider(value: $progress, in: 0...totalDuration, onEditingChanged: { editing in
                isSeeking = editing
                if !editing {
                    onEditingChanged(progress)
                }
            })
            .accentColor(accentColor)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .cornerRadius(10)
            .frame(height: 40)
        }
    }
}

// MARK: - WaveformView (Enhanced)
struct WaveformView: View {
    let progress: Double
    let accentGradient: LinearGradient
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background waveform bars
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(0.6)
                            .overlay(AnyShapeStyle(accentGradient.opacity(0.5)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Progress Indicator
                Rectangle()
                    .fill(AnyShapeStyle(accentGradient.opacity(isPlaying ? 1.0 : 0.5)))
                    .frame(width: 3)
                    .offset(x: geometry.size.width * progress - 1.5)
                    .animation(.linear(duration: 0.05), value: progress)

                // Foreground active waveform
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(1.0)
                            .overlay(AnyShapeStyle(accentGradient))
                    }
                }
                .mask(
                    Rectangle()
                        .frame(width: geometry.size.width * progress)
                        .offset(x: 0)
                )
                .animation(.linear(duration: 0.05), value: progress)
            }
        }
    }
}

// MARK: - Enhanced RecordingManager



// MARK: - Preview Provider
struct SessionPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let dummy = SessionModel(
            beatName: "Chill Groove",
            beatFileName: "beat1.mp3",
            vocalFileName: "vocal_dummy.m4a",
            scale: "C Major",
            bpm: 90,
            duration: 180.0,
            timestamp: Date(),
            displayName: "My Epic Freestyle"
        )
        SessionPlayerView(session: dummy)
    }
} 
