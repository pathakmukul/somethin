# VAPI Assistant Configuration

## Important: Tool Configuration

For iOS app to receive function calls, you need to configure tools WITHOUT server URL in VAPI dashboard.

### Option 1: Client-Side Tools (Recommended for iOS)

In VAPI Dashboard (https://dashboard.vapi.ai/), configure your assistant with these tools:

```json
{
  "name": "Voice Agent Assistant",
  "model": {
    "provider": "openai",
    "model": "gpt-4"
  },
  "voice": {
    "provider": "11labs",
    "voiceId": "your-voice-id"
  },
  "firstMessage": "Hi! I can help you search photos, create notes, or play music. What would you like to do?",
  "functions": [
    {
      "name": "create_note",
      "description": "Create a note with the given title and content",
      "parameters": {
        "type": "object",
        "properties": {
          "title": {
            "type": "string",
            "description": "The title of the note"
          },
          "content": {
            "type": "string",
            "description": "The content of the note"
          }
        },
        "required": ["content"]
      }
    },
    {
      "name": "search_photos",
      "description": "Search for photos in the user's photo library",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "The search query (e.g., 'sunset', 'beach', 'family')"
          }
        },
        "required": ["query"]
      }
    },
    {
      "name": "play_music",
      "description": "Control music playback",
      "parameters": {
        "type": "object",
        "properties": {
          "action": {
            "type": "string",
            "enum": ["play", "pause", "next", "previous"],
            "description": "The action to perform"
          },
          "query": {
            "type": "string",
            "description": "Optional search query for finding specific music"
          }
        },
        "required": ["action"]
      }
    }
  ]
}
```

**DO NOT** set a `serverUrl` for these functions if you want iOS to handle them directly!

### Option 2: Hybrid Approach (Complex tasks via Convex, simple via iOS)

Keep local tools client-side (no serverUrl) and add server-side tools for complex tasks:

```json
{
  "functions": [
    // ... local tools above without serverUrl ...
    {
      "name": "web_search",
      "description": "Search the web for information",
      "serverUrl": "https://quick-ermine-34.convex.cloud/vapi/toolHandler",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "The search query"
          }
        },
        "required": ["query"]
      }
    }
  ]
}
```

## Key Points

1. **Client-side tools** (no serverUrl) → iOS receives `functionCall` events
2. **Server-side tools** (with serverUrl) → Only Convex receives them, iOS just gets conversation updates
3. The iOS SDK will ONLY receive functionCall events for tools WITHOUT a serverUrl

## Hybrid Configuration (RECOMMENDED)

Configure your assistant with BOTH types of tools:

### Local Tools (NO serverUrl) - Handled by iOS directly:
```json
{
  "name": "create_note",
  "description": "Create a note with the given title and content",
  "parameters": {
    "type": "object",
    "properties": {
      "title": {"type": "string", "description": "The title of the note"},
      "content": {"type": "string", "description": "The content of the note"}
    },
    "required": ["content"]
  }
},
{
  "name": "search_photos",
  "description": "Search for photos in the user's photo library",
  "parameters": {
    "type": "object",
    "properties": {
      "query": {"type": "string", "description": "Search query"}
    },
    "required": ["query"]
  }
},
{
  "name": "play_music",
  "description": "Control music playback",
  "parameters": {
    "type": "object",
    "properties": {
      "action": {"type": "string", "enum": ["play", "pause", "next", "previous"]},
      "query": {"type": "string", "description": "Optional search query"}
    },
    "required": ["action"]
  }
}
```

### Dedalus Tools (WITH serverUrl) - Handled by Convex/Dedalus:
```json
{
  "name": "web_search",
  "description": "Search the web for current information",
  "serverUrl": "https://quick-ermine-34.convex.cloud/vapi/toolHandler",
  "parameters": {
    "type": "object",
    "properties": {
      "query": {"type": "string", "description": "Search query"}
    },
    "required": ["query"]
  }
},
{
  "name": "complex_task",
  "description": "Handle complex multi-step tasks that require advanced reasoning",
  "serverUrl": "https://quick-ermine-34.convex.cloud/vapi/toolHandler",
  "parameters": {
    "type": "object",
    "properties": {
      "request": {"type": "string", "description": "Detailed task description"}
    },
    "required": ["request"]
  }
}
```

## Result:
- Local actions (notes, photos, music) → iOS handles directly via functionCall events
- Complex tasks (web search, Dedalus) → Convex/Dedalus handles via serverUrl
- Both work seamlessly in the same assistant!