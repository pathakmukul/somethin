import Foundation
import Vapi
import Combine

// VAPI Service for managing voice interactions
class VAPIService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var agentResponse = ""
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var currentToolCall: String?
    @Published var isSpeaking = false  // Track if user is speaking
    @Published var isAgentSpeaking = false  // Track if agent is speaking
    
    private var vapiClient: Vapi?
    private var currentCallActive = false
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    override init() {
        super.init()
        setupVAPI()
        setupToolResultListener()
    }
    
    private func setupVAPI() {
        // Initialize VAPI with public key from config
        vapiClient = Vapi(publicKey: AppConfig.vapiPublicKey)
        
        // Subscribe to events
        vapiClient?.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleVAPIEvent(event)
            }
            .store(in: &cancellables)
    }
    
    func startConversation() {
        guard let client = vapiClient else { 
            print("VAPI Error: Client not initialized")
            return 
        }
        
        connectionStatus = .connecting
        print("VAPI: Starting conversation with assistant ID: 18e912f6-35f1-4a6a-a1ef-8ccbed310d27")
        
        Task {
            do {
                // Load user settings and contacts for personalization
                let userVariables = await loadUserVariables()
                
                // Create assistant overrides with dynamic variables
                let assistantOverrides: [String: Any] = [
                    "variableValues": userVariables
                ]
                
                print("VAPI: Starting with user variables: \(userVariables)")
                
                // Use the assistant ID from config with variable values
                _ = try await client.start(
                    assistantId: AppConfig.vapiAssistantId,
                    assistantOverrides: assistantOverrides
                )
                
                await MainActor.run {
                    self.currentCallActive = true
                    self.isListening = true
                    self.connectionStatus = .connected
                    print("VAPI: Successfully connected with personalization")
                }
            } catch {
                print("VAPI Error: \(error)")
                print("Error details: \(String(describing: error))")
                await MainActor.run {
                    self.connectionStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func stopConversation() {
        vapiClient?.stop()
        currentCallActive = false
        isListening = false
        connectionStatus = .disconnected
    }
    
    private func loadUserVariables() async -> [String: Any] {
        var variables: [String: Any] = [:]
        
        // Load user settings
        if let settingsUrl = URL(string: "https://quick-ermine-34.convex.cloud/api/query") {
            var settingsRequest = URLRequest(url: settingsUrl)
            settingsRequest.httpMethod = "POST"
            settingsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let settingsBody: [String: Any] = [
                "path": "settings:get",
                "args": ["userId": "default_user"]
            ]
            
            do {
                settingsRequest.httpBody = try JSONSerialization.data(withJSONObject: settingsBody)
                let (settingsData, _) = try await URLSession.shared.data(for: settingsRequest)
                
                if let json = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any],
                   let value = json["value"] as? [String: Any] {
                    
                    // Set user variables from settings
                    variables["userName"] = value["name"] as? String ?? "User"
                    variables["userSummary"] = value["summary"] as? String ?? ""
                    
                    print("Loaded user settings - Name: \(variables["userName"] ?? ""), Summary: \(variables["userSummary"] ?? "")")
                }
            } catch {
                print("Failed to load user settings: \(error)")
                variables["userName"] = "User"
                variables["userSummary"] = ""
            }
        }
        
        // Load contacts
        if let contactsUrl = URL(string: "https://quick-ermine-34.convex.cloud/api/query") {
            var contactsRequest = URLRequest(url: contactsUrl)
            contactsRequest.httpMethod = "POST"
            contactsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let contactsBody: [String: Any] = [
                "path": "settings:getContacts",
                "args": ["userId": "default_user"]
            ]
            
            do {
                contactsRequest.httpBody = try JSONSerialization.data(withJSONObject: contactsBody)
                let (contactsData, _) = try await URLSession.shared.data(for: contactsRequest)
                
                if let json = try JSONSerialization.jsonObject(with: contactsData) as? [String: Any],
                   let contactsList = json["value"] as? [[String: Any]] {
                    
                    // Format contacts as a string
                    let formattedContacts = contactsList.map { contact in
                        let name = contact["name"] as? String ?? ""
                        let email = contact["email"] as? String ?? ""
                        let nickname = contact["nickname"] as? String
                        
                        if let nickname = nickname {
                            return "\(name) (nickname: \(nickname), email: \(email))"
                        } else {
                            return "\(name) (email: \(email))"
                        }
                    }.joined(separator: "; ")
                    
                    variables["userContacts"] = formattedContacts
                    print("Loaded \(contactsList.count) contacts")
                }
            } catch {
                print("Failed to load contacts: \(error)")
                variables["userContacts"] = ""
            }
        }
        
        return variables
    }
    
    private func handleVAPIEvent(_ event: Vapi.Event) {
        // Debug: Log ALL events
        print("VAPI Event received: \(event)")
        
        switch event {
        case .callDidStart:
            connectionStatus = .connected
            
        case .callDidEnd:
            connectionStatus = .disconnected
            isListening = false
            
        case .transcript(let transcript):
            // User is speaking - update transcript
            // The transcript object likely doesn't have isFinal property, so we'll treat all as ongoing
            self.transcript = transcript.transcript
            self.isSpeaking = true
            self.isAgentSpeaking = false
            
        case .functionCall(let functionCall):
            print("🔴🔴🔴 VAPI functionCall received!")
            print("🔴 FunctionCall object: \(functionCall)")
            
            // Debug: Print the full functionCall object
            let mirror = Mirror(reflecting: functionCall)
            for child in mirror.children {
                print("  🔍 \(child.label ?? "unknown"): \(child.value)")
            }
            
            // Try to extract the name directly
            if let nameProperty = mirror.descendant("name") as? String {
                currentToolCall = nameProperty
                print("🎯 Tool name: \(nameProperty)")
            }
            
            // Execute the tool locally IMMEDIATELY
            executeLocalTool(functionCall: functionCall)
            
        case .conversationUpdate(let update):
            print("📘 Conversation update received")
            
            // The update is likely a JSON string or similar - let's inspect it
            let updateMirror = Mirror(reflecting: update)
            for prop in updateMirror.children {
                print("  Update property: \(prop.label ?? "")")
            }
            
            // Try a different approach - check if there's a messages property
            if let messages = Mirror(reflecting: update).descendant("messages") {
                print("🎯 Found messages in update")
                // Look for tool calls in messages
                parseMessagesForToolCalls(messages)
            }
            
            // Also check conversation property
            if let conversation = Mirror(reflecting: update).descendant("conversation") {
                print("🎯 Found conversation in update")
                // Look for tool calls in conversation
                parseMessagesForToolCalls(conversation)
            }
            
            // Update agent response if present
            for message in update.conversation {
                if Mirror(reflecting: message).descendant("role") as? String == "assistant" {
                    if let content = Mirror(reflecting: message).descendant("content") as? String {
                        self.agentResponse = content
                        self.isAgentSpeaking = true
                        self.isSpeaking = false
                    }
                }
            }
            
        case .error(let error):
            connectionStatus = .error(error.localizedDescription)
            
        case .speechUpdate(let speechUpdate):
            // Track when agent starts/stops speaking
            // Use the enum values directly instead of comparing to strings
            let statusMirror = Mirror(reflecting: speechUpdate.status)
            if let statusLabel = statusMirror.children.first?.label {
                if statusLabel == "started" {
                    isAgentSpeaking = true
                    isSpeaking = false
                } else if statusLabel == "stopped" {
                    isAgentSpeaking = false
                }
            }
            
        case .metadata, .statusUpdate, .modelOutput, .userInterrupted, .voiceInput, .hang:
            // Handle other events as needed
            break
        }
    }
    
    private func parseMessagesForToolCalls(_ messages: Any) {
        print("🔍 Parsing messages for tool calls")
        
        // Try to iterate if it's an array
        if let messagesArray = messages as? Array<Any> {
            for message in messagesArray {
                // Check each message for toolCalls
                let messageMirror = Mirror(reflecting: message)
                
                // Look for toolCalls property
                if let toolCalls = messageMirror.descendant("toolCalls") {
                    print("🎯🎯 Found toolCalls in message!")
                    if let toolCallsArray = toolCalls as? Array<Any> {
                        for toolCall in toolCallsArray {
                            processToolCallFromConversation(toolCall)
                        }
                    }
                }
                
                // Also check for tool_calls
                if let toolCalls = messageMirror.descendant("tool_calls") {
                    print("🎯🎯 Found tool_calls in message!")
                    if let toolCallsArray = toolCalls as? Array<Any> {
                        for toolCall in toolCallsArray {
                            processToolCallFromConversation(toolCall)
                        }
                    }
                }
            }
        }
    }
    
    private func processToolCallFromConversation(_ toolCall: Any) {
        print("🔨 Processing tool call from conversation update")
        
        let mirror = Mirror(reflecting: toolCall)
        var functionName = ""
        var arguments = ""
        
        for child in mirror.children {
            print("  📦 ToolCall property: \(child.label ?? ""): \(child.value)")
            
            if child.label == "function" {
                // The function property contains name and arguments
                let funcMirror = Mirror(reflecting: child.value)
                for funcChild in funcMirror.children {
                    if funcChild.label == "name" {
                        functionName = funcChild.value as? String ?? ""
                    } else if funcChild.label == "arguments" {
                        arguments = funcChild.value as? String ?? ""
                    }
                }
            }
        }
        
        print("🎯 Extracted function: \(functionName) with args: \(arguments)")
        
        // Parse arguments JSON
        var params: [String: Any] = [:]
        if let data = arguments.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            params = parsed
        }
        
        // Execute based on function name
        switch functionName {
        case "device_create_note", "create_note":
            let title = params["title"] as? String ?? "Voice Note"
            let content = params["content"] as? String ?? transcript
            
            print("📝 Creating note - Title: \(title), Content: \(content)")
            
            NotificationCenter.default.post(
                name: .executeLocalTool,
                object: nil,
                userInfo: [
                    "action": "create_note",
                    "params": [
                        "title": title,
                        "content": content
                    ]
                ]
            )
            
        default:
            print("⚠️ Unknown function: \(functionName)")
        }
    }
    
    private func executeLocalTool(functionCall: Any) {
        // Extract function details from the VAPI event
        let mirror = Mirror(reflecting: functionCall)
        var name = ""
        var parameters: [String: Any] = [:]
        var arguments: String = ""
        
        for child in mirror.children {
            print("🔍 FunctionCall property: \(child.label ?? "unknown") = \(child.value)")
            
            if child.label == "name" {
                name = child.value as? String ?? ""
            } else if child.label == "parameters" {
                parameters = child.value as? [String: Any] ?? [:]
            } else if child.label == "arguments" {
                // Arguments might be a JSON string that needs parsing
                if let argsString = child.value as? String {
                    arguments = argsString
                    if let data = argsString.data(using: .utf8),
                       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        parameters = parsed
                    }
                }
            }
        }
        
        print("📋 Extracted - name: \(name)")
        print("📋 Extracted - parameters: \(parameters)")
        print("📋 Extracted - arguments string: \(arguments)")
        
        // Map VAPI function calls to local actions
        switch name {
        case "create_note", "create_note_local", "createNote", "device_create_note": // Including new tool name
            // Extract parameters from the function call
            let title = parameters["title"] as? String ?? "Voice Note"
            let content = parameters["content"] as? String ?? transcript
            
            print("Creating note locally - Title: \(title), Content: \(content)")
            
            // Post notification to LocalToolExecutor to actually create the note
            NotificationCenter.default.post(
                name: .executeLocalTool,
                object: nil,
                userInfo: [
                    "action": "create_note",
                    "params": [
                        "title": title,
                        "content": content
                    ]
                ]
            )
            
        case "search_photos":
            let query = parameters["query"] as? String ?? transcript
            print("Searching photos locally for: \(query)")
            
            NotificationCenter.default.post(
                name: .executeLocalTool,
                object: nil,
                userInfo: [
                    "action": "search_photos",
                    "params": ["query": query]
                ]
            )
            
        case "play_music":
            let action = parameters["action"] as? String ?? "play"
            let query = parameters["query"] as? String
            
            print("Music control - Action: \(action), Query: \(query ?? "none")")
            
            var params: [String: Any] = ["action": action]
            if let query = query {
                params["query"] = query
            }
            
            NotificationCenter.default.post(
                name: .executeLocalTool,
                object: nil,
                userInfo: [
                    "action": "play_music",
                    "params": params
                ]
            )
            
        case "read_messages", "read_last_text":
            let count = parameters["count"] as? Int ?? 1
            let sender = parameters["sender"] as? String
            
            print("🔴 VAPI called read_messages - Count: \(count), Sender: \(sender ?? "any")")
            
            var params: [String: Any] = ["count": count]
            if let sender = sender {
                params["sender"] = sender
            }
            
            // Post notification to execute locally
            NotificationCenter.default.post(
                name: .executeLocalTool,
                object: nil,
                userInfo: [
                    "action": "read_messages",
                    "params": params
                ]
            )
            
            // IMPORTANT: Return a result immediately to VAPI
            // The actual execution happens asynchronously
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.agentResponse = "Checking for messages..."
            }
            
        default:
            print("Unknown tool: \(name)")
        }
    }
    
    // Listen for local tool execution results
    func setupToolResultListener() {
        NotificationCenter.default.addObserver(
            forName: .localToolExecuted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let result = notification.userInfo?["result"] {
                // Extract success and message from result
                let mirror = Mirror(reflecting: result)
                var success = false
                var message = ""
                
                for child in mirror.children {
                    if child.label == "success", let successValue = child.value as? Bool {
                        success = successValue
                    }
                    if child.label == "message", let messageValue = child.value as? String {
                        message = messageValue
                    }
                }
                
                print("Tool executed locally - Success: \(success), Message: \(message)")
                
                // Update the response to show ACTUAL result
                if success {
                    self?.agentResponse = "✅ \(message)"
                } else {
                    self?.agentResponse = "❌ Failed: \(message)"
                }
            }
        }
    }
}

extension Notification.Name {
    static let executeLocalTool = Notification.Name("executeLocalTool")
}