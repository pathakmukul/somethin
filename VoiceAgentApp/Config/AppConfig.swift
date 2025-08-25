import Foundation

// Configuration manager for API keys and environment variables
enum AppConfig {
    // VAPI Configuration
    static let vapiPublicKey = getEnvVar("VAPI_PUBLIC_KEY") ?? ""
    static let vapiPrivateKey = getEnvVar("VAPI_PRIVATE_KEY") ?? ""
    static let vapiAssistantId = getEnvVar("VAPI_ASSISTANT_ID") ?? ""
    static let vapiSecret = getEnvVar("VAPI_SECRET") ?? ""
    
    // Serper API
    static let serperApiKey = getEnvVar("SERPER_API_KEY") ?? ""
    
    // Dedalus AI
    static let dedalusApiKey = getEnvVar("DEDALUS_API_KEY") ?? ""
    
    // Convex
    static let convexDeployment = getEnvVar("CONVEX_DEPLOYMENT") ?? ""
    static let convexUrl = getEnvVar("CONVEX_URL") ?? ""
    
    // Helper function to read from Info.plist or environment
    private static func getEnvVar(_ key: String) -> String? {
        // First try to read from Info.plist (for production builds)
        if let infoDictionary = Bundle.main.infoDictionary,
           let value = infoDictionary[key] as? String {
            return value
        }
        
        // Then try ProcessInfo (for development)
        return ProcessInfo.processInfo.environment[key]
    }
}

// For build-time configuration, add a Config.plist file with your keys
// Or use a build phase script to inject environment variables