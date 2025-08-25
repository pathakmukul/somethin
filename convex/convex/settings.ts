import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

// Get user settings
export const get = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    const settings = await ctx.db
      .query("userSettings")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .first();
    
    return settings || null;
  },
});

// Save or update user settings
export const save = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    email: v.string(),
    bio: v.optional(v.string()),
    favoriteMusic: v.optional(v.string()),
    favoriteMovies: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("userSettings")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .first();

    // Generate summary based on user data
    const summary = `User ${args.name} (${args.email}). ${args.bio ? `Bio: ${args.bio}. ` : ''}${args.favoriteMusic ? `Likes ${args.favoriteMusic} music. ` : ''}${args.favoriteMovies ? `Enjoys ${args.favoriteMovies} movies.` : ''}`;

    const now = Date.now();

    if (existing) {
      // Update existing settings
      await ctx.db.patch(existing._id, {
        ...args,
        summary,
        updatedAt: now,
      });
      return existing._id;
    } else {
      // Create new settings
      return await ctx.db.insert("userSettings", {
        ...args,
        summary,
        createdAt: now,
        updatedAt: now,
      });
    }
  },
});

// Get all contacts for a user
export const getContacts = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("contacts")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .collect();
  },
});

// Add a new contact
export const addContact = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    email: v.string(),
    nickname: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    
    return await ctx.db.insert("contacts", {
      ...args,
      createdAt: now,
      updatedAt: now,
    });
  },
});

// Update a contact
export const updateContact = mutation({
  args: {
    id: v.id("contacts"),
    name: v.optional(v.string()),
    email: v.optional(v.string()),
    nickname: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    
    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });
    
    return id;
  },
});

// Delete a contact
export const deleteContact = mutation({
  args: { id: v.id("contacts") },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.id);
  },
});

// Find contact by name or nickname (for voice commands)
export const findContactByName = query({
  args: {
    userId: v.string(),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    const contacts = await ctx.db
      .query("contacts")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .collect();
    
    const lowerName = args.name.toLowerCase();
    
    return contacts.find(contact => 
      contact.name.toLowerCase().includes(lowerName) ||
      (contact.nickname && contact.nickname.toLowerCase().includes(lowerName))
    ) || null;
  },
});