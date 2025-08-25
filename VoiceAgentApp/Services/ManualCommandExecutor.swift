import Foundation
import SwiftUI

class ManualCommandExecutor: ObservableObject {
    @Published var pendingCommands: [[String: Any]] = []
    @Published var isExecuting = false
    
    private let toolExecutor = LocalToolExecutor()
    
    // Fetch pending commands from Convex
    func fetchPendingCommands() async {
        let url = URL(string: "https://quick-ermine-34.convex.cloud/api/mutation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["path": "commands:getUnexecutedCommands", "args": [:]] as [String : Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let commands = json["value"] as? [[String: Any]] {
                await MainActor.run {
                    self.pendingCommands = commands
                    print("📦 Found \(commands.count) pending commands")
                }
            }
        } catch {
            print("Failed to fetch commands: \(error)")
        }
    }
    
    // Execute all pending commands
    func executeAllCommands() async {
        await MainActor.run {
            isExecuting = true
        }
        
        for command in pendingCommands {
            if let action = command["action"] as? String,
               let params = command["params"] as? [String: Any] {
                
                print("🚀 Executing: \(action)")
                await toolExecutor.executeLocalTool(action: action, params: params)
            }
        }
        
        // Clear the list
        await MainActor.run {
            pendingCommands = []
            isExecuting = false
        }
    }
}