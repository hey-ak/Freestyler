import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @EnvironmentObject var sessionManager: UserSessionManager
    
    var body: some View {
        Form {
            if let username = sessionManager.username, let email = sessionManager.email {
                Section {
                    VStack(spacing: 12) {
                        // Profile Image (placeholder)
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)
                        // Username
                        Text(username)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        // Email
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }
            }
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            Section(header: Text("Countdown Length")) {
                Picker("Countdown", selection: $settings.countdownLength) {
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("Sessions")) {
                NavigationLink(destination: SessionListView()) {
                    Label("View Recorded Sessions", systemImage: "music.note.list")
                }
            }
            Section {
                Button(role: .destructive) {
                    sessionManager.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(UserSessionManager())
    }
} 
