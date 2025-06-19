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

    var body: some View {
        VStack(spacing: 32) {
            Text(session.displayName ?? session.beatName)
                .font(.title2.bold())
                .padding(.top, 40)
            Text("File: \(session.vocalFileName)")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 40) {
                Button(action: {
                    if isPlaying {
                        pause()
                    } else {
                        play()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.blue)
                }
            }
            Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                if !editing {
                    audioPlayer?.currentTime = currentTime
                }
            })
            .padding(.horizontal, 24)
            .accentColor(.blue)
            Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            Spacer()
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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.sessions) { session in
                    NavigationLink(destination: SessionAudioPlayerView(session: session)) {
                        VStack(alignment: .leading) {
                            Text(session.displayName ?? session.beatName)
                                .font(.headline)
                            Text("\(session.scale), \(session.bpm) BPM")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(session.timestamp, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .contextMenu {
                            Button("Rename") {
                                renamingSession = session
                                newName = session.displayName ?? session.beatName
                            }
                        }
                    }
                }
                .onDelete(perform: store.deleteSession)
            }
            .navigationTitle("Sessions")
        }
        .sheet(item: $renamingSession) { session in
            VStack(spacing: 20) {
                Text("Rename Session")
                    .font(.headline)
                TextField("Session Name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save") {
                    store.renameSession(session, newName: newName)
                    renamingSession = nil
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel") {
                    renamingSession = nil
                }
            }
            .padding()
        }
    }
}

struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListView()
    }
} 
