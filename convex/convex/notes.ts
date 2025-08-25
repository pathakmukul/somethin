import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const create = mutation({
  args: {
    title: v.string(),
    content: v.string(),
    userId: v.optional(v.string()),
    tags: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const noteId = await ctx.db.insert("notes", {
      title: args.title,
      content: args.content,
      userId: args.userId,
      tags: args.tags,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    });
    return noteId;
  },
});

export const list = query({
  args: {
    userId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    if (args.userId) {
      return await ctx.db
        .query("notes")
        .withIndex("by_user", (q) => q.eq("userId", args.userId))
        .order("desc")
        .collect();
    }
    return await ctx.db.query("notes").order("desc").take(50);
  },
});

export const update = mutation({
  args: {
    id: v.id("notes"),
    title: v.optional(v.string()),
    content: v.optional(v.string()),
    tags: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });
  },
});

export const remove = mutation({
  args: {
    id: v.id("notes"),
  },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.id);
  },
});

export const search = query({
  args: {
    query: v.string(),
  },
  handler: async (ctx, args) => {
    const allNotes = await ctx.db.query("notes").order("desc").collect();
    
    if (!args.query || args.query.trim() === "") {
      // Return all notes if no query
      return allNotes.slice(0, 10);
    }
    
    const queryLower = args.query.toLowerCase();
    
    // Search in title and content
    const filteredNotes = allNotes.filter(note => 
      note.title.toLowerCase().includes(queryLower) ||
      note.content.toLowerCase().includes(queryLower)
    );
    
    return filteredNotes.slice(0, 10);
  },
});