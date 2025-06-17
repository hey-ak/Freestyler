import Foundation
import AVFoundation

class MetronomeManager: ObservableObject {
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    @Published var isTicking: Bool = false
    var onTick: (() -> Void)?
    
    func start(bpm: Int) {
        stop()
        let interval = 60.0 / Double(bpm)
        isTicking = true
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
        isTicking = false
    }
    
    private func playClick() {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "wav") else {
            print("Metronome click sound not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play metronome click: \(error)")
        }
    }
} 