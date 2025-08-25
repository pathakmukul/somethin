
⏺ # Weather
  curl -X POST https://dedalus-api.vercel.app/api -H
  "Content-Type: application/json" -d '{"name": "get_weather", 
  "arguments": {"query": "weather in San Francisco"}}'

  # Air Quality
  curl -X POST https://dedalus-api.vercel.app/api -H
  "Content-Type: application/json" -d '{"name": "get_weather", 
  "arguments": {"query": "Get the air quality index and PM2.5 
  levels for San Francisco"}}'

  # Web Search
  curl -X POST https://dedalus-api.vercel.app/api -H
  "Content-Type: application/json" -d '{"name": "web_search", 
  "arguments": {"query": "latest news about artificial 
  intelligence"}}'

  # Email Send
  curl -X POST https://dedalus-api.vercel.app/api -H
  "Content-Type: application/json" -d '{"name": 
  "email_assistant", "arguments": {"request": "send email to 
  test@example.com with subject Meeting Tomorrow about our 
  project discussion"}}'

  # Date/Time
  curl -X POST https://dedalus-api.vercel.app/api -H
  "Content-Type: application/json" -d '{"name": "get_datetime",
   "arguments": {"timezone": "America/New_York"}}'
