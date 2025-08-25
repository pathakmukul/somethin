import Foundation
import Photos
import MusicKit
import UIKit

// Protocol for local tool execution
protocol LocalTool {
    var name: String { get }
    func execute(params: [String: Any]) async throws -> ToolResult
}

struct ToolResult {
    let success: Bool
    let data: Any?
    let message: String
}

// Main executor that manages all local tools
class LocalToolExecutor: ObservableObject {
    @Published var isExecuting = false
    @Published var lastResult: ToolResult?
    
    private let photosTool = PhotosSearchTool()
    private let notesTool = NotesTool()
    private let musicTool = MusicTool()
    private let messagesTool = MessagesTool()
    
    init() {
        // Listen for tool execution requests from VAPI
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToolExecution),
            name: .executeLocalTool,
            object: nil
        )
    }
    
    @objc private func handleToolExecution(_ notification: Notification) {
        print("🎯 LocalToolExecutor received notification")
        
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? String,
              let params = userInfo["params"] as? [String: Any] else {
            print("❌ Missing action or params in notification")
            return
        }
        
        print("🎯 Executing action: \(action) with params: \(params)")
        
        Task {
            await executeLocalTool(action: action, params: params)
        }
    }
    
    func executeLocalTool(action: String, params: [String: Any]) async {
        print("🔥 executeLocalTool called with action: \(action)")
        
        await MainActor.run {
            isExecuting = true
        }
        
        do {
            let result: ToolResult
            
            switch action {
            case "search_photos":
                print("🔥 Executing search_photos")
                result = try await photosTool.execute(params: params)
                
            case "create_note":
                print("🔥 Executing create_note")
                result = try await notesTool.execute(params: params)
                
            case "play_music", "control_music":
                print("🔥 Executing play_music")
                result = try await musicTool.execute(params: params)
                
            case "read_messages", "read_last_text":
                print("🔥 Executing read_messages")
                result = try await messagesTool.execute(params: params)
                
            default:
                result = ToolResult(
                    success: false,
                    data: nil,
                    message: "Unknown action: \(action)"
                )
            }
            
            await MainActor.run {
                self.lastResult = result
                self.isExecuting = false
            }
            
            // Post result notification
            NotificationCenter.default.post(
                name: .localToolExecuted,
                object: nil,
                userInfo: ["result": result]
            )
            
        } catch {
            await MainActor.run {
                self.lastResult = ToolResult(
                    success: false,
                    data: nil,
                    message: "Error: \(error.localizedDescription)"
                )
                self.isExecuting = false
            }
        }
    }
}

// MARK: - Photos Tool

class PhotosSearchTool: LocalTool {
    let name = "search_photos"
    private let searchService = PhotoSearchServiceEnhanced()
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        guard let query = params["query"] as? String else {
            return ToolResult(
                success: false,
                data: nil,
                message: "Missing search query"
            )
        }
        
        // Request permission if needed
        let authorized = await requestPhotoAccess()
        guard authorized else {
            return ToolResult(
                success: false,
                data: nil,
                message: "Photo library access denied"
            )
        }
        
        // Search photos
        return await withCheckedContinuation { continuation in
            searchService.searchPhotos(query: query) { assets in
                let photoData = assets.map { asset in
                    return [
                        "id": asset.localIdentifier,
                        "creationDate": asset.creationDate?.timeIntervalSince1970 ?? 0,
                        "mediaType": asset.mediaType.rawValue,
                        "isFavorite": asset.isFavorite
                    ]
                }
                
                let result = ToolResult(
                    success: true,
                    data: photoData,
                    message: "Found \(assets.count) photos matching '\(query)'"
                )
                
                // Also trigger UI update to show photos
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .showPhotosResult,
                        object: nil,
                        userInfo: ["assets": assets, "query": query]
                    )
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func requestPhotoAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }
}

// MARK: - Notes Tool

class NotesTool: LocalTool {
    let name = "create_note"
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        let title = params["title"] as? String ?? "Voice Note"
        let content = params["content"] as? String ?? ""
        
        print("📝 NotesTool executing with title: '\(title)', content: '\(content)'")
        
