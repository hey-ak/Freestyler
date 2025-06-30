import Foundation
import AVFoundation
//
//class RecordingManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
//    private var audioRecorder: AVAudioRecorder?
//    @Published var isRecording: Bool = false
//    @Published var recordedFileURL: URL?
//    
//    func startRecording() {
//        let session = AVAudioSession.sharedInstance()
//        do {
//            try session.setCategory(.playAndRecord, mode: .default)
//            try session.setActive(true)
//            let settings: [String: Any] = [
//                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//                AVSampleRateKey: 44100,
//                AVNumberOfChannelsKey: 1,
//                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//            ]
//            let fileName = "vocal_\(timestampString()).m4a"
//            let url = getDocumentsDirectory().appendingPathComponent(fileName)
//            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
//            audioRecorder?.delegate = self
//            audioRecorder?.record()
//            isRecording = true
//            recordedFileURL = url
//        } catch {
//            print("Failed to start recording: \(error)")
//            isRecording = false
//        }
//    }
//    
//    func stopRecording() {
//        audioRecorder?.stop()
//        isRecording = false
//        audioRecorder = nil
//        if let url = recordedFileURL {
//            // Create a new session and add to SessionStore
//            let session = SessionModel(
//                beatName: "Custom Beat", // TODO: Pass actual beat name
//                beatFileName: "", // TODO: Pass actual beat file name
//                vocalFileName: url.lastPathComponent,
//                scale: "", // TODO: Pass actual scale
//                bpm: 0, // TODO: Pass actual bpm
//                duration: 0, // TODO: Calculate duration if possible
//                timestamp: Date(),
//                displayName: nil
//            )
//            let store = SessionStore()
//            store.addSession(session)
//        }
//    }
//    
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//    
//    private func timestampString() -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyyMMdd_HHmmss"
//        return formatter.string(from: Date())
//    }
//} 

class RecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordedFileURL: URL?
    @Published var recordingLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var levelTimer: Timer?
    private var isPaused = false
    
    init() {
        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true)
            
            recordingSession?.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Recording permission denied")
                    }
                }
            }
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.isPaused = false
                self.recordedFileURL = audioURL
            }
            startLevelMonitoring()
            
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        DispatchQueue.main.async {
            self.isPaused = true
        }
        stopLevelMonitoring()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        DispatchQueue.main.async {
            self.isPaused = false
        }
        startLevelMonitoring()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
            self.isPaused = false
        }
        stopLevelMonitoring()
    }
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let normalizedLevel = max(0, (level + 60) / 60) // Normalize to 0-1
            
            DispatchQueue.main.async {
                self.recordingLevel = normalizedLevel
            }
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        DispatchQueue.main.async {
            self.recordingLevel = 0.0
        }
    }
}
