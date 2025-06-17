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
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)
                    
                    // Beat Selection Filters
                    Form {
                        Picker("Scale", selection: $selectedScale) {
                            ForEach(scales, id: \.self) { scale in
                                Text(scale)
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color.white.opacity(0.7))
                        
                        Picker("BPM", selection: $selectedBPM) {
                            ForEach(bpms, id: \.self) { bpm in
                                Text("\(bpm) BPM")
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: 160)
                    .scrollDisabled(true)
                    .padding(.horizontal)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    
                    Button {
                        filteredBeats = allBeats.filter { $0.scale == selectedScale && $0.bpm == selectedBPM }
                        selectedBeat = nil // Deselect any previously selected beat when finding new ones
                        audioManager.stop() // Stop any ongoing playback
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
                    
                    // MARK: - Filtered Beats Display (Enhanced Card Design)
                    if !filteredBeats.isEmpty {
                        // Using ScrollView to make the "card" always visible and scrollable if many beats
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 12) { // Spacing between individual beat items
                                ForEach(filteredBeats, id: \.id) { beat in
                                    BeatCardView(beat: beat, isSelected: selectedBeat?.id == beat.id)
                                        .onTapGesture {
                                            selectedBeat = beat
                                            // Optionally play a preview when selected
                                            audioManager.play(fileName: beat.fileName)
                                        }
                                }
                            }
                            .padding(.vertical, 10) // Padding inside the scroll view
                        }
                        .frame(height: min(CGFloat(filteredBeats.count) * 90 + 20, 300)) // Dynamic height, max 300pt
                        .padding(.horizontal)
                        .background(Material.regularMaterial) // Glassmorphic background for the card
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 8) // Enhanced shadow for depth
                        
                        // MARK: - Playback and Freestyle Buttons
                        if let beat = selectedBeat {
                            HStack(spacing: 20) {
                                Button {
                                    if audioManager.isPlaying {
                                        audioManager.pause()
                                    } else {
                                        audioManager.play(fileName: beat.fileName)
                                    }
                                } label: {
                                    Label(audioManager.isPlaying ? "Pause Beat" : "Play Beat", systemImage: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.headline)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(15)
                                }
                                
                                Button {
                                    showSessionView = true // This will open the SessionPlayerView
                                } label: {
                                    Label("Freestyle", systemImage: "music.mic")
                                        .font(.headline)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                }
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            
            // MARK: - Countdown Overlay (for recording directly from here, if you choose to enable it)
            // Currently, 'Freestyle' button leads to SessionPlayerView
            // If you want to record directly from BeatSelectorView, move the logic here.
            if showCountdown {
                CountdownView(isShowing: $showCountdown, seconds: settings.countdownLength) {
                    startSession() // This would trigger recording etc. from BeatSelectorView
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                .zIndex(1)
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
        .fullScreenCover(isPresented: $showSessionView, onDismiss: stopSession) {
            // Ensure SessionModel is created with all required parameters, including duration
            // For a new recording, duration might initially be 0.0, and updated in SessionPlayerView
            if let beat = selectedBeat {
                SessionPlayerView(session: SessionModel(
                    beatName: beat.name,
                    beatFileName: beat.fileName,
                    vocalFileName: "vocal_\(UUID().uuidString).m4a", // Unique filename for new recording
                    scale: beat.scale,
                    bpm: beat.bpm,
                    duration: 0.0, // Initial duration for a new recording
                    timestamp: Date(),
                    displayName: nil // User can set display name in SessionPlayerView
                ))
            } else {
                // Fallback or alert if no beat is selected, though button should be disabled
                Text("Error: No beat selected to freestyle to.")
                    .onAppear {
                        showSessionView = false
                    }
            }
        }
    }
    
    // This startSession is currently for if you initiate recording directly from this view.
    // Given the new SessionPlayerView, you might move recording initiation logic there.
    private func startSession() {
        guard let beat = selectedBeat else { return }
        showBeatIndicator = settings.metronomeOn
        if settings.metronomeOn {
            metronomeManager.start(bpm: selectedBPM)
        }
        audioManager.play(fileName: beat.fileName)
        recordingManager.startRecording()
        isRecordingSession = true
        // This 'showSessionView' should ideally transition to the actual SessionPlayerView
        // if recording is intended to happen there.
        showSessionView = true
    }
    
    private func stopSession() {
        metronomeManager.stop()
        audioManager.stop()
        recordingManager.stopRecording()
        showBeatIndicator = false
        isRecordingSession = false
        // The vocal file name would be saved to the SessionModel
        // by the SessionPlayerView if the recording was successful there.
    }
}

// MARK: - BeatCardView Helper
struct BeatCardView: View {
    let beat: BeatModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(isSelected ? .white : .accentColor)
                .frame(width: 40, height: 40)
                // FIX 1: Ensure both sides of the conditional return the same type (ShapeStyle)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ?
                              AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                              AnyShapeStyle(Color.white.opacity(0.8))
                        )
                )
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            VStack(alignment: .leading) {
                Text(beat.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                Text("\(beat.scale) | \(beat.bpm) BPM")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            // FIX 2: Ensure both sides of the conditional return the same type (ShapeStyle)
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ?
                      AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                      AnyShapeStyle(Material.ultraThinMaterial)
                )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue.opacity(0.8) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}


struct BeatSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        BeatSelectorView()
    }
}
