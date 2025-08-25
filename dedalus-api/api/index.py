from http.server import BaseHTTPRequestHandler
import json
import os
from urllib.parse import parse_qs
import asyncio
from dedalus_labs import AsyncDedalus, DedalusRunner

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        # Handle CORS
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        try:
            # Read request body
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Log what VAPI sent
            print(f"VAPI Request: {json.dumps(data)}")
            
            # VAPI sends tool calls in different formats
            # Check for webhook format (message.toolCalls)
            if 'message' in data and data['message'].get('type') == 'tool-calls':
                # VAPI webhook format
                tool_calls = data['message'].get('toolCalls', [])
                if tool_calls and len(tool_calls) > 0:
                    tool_call = tool_calls[0]
                    function_data = tool_call.get('function', {})
                    tool_name = function_data.get('name', 'web_search')
                    
                    # Arguments might be a JSON string
                    args = function_data.get('arguments', {})
                    if isinstance(args, str):
                        parameters = json.loads(args)
                    else:
                        parameters = args
                    
                    tool_call_id = tool_call.get('id', '')
                else:
                    raise ValueError("No tool calls in request")
            elif 'toolCallList' in data:
                # VAPI format
                tool_calls = data['toolCallList']
                if tool_calls and len(tool_calls) > 0:
                    tool_call = tool_calls[0]
                    tool_name = tool_call.get('name', 'web_search')
                    parameters = tool_call.get('arguments', {})
                    tool_call_id = tool_call.get('id', '')
                else:
                    raise ValueError("No tool calls in request")
            else:
                # Direct format (for testing)
                tool_name = data.get('name', 'web_search')
                parameters = data.get('arguments', {})
                tool_call_id = data.get('id', '')
            
            # Run async function
            result = asyncio.run(execute_dedalus(tool_name, parameters))
            
            # Return VAPI-compatible response
            # VAPI webhook expects a specific format
            if 'message' in data:
                # VAPI webhook response format
                response = {
                    "results": [{
                        "toolCallId": tool_call_id,
                        "result": result
                    }]
                }
            elif 'toolCallList' in data:
                # VAPI format response
                response = {
                    "results": [{
                        "toolCallId": tool_call_id,
                        "result": result
                    }]
                }
            else:
                # Direct format response (for testing)
                response = {
                    "toolCallId": tool_call_id,
                    "result": result
                }
            
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except Exception as e:
            error_response = {
                "toolCallId": tool_call_id if 'tool_call_id' in locals() else "",
                "error": str(e)
            }
            self.wfile.write(json.dumps(error_response).encode('utf-8'))
    
    def do_OPTIONS(self):
        # Handle CORS preflight
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

async def execute_dedalus(tool_name, parameters):
    """Execute Dedalus with ALL MCP servers - let Dedalus choose which to use"""
    
    from datetime import datetime, timezone
    import pytz
    
    # Get current datetime for context
    now_utc = datetime.now(timezone.utc)
    now_pst = now_utc.astimezone(pytz.timezone('America/Los_Angeles'))
    date_context = f"Today is {now_pst.strftime('%A, %B %d, %Y at %I:%M %p PST')}. "
    
    # Initialize Dedalus client
    client = AsyncDedalus()
    runner = DedalusRunner(client)
    
    # ALL available MCP servers
    all_mcp_servers = [
        "tsion/brave-search-mcp",      # Web search
        "joerup/open-meteo-mcp",        # Weather
        "vroom08/agentmail-mcp"         # Email (send, read, search)
    ]
    
    # Special case for simple datetime
    if tool_name == "get_datetime":
        timezone_name = parameters.get('timezone', 'UTC')
        try:
            if timezone_name == 'UTC':
                target_time = now_utc
            else:
                tz = pytz.timezone(timezone_name)
                target_time = now_utc.astimezone(tz)
            
            return f"Current date and time in {timezone_name}: {target_time.strftime('%A, %B %d, %Y at %I:%M %p %Z')}"
        except Exception as e:
            return f"Current UTC time: {now_utc.strftime('%A, %B %d, %Y at %I:%M %p UTC')}"
    
    # For EVERYTHING else, just one handler!
    else:
        # Get the request/query from parameters
        request = parameters.get('request') or parameters.get('query') or parameters.get('prompt') or ""
        
        # Add date context for time-sensitive queries
        if any(word in request.lower() for word in ['news', 'latest', 'today', 'current', 'recent', 'now', 'weather']):
            request = f"{date_context}{request}"
        
        # Let Dedalus figure out which MCP servers to use!
        result = await runner.run(
            input=request,
            model=["openai/gpt-4-turbo"],
            mcp_servers=all_mcp_servers,  # Pass ALL servers, Dedalus chooses
            stream=False
        )
        return result.final_output