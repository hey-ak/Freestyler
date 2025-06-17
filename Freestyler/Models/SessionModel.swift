import Foundation

struct SessionModel: Identifiable, Codable, Hashable {
    let id: UUID
    var beatName: String
    var beatFileName: String
    var vocalFileName: String
    var scale: String
    var bpm: Int
    var timestamp: Date
    var displayName: String?
    var duration: TimeInterval // Added duration property

    init(beatName: String, beatFileName: String, vocalFileName: String, scale: String, bpm: Int, duration: TimeInterval, timestamp: Date = Date(), displayName: String? = nil) {
        self.id = UUID()
        self.beatName = beatName
        self.beatFileName = beatFileName
        self.vocalFileName = vocalFileName
        self.scale = scale
        self.bpm = bpm
        self.timestamp = timestamp
        self.displayName = displayName
        self.duration = duration // Initialize duration
    }

    // You might also want a convenience initializer if the duration can be derived later
    // or if you want to create a dummy for previews without needing a duration
    init(beatName: String, beatFileName: String, vocalFileName: String, scale: String, bpm: Int, timestamp: Date = Date(), displayName: String? = nil) {
        self.id = UUID()
        self.beatName = beatName
        self.beatFileName = beatFileName
        self.vocalFileName = vocalFileName
        self.scale = scale
        self.bpm = bpm
        self.timestamp = timestamp
        self.displayName = displayName
        self.duration = 0.0 // Default or placeholder, should be updated when known
    }
}
