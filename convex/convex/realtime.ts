import { mutation } from "./_generated/server";
import { v } from "convex/values";

// Mutation to notify all connected clients
export const notifyClients = mutation({
  args: {
    event: v.string(),
    data: v.any(),
  },
  handler: async (ctx, args) => {
    // Store the event in a table that clients can subscribe to
    await ctx.db.insert("realtimeEvents", {
      event: args.event,
      data: args.data,
      timestamp: Date.now(),
      processed: false,
    });
  },
});

// Query to get unprocessed events for a client
export const getUnprocessedEvents = mutation({
  args: {},
  handler: async (ctx) => {
    const events = await ctx.db
      .query("realtimeEvents")
      .filter((q) => q.eq(q.field("processed"), false))
      .order("desc")
      .take(10);
    
    // Mark as processed
    for (const event of events) {
      await ctx.db.patch(event._id, { processed: true });
    }
    
    return events;
  },
});