import SwiftUI
import Foundation
import Combine
import struct Freestyler.Constants

struct ChatBubbleView: View {
    let message: ChatMessage
    @Namespace private var bubbleNamespace
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 80)
                messageContent
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                messageContent
                Spacer(minLength: 80)
            }
        }
        .padding(.horizontal, 20)
        .matchedGeometryEffect(id: message.id, in: bubbleNamespace)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .font(.system(size: 16, weight: .regular, design: .default))
                .lineSpacing(2)
                .foregroundColor(message.isUser ? .white : .primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if message.isUser {
                            LinearGradient(
                                colors: [.purple, .blue],
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
                    color: message.isUser ? .purple.opacity(0.2) : .black.opacity(0.06),
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

// MARK: - Chat Header
struct ChatHeaderView: View {
    var isLoading: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rap Buddy")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isLoading ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isLoading ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)
                        Text(isLoading ? "Thinking..." : "Online")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
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
                    colors: [Color(.separator).opacity(0.3), Color(.separator).opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
        }
    }
}

// MARK: - Chat Messages List
struct ChatMessagesListView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    @Namespace private var bubbleNamespace
    @State private var lastMessageId: UUID? = nil

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                                .matchedGeometryEffect(id: message.id, in: bubbleNamespace)
                                .transition(.asymmetric(
                                    insertion: .move(edge: message.isUser ? .trailing : .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 0.95))
                                ))
                        }
                        if isLoading {
                            ChatLoadingIndicator()
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(.vertical, 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: messages)
                    .onChange(of: messages) { newMessages in
                        if let last = newMessages.last?.id {
                            withAnimation(.easeOut(duration: 0.6)) {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let last = messages.last?.id {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemGroupedBackground),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - Chat Loading Indicator
struct ChatLoadingIndicator: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(.tertiaryLabel))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .opacity(animate ? 0.8 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animate
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
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

struct RapBuddyChatView: View {
    @StateObject private var viewModel = RapBuddyChatViewModel.shared
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView(isLoading: viewModel.isLoading)
            ChatMessagesListView(messages: viewModel.messages, isLoading: viewModel.isLoading)
            ChatInputBar(
                inputText: $viewModel.inputText,
                isLoading: viewModel.isLoading,
                onSend: sendMessage,
                isInputFocused: $isInputFocused
            )
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.purple.opacity(0.02),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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
        
        let maxHistory = 8
        let recentMessages = viewModel.messages.suffix(maxHistory)
        let messagesForAPI = recentMessages.map { ["role": $0.isUser ? "user" : "assistant", "content": $0.text] }
        let body: [String: Any] = [
            "model": "deepseek/deepseek-r1-0528:free",
            "messages": messagesForAPI,
            "max_tokens": 768,
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
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 500 {
                    self.viewModel.errorMessage = "Sorry, the server is busy or encountered an error. Please try again in a moment."
                    self.viewModel.isLoading = false
                    return
                }
                
                guard let data = data else {
                    self.viewModel.errorMessage = "No response received from server."
                    return
                }
                
                print("API raw response: ", String(data: data, encoding: .utf8) ?? "<nil>")
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        let rawContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        let summarizedContent: String
                        if rawContent.count > 500 {
                            let index = rawContent.index(rawContent.startIndex, offsetBy: 500)
                            summarizedContent = String(rawContent[..<index]) + "..."
                        } else {
                            summarizedContent = rawContent
                        }
                        let responseMessage = ChatMessage(text: summarizedContent, isUser: false)
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
