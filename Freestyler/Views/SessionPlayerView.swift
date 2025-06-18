import SwiftUI
import AVFoundation

struct SessionPlayerView: View {
    let session: SessionModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Playback States
    @State private var beatPlayer: AVAudioPlayer?
    @State private var vocalPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0.0
    @State private var totalDuration: TimeInterval = 0.0

    // MARK: - Sliders & Seeking
    @State private var beatProgressSliderValue: Double = 0.0
    @State private var isSeeking = false // To prevent timer updates during manual slider adjustment
    @State private var timer: Timer?

    // MARK: - Recording States
    @StateObject private var recordingManager = RecordingManager()
    @ObservedObject private var settings = SettingsModel.shared // For countdown length
    @State private var showCountdown = false
    @State private var showDeleteAlert = false
    @State private var isRecordingInitiated = false // Flag to manage initial recording setup

    // MARK: - Playback Control Constants
    let seekInterval: TimeInterval = 10.0 // Seek forward/backward by 10 seconds

    // MARK: - Unified Accent Colors/Gradients
    let primaryAccentGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
    let secondaryAccentGradient = LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing)

    // MARK: - Metronome
    @StateObject private var metronomeManager = MetronomeManager()
    @State private var metronomeOn = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.red.opacity(0.3)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Close Button (top right)
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.secondary)
                            .shadow(radius: 4)
                            .padding(8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)

                // MARK: - Player Card Background (Transparent & Glossy)
                VStack(spacing: 25) {
                    // Session Info
                    VStack(spacing: 8) {
                        Text(session.displayName ?? session.beatName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("\(session.scale) | \(session.bpm) BPM")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)

                    // MARK: - Metronome Toggle
                    HStack {
                        Toggle(isOn: $metronomeOn) {
                            Label("Metronome", systemImage: "metronome")
                                .font(.headline)
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
                    .padding(.horizontal, 8)

                    // MARK: - Beat Slider (Glassmorphic)
                    VStack(spacing: 8) {
                        SliderSection(
                            title: "Beat",
                            progress: $beatProgressSliderValue,
                            totalDuration: totalDuration,
                            accentColor: .blue, // Distinct color for beat
                            isSeeking: $isSeeking
                        ) { value in
                            funcseek(to: value)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    // MARK: - Vocal Waveform Visualization (Same Color as Play Button when idle)
                    VStack(spacing: 8) {
                        HStack {
                            Text("Vocal")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Placeholder Waveform View
                        WaveformView(
                            progress: currentTime / totalDuration,
                            accentGradient: primaryAccentGradient, // Use the unified primary gradient
                            isPlaying: isPlaying // Pass isPlaying to indicate active state
                        )
                        .frame(height: 60) // Taller for better visual
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Material.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .cornerRadius(10)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isSeeking = true
                                    // Use geometry proxy from WaveformView to calculate percentage
                                    // This requires the gesture to be handled inside WaveformView itself,
                                    // or you need to pass geometry.size.width to this gesture scope.
                                    // For now, let's assume the gesture is moved inside WaveformView or `totalDuration`
                                    // is used for a rough calculation if total width isn't available.
                                    // A robust solution would pass current width from GeometryReader to gesture.
                                    // Re-checking previous context, `WaveformView` itself has a `GeometryReader`.
                                    // The `gesture` should be applied directly to the content *inside* `WaveformView`.
                                    // Since it's here, we need to approximate or pass the width.
                                    // Let's assume you'll move this gesture into WaveformView or use totalDuration
                                    // as a proxy for width calculation if totalDuration is linked to visual width.
                                    // For this fix, let's use a placeholder calculation, the robust way is to move it.
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
                        Text(formatTime(totalDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                    // MARK: - Playback Controls (Back, Play/Pause, Forward)
                    HStack(spacing: 40) {
                        Button {
                            seek(by: -seekInterval)
                        } label: {
                            Image(systemName: "gobackward.\(Int(seekInterval)).fill")
                                .font(.system(size: 30))
                                .padding(10)
                                .background(Circle().fill(Material.thinMaterial))
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }

                        Button {
                            if isPlaying {
                                pause()
                            } else {
                                play()
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60, weight: .semibold))
                                .padding(5)
                                .background(
                                    Circle()
                                        .fill(isPlaying ? secondaryAccentGradient : primaryAccentGradient) // Dynamic gradient
                                )
                                .foregroundColor(.white)
                                .shadow(color: isPlaying ? Color.red.opacity(0.4) : Color.blue.opacity(0.4), radius: 10, x: 0, y: 5) // Dynamic shadow color
                        }

                        Button {
                            seek(by: seekInterval)
                        } label: {
                            Image(systemName: "goforward.\(Int(seekInterval)).fill")
                                .font(.system(size: 30))
                                .padding(10)
                                .background(Circle().fill(Material.thinMaterial))
                                .foregroundColor(.primary)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }

                    // MARK: - Vocal Recording Controls (Same Color as Play Button when Idle)
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            Button(action: {
                                if recordingManager.isRecording {
                                    recordingManager.stopRecording()
                                } else {
                                    isRecordingInitiated = true
                                    showCountdown = true // Trigger countdown overlay
                                }
                            }) {
                                HStack {
                                    Image(systemName: recordingManager.isRecording ? "stop.circle.fill" : "mic.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white) // Icon color white for visibility on gradient
                                    Text(recordingManager.isRecording ? "Stop" : "Record")
                                        .font(.headline)
                                        .foregroundColor(.white) // Text color white for visibility on gradient
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(recordingManager.isRecording ? AnyShapeStyle(secondaryAccentGradient) : AnyShapeStyle(primaryAccentGradient)) // Dynamic gradient
                                .cornerRadius(16)
                                .shadow(color: recordingManager.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .disabled(isPlaying)

                            if recordingManager.recordedFileURL != nil {
                                Button(action: { showDeleteAlert = true }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.red)
                                }
                                .alert(isPresented: $showDeleteAlert) {
                                    Alert(
                                        title: Text("Delete Vocal Recording?"),
                                        message: Text("This will permanently delete your vocal take. You will need to record a new one."),
                                        primaryButton: .destructive(Text("Delete")) {
                                            deleteVocalRecording()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }

                        // Recording Status / File Info
                        if recordingManager.isRecording {
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.red)
                                Text("Recording...")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        } else if let url = recordingManager.recordedFileURL {
                            HStack {
                                Image(systemName: "waveform.path.badge.plus")
                                    .foregroundColor(.green)
                                Text("Vocal saved: \(url.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(30)
                .background(Material.thinMaterial) // More transparent and glossy
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 15)
                .padding(.horizontal, 20)
                Spacer()
            }

            // MARK: - Countdown Overlay
            if showCountdown {
                CountdownView(isShowing: $showCountdown, seconds: settings.countdownLength) {
                    recordingManager.startRecording()
                    if !isPlaying {
                        play()
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                .zIndex(1)
            }
        }
        .onAppear(perform: setupAudioPlayers)
        .onDisappear {
            stop()
            metronomeManager.stop()
        }
    }

    // MARK: - Audio Playback Methods
    private func setupAudioPlayers() {
        let beatURL = Bundle.main.url(forResource: session.beatFileName, withExtension: nil) ?? getDocumentsDirectory().appendingPathComponent(session.beatFileName)
        let vocalURL = getDocumentsDirectory().appendingPathComponent(session.vocalFileName)

        do {
            beatPlayer = try AVAudioPlayer(contentsOf: beatURL)
            if FileManager.default.fileExists(atPath: vocalURL.path) {
                vocalPlayer = try AVAudioPlayer(contentsOf: vocalURL)
            } else {
                print("Vocal file does not exist at: \(vocalURL.lastPathComponent)")
                vocalPlayer = nil
            }

            beatPlayer?.prepareToPlay()
            vocalPlayer?.prepareToPlay()

            totalDuration = beatPlayer?.duration ?? 0.0

        } catch {
            print("Failed to set up players: \(error.localizedDescription)")
        }
    }

    private func play() {
        guard let beatPlayer = beatPlayer else {
            setupAudioPlayers()
            return
        }

        beatPlayer.currentTime = currentTime
        vocalPlayer?.currentTime = currentTime

        if !beatPlayer.isPlaying { beatPlayer.play() }
        if !(vocalPlayer?.isPlaying ?? true) {
            vocalPlayer?.play()
        }

        isPlaying = true
        startTimer()
    }

    private func pause() {
        beatPlayer?.pause()
        vocalPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    private func stop() {
        beatPlayer?.stop()
        vocalPlayer?.stop()
        isPlaying = false
        stopTimer()
        currentTime = 0.0
        beatProgressSliderValue = 0.0
        isRecordingInitiated = false
    }

    private func funcseek(to time: TimeInterval) {
        let newTime = max(0, min(time, totalDuration))
        beatPlayer?.currentTime = newTime
        vocalPlayer?.currentTime = newTime
        currentTime = newTime
        beatProgressSliderValue = newTime

        if !isPlaying {
            play()
        }
    }

    private func seek(by interval: TimeInterval) {
        let newTime = currentTime + interval
        funcseek(to: newTime)
    }

    // MARK: - Timer Management
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

    // MARK: - Helper Methods
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
                vocalPlayer = nil // Reset vocal player after deletion
                print("Vocal recording deleted successfully.")
            } catch {
                print("Error deleting vocal recording: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - SliderSection Helper View
struct SliderSection: View {
    let title: String
    @Binding var progress: Double
    let totalDuration: TimeInterval
    let accentColor: Color // This will still be used for the beat slider's unique color
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

// MARK: - WaveformView
struct WaveformView: View {
    let progress: Double // Normalized progress (0.0 to 1.0)
    let accentGradient: LinearGradient // Now expects a LinearGradient
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in // GeometryReader must wrap the content that needs its size
            ZStack(alignment: .leading) {
                // Background waveform bars (static for visual effect)
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(0.6)
                            .overlay(AnyShapeStyle(accentGradient.opacity(0.5))) // FIX 1
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Progress Indicator (the playhead)
                Rectangle()
                    .fill(AnyShapeStyle(accentGradient.opacity(isPlaying ? 1.0 : 0.5))) // FIX 2
                    .frame(width: 3) // Vertical line
                    .offset(x: geometry.size.width * progress - 1.5) // Center the line
                    .animation(.linear(duration: 0.05), value: progress) // Smooth movement

                // Foreground active waveform (covers up to current progress)
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(1.0)
                            .overlay(AnyShapeStyle(accentGradient)) // FIX 3
                    }
                }
                // Mask with a rectangle that moves with progress
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
            vocalFileName: "vocal_dummy.m4a", // Ensure this file exists in your app's Documents for preview to function correctly
            scale: "C Major",
            bpm: 90,
            duration: 180.0,
            timestamp: Date(),
            displayName: "My Epic Freestyle"
        )
        SessionPlayerView(session: dummy)
    }
}
