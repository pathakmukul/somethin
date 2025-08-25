import Foundation
import Speech
import AVFoundation

class VoiceAgentService: NSObject, ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isListening = false
    @Published var transcribedText = ""
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    self.requestSpeechRecognitionPermission()
                } else {
                    print("Microphone permission denied")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    self.requestSpeechRecognitionPermission()
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied:
                print("Speech recognition denied")
            case .restricted:
                print("Speech recognition restricted")
            case .notDetermined:
                print("Speech recognition not determined")
            @unknown default:
                print("Unknown speech recognition status")
            }
        }
    }
    
    func startListening(completion: @escaping (String) -> Void) {
        if audioEngine.isRunning {
            stopListening()
            return
        }
        
        do {
            try startRecording(completion: completion)
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    private func startRecording(completion: @escaping (String) -> Void) throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceAgentService", code: 1, userInfo: nil)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.transcribedText = transcription
                completion(transcription)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
    }
    
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
    }
    
    func processWithAgent(_ text: String, completion: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion("Voice agent processing placeholder for: '\(text)'")
        }
    }
}

extension VoiceAgentService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("Speech recognition not available")
        }
    }
}