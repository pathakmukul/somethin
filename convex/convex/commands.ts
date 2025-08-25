import { mutation } from "./_generated/server";
import { v } from "convex/values";

// Store commands for iOS to execute
export const addCommand = mutation({
  args: {
    action: v.string(),
    params: v.any(),
  },
  handler: async (ctx, args) => {
    const id = await ctx.db.insert("commands", {
      action: args.action,
      params: args.params,
      timestamp: Date.now(),
      executed: false,
    });
    return id;
  },
});

// Get and mark commands as executed
export const getUnexecutedCommands = mutation({
  args: {},
  handler: async (ctx) => {
    const commands = await ctx.db
      .query("commands")
      .filter((q) => q.eq(q.field("executed"), false))
      .collect();
    
    // Mark as executed
    for (const cmd of commands) {
      await ctx.db.patch(cmd._id, { executed: true });
    }
    
    return commands;
  },
});