import Foundation
import AVFoundation
import Combine

class MetronomeManager: ObservableObject {
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    @Published var isTicking: Bool = false
    var onTick: (() -> Void)?
    private var settings = SettingsModel.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        settings.$metronomeBPM
            .sink { [weak self] newBPM in
                guard let self = self, self.isTicking else { return }
                self.start(bpm: newBPM)
            }
            .store(in: &cancellables)
        // Optionally observe time signature for future use
        settings.$metronomeTimeSignature
            .sink { [weak self] newSignature in
                // Future: update metronome pattern if needed
            }
            .store(in: &cancellables)
    }
    
    func start(bpm: Int? = nil) {
        stop()
        let bpmToUse = bpm ?? settings.metronomeBPM
        let interval = 60.0 / Double(bpmToUse)
        DispatchQueue.main.async {
            self.isTicking = true
        }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playClick()
            self?.onTick?()
        }
        // Play first click immediately
        playClick()
        onTick?()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        DispatchQueue.main.async {
            self.isTicking = false
        }
    }
    
    private func playClick() {
        guard let url = Bundle.main.url(forResource: "metronome", withExtension: "mp3") else {
            print("Metronome sound not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play metronome click: \(error)")
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 