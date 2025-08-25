import SwiftUI
import Photos
import Speech

struct PhotoSearchTestView: View {
    @StateObject private var photoSearchService = PhotoSearchServiceEnhanced()
    @StateObject private var voiceService = VoiceAgentService()
    @State private var isListening = false
    @State private var searchQuery = ""
    @State private var searchResults: [PHAsset] = []
    @State private var isSearching = false
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Voice Input Section
                VStack(spacing: 15) {
                    // Microphone Button
                    Button(action: {
                        if isListening {
                            stopListening()
                        } else {
                            startListening()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isListening ? Color.red : Color.blue)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: isListening ? "mic.fill" : "mic")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .scaleEffect(isListening ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
                        }
                    }
                    
                    Text(isListening ? "Listening..." : "Tap to search photos")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Search Query Display
                    if !searchQuery.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Search query:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(searchQuery)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                
                Divider()
                
                // Results Section
                if isSearching {
                    ProgressView("Searching photos...")
                        .padding()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No photos found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Try more specific queries:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• \"photos from yesterday\"\n• \"selfies from last month\"\n• \"screenshots\"\n• \"videos at beach\"\n• \"favorites\"\n• \"panorama photos\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if !searchResults.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(searchResults, id: \.localIdentifier) { asset in
                                PhotoThumbnailView(asset: asset)
                                    .frame(height: 120)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Manual Search Bar (for testing)
                HStack {
                    TextField("Or type to search...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchPhotos()
                        }
                    
                    Button("Search") {
                        searchPhotos()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Photo Search Test")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearSearch()
                    }
                }
            }
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("OK") { }
            } message: {
                Text(permissionMessage)
            }
            .onAppear {
                requestPermissions()
            }
        }
    }
    
    private func startListening() {
        isListening = true
        voiceService.startListening { transcribedText in
            self.searchQuery = transcribedText
            
            // Auto-search after a pause in speech
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !transcribedText.isEmpty && self.isListening {
                    self.stopListening()
                    self.searchPhotos()
                }
            }
        }
    }
    
    private func stopListening() {
        isListening = false
        voiceService.stopListening()
    }
    
    private func searchPhotos() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        
        photoSearchService.searchPhotos(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchResults = []
        isListening = false
        voiceService.stopListening()
    }
    
    private func requestPermissions() {
        // Request photo library permission
        photoSearchService.requestPhotoLibraryAccess { granted in
            if !granted {
                self.permissionMessage = "Photo library access is required to search photos."
                self.showPermissionAlert = true
            }
        }
        
        // Request microphone permission
        voiceService.requestMicrophonePermission()
    }
}

// Photo Thumbnail View
struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.image = image
        }
    }
}