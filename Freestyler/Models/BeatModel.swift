import Foundation

struct BeatModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let scale: String
    let bpm: Int
    let fileName: String // Name of the local audio file (e.g., "beat1.mp3")
} 