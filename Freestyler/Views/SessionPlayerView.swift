import SwiftUI
import AVFoundation
import Combine

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
    @State private var hasUnsavedRecording = false
    @State private var showRecordingOptions = false

    // MARK: - Playback Control Constants
    let seekInterval: TimeInterval = 10.0

    // MARK: - Consistent Color Scheme (Only 2 colors)
    let primaryGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
    let accentGradient = LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing)

    // MARK: - Metronome
    @StateObject private var metronomeManager = MetronomeManager()
    @State private var metronomeOn = false
    @State private var metronomePlayer: AVAudioPlayer?
    @State private var cancellables = Set<AnyCancellable>()
    
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
                            .foregroundStyle(primaryGradient)
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
                                            .foregroundStyle(primaryGradient)
                                        Text("Metronome")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .onChange(of: metronomeOn) { value in
                                    if value {
                                        playMetronome()
                                    } else {
                                        stopMetronome()
                                    }
                                }
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
                            RecordingStatusIndicator(
                                isRecording: recordingManager.isRecording,
                                isPaused: isRecordingPaused,
                                isPlaying: isPlaying
                            )
                        }
                        WaveformView(
                            progress: currentTime / totalDuration,
                            accentGradient: getWaveformGradient(),
                            isPlaying: recordingManager.isRecording && !isRecordingPaused
                        )
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .cornerRadius(14)
                        .opacity(0.5)
                        .padding(.vertical, 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isSeeking = true
                                    let percentage = gesture.location.x / (totalDuration > 0 ? CGFloat(totalDuration) : 1.0)
                                    let newTime = percentage * totalDuration
                                    self.currentTime = newTime
                                    self.beatProgressSliderValue = newTime
                                }
                                .onEnded { gesture in
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
                                .foregroundStyle(recordingManager.isRecording ? primaryGradient : accentGradient)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text(formatTime(totalDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                    // MARK: - Seamless Recording Controls
                    RecordingControlsView(
                        recordingManager: recordingManager,
                        isRecordingPaused: $isRecordingPaused,
                        hasUnsavedRecording: $hasUnsavedRecording,
                        isPlaying: isPlaying,
                        primaryGradient: primaryGradient,
                        accentGradient: accentGradient,
                        onStartRecording: { initiateRecording() },
                        onPauseRecording: { pauseRecording() },
                        onResumeRecording: { resumeRecording() },
                        onStopRecording: { stopRecording() },
                        onDeleteRecording: { showDeleteAlert = true },
                        onSaveRecording: {
                            recordingName = session.displayName ?? session.beatName
                            showSaveDialog = true
                        },
                        onShowOptions: { showRecordingOptions = true }
                    )
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
        .onAppear {
            // Observe BPM changes and restart metronome if needed
            settings.$metronomeBPM.sink { newBPM in
                if metronomeOn {
                    metronomeManager.start(bpm: newBPM)
                }
            }.store(in: &cancellables)
        }
        .onDisappear {
            stop()
            metronomeManager.stop()
            if let observer = avPlayerObserver, let avPlayer = avPlayer {
                avPlayer.removeTimeObserver(observer)
                avPlayerObserver = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getWaveformGradient() -> LinearGradient {
        if recordingManager.isRecording {
            return primaryGradient
        } else if isRecordingPaused {
            return accentGradient
        } else {
            return primaryGradient
        }
    }
    
    // MARK: - Seamless Recording Methods
    private func initiateRecording() {
        isRecordingInitiated = true
        showCountdown = true
    }
    
    private func startRecording() {
        recordingStartTime = currentTime
        recordingManager.startRecording()
        hasUnsavedRecording = true
        isRecordingPaused = false
        
        if !isPlaying {
            play()
        }
    }
    
    private func pauseRecording() {
        recordingManager.pauseRecording()
        recordingPausedTime = currentTime
        isRecordingPaused = true
        if isPlaying {
            pause()
        }
        metronomeManager.stop()
    }
    
    private func resumeRecording() {
        recordingManager.resumeRecording()
        isRecordingPaused = false
        if !isPlaying {
            play()
        }
        if metronomeOn {
            metronomeManager.start(bpm: settings.metronomeBPM)
        }
    }
    
    private func stopRecording() {
        recordingManager.stopRecording()
        isRecordingPaused = false
        hasUnsavedRecording = true
        stop()
        metronomeManager.stop()
    }
    
    private func saveRecording() {
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
                // Add to sessions
                let newSession = SessionModel(
                    beatName: session.beatName,
                    beatFileName: session.beatFileName,
                    vocalFileName: "\(recordingName).m4a",
                    scale: session.scale,
                    bpm: session.bpm,
                    duration: totalDuration,
                    timestamp: Date(),
                    displayName: recordingName
                )
                let store = SessionStore()
                store.addSession(newSession)
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
        print("Export recording functionality")
    }
    
    private func shareRecording() {
        print("Share recording functionality")
    }
    
    private func startNewRecording() {
        deleteVocalRecording()
        hasUnsavedRecording = false
        initiateRecording()
    }
    
    // MARK: - Audio Playback Methods (Preserved existing functionality)
    private func setupAudioPlayers() {
        let beatFile = session.beatFileName
        if beatFile.hasPrefix("http://") || beatFile.hasPrefix("https://") {
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
                if FileManager.default.fileExists(atPath: vocalURL.path) {
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
            if !isPlaying {
                vocalPlayer?.currentTime = currentTime
            }
            if !beatPlayer.isPlaying {
                beatPlayer.play()
            }
            if !isPlaying && !(vocalPlayer?.isPlaying ?? true) {
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
            if !isPlaying {
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
            if !isPlaying {
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
            vocalPlayer?.currentTime = newTime
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

    private func playMetronome() {
        metronomeManager.start(bpm: settings.metronomeBPM)
    }

    private func stopMetronome() {
        metronomeManager.stop()
        metronomePlayer?.stop()
        metronomePlayer = nil
    }
}

// MARK: - Recording Status Indicator Component
struct RecordingStatusIndicator: View {
    let isRecording: Bool
    let isPaused: Bool
    let isPlaying: Bool
    
    var body: some View {
        Group {
            if isRecording {
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
            } else if isPaused {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("PAUSED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}

// MARK: - Seamless Recording Controls Component
struct RecordingControlsView: View {
    @ObservedObject var recordingManager: RecordingManager
    @Binding var isRecordingPaused: Bool
    @Binding var hasUnsavedRecording: Bool
    let isPlaying: Bool
    let primaryGradient: LinearGradient
    let accentGradient: LinearGradient
    
    let onStartRecording: () -> Void
    let onPauseRecording: () -> Void
    let onResumeRecording: () -> Void
    let onStopRecording: () -> Void
    let onDeleteRecording: () -> Void
    let onSaveRecording: () -> Void
    let onShowOptions: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Recording Control
            HStack(spacing: 20) {
                // Primary Action Button
                MainRecordingButton(
                    isRecording: recordingManager.isRecording,
                    isPaused: isRecordingPaused,
                    primaryGradient: primaryGradient,
                    accentGradient: accentGradient,
                    onAction: {
                        if recordingManager.isRecording {
                            onStopRecording()
                        } else if isRecordingPaused {
                            onStopRecording()
                        } else {
                            onStartRecording()
                        }
                    }
                )
                
                // Secondary Actions (show when recording is active)
                if recordingManager.isRecording || isRecordingPaused {
                    HStack(spacing: 16) {
                        // Pause/Resume Button
                        SecondaryActionButton(
                            icon: isRecordingPaused ? "play.circle.fill" : "pause.circle.fill",
                            gradient: isRecordingPaused ? primaryGradient : accentGradient,
                            action: {
                                if isRecordingPaused {
                                    onResumeRecording()
                                } else {
                                    onPauseRecording()
                                }
                            }
                        )
                        
                        // Delete Button
                        SecondaryActionButton(
                            icon: "trash.circle.fill",
                            gradient: LinearGradient(colors: [.red.opacity(0.8), .red], startPoint: .leading, endPoint: .trailing),
                            action: onDeleteRecording
                        )
                    }
                }
            }
            
            // Additional Actions (show when recording exists)
            if hasUnsavedRecording || recordingManager.recordedFileURL != nil {
                HStack(spacing: 16) {
                    if hasUnsavedRecording {
                        SessionActionButton(
                            title: "Save",
                            icon: "square.and.arrow.down.fill",
                            gradient: primaryGradient,
                            action: onSaveRecording
                        )
                    }
                    
                    SessionActionButton(
                        title: "Options",
                        icon: "ellipsis.circle.fill",
                        gradient: accentGradient,
                        action: onShowOptions
                    )
                }
            }
            // Status Information
            RecordingStatusInfo(
                isRecording: recordingManager.isRecording,
                isPaused: isRecordingPaused,
                recordedFileURL: recordingManager.recordedFileURL,
                hasUnsavedRecording: hasUnsavedRecording,
                primaryGradient: primaryGradient,
                accentGradient: accentGradient
            )
        }
    }
}

// MARK: - Main Recording Button Component
struct MainRecordingButton: View {
    let isRecording: Bool
    let isPaused: Bool
    let primaryGradient: LinearGradient
    let accentGradient: LinearGradient
    let onAction: () -> Void
    
    private var buttonIcon: String {
        if isRecording || isPaused {
            return "stop.circle.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var buttonGradient: LinearGradient {
        if isRecording {
            return primaryGradient
        } else if isPaused {
            return accentGradient
        } else {
            return primaryGradient
        }
    }
    
    var body: some View {
        Button(action: onAction) {
            Image(systemName: buttonIcon)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(buttonGradient)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(isRecording ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
}

// MARK: - Secondary Action Button Component
struct SecondaryActionButton: View {
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(gradient, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Action Button Component
struct SessionActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(gradient, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Recording Status Info Component
struct RecordingStatusInfo: View {
    let isRecording: Bool
    let isPaused: Bool
    let recordedFileURL: URL?
    let hasUnsavedRecording: Bool
    let primaryGradient: LinearGradient
    let accentGradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            if isRecording {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(primaryGradient)
                    Text("Recording in progress...")
                        .font(.caption)
                        .foregroundStyle(primaryGradient)
                        .fontWeight(.medium)
                }
            } else if isPaused {
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle")
                        .foregroundStyle(accentGradient)
                    Text("Recording paused - tap resume to continue")
                        .font(.caption)
                        .foregroundStyle(accentGradient)
                        .fontWeight(.medium)
                }
            } else if let url = recordedFileURL {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(primaryGradient)
                    Text("Vocal saved: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if hasUnsavedRecording {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(accentGradient)
                    Text("Unsaved recording - tap save to keep it")
                        .font(.caption)
                        .foregroundStyle(accentGradient)
                        .fontWeight(.medium)
                }
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
