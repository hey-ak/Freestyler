import SwiftUI

struct CountdownView: View {
    @Binding var isShowing: Bool
    var seconds: Int = 3
    var onComplete: () -> Void
    @State private var count: Int = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        if isShowing {
            ZStack {
                // Themed gradient background for the overlay
                LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.5), Color.blue.opacity(0.5)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                Text("\(count)")
                    .font(.system(size: 150, weight: .heavy))
                    .foregroundColor(.clear) // Make text clear to apply gradient overlay
                    .overlay(
                        // NEW: Darker gradient for the numbers
                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9), Color.black]),
                                       startPoint: .top,
                                       endPoint: .bottom)
                        .mask(
                            Text("\(count)")
                                .font(.system(size: 150, weight: .heavy))
                        )
                    )
                    // Enhanced shadow for maximum visibility
                    .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5), value: scale)
                    .animation(.easeInOut(duration: 0.3), value: opacity)
                    .onAppear {
                        startCountdown()
                    }
            }
            .transition(.opacity)
        }
    }
    
    private func startCountdown() {
        count = seconds
        scale = 0.5
        opacity = 0.0
        
        var timer: DispatchSourceTimer?
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        
        timer?.setEventHandler {
            DispatchQueue.main.async {
                if count > 0 {
                    // Animate the number appearance
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    // Animate the number disappearance and reset for the next number
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = 0.5
                            opacity = 0.0
                        }
                    }
                    count -= 1
                } else {
                    timer?.cancel()
                    isShowing = false
                    onComplete()
                }
            }
        }
        timer?.resume()
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(isShowing: .constant(true), seconds: 3) {}
    }
}
