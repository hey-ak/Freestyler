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
    // Removed vocalProgressSliderValue as it's replaced by waveform
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

                // MARK: - Player Card Background (Glassmorphic)
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

                    // MARK: - Vocal Waveform Visualization
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
                            accentColor: .red, // Vocal waveform color
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
                                    // Enable seeking by tapping/dragging on the waveform
                                    isSeeking = true
                                    let percentage = gesture.location.x / gesture.translation.width
                                    let newTime = percentage * totalDuration
                                    self.currentTime = newTime // Update current time visually
                                    self.beatProgressSliderValue = newTime // Keep beat slider in sync visually
                                }
                                .onEnded { gesture in
                                    isSeeking = false
                                    let percentage = gesture.location.x / gesture.translation.width
                                    let seekTime = percentage * totalDuration
                                    funcseek(to: seekTime) // Actual seek after gesture ends
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
                    .padding(.horizontal, 40) // Match card padding
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
                                        .fill(
                                            LinearGradient(colors: isPlaying ? [Color.red, Color.orange] : [Color.blue, Color.purple],
                                                           startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                                .foregroundColor(.white)
                                .shadow(color: isPlaying ? .red.opacity(0.4) : .blue.opacity(0.4), radius: 10, x: 0, y: 5)
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

                    // MARK: - Vocal Recording Controls
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
                                        .foregroundColor(recordingManager.isRecording ? .red : .accentColor)
                                    Text(recordingManager.isRecording ? "Stop" : "Record")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Material.ultraThinMaterial)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                .background(Material.regularMaterial)
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
        // vocalProgressSliderValue is no longer explicitly set here, as WaveformView handles its own progress
        isRecordingInitiated = false
    }

    private func funcseek(to time: TimeInterval) {
        let newTime = max(0, min(time, totalDuration))
        beatPlayer?.currentTime = newTime
        vocalPlayer?.currentTime = newTime
        currentTime = newTime
        beatProgressSliderValue = newTime
        // vocalProgressSliderValue is no longer explicitly set here, as WaveformView uses currentTime directly

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
            // vocalProgressSliderValue no longer updated directly from here

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

struct WaveformView: View {
    let progress: Double // Normalized progress (0.0 to 1.0)
    let accentColor: Color
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background waveform bars (static for visual effect)
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(0.6)
                            .foregroundColor(accentColor.opacity(0.5)) // Faded background color
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Progress Indicator (the playhead)
                Rectangle()
                    .fill(accentColor.opacity(isPlaying ? 1.0 : 0.5)) // Brighter when playing
                    .frame(width: 3) // Vertical line
                    .offset(x: geometry.size.width * progress - 1.5) // Center the line
                    .animation(.linear(duration: 0.05), value: progress) // Smooth movement

                // Foreground active waveform (covers up to current progress)
                HStack(spacing: 2) {
                    ForEach(0..<Int(geometry.size.width / 5), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .frame(height: CGFloat.random(in: 10...geometry.size.height * 0.8))
                            .opacity(1.0)
                            .foregroundColor(accentColor) // Full color
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
