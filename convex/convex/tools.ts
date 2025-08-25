import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const logExecution = mutation({
  args: {
    sessionId: v.string(),
    toolName: v.string(),
    input: v.any(),
    output: v.any(),
    success: v.boolean(),
    executionTime: v.number(),
  },
  handler: async (ctx, args) => {
    await ctx.db.insert("toolExecutions", {
      ...args,
      timestamp: Date.now(),
    });
  },
});

export const getSessionHistory = query({
  args: {
    sessionId: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("toolExecutions")
      .withIndex("by_session", (q) => q.eq("sessionId", args.sessionId))
      .order("desc")
      .collect();
  },
});

export const getRecentExecutions = query({
  args: {
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit || 20;
    return await ctx.db
      .query("toolExecutions")
      .order("desc")
      .take(limit);
  },
});