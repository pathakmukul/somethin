# Somethin' - The AI That Actually Does Somethin'

**Stop asking Siri the same question 5 times.** Somethin' is the iOS voice assistant that actually understands you the first time and gets stuff done. Built in Swift, powered by GPT-4, and integrated with Dedalus MCP for real intelligence.


<p align="center">
  <img src="https://raw.githubusercontent.com/pathakmukul/somethin/main/IMG_8551.PNG" width="250" alt="Somethin' App Screenshot">
</p>

<p align="center">
  <strong>Watch Demo:</strong><br>
  <a href="https://youtu.be/DRFrmCRjPJw">
    <img src="https://img.youtube.com/vi/DRFrmCRjPJw/0.jpg" width="400" alt="Demo Video">
  </a>
</p>

## Core Features

### 📧 **Email Management (via AgentMail MCP)**
- **Read emails** - "What did John email me about?"
- **Send emails** - "Email Sarah the meeting notes"
- **Search inbox** - "Find emails about the project deadline"
- **Smart summaries** - "Summarize today's important emails"

### 📝 **Smart Notes System**
- **Create notes** - Capture thoughts instantly with voice
- **Update existing notes** - "Add to my project ideas note"
- **Search across notes** - "Find my notes about machine learning"
- **Combine ideas** - "Merge my startup ideas into one document"
- **Auto-summarize** - Long conversations automatically saved as concise notes

### 🔍 **Research & Information**
- **Web search** - Real-time information via Brave Search MCP
- **Weather** - Current conditions and forecasts via Open-Meteo MCP
- **Shopping** - Price comparisons and product search
- **News** - Latest updates on any topic

### 🎯 **Intelligent Compilation**
The assistant can compile information from multiple sources and:
- Send as an email summary
- Save as a structured note
- Create action items
- Generate reports

### 🛍️ **Shopping Assistant**
- **Product Search**: "Find iPhone 15 prices" or "Search for Nike shoes"
- **Price Comparison**: Real-time pricing from multiple retailers
- **Google Shopping Integration**: Access to millions of products
- **Voice-Guided Shopping**: Get product details spoken back to you

### 💬 **Message Reading (Beta)**
- **Notification Access**: Read recent messages from notification center
- **Sender Filtering**: "Read messages from John"
- **Privacy-Focused**: Only accesses notifications you permit

### 🧠 **Personalization**
- **User Profiles**: Remembers your name and preferences
- **Contact Management**: Knows your contacts and nicknames
- **Custom Summaries**: Personalized context for better responses

*Also includes local device control for photos and music (in development)*

## Dedalus MCP Integration

The app uses Dedalus Labs' MCP runner to intelligently route requests to the right tools without hardcoded logic.

**Available MCP Servers**:
- `vroom08/agentmail-mcp` - Full email capabilities (read, send, search)
- `tsion/brave-search-mcp` - Web search and information retrieval  
- `joerup/open-meteo-mcp` - Weather data

**Implementation**: `dedalus-api/api/index.py`

The Python backend receives voice commands from Vapi and uses Dedalus to:
1. Determine which MCP servers are needed
2. Execute them in the right order
3. Combine results intelligently

**Example Flow**:
```
User: "Email the team a summary of today's tech news"
→ Vapi processes voice command
→ Routes to Dedalus backend
→ Dedalus automatically:
  - Uses Brave Search MCP to get tech news
  - Summarizes the information
  - Uses AgentMail MCP to compose and send email
→ Confirms to user via voice
```

## Tech Stack

- **Language**: Swift (iOS app)
- **UI Framework**: SwiftUI
- **Voice AI**: Vapi (GPT-4 + 11Labs voices)
- **Backend**: Convex (real-time sync, note storage)
- **MCP Gateway**: Dedalus Labs (Python backend on Vercel)
- **Database**: Convex for persistent storage

## Use Cases

Perfect for situations where you can't use your hands:
- **Driving** - "Send an email saying I'm running late"
- **Gym** - "Add protein shake recipe to my notes"
- **Cooking** - "What's the weather tomorrow?"
- **Walking** - "Search for the nearest coffee shop"
- **Working** - "Compile today's meeting notes and email to the team"

## Setup

1. **Clone the repository**
```bash
git clone https://github.com/pathakmukul/somethin.git
```

2. **Configure environment**
```bash
cp .env.example .env
# Add your API keys:
# - DEDALUS_API_KEY (from dedaluslabs.ai)
# - VAPI_PUBLIC_KEY
# - Email configuration for AgentMail
```

3. **Start Convex backend**
```bash
cd convex
npm install
npx convex dev
```

4. **Deploy Dedalus backend** (optional for local testing)
```bash
cd dedalus-api
pip install -r requirements.txt
vercel dev
```

5. **Run iOS app**
```bash
open VoiceAgentApp.xcodeproj
# Build and run in Xcode
```

## Project Structure

```
VoiceAgentApp/        - Swift/SwiftUI iOS application
├── Services/         - VAPIService, LocalToolExecutor, ConvexNotesSync
├── Config/           - AppConfig for API keys
└── Views/            - VoiceAgentView, SettingsView

convex/               - Backend for note storage and sync
├── notes.ts          - CRUD operations for notes
├── vapi/             - Tool handlers
└── lib/dedalus.ts    - Dedalus integration stub

dedalus-api/          - Python backend for MCP execution
└── api/index.py      - Dedalus runner with all MCP servers
```

## 🚀 Unique Selling Points

1. **Hybrid Architecture**: Combines local device capabilities with cloud AI
2. **Tool Flexibility**: Easy to add new capabilities without app updates
3. **Real-Time Sync**: Instant synchronization across features
4. **Native Performance**: Optimized for iOS with SwiftUI
5. **Extensible Platform**: Plugin-ready architecture for future features

## 🔮 Future Roadmap

- Calendar integration
- Smart home control
- Multi-language support
- Offline mode for basic features
- Widget support
- Apple Watch companion app

## Note on Security

All API keys are stored in `.env` and never committed to the repository. The app uses iOS Keychain for secure storage on device.

---

Built for YC Hacks. Demonstrates practical integration of Dedalus MCP runner for real-world voice assistant applications.