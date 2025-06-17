import SwiftUI

struct SessionView: View {
    @ObservedObject var recordingManager: RecordingManager
    var onStop: () -> Void
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Recording...")
                .font(.title)
                .bold()
            
            // Live Timer
            Text(timeString(from: elapsedTime))
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }
            
            // Mic Indicator
            Image(systemName: "mic.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.red)
                .scaleEffect(recordingManager.isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingManager.isRecording)
            
            // Placeholder for beat waveform
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 60)
                .overlay(Text("[Beat Waveform]").foregroundColor(.gray))
            
            Button(action: {
                onStop()
            }) {
                Text("Stop Recording")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func startTimer() {
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(recordingManager: RecordingManager(), onStop: {})
    }
} 