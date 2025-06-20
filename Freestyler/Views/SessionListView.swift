import SwiftUI
import AVFAudio

class SessionStore: ObservableObject {
    @Published var sessions: [SessionModel] = []
    
    private let saveKey = "SavedSessions"
    
    init() {
        loadSessions()
    }
    
    func addSession(_ session: SessionModel) {
        sessions.append(session)
        saveSessions()
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    func renameSession(_ session: SessionModel, newName: String) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx].displayName = newName
            saveSessions()
        }
    }
    
    func deleteAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([SessionModel].self, from: data) {
            sessions = decoded
        }
    }
}

struct SessionAudioPlayerView: View {
    let session: SessionModel
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var duration: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 16) {
                    // Session title
                    Text(session.displayName ?? session.beatName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // File info card
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.blue)
                        Text(session.vocalFileName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Player controls section
                VStack(spacing: 32) {
                    // Main play button
                    Button(action: {
                        if isPlaying {
                            pause()
                        } else {
                            play()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isPlaying ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPlaying)
                    
                    // Progress section
                    VStack(spacing: 12) {
                        // Time labels
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatTime(duration))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Progress slider
                        Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                            if !editing {
                                audioPlayer?.currentTime = currentTime
                            }
                        })
                        .tint(.blue)
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Sessions")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear(perform: setupPlayer)
        .onDisappear(perform: stop)
    }

    private func setupPlayer() {
        // Ensure audio plays through the main speaker
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
        let url = getDocumentsDirectory().appendingPathComponent(session.vocalFileName)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = AVAudioPlayerDelegateProxy(onFinish: {
                isPlaying = false
                stopTimer()
            })
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    private func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    private func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    private func stop() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
        currentTime = 0
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                currentTime = player.currentTime
                if currentTime >= duration {
                    isPlaying = false
                    stopTimer()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper AVAudioPlayerDelegate proxy
class AVAudioPlayerDelegateProxy: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}

struct SessionListView: View {
    @StateObject private var store = SessionStore()
    @State private var renamingSession: SessionModel?
    @State private var newName: String = ""
    @State private var showDeleteAllAlert = false
    @State private var selectedSession: SessionModel? = nil
    @State private var showSessionPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if store.sessions.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Sessions Yet")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("Your recorded sessions will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.horizontal, 32)
                    } else {
                        // Sessions list
                        List {
                            ForEach(store.sessions) { session in
                                Button(action: {
                                    selectedSession = session
                                    showSessionPlayer = true
                                }) {
                                    SessionRowView(session: session)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color(.systemBackground))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .contextMenu {
                                    Button {
                                        renamingSession = session
                                        newName = session.displayName ?? session.beatName
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                }
                            }
                            .onDelete(perform: store.deleteSession)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        
                        // Delete all button
                        if !store.sessions.isEmpty {
                            VStack {
                                Divider()
                                    .padding(.horizontal)
                                
                                Button(role: .destructive) {
                                    showDeleteAllAlert = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Delete All Sessions")
                                            .font(.body.weight(.medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            .background(Color(.systemGroupedBackground))
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete All Sessions?", isPresented: $showDeleteAllAlert) {
            Button("Delete All", role: .destructive) {
                store.deleteAllSessions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your recorded sessions. This action cannot be undone.")
        }
        .sheet(item: $renamingSession) { session in
            RenameSessionView(
                session: session,
                newName: $newName,
                onSave: { store.renameSession(session, newName: newName) },
                onCancel: { renamingSession = nil }
            )
        }
        .sheet(item: $selectedSession) { session in
            SessionAudioPlayerView(session: session)
        }
    }
}

struct SessionRowView: View {
    let session: SessionModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            // Vibrant audio icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 54, height: 54)
                Circle()
                    .strokeBorder(LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 2)
                    .frame(width: 54, height: 54)
                Image(systemName: "waveform")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            // Session info
            VStack(alignment: .leading, spacing: 6) {
                Text(session.displayName ?? session.beatName)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(session.scale)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "metronome")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(session.bpm) BPM")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Text(session.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 90, maxHeight: 100, alignment: .center)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LinearGradient(
                    colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1.5)
        )
        .padding(.vertical, 4)
    }
}

struct RenameSessionView: View {
    let session: SessionModel
    @Binding var newName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Rename Session")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter session name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .font(.body)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSave()
                        onCancel()
                    }) {
                        Text("Save")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListView()
    }
}
