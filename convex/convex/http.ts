import { httpRouter } from "convex/server";
import { toolHandler } from "./vapi/toolHandler";

const http = httpRouter();

// Route for VAPI webhook
http.route({
  path: "/vapi/toolHandler",
  method: "POST",
  handler: toolHandler,
});

export default http;