import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    
    init(id: UUID = UUID(), text: String, isUser: Bool) {
        self.id = id
        self.text = text
        self.isUser = isUser
    }
}

class RapBuddyChatViewModel: ObservableObject {
    static let shared = RapBuddyChatViewModel()
    
    @Published var messages: [ChatMessage] = [
        ChatMessage(text: "Hey! I'm your Rap Buddy. Ask me anything about rapping, lyrics, flow, or even get feedback on your bars!", isUser: false)
    ]
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private init() {}
    
    func reset() {
        DispatchQueue.main.async {
            self.messages = [
                ChatMessage(text: "Hey! I'm your Rap Buddy. Ask me anything about rapping, lyrics, flow, or even get feedback on your bars!", isUser: false)
            ]
            self.inputText = ""
            self.isLoading = false
            self.errorMessage = nil
        }
    }
} 