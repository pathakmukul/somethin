import { httpAction } from "../_generated/server";
import { api } from "../_generated/api";
import { runDedalusAgent, performWebSearch } from "../lib/dedalus";

// Main handler for VAPI tool calls
export const toolHandler = httpAction(async (ctx, request) => {
  // Parse the request body
  const body = await request.json();
  
  // Validate VAPI secret (optional but recommended)
  const secret = request.headers.get("x-vapi-secret");
  console.log("Received secret:", secret);
  console.log("Expected secret:", process.env.VAPI_SECRET);
  
  // For now, let's skip validation to test
  // if (secret !== process.env.VAPI_SECRET) {
  //   return new Response("Unauthorized", { status: 401 });
  // }

  const { message } = body;
  
  // Handle tool calls
  if (message?.type === "tool-calls") {
    const toolCalls = message.toolCalls;
    const results = [];

    for (const toolCall of toolCalls) {
      console.log("Processing toolCall:", JSON.stringify(toolCall));
      const result = await handleToolCall(ctx, toolCall);
      results.push(result);
    }

    return new Response(JSON.stringify({ results }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Handle other message types if needed
  return new Response(JSON.stringify({ message: "OK" }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});

async function handleToolCall(ctx: any, toolCall: any) {
  console.log("Received toolCall:", JSON.stringify(toolCall));
  
  // VAPI sends function details in toolCall.function
  const toolName = toolCall.function?.name || toolCall.name;
  const toolCallId = toolCall.id;
  const parameters = toolCall.function?.arguments || toolCall.arguments || toolCall.parameters || {};
  
  console.log("Extracted - toolName:", toolName, "parameters:", parameters);
  
  try {
    let result;
    
    switch (toolName) {
      // Handle both create_note and device_create_note
      case "create_note":
      case "device_create_note":
        // Store the note in Convex
        const noteId = await ctx.runMutation(api.notes.create, {
          title: parameters.title || "Voice Note",
          content: parameters.content || "",
        });
        
        console.log(`Note created in Convex: ${parameters.content}`);
        
        // Return success to VAPI
        result = {
          toolCallId,
          result: `Note created successfully with content: "${parameters.content}"`
        };
        break;
        
      case "search_notes":
        // Search notes in Convex
        const query = parameters.query || "";
        const notes = await ctx.runQuery(api.notes.search, { query });
        
        if (notes.length === 0) {
          result = {
            toolCallId,
            result: "No notes found matching your search."
          };
        } else {
          const notesList = notes.map((note: any) => 
            `- ${note.title}: ${note.content}`
          ).join("\n");
          
          result = {
            toolCallId,
            result: `Found ${notes.length} notes:\n${notesList}`
          };
        }
        break;
        
      case "search_photos":
      case "play_music":
        console.error(`ERROR: Local tool ${toolName} should not be routed to Convex!`);
        result = {
          toolCallId,
          error: `This tool should be handled locally on iOS.`,
        };
        break;

      case "web_search":
        // Use Dedalus with Brave Search MCP
        const searchResult = await performWebSearch(parameters.query || "");
        
        if (searchResult.success) {
          result = {
            toolCallId,
            result: searchResult.message
          };
        } else {
          // Fallback response if Dedalus not configured
          result = {
            toolCallId,
            result: `Unable to search at this time. Would need to search for: ${parameters.query}`
          };
        }
        break;

      case "complex_task":
        // Use Dedalus for complex multi-step tasks
        const taskResult = await runDedalusAgent(parameters.request || "", "general");
        
        if (taskResult.success) {
          result = {
            toolCallId,
            result: taskResult.message
          };
        } else {
          result = {
            toolCallId,
            result: `Unable to process complex task: ${parameters.request}`
          };
        }
        break;

      case "search_shopping":
        // Search for products using Serper API
        const searchQuery = parameters.query || "";
        const count = parameters.count || 10;
        
        if (!process.env.SERPER_API_KEY) {
          console.error("SERPER_API_KEY not set in environment variables!");
          result = {
            toolCallId,
            result: "Shopping search unavailable - API key not configured"
          };
          break;
        }
        
        try {
          const response = await fetch("https://google.serper.dev/shopping", {
            method: "POST",
            headers: {
              "X-API-KEY": process.env.SERPER_API_KEY,
              "Content-Type": "application/json"
            },
            body: JSON.stringify({
              q: searchQuery,
              num: Math.min(count, 40) // Max 40 results
            })
          });
          
          if (!response.ok) {
            throw new Error(`Serper API error: ${response.status}`);
          }
          
          const data = await response.json();
          const shopping = data.shopping || [];
          
          if (shopping.length === 0) {
            result = {
              toolCallId,
              result: `No products found for "${query}"`
            };
          } else {
            // Format top results for voice response
            const topResults = shopping.slice(0, 3).map((item: any) => {
              const price = item.price || "Price not available";
              const seller = item.source || "Unknown seller";
              return `${item.title} for ${price} from ${seller}`;
            }).join(". ");
            
            result = {
              toolCallId,
              result: `Found ${shopping.length} products for "${query}". Top results: ${topResults}`
            };
          }
        } catch (error: any) {
          console.error("Shopping search error:", error);
          result = {
            toolCallId,
            result: `Unable to search for products: ${error.message}`
          };
        }
        break;

      default:
        result = {
          toolCallId,
          error: `Unknown tool: ${toolName}`,
        };
    }

    // Log tool execution
    try {
      await ctx.runMutation(api.tools.logExecution, {
        sessionId: "default", // VAPI doesn't provide sessionId in tool calls
        toolName: toolName || "unknown",
        input: parameters || {},
        output: result || {},
        success: !result.error,
        executionTime: Date.now(),
      });
    } catch (logError) {
      console.error("Failed to log tool execution:", logError);
      // Continue even if logging fails
    }

    return result;
  } catch (error: any) {
    return {
      toolCallId,
      error: error.message || "Tool execution failed",
    };
  }
}

