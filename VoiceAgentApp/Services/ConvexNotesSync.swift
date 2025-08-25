import Foundation
import Combine

// Service to sync notes from Convex to iOS
class ConvexNotesSync: ObservableObject {
    @Published var syncedNotes: [Note] = []
    private var timer: Timer?
    private let convexURL = "https://quick-ermine-34.convex.cloud"
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        // Poll every 2 seconds for new notes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.fetchNotes()
        }
    }
    
    func fetchNotes() {
        // This is a simplified version - you'd need to implement actual Convex query
        // For now, just check if VAPIService created any notes
        Task {
            do {
                // Query Convex for notes
                let url = URL(string: "\(convexURL)/api/query")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = ["path": "notes:list", "args": [:]] as [String : Any]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                if let notes = try? JSONDecoder().decode([Note].self, from: data) {
                    await MainActor.run {
                        self.syncedNotes = notes
                        // Post notification when new notes arrive
                        if !notes.isEmpty {
                            NotificationCenter.default.post(
                                name: .convexNotesUpdated,
                                object: nil,
                                userInfo: ["notes": notes]
                            )
                        }
                    }
                }
            } catch {
                print("Failed to fetch notes from Convex: \(error)")
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension Notification.Name {
    static let convexNotesUpdated = Notification.Name("convexNotesUpdated")
}