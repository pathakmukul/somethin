import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var voiceAgent = VoiceAgentService()
    @State private var isListening = false
    @State private var transcribedText = ""
    @State private var agentResponse = ""
    @State private var showingWaveform = false
    @State private var showPhotoSearch = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                VStack(spacing: 10) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(isListening ? .red : .blue)
                        .scaleEffect(showingWaveform ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showingWaveform)
                    
                    Text(isListening ? "Listening..." : "Tap to speak")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("You said:", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            Text(transcribedText.isEmpty ? "Your speech will appear here..." : transcribedText)
                                .font(.body)
                                .foregroundColor(transcribedText.isEmpty ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Agent response:", systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            Text(agentResponse.isEmpty ? "Agent response will appear here..." : agentResponse)
                                .font(.body)
                                .foregroundColor(agentResponse.isEmpty ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .frame(height: 100)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        if isListening {
                            stopListening()
                        } else {
                            startListening()
                        }
                    }) {
                        HStack {
                            Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            Text(isListening ? "Stop" : "Start")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(isListening ? Color.red : Color.blue)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        clearConversation()
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Voice Agent")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PhotoSearchTestView()) {
                        Label("Photo Search", systemImage: "photo.stack")
                    }
                }
            }
            .onAppear {
                voiceAgent.requestMicrophonePermission()
            }
        }
    }
    
    private func startListening() {
        isListening = true
        showingWaveform = true
        voiceAgent.startListening { text in
            self.transcribedText = text
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.agentResponse = "Processing your request..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.agentResponse = "Voice agent service will be implemented here. Your message: '\(self.transcribedText)'"
        }
    }
    
    private func stopListening() {
        isListening = false
        showingWaveform = false
        voiceAgent.stopListening()
    }
    
    private func clearConversation() {
        transcribedText = ""
        agentResponse = ""
        isListening = false
        showingWaveform = false
        voiceAgent.stopListening()
    }
}