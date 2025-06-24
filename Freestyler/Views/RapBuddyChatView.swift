import SwiftUI
import Foundation
import Combine
import struct Freestyler.Constants

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 80)
                messageContent
            } else {
                // AI Avatar - More professional design
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.9),
                            Color(red: 0.1, green: 0.3, blue: 0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
                
                messageContent
                Spacer(minLength: 80)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .font(.system(size: 16, weight: .regular, design: .default))
                .lineSpacing(2)
                .foregroundColor(message.isUser ? .white : Color(.label))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if message.isUser {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.4, blue: 0.9),
                                    Color(red: 0.3, green: 0.2, blue: 0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(.secondarySystemGroupedBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(
                    color: message.isUser
                        ? Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.2)
                        : Color.black.opacity(0.06),
                    radius: message.isUser ? 12 : 8,
                    x: 0,
                    y: message.isUser ? 6 : 3
                )
        }
    }
}

struct ChatInputBar: View {
    @Binding var inputText: String
    var isLoading: Bool
    var onSend: () -> Void
    @FocusState.Binding var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional divider
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.separator).opacity(0.3),
                        Color(.separator).opacity(0.1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
            
            HStack(spacing: 14) {
                // Enhanced input field container
                HStack(spacing: 10) {
                    TextField("Message Rap Buddy", text: $inputText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(Color(.label))
                        .focused($isInputFocused)
                        .disabled(isLoading)
                        .onSubmit { onSend() }
                        .lineLimit(1...5)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .strokeBorder(
                                    isInputFocused
                                        ? Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.4)
                                        : Color(.separator).opacity(0.2),
                                    lineWidth: isInputFocused ? 2 : 1
                                )
                        )
                )
                .shadow(
                    color: isInputFocused
                        ? Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.1)
                        : Color.black.opacity(0.03),
                    radius: isInputFocused ? 8 : 4,
                    x: 0,
                    y: 2
                )
                .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                
                // Professional send button
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors:
                                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                        ? [Color(.quaternaryLabel), Color(.quaternaryLabel)]
                                        : [Color(red: 0.2, green: 0.4, blue: 0.9), Color(red: 0.3, green: 0.2, blue: 0.8)]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(
                                color: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                ? .clear
                                : Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.3),
                                radius: 8, x: 0, y: 4
                            )
                        
                        Image(systemName: isLoading ? "stop.fill" : "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(isLoading ? 0.85 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            )
        }
    }
}

struct RapBuddyChatView: View {
    @StateObject private var viewModel = RapBuddyChatViewModel.shared
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional header
            headerView
            
            // Enhanced chat messages area
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isUser ? .trailing : .leading)
                                            .combined(with: .opacity)
                                            .combined(with: .scale(scale: 0.95)),
                                        removal: .opacity.combined(with: .scale(scale: 0.95))
                                    ))
                            }
                            
                            // Enhanced loading indicator
                            if viewModel.isLoading {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.4, blue: 0.9),
                                                Color(red: 0.1, green: 0.3, blue: 0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                        .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    HStack(spacing: 6) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color(.tertiaryLabel))
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(viewModel.isLoading ? 1.2 : 0.8)
                                                .opacity(viewModel.isLoading ? 0.8 : 0.4)
                                                .animation(
                                                    .easeInOut(duration: 0.8)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.15),
                                                    value: viewModel.isLoading
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                                        
                                    Spacer(minLength: 80)
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .padding(.vertical, 24)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.messages.count)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.systemGroupedBackground),
                                Color(.systemBackground)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.6)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _ in
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input bar
            ChatInputBar(
                inputText: $viewModel.inputText,
                isLoading: viewModel.isLoading,
                onSend: sendMessage,
                isInputFocused: $isInputFocused
            )
        }
        .navigationTitle("Rap Buddy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Connection Error"),
                message: Text(viewModel.errorMessage ?? "Unable to reach Rap Buddy. Please try again."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Enhanced AI avatar in header
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.9),
                            Color(red: 0.1, green: 0.3, blue: 0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rap Buddy")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(Color(.label))
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isLoading ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(viewModel.isLoading ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
                        
                        Text(viewModel.isLoading ? "Thinking..." : "Online")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            )
            
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.separator).opacity(0.3),
                        Color(.separator).opacity(0.1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
        }
    }
    
    private func sendMessage() {
        let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewModel.messages.append(userMessage)
        }
        
        viewModel.inputText = ""
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        callOpenRouter(with: trimmed)
    }
    
    private func callOpenRouter(with prompt: String) {
        let apiKey = DEEPSEEK_API_KEY
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            self.viewModel.errorMessage = "Invalid API URL."
            self.viewModel.isLoading = false
            return
        }
        
        let messagesForAPI = viewModel.messages.map { ["role": $0.isUser ? "user" : "assistant", "content": $0.text] }
        let body: [String: Any] = [
            "model": "deepseek/deepseek-r1-0528:free",
            "messages": messagesForAPI,
            "max_tokens": 256,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://freestyler.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Freestyler iOS App", forHTTPHeaderField: "X-Title")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                
                if let error = error {
                    self.viewModel.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.viewModel.errorMessage = "No response received from server."
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        let responseMessage = ChatMessage(text: content.trimmingCharacters(in: .whitespacesAndNewlines), isUser: false)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            self.viewModel.messages.append(responseMessage)
                        }
                        
                        // Success haptic feedback
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                        
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let errorDict = json["error"] as? [String: Any],
                              let message = errorDict["message"] as? String {
                        self.viewModel.errorMessage = "API Error: \(message)"
                    } else {
                        self.viewModel.errorMessage = "Unexpected response format from server."
                    }
                } catch {
                    self.viewModel.errorMessage = "Failed to parse server response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
