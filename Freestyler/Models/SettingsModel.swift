import Foundation

class SettingsModel: ObservableObject {
    static let shared = SettingsModel()
    @Published var metronomeOn: Bool {
        didSet { UserDefaults.standard.set(metronomeOn, forKey: "metronomeOn") }
    }
    @Published var countdownLength: Int {
        didSet { UserDefaults.standard.set(countdownLength, forKey: "countdownLength") }
    }
    
    private init() {
        self.metronomeOn = UserDefaults.standard.object(forKey: "metronomeOn") as? Bool ?? true
        self.countdownLength = UserDefaults.standard.object(forKey: "countdownLength") as? Int ?? 3
    }
} 