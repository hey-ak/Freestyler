import SwiftUI
import PhotosUI
import Combine

// MARK: - Custom Image Cache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {}
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: () -> AnyView
    let image: (Image) -> AnyView
    @State private var loadedImage: UIImage?
    @State private var cancellable: AnyCancellable?

    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                image(Image(uiImage: loadedImage))
            } else {
                placeholder()
                    .onAppear(perform: load)
            }
        }
    }

    private func load() {
        guard let url = url else { return }
        if let cached = ImageCache.shared.image(forKey: url.absoluteString) {
            loadedImage = cached
            return
        }
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { image in
                if let image = image {
                    ImageCache.shared.setImage(image, forKey: url.absoluteString)
                    loadedImage = image
                }
            }
    }
}

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
    @State private var showRapBuddy = false
    let timeSignatures = ["4/4", "3/4", "2/4", "6/8"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Profile Section
                    if let username = sessionManager.username, let email = sessionManager.email {
                        profileSection(username: username, email: email)
                            .padding(.bottom, 8)
                    }
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        appearanceSection
                        countdownSection
                        metronomeSection
                        sessionsSection
                        rapBuddySection
                        logoutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
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
                DispatchQueue.main.async {
                    isUploading = false
                    if success {
                        selectedUIImage = nil // Clear picker
                        sessionManager.fetchProfile() // Refresh from backend
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Section
    @ViewBuilder
    private func profileSection(username: String, email: String) -> some View {
        VStack(spacing: 0) {
            // Remove background gradient and overlay
            // Only show profile image and user info
            VStack(spacing: 20) {
                // Profile Image with enhanced styling
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            Color.accentColor.opacity(0.3),
                            lineWidth: 3
                        )
                        .frame(width: 114, height: 114)
                    
                    // Remove main circle background
                    // Only show image or placeholder
                    if let imageUrl = sessionManager.profileImage, let url = URL(string: imageUrl, relativeTo: URL(string: sessionManager.apiBaseURL)) {
                        CachedAsyncImage(
                            url: url,
                            placeholder: {
                                AnyView(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                        .frame(width: 98, height: 98)
                                )
                            },
                            image: { img in
                                AnyView(
                                    img
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 98, height: 98)
                                        .clipShape(Circle())
                                )
                            }
                        )
                        .id(sessionManager.profileImage ?? "")
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    // Upload overlay
                    if isUploading {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 98, height: 98)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                            .scaleEffect(1.3)
                    }
                    
                    // Camera icon
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .offset(x: -8, y: -8)
                        }
                    }
                    .frame(width: 108, height: 108)
                }
                .onTapGesture {
                    showImagePicker = true
                }
                
                // User info with enhanced typography
                VStack(spacing: 8) {
                    Text(username)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 24) // Add some top padding
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        settingsCard(
            title: "Appearance",
            icon: "paintbrush.pointed.fill",
            iconColor: .orange,
            content: {
                SettingsRow(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    iconColor: isDarkMode ? .indigo : .orange,
                    title: "Dark Mode",
                    trailing: {
                        Toggle("", isOn: $isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                    }
                )
            }
        )
    }
    
    // MARK: - Countdown Section
    private var countdownSection: some View {
        settingsCard(
            title: "Recording",
            icon: "record.circle.fill",
            iconColor: .red,
            content: {
                VStack(spacing: 16) {
                    SettingsRow(
                        icon: "timer",
                        iconColor: .blue,
                        title: "Countdown Duration"
                    )
                    
                    Picker("Countdown", selection: $settings.countdownLength) {
                        Text("3 seconds").tag(3)
                        Text("5 seconds").tag(5)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 4)
                }
            }
        )
    }
    
    // MARK: - Metronome Section
    private var metronomeSection: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showMetronomeSettings = true
            }
        }) {
            settingsCard(
                title: "Metronome",
                icon: "metronome.fill",
                iconColor: .purple,
                content: {
                    SettingsRow(
                        icon: "slider.horizontal.3",
                        iconColor: .purple,
                        title: "Configure Settings",
                        subtitle: "\(settings.metronomeBPM) BPM • \(settings.metronomeTimeSignature)",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMetronomeSettings) {
            metronomeSettingsSheet
        }
    }
    
    // MARK: - Sessions Section
    private var sessionsSection: some View {
        settingsCard(
            title: "Sessions",
            icon: "waveform.circle.fill",
            iconColor: .green,
            content: {
                NavigationLink(destination: SessionListView()) {
                    SettingsRow(
                        icon: "music.note.list",
                        iconColor: .green,
                        title: "View Recorded Sessions",
                        subtitle: "Browse your recordings",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        )
    }
    
    // MARK: - Rap Buddy Section
    private var rapBuddySection: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showRapBuddy = true
            }
        }) {
            settingsCard(
                title: "AI Assistant",
                icon: "brain.head.profile.fill",
                iconColor: .pink,
                content: {
                    SettingsRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: .pink,
                        title: "Rap Buddy",
                        subtitle: "Get AI-powered rap assistance",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(destination: RapBuddyChatView(), isActive: $showRapBuddy) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                sessionManager.logout()
            }
        }) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 1)
                
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sign Out")
                            .font(.body.weight(.medium))
                            .foregroundColor(.red)
                        
                        Text("You'll need to sign in again")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.red.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Metronome Settings Sheet
    private var metronomeSettingsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metronome Settings")
                            .font(.largeTitle.bold())
                        Text("Customize your rhythm companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Volume Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Volume", systemImage: "speaker.wave.2.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.secondary)
                                Slider(value: $metronomeVolume, in: 0...1, step: 0.01)
                                    .tint(Color.accentColor)
                                    .onChange(of: metronomeVolume) { newValue in
                                        settings.metronomeVolume = newValue
                                    }
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("\(Int(metronomeVolume * 100))%")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Tempo Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Tempo", systemImage: "metronome.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BPM")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.secondary)
                                    Text("\(settings.metronomeBPM)")
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if settings.metronomeBPM > 40 {
                                            settings.metronomeBPM -= 1
                                            bpmText = String(settings.metronomeBPM)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.accentColor)
                                    }
                                    .disabled(settings.metronomeBPM <= 40)
                                    
                                    TextField("BPM", text: $bpmText, onCommit: {
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
                                    .multilineTextAlignment(.center)
                                    .font(.body.weight(.medium))
                                    .frame(width: 60)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: bpmText) { newValue in
                                        if let bpm = Int(newValue), bpm >= 40, bpm <= 200 {
                                            settings.metronomeBPM = bpm
                                        }
                                    }
                                    .onChange(of: settings.metronomeBPM) { newValue in
                                        bpmText = String(newValue)
                                    }
                                    
                                    Button(action: {
                                        if settings.metronomeBPM < 200 {
                                            settings.metronomeBPM += 1
                                            bpmText = String(settings.metronomeBPM)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.accentColor)
                                    }
                                    .disabled(settings.metronomeBPM >= 200)
                                }
                            }
                            
                            Text("Range: 40-200 BPM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Time Signature Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Time Signature", systemImage: "music.note")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Picker("Time Signature", selection: $settings.metronomeTimeSignature) {
                            ForEach(timeSignatures, id: \.self) { sig in
                                Text(sig).tag(sig)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showMetronomeSettings = false
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Helper Methods
    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Divider
            Rectangle()
                .fill(.separator.opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, 24)
            
            // Content
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Settings Row Component
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let trailing: () -> Trailing
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
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