        // Create the note text
        let noteText = "\(title)\n\n\(content)"
        
        // Method 1: Post notification to show share sheet from VoiceAgentView
        await MainActor.run {
            NotificationCenter.default.post(
                name: .showShareSheet,
                object: nil,
                userInfo: ["text": noteText]
            )
            print("📤 Posted showShareSheet notification")
        }
        
        // Also save locally for the app's notes list
        let note = Note(
            id: UUID().uuidString,
            title: title,
            content: content,
            createdAt: Date()
        )
        saveNote(note)
        
        // Show in UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .noteCreated,
                object: nil,
                userInfo: ["note": note]
            )
        }
        
        return ToolResult(
            success: true,
            data: ["noteId": note.id],
            message: "Note ready to save: \(title)"
        )
    }
    
    private func getTopViewController(from root: UIViewController) -> UIViewController? {
        if let presented = root.presentedViewController {
            return getTopViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = root as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return root
    }
    
    private func saveNote(_ note: Note) {
        var notes = getSavedNotes()
        notes.append(note)
        
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "VoiceAgentNotes")
        }
    }
    
    private func getSavedNotes() -> [Note] {
        guard let data = UserDefaults.standard.data(forKey: "VoiceAgentNotes"),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
    
    private func createShortcutURL(for note: Note) -> URL? {
        // Create a URL to trigger a Shortcut that creates a note
        let shortcutName = "Create Note"
        let params = [
            "title": note.title,
            "content": note.content
        ]
        
        var components = URLComponents(string: "shortcuts://run-shortcut")
        components?.queryItems = [
            URLQueryItem(name: "name", value: shortcutName),
            URLQueryItem(name: "input", value: "text"),
            URLQueryItem(name: "text", value: "\(note.title)\n\n\(note.content)")
        ]
        
        return components?.url
    }
}

// MARK: - Messages Tool
import UserNotifications

class MessagesTool: LocalTool {
    let name = "read_messages"
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        print("📱 MessagesTool.execute called with params: \(params)")
        
        let count = params["count"] as? Int ?? 1
        let sender = params["sender"] as? String
        
        print("📱 Reading \(count) messages, sender filter: \(sender ?? "none")")
        
        // Read from Notification Center (permissions already requested at app launch)
        let messages = await getMessagesFromNotificationCenter(count: count, sender: sender)
        
        print("📱 Found \(messages.count) messages")
        
        if !messages.isEmpty {
            let messageText = messages.map { msg in
                "Message from \(msg.sender): \(msg.body)"
            }.joined(separator: ". ")
            
            return ToolResult(
                success: true,
                data: ["messages": messages],
                message: messageText
            )
        }
        
        // Method 2: Try Apple's Messages URL scheme to open specific conversation
        // This opens the Messages app directly
        if let messagesURL = URL(string: "sms://") {
            await UIApplication.shared.open(messagesURL)
            return ToolResult(
                success: true,
                data: nil,
                message: "Opening Messages app. Please check your messages there."
            )
        }
        
        return ToolResult(
            success: false,
            data: nil,
            message: "No messages found in notification center. Check the Messages app directly."
        )
    }
    
    private func getMessagesFromNotificationCenter(count: Int, sender: String?) async -> [StoredMessage] {
        var messages: [StoredMessage] = []
        
        // Request notification permission if needed
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        guard settings.authorizationStatus == .authorized else {
            print("Notification access not authorized")
            return []
        }
        
        // Get delivered notifications (messages that are still in notification center)
        let notifications = await center.deliveredNotifications()
        
        print("Total notifications in center: \(notifications.count)")
        
        // Get ALL notifications (not filtering by category since iOS messages don't have specific categories)
        for notification in notifications {
            let request = notification.request
            let content = request.content
            
            // Get sender and message content
            let senderName = content.title // Usually the sender's name
            let messageBody = content.body
            
            // Skip if both title and body are empty
            if senderName.isEmpty && messageBody.isEmpty {
                continue
            }
            
            // Filter by sender if specified
            if let sender = sender, !senderName.lowercased().contains(sender.lowercased()) {
                continue
            }
            
            messages.append(StoredMessage(
                id: request.identifier,
                sender: senderName.isEmpty ? "Unknown" : senderName,
                body: messageBody,
                timestamp: notification.date
            ))
            
            // Debug logging
            print("Found notification - Sender: \(senderName), Body: \(messageBody), Category: \(content.categoryIdentifier)")
            
            if messages.count >= count {
                break
            }
        }
        
        // Sort by most recent first
        messages.sort { $0.timestamp > $1.timestamp }
        
        return Array(messages.prefix(count))
    }
    
    private func createShortcutURLForMessages(count: Int) -> URL? {
        // This creates a URL that opens the Shortcuts app to run a shortcut
        // The user needs to create a shortcut named "Read Messages" that:
        // 1. Gets the latest messages
        // 2. Speaks them out loud
        // 3. Returns to your app
        
        var components = URLComponents(string: "shortcuts://run-shortcut")
        components?.queryItems = [
            URLQueryItem(name: "name", value: "Read Messages"),
            URLQueryItem(name: "input", value: String(count))
        ]
        
        return components?.url
    }
}

