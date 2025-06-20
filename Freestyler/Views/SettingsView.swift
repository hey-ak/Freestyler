import SwiftUI
import PhotosUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsModel.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @EnvironmentObject var sessionManager: UserSessionManager
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage?
    @State private var isUploading = false
    @State private var metronomeVolume: Double = SettingsModel.shared.metronomeVolume
    @State private var metronomeSound: String = SettingsModel.shared.metronomeSound
    @State private var showMetronomeSettings = false
    @State private var bpmText: String = String(SettingsModel.shared.metronomeBPM)
    let timeSignatures = ["4/4", "3/4", "2/4", "6/8"]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Profile Section
                if let username = sessionManager.username, let email = sessionManager.email {
                    profileSection(username: username, email: email)
                }
                
                // Settings Sections
                VStack(spacing: 16) {
                    appearanceSection
                    countdownSection
                    metronomeSection
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedUIImage)
        }
        .onChange(of: selectedUIImage) { newImage in
            guard let image = newImage, let data = image.jpegData(compressionQuality: 0.8) else { return }
            isUploading = true
            sessionManager.uploadProfileImage(imageData: data) { success in
                isUploading = false
                if success {
                    selectedUIImage = nil // Clear picker
                    sessionManager.fetchProfile() // Refresh from backend
                }
            }
        }
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
                if let imageUrl = sessionManager.profileImage, let url = URL(string: imageUrl, relativeTo: URL(string: sessionManager.apiBaseURL)) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        } else {
                            ProgressView()
                                .frame(width: 90, height: 90)
                        }
                    }
                    .id(sessionManager.profileImage ?? "")
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }
                if isUploading {
                    ProgressView()
                        .frame(width: 90, height: 90)
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .onTapGesture {
                showImagePicker = true
            }
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
    
    // MARK: - Metronome Section
    private var metronomeSection: some View {
        Button(action: { showMetronomeSettings = true }) {
            settingsCard(title: "Metronome Settings", icon: "metronome") {
                HStack {
                    Image(systemName: "metronome")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Metronome")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMetronomeSettings) {
            NavigationView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Metronome Settings")
                        .font(.title2.bold())
                        .padding(.top)
                    // Volume
                    VStack(alignment: .leading) {
                        Text("Volume")
                            .font(.headline)
                        Slider(value: $metronomeVolume, in: 0...1, step: 0.01) {
                            Text("Metronome Volume")
                        }
                        .onChange(of: metronomeVolume) { newValue in
                            settings.metronomeVolume = newValue
                        }
                        Text(String(format: "%.0f%%", metronomeVolume * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // Tempo (BPM)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tempo (BPM)")
                            .font(.headline)
                        HStack {
                            Stepper(value: $settings.metronomeBPM, in: 40...200, step: 1) {
                                Text("\(settings.metronomeBPM) BPM")
                            }
                            Spacer()
                            TextField("", text: $bpmText, onCommit: {
                                if let bpm = Int(bpmText), bpm >= 40, bpm <= 200 {
                                    settings.metronomeBPM = bpm
                                } else if let bpm = Int(bpmText), bpm < 40 {
                                    settings.metronomeBPM = 40
                                    bpmText = "40"
                                } else if let bpm = Int(bpmText), bpm > 200 {
                                    settings.metronomeBPM = 200
                                    bpmText = "200"
                                } else {
                                    bpmText = String(settings.metronomeBPM)
                                }
                            })
                            .keyboardType(.numberPad)
                            .frame(width: 70)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: bpmText) { newValue in
                                if let bpm = Int(newValue), bpm >= 40, bpm <= 200 {
                                    settings.metronomeBPM = bpm
                                }
                            }
                            .onChange(of: settings.metronomeBPM) { newValue in
                                bpmText = String(newValue)
                            }
                        }
                    }
                    // Time Signature
                    VStack(alignment: .leading) {
                        Text("Time Signature")
                            .font(.headline)
                        Picker("Time Signature", selection: $settings.metronomeTimeSignature) {
                            ForEach(timeSignatures, id: \.self) { sig in
                                Text(sig).tag(sig)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showMetronomeSettings = false }
                    }
                }
            }
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

// MARK: - UIKit ImagePicker bridge
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
