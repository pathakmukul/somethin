import Foundation
import Combine

// Polls Convex for commands to execute locally
class ConvexCommandPoller: ObservableObject {
    private var timer: Timer?
    private let toolExecutor = LocalToolExecutor()
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        // Poll every 1 second for new commands
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkForCommands()
        }
    }
    
    func checkForCommands() {
        Task {
            // Call Convex to get unexecuted commands
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
                    
                    for command in commands {
                        if let action = command["action"] as? String,
                           let params = command["params"] as? [String: Any] {
                            
                            print("📱 Executing command from Convex: \(action)")
                            
                            // Execute the command locally
                            await toolExecutor.executeLocalTool(action: action, params: params)
                        }
                    }
                }
            } catch {
                print("Failed to poll Convex: \(error)")
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}