// Message storage structure
struct StoredMessage: Codable {
    let id: String
    let sender: String
    let body: String
    let timestamp: Date
}

// MARK: - Music Tool

class MusicTool: LocalTool {
    let name = "play_music"
    private let player = ApplicationMusicPlayer.shared
    
    func execute(params: [String: Any]) async throws -> ToolResult {
        let action = params["action"] as? String ?? "play"
        let query = params["query"] as? String
        
        // Request music access if needed
        let authorized = await requestMusicAccess()
        guard authorized else {
            return ToolResult(
                success: false,
                data: nil,
                message: "Apple Music access denied"
            )
        }
        
        switch action {
        case "play":
            if let query = query {
                return await searchAndPlay(query: query)
            } else {
                try await player.play()
                return ToolResult(success: true, data: nil, message: "Resumed playback")
            }
            
        case "pause":
            player.pause()
            return ToolResult(success: true, data: nil, message: "Paused playback")
            
        case "next":
            try await player.skipToNextEntry()
            return ToolResult(success: true, data: nil, message: "Skipped to next track")
            
        case "previous":
            try await player.skipToPreviousEntry()
            return ToolResult(success: true, data: nil, message: "Skipped to previous track")
            
        case "search":
            if let query = query {
                return await searchMusic(query: query)
            }
            return ToolResult(success: false, data: nil, message: "No search query provided")
            
        default:
            return ToolResult(success: false, data: nil, message: "Unknown music action")
        }
    }
    
    private func requestMusicAccess() async -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }
    
    private func searchAndPlay(query: String) async -> ToolResult {
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 25
            
            let response = try await request.response()
            
            guard let firstSong = response.songs.first else {
                return ToolResult(
                    success: false,
                    data: nil,
                    message: "No songs found for '\(query)'"
                )
            }
            
            // Play the first result
            try await player.queue.insert(firstSong, position: .tail)
            try await player.play()
            
            return ToolResult(
                success: true,
                data: ["song": firstSong.title, "artist": firstSong.artistName],
                message: "Playing \(firstSong.title) by \(firstSong.artistName)"
            )
            
        } catch {
            return ToolResult(
                success: false,
                data: nil,
                message: "Error playing music: \(error.localizedDescription)"
            )
        }
    }
    
    private func searchMusic(query: String) async -> ToolResult {
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self, Album.self])
            request.limit = 10
            
            let response = try await request.response()
            
            let results = [
                "songs": response.songs.map { ["title": $0.title, "artist": $0.artistName] },
                "albums": response.albums.map { ["title": $0.title, "artist": $0.artistName] }
            ]
            
            return ToolResult(
                success: true,
                data: results,
                message: "Found \(response.songs.count) songs and \(response.albums.count) albums"
            )
            
        } catch {
            return ToolResult(
                success: false,
                data: nil,
                message: "Search error: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Supporting Types

struct Note: Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let localToolExecuted = Notification.Name("localToolExecuted")
    static let showPhotosResult = Notification.Name("showPhotosResult")
    static let noteCreated = Notification.Name("noteCreated")
    static let showShareSheet = Notification.Name("showShareSheet")
}