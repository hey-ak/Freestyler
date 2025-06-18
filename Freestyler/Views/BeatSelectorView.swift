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
    @State private var showSettings = false
    @State private var showScalePicker = false
    @State private var showBPMPicker = false
    
    let scales = ["C Major", "A Minor", "G Major", "E Minor"]
    let bpms = [70, 90, 120]
    let allBeats: [BeatModel] = [
        BeatModel(name: "Chill Groove", scale: "C Major", bpm: 90, fileName: "beat1.mp3"),
        BeatModel(name: "Uptempo Flow", scale: "A Minor", bpm: 120, fileName: "beat2.mp3"),
        BeatModel(name: "Smooth Jam", scale: "G Major", bpm: 70, fileName: "beat3.mp3")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced gradient background
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.4),
                        Color.blue.opacity(0.3),
                        Color.black.opacity(0.1)
                    ]),
                    center: .topLeading,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header section with floating card design
                    VStack(spacing: 24) {
                        // Modernized icon
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 45, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Beat Selection")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    // Compact filter controls
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            FilterButton(
                                title: selectedScale,
                                icon: "music.note",
                                isActive: true
                            ) {
                                showScalePicker = true
                            }
                            .confirmationDialog("Select Scale", isPresented: $showScalePicker, titleVisibility: .visible) {
                                ForEach(scales, id: \.self) { scale in
                                    Button(scale) { selectedScale = scale }
                                }
                            }
                            
                            FilterButton(
                                title: "\(selectedBPM)",
                                icon: "metronome",
                                isActive: true
                            ) {
                                showBPMPicker = true
                            }
                            .confirmationDialog("Select BPM", isPresented: $showBPMPicker, titleVisibility: .visible) {
                                ForEach(bpms, id: \.self) { bpm in
                                    Button("\(bpm)") { selectedBPM = bpm }
                                }
                            }
                        }
                        
                        // Search button
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                filteredBeats = allBeats.filter { $0.scale == selectedScale && $0.bpm == selectedBPM }
                                selectedBeat = nil
                                audioManager.stop()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "waveform.path.badge.plus")
                                    .font(.title3)
                                Text("Find Beats")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                        .scaleEffect(filteredBeats.isEmpty ? 1.0 : 0.98)
                        .animation(.spring(response: 0.3), value: filteredBeats.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    
                    // Beat results
                    if !filteredBeats.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredBeats, id: \.id) { beat in
                                    ModernBeatCard(
                                        beat: beat,
                                        isSelected: selectedBeat?.id == beat.id,
                                        isPlaying: audioManager.isPlaying && selectedBeat?.id == beat.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedBeat = beat
                                        }
                                        audioManager.play(fileName: beat.fileName)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 280)
                        
                        // Action buttons
                        if let beat = selectedBeat {
                            HStack(spacing: 16) {
                                ActionButton(
                                    title: audioManager.isPlaying ? "Pause" : "Play",
                                    icon: audioManager.isPlaying ? "pause.fill" : "play.fill",
                                    style: .secondary
                                ) {
                                    if audioManager.isPlaying {
                                        audioManager.pause()
                                    } else {
                                        audioManager.play(fileName: beat.fileName)
                                    }
                                }
                                
                                ActionButton(
                                    title: "Freestyle",
                                    icon: "music.mic",
                                    style: .primary
                                ) {
                                    showSessionView = true
                                }
                            }
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.6))
                            
                            Text("Discover Your Beat")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Beat indicator
                    if showBeatIndicator {
                        Circle()
                            .fill(beatIndicatorOn ? .green : .gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .scaleEffect(beatIndicatorOn ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: beatIndicatorOn)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            if showCountdown {
                CountdownView(isShowing: $showCountdown, seconds: settings.countdownLength) {
                    startSession()
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
            if let beat = selectedBeat {
                SessionPlayerView(session: SessionModel(
                    beatName: beat.name,
                    beatFileName: beat.fileName,
                    vocalFileName: "vocal_\(UUID().uuidString).m4a",
                    scale: beat.scale,
                    bpm: beat.bpm,
                    duration: 0.0,
                    timestamp: Date(),
                    displayName: nil
                ))
            } else {
                Text("Error: No beat selected")
                    .onAppear {
                        showSessionView = false
                    }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private func startSession() {
        guard let beat = selectedBeat else { return }
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
        metronomeManager.stop()
        audioManager.stop()
        recordingManager.stopRecording()
        showBeatIndicator = false
        isRecordingSession = false
    }
}

// MARK: - Modern UI Components

struct FilterButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isActive ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isActive ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}

struct ModernBeatCard: View {
    let beat: BeatModel
    let isSelected: Bool
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(isSelected ?
                          AnyShapeStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                          AnyShapeStyle(.ultraThinMaterial))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isPlaying ? "waveform" : "music.note")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPlaying)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(beat.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label(beat.scale, systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(beat.bpm)", systemImage: "metronome")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? .ultraThinMaterial : .regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ?
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isSelected ? 2 : 0
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? .purple.opacity(0.3) : .black.opacity(0.05),
            radius: isSelected ? 15 : 5,
            x: 0,
            y: isSelected ? 8 : 2
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                Group {
                    switch style {
                    case .primary:
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    case .secondary:
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style == .secondary ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: style == .primary ? .purple.opacity(0.3) : .clear,
                radius: style == .primary ? 10 : 0,
                x: 0,
                y: style == .primary ? 5 : 0
            )
        }
    }
}

struct BeatSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        BeatSelectorView()
    }
}
