import Foundation

struct BeatModel: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let scale: String
    let bpm: Int
    let fileUrl: String? // URL to the beat file on the backend
    // Optionally keep fileName for local fallback
    let fileName: String? 
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, scale, bpm, fileUrl, fileName
    }
} 