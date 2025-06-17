import SwiftUI

struct BeatSelectorView: View {
    @State private var selectedScale: String = "C Major"
    @State private var selectedBPM: Int = 90
    @State private var filteredBeats: [BeatModel] = []
    @State private var selectedBeat: BeatModel?
    @ObservedObject private var audioManager = AudioManager()
    @ObservedObject private var metronomeManager = MetronomeManager()
    @StateObject private var recordingManager = RecordingManager()
    @ObservedObject private var settings = SettingsModel.shared
    @State private var showCountdown = false
    @State private var showBeatIndicator = false
    @State private var isRecordingSession = false
    @State private var beatIndicatorOn = false
    @State private var showSessionView = false
    
    let scales = ["C Major", "A Minor", "G Major", "E Minor"]
    let bpms = [70, 90, 120]
    // Dummy beats (replace fileName with actual audio files in your bundle)
    let allBeats: [BeatModel] = [
        BeatModel(name: "Chill Groove", scale: "C Major", bpm: 90, fileName: "beat1.mp3"),
        BeatModel(name: "Uptempo Flow", scale: "A Minor", bpm: 120, fileName: "beat2.mp3"),
        BeatModel(name: "Smooth Jam", scale: "G Major", bpm: 70, fileName: "beat3.mp3")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.3), Color.blue.opacity(0.3)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Text("Pick Your Beat")
                        .font(.largeTitle)
                        .fontWeight(.heavy) // Make title bolder
                        .foregroundColor(.primary) // Adapt to dark/light mode
                        .padding(.bottom, 20)
                    
                    // Beat Selection Filters
                    Form {
                        Picker("Scale", selection: $selectedScale) {
                            ForEach(scales, id: \.self) { scale in
                                Text(scale)
                            }
                        }
                        .pickerStyle(.menu) // Ensure consistent menu style
                        .listRowBackground(Color.white.opacity(0.7)) // Slightly translucent background for form rows
                        
                        Picker("BPM", selection: $selectedBPM) {
                            ForEach(bpms, id: \.self) { bpm in
                                Text("\(bpm) BPM")
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                    .scrollContentBackground(.hidden) // Hide default form background
                    .background(Color.clear) // Make form background clear to show gradient
                    .frame(height: 160)
                    .scrollDisabled(true)
                    .padding(.horizontal)
                    .cornerRadius(15) // Rounded corners for the form
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5) // Subtle shadow
                    
                    Button {
                        filteredBeats = allBeats.filter { $0.scale == selectedScale && $0.bpm == selectedBPM }
                    } label: {
                        Label("Find Beat", systemImage: "magnifyingglass")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    
                    // Filtered Beats List
                    if !filteredBeats.isEmpty {
                        List(filteredBeats, id: \.id, selection: $selectedBeat) { beat in
                            HStack {
                                Text(beat.name)
                                Spacer()
                                if selectedBeat?.id == beat.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor) // Uses system accent color for consistency
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedBeat = beat
                            }
                            .listRowBackground(selectedBeat?.id == beat.id ? Color.blue.opacity(0.2) : Color.white.opacity(0.7)) // Highlight selected row
                        }
                        .listStyle(.insetGrouped)
                        .frame(height: min(CGFloat(filteredBeats.count) * 60, 200))
                        .clipShape(RoundedRectangle(cornerRadius: 15)) // Rounded corners for the list
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                        
                        if let beat = selectedBeat {
                            Button {
                                showSessionView = true
                            } label: {
                                Label("Freestyle", systemImage: "music.mic")
                                    .font(.headline)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                            .padding(.top, 20)
                            .padding(.horizontal)
                        }
                    } else {
                        ContentUnavailableView("No Beats Found", systemImage: "waveform.slash", description: Text("Try adjusting your scale and BPM selections."))
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    }
                    
                    // Visual Beat Indicator
                    if showBeatIndicator {
                        Circle()
                            .fill(beatIndicatorOn ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .animation(.easeInOut(duration: 0.1), value: beatIndicatorOn)
                            .padding(.top, 30)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Beats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                LinearGradient(colors: [Color.red.opacity(0.5), Color.blue.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) // Ensures title is readable on dark gradient
            
            // Countdown Overlay
            if showCountdown {
                CountdownView(isShowing: $showCountdown, seconds: settings.countdownLength) {
                    startSession()
                }
            }
        }
        .onAppear {
            metronomeManager.onTick = {
                beatIndicatorOn = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    beatIndicatorOn = false
                }
            }
        }
        .fullScreenCover(isPresented: $showSessionView) {
            if let beat = selectedBeat {
                let session = SessionModel(
                    beatName: beat.name,
                    beatFileName: beat.fileName,
                    vocalFileName: "vocal_\(UUID().uuidString).m4a",
                    scale: beat.scale,
                    bpm: beat.bpm,
                    timestamp: Date(),
                    displayName: beat.name
                )
                SessionPlayerView(session: session)
            }
        }
    }
    
    private func startSession() {
        guard let beat = selectedBeat else { return }
        // Start metronome, beat playback, and recording
        showBeatIndicator = settings.metronomeOn
        if settings.metronomeOn {
            metronomeManager.start(bpm: selectedBPM)
        }
        audioManager.play(fileName: beat.fileName)
        recordingManager.startRecording()
        isRecordingSession = true
        showSessionView = true
    }
    
    private func stopSession() {
        // Stop all playback and recording
        metronomeManager.stop()
        audioManager.stop()
        recordingManager.stopRecording()
        showBeatIndicator = false
        isRecordingSession = false
        // At this point, beat and vocal files are saved separately for future use
    }
}

struct BeatSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        BeatSelectorView()
    }
}
