import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    @Published var isPlaying = false

    func play(fileName: String) {
        stop()
        if let url = URL(string: fileName), url.scheme == "http" || url.scheme == "https" {
            // Remote file: use AVPlayer
            avPlayer = AVPlayer(url: url)
            avPlayer?.play()
            isPlaying = true
        } else {
            // Local file: use AVAudioPlayer
            let url: URL
            if fileName.hasPrefix("/") {
                url = URL(fileURLWithPath: fileName)
            } else {
                url = Bundle.main.url(forResource: fileName, withExtension: nil) ?? URL(fileURLWithPath: fileName)
            }
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("Failed to set up players: \(error)")
                isPlaying = false
            }
        }
    }

    func pause() {
        audioPlayer?.pause()
        avPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer?.stop()
        avPlayer?.pause()
        isPlaying = false
    }
} 