import SwiftUI

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

struct SessionListView: View {
    @StateObject private var store = SessionStore()
    @State private var renamingSession: SessionModel?
    @State private var newName: String = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.sessions) { session in
                    NavigationLink(destination: SessionPlayerView(session: session)) {
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
