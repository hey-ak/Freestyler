import Foundation

class SettingsModel: ObservableObject {
    static let shared = SettingsModel()
    @Published var metronomeOn: Bool {
        didSet { UserDefaults.standard.set(metronomeOn, forKey: "metronomeOn") }
    }
    @Published var countdownLength: Int {
        didSet { UserDefaults.standard.set(countdownLength, forKey: "countdownLength") }
    }
    @Published var metronomeVolume: Double {
        didSet { UserDefaults.standard.set(metronomeVolume, forKey: "metronomeVolume") }
    }
    @Published var metronomeSound: String {
        didSet { UserDefaults.standard.set(metronomeSound, forKey: "metronomeSound") }
    }
    
    private init() {
        self.metronomeOn = UserDefaults.standard.object(forKey: "metronomeOn") as? Bool ?? true
        self.countdownLength = UserDefaults.standard.object(forKey: "countdownLength") as? Int ?? 3
        self.metronomeVolume = UserDefaults.standard.object(forKey: "metronomeVolume") as? Double ?? 0.7
        self.metronomeSound = UserDefaults.standard.string(forKey: "metronomeSound") ?? "metronome.mp3"
    }
} 