import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @EnvironmentObject var sessionManager: UserSessionManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Profile Section
                if let username = sessionManager.username, let email = sessionManager.email {
                    profileSection(username: username, email: email)
                }
                
                // Settings Sections
                VStack(spacing: 16) {
                    appearanceSection
                    countdownSection
                    sessionsSection
                    logoutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    // MARK: - Profile Section
    @ViewBuilder
    private func profileSection(username: String, email: String) -> some View {
        VStack(spacing: 16) {
            // Profile Image with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.8), .accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text(username)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        settingsCard(title: "Appearance", icon: "paintbrush.fill") {
            HStack {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(isDarkMode ? .purple : .orange)
                    .frame(width: 20)
                
                Text("Dark Mode")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Countdown Section
    private var countdownSection: some View {
        settingsCard(title: "Recording", icon: "timer.circle.fill") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text("Countdown Duration")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Picker("Countdown", selection: $settings.countdownLength) {
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Sessions Section
    private var sessionsSection: some View {
        settingsCard(title: "Sessions", icon: "waveform.circle.fill") {
            NavigationLink(destination: SessionListView()) {
                HStack {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    Text("View Recorded Sessions")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Button(action: {
            sessionManager.logout()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                    .frame(width: 20)
                
                Text("Log Out")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(UserSessionManager())
        }
    }
}
