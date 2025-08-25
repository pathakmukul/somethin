// Since Dedalus only has Python SDK, we'll use Brave Search API directly
export async function runDedalusAgent(request: string, toolType: string = "general") {
  // For now, return a message that Dedalus needs a Python backend
  return {
    success: false,
    message: "Dedalus requires Python SDK. For web search, using Brave Search API directly.",
  };
}

// Direct Brave Search implementation
async function searchBraveAPI(query: string) {
  const apiKey = process.env.BRAVE_SEARCH_API_KEY;
  
  if (!apiKey) {
    return null;
  }

  try {
    const response = await fetch(`https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}`, {
      headers: {
        "X-Subscription-Token": apiKey,
        "Accept": "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Dedalus API error: ${response.status}`);
    }

    const data = await response.json();
    
    return {
      success: true,
      message: data.result || data.response || "Task completed",
      steps: data.steps || [],
      tools_used: data.tools_used || [],
      raw_response: data,
    };
  } catch (error: any) {
    console.error("Dedalus error:", error);
    return {
      success: false,
      message: error.message || "Dedalus execution failed",
      error: error,
    };
  }
}

export async function performWebSearch(query: string) {
  // Try Brave Search API first
  const braveResult = await searchBraveAPI(query);
  
  if (braveResult) {
    const topResults = braveResult.web?.results?.slice(0, 3) || [];
    const summary = topResults.map((r: any) => 
      `• ${r.title}: ${r.description}`
    ).join('\n');
    
    return {
      success: true,
      message: summary || "No results found",
    };
  }
  
  // Fallback message
  return {
    success: false,
    message: `Cannot perform web search. Need Brave Search API key.`,
  };
}