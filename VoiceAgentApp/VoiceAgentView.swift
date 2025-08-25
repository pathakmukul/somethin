import SwiftUI
import Photos
import UserNotifications

struct VoiceAgentView: View {
    @StateObject private var vapiService = VAPIService()
    @StateObject private var toolExecutor = LocalToolExecutor()
    
    @State private var showingPhotos = false
    @State private var photoResults: [PHAsset] = []
    @State private var showingNotes = false
    @State private var recentNotes: [Note] = []
    @State private var isLoadingNotes = false
    @State private var isProcessing = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black base background
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Status Header
                    statusHeader
                    
                    // Video Player - switches between idle and talk
                    VideoPlayerView(isAgentActive: Binding(
                        get: { vapiService.isListening || vapiService.isAgentSpeaking },
                        set: { _ in }
                    ))
                    .frame(height: 390)
                    .cornerRadius(20)
                    .padding([.horizontal, .top])
                    
                    Spacer()
                    
                    // Compact faded logs
                    compactLogsView
                    
                    // Control Buttons with record button
                    controlButtons
                }
                .padding()
                
                // Gradient overlay on top of everything - enhanced colors
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.4), // Vibrant purple
                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3), // Electric blue
                        Color.clear,
                        Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.2)  // Hot pink accent
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allow touches to pass through
            }
            .navigationTitle("Somethin'")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingPhotos.toggle() }) {
                            HStack {
                                Image(systemName: "photo.stack.fill")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], 
                                                     startPoint: .leading, 
                                                     endPoint: .trailing)
                                    )
                                Text("Photos")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Button(action: { showingNotes.toggle() }) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], 
                                                     startPoint: .leading, 
                                                     endPoint: .trailing)
                                    )
                                Text("Notes")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { showingSettings.toggle() }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], 
                                                     startPoint: .leading, 
                                                     endPoint: .trailing)
                                    )
                                Text("Settings")
                                    .foregroundColor(.primary)
                            }
                        }
                    } label: {
                        ZStack {
                            // Gradient background circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.7), .blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            // Modern menu icon
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPhotos) {
                PhotoResultsView(assets: photoResults)
            }
            .sheet(isPresented: $showingNotes) {
                NotesListView(notes: recentNotes)
                    .onAppear {
                        Task {
                            await fetchNotesFromConvex()
                        }
                    }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                setupNotifications()
                requestAllPermissions()
                Task {
                    await fetchNotesFromConvex()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            if vapiService.currentToolCall != nil {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(vapiService.currentToolCall ?? "")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch vapiService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch vapiService.connectionStatus {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Tap to start"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var compactLogsView: some View {
        VStack(spacing: 12) {
            // User message (show when user is/was speaking)
            if !vapiService.transcript.isEmpty {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if vapiService.isSpeaking {
                        // Show animated dots when user is actively speaking
                        HStack(spacing: 2) {
                            Text(vapiService.transcript)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text("...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(vapiService.transcript)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Agent response (show when agent is speaking)
            if !vapiService.agentResponse.isEmpty && !vapiService.isSpeaking {
                HStack {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                    
                    if vapiService.isAgentSpeaking {
                        // Show with higher opacity when agent is actively speaking
                        Text(vapiService.agentResponse)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(vapiService.agentResponse)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vapiService.transcript)
        .animation(.easeInOut(duration: 0.3), value: vapiService.agentResponse)
        .animation(.easeInOut(duration: 0.2), value: vapiService.isSpeaking)
        .animation(.easeInOut(duration: 0.2), value: vapiService.isAgentSpeaking)
    }
    
    private var voiceVisualization: some View {
        ZStack {
            // Outer ring animation
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 150, height: 150)
                .scaleEffect(vapiService.isListening ? 1.2 : 1.0)
                .opacity(vapiService.isListening ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: vapiService.isListening)
            
            // Center button
            Button(action: toggleListening) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: vapiService.isListening ? [.red, .orange] : [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: vapiService.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(vapiService.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vapiService.isListening)
                }
            }
            .disabled(isProcessing)
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Clear button
            Button(action: clearConversation) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            .disabled(vapiService.isListening)
            
            Spacer()
            
            // Record button in center with original animations but smaller
            ZStack {
                // Outer ring animation
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0), // Electric blue
                                Color(red: 0.4, green: 0.2, blue: 0.8), // Vibrant purple
                                Color(red: 1.0, green: 0.3, blue: 0.5)  // Hot pink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(vapiService.isListening ? 1.2 : 1.0)
                    .opacity(vapiService.isListening ? 0.8 : 0.4)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: vapiService.isListening)
                
                // Center button
                Button(action: toggleListening) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: vapiService.isListening ? 
                                        [Color(red: 1.0, green: 0.2, blue: 0.4), Color(red: 1.0, green: 0.5, blue: 0.2)] : 
                                        [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.4, green: 0.2, blue: 0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: vapiService.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                            .scaleEffect(vapiService.isListening ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: vapiService.isListening)
                    }
                }
                .disabled(isProcessing)
            }
            
            Spacer()
            
            // Example commands
            Menu {
                Button("Search sunset photos") {
                    simulateCommand("Show me sunset photos")
                }
                Button("Create a note") {
                    let shortcutName = "VoiceAgent_CreateNote"
                    let noteContent = "Test Note\n\nThis is a test note created at \(Date())"
                    
                    // First try to run the shortcut
                    var runComponents = URLComponents(string: "shortcuts://x-callback-url/run-shortcut")!
                    runComponents.queryItems = [
                        URLQueryItem(name: "name", value: shortcutName),
                        URLQueryItem(name: "input", value: "text"),
                        URLQueryItem(name: "text", value: noteContent),
                        URLQueryItem(name: "x-success", value: "voiceagentapp://"),
                        URLQueryItem(name: "x-error", value: "shortcuts://create-shortcut?name=\(shortcutName)&actions=CreateNote")
                    ]
                    
                    if let url = runComponents.url {
                        UIApplication.shared.open(url, options: [:]) { success in
                            if !success {
                                // If shortcut doesn't exist, create it
                                if let createURL = URL(string: "https://www.icloud.com/shortcuts/aa1c7e8e5f5f4a8b9c3d5e6f7g8h9i0j") {
                                    // This would be a real shortcut template URL
                                    UIApplication.shared.open(createURL)
                                }
                            }
                        }
                    }
                }
                Button("Play music") {
                    simulateCommand("Play some relaxing music")
                }
            } label: {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
    
    
    // MARK: - Actions
    
    private func toggleListening() {
        if vapiService.isListening {
            vapiService.stopConversation()
        } else {
            vapiService.startConversation()
        }
    }
    
    private func clearConversation() {
        vapiService.transcript = ""
        vapiService.agentResponse = ""
        photoResults = []
        recentNotes = []
    }
    
    private func simulateCommand(_ command: String) {
        vapiService.transcript = command
        // The actual processing would happen through VAPI
    }
    
    private func fetchNotesFromConvex() async {
        print("📚 Fetching notes from Convex...")
        
        let url = URL(string: "https://quick-ermine-34.convex.cloud/api/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "path": "notes:list",
            "args": [:]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📝 Raw Convex response: \(responseString)")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📊 Parsed JSON keys: \(json.keys)")
                
                // Try different possible response structures
                var notesArray: [[String: Any]]? = nil
                
                // Check if notes are directly in "value"
                if let value = json["value"] as? [[String: Any]] {
                    notesArray = value
                }
                // Or if there's a "data" field
                else if let data = json["data"] as? [[String: Any]] {
                    notesArray = data
                }
                // Or if the response is the array directly
                else if let status = json["status"] as? String, status == "success",
                      let value = json["value"] as? [[String: Any]] {
                    notesArray = value
                }
                
                if let notesArray = notesArray {
                    print("📋 Found \(notesArray.count) notes in response")
                    
                    let notes = notesArray.compactMap { noteData -> Note? in
                        print("🔍 Processing note data: \(noteData)")
                        
                        // Try different field names
                        let id = (noteData["_id"] as? String) ?? (noteData["id"] as? String) ?? UUID().uuidString
                        let title = (noteData["title"] as? String) ?? (noteData["text"] as? String) ?? "Untitled"
                        let content = (noteData["content"] as? String) ?? (noteData["text"] as? String) ?? ""
                        
                        // Handle different timestamp formats
                        var date = Date()
                        if let createdAt = noteData["_creationTime"] as? Double {
                            date = Date(timeIntervalSince1970: createdAt / 1000)
                        } else if let createdAt = noteData["createdAt"] as? Double {
                            date = Date(timeIntervalSince1970: createdAt / 1000)
                        } else if let timestamp = noteData["timestamp"] as? Double {
                            date = Date(timeIntervalSince1970: timestamp / 1000)
                        }
                        
                        return Note(
                            id: id,
                            title: title,
                            content: content,
                            createdAt: date
                        )
                    }
                    
                    await MainActor.run {
                        self.recentNotes = notes
                        print("✅ Loaded \(notes.count) notes from Convex")
                    }
                } else {
                    print("⚠️ No notes array found in response")
                }
            }
        } catch {
            print("❌ Failed to fetch notes from Convex: \(error)")
        }
    }
    
    private func requestAllPermissions() {
        // Request notification permissions on app launch
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                print("Notification permission granted: \(granted)")
                
                // Also request photo library permission
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    print("Photo library permission: \(status)")
                }
            } catch {
                print("Error requesting permissions: \(error)")
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for photo results
        NotificationCenter.default.addObserver(
            forName: .showPhotosResult,
            object: nil,
            queue: .main
        ) { notification in
            if let assets = notification.userInfo?["assets"] as? [PHAsset] {
                self.photoResults = assets
                self.showingPhotos = true
            }
        }
        
        // Listen for created notes
        NotificationCenter.default.addObserver(
            forName: .noteCreated,
            object: nil,
            queue: .main
        ) { notification in
            if let note = notification.userInfo?["note"] as? Note {
                self.recentNotes.insert(note, at: 0)
            }
        }
        
        // Listen for share sheet request
        NotificationCenter.default.addObserver(
            forName: .showShareSheet,
            object: nil,
            queue: .main
        ) { notification in
            if let text = notification.userInfo?["text"] as? String {
                self.showShareSheet(text: text)
            }
        }
        
        // Listen for local tool execution from VAPI
        NotificationCenter.default.addObserver(
            forName: .executeLocalTool,
            object: nil,
            queue: .main
        ) { notification in
            if let action = notification.userInfo?["action"] as? String,
               let params = notification.userInfo?["params"] as? [String: Any] {
                Task {
                    await self.toolExecutor.executeLocalTool(action: action, params: params)
                }
            }
        }
    }
    
    private func showShareSheet(text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            print("❌ Could not get root view controller for share sheet")
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(activityVC, animated: true) {
            print("✅ Share sheet presented with text: \(text.prefix(50))...")
        }
    }
}

// MARK: - Supporting Views

struct PhotoResultsView: View {
    let assets: [PHAsset]
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(asset: asset)
                            .frame(height: 120)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotesListView: View {
    let notes: [Note]
    @Environment(\.dismiss) var dismiss
    @State private var selectedNote: Note? = nil
    @State private var showingNoteDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(notes, id: \.id) { note in
                            Button(action: {
                                selectedNote = note
                                showingNoteDetail = true
                            }) {
                                ZStack {
                                    // Card background with gradient border
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.black.opacity(0.5))
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(note.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(note.content)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(note.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundColor(.purple.opacity(0.8))
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top)
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.2),
                        Color.clear,
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationTitle("Notes (\(notes.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingNoteDetail) {
                if let note = selectedNote {
                    NoteDetailView(note: note)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct NoteDetailView: View {
    let note: Note
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title with gradient
                        Text(note.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.horizontal)
                        
                        // Date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple.opacity(0.8))
                            Text(note.createdAt, style: .date)
                                .foregroundColor(.white.opacity(0.7))
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(note.createdAt, style: .time)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .font(.caption)
                        .padding(.horizontal)
                        
                        // Gradient divider
                        LinearGradient(
                            colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        .padding(.horizontal)
                        
                        // Content
                        Text(note.content)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                    }
                    .padding(.top)
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.clear,
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Share the note
                        let text = "\(note.title)\n\n\(note.content)"
                        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(av, animated: true)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

