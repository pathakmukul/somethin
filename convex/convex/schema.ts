import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  conversations: defineTable({
    userId: v.optional(v.string()),
    sessionId: v.string(),
    message: v.string(),
    response: v.string(),
    toolsUsed: v.optional(v.array(v.string())),
    timestamp: v.number(),
    metadata: v.optional(v.any()),
  }).index("by_session", ["sessionId"])
    .index("by_user", ["userId"]),

  toolExecutions: defineTable({
    sessionId: v.string(),
    toolName: v.string(),
    input: v.any(),
    output: v.any(),
    success: v.boolean(),
    executionTime: v.number(),
    timestamp: v.number(),
  }).index("by_session", ["sessionId"]),

  userPreferences: defineTable({
    userId: v.string(),
    preferences: v.any(),
    updatedAt: v.number(),
  }).index("by_user", ["userId"]),

  userSettings: defineTable({
    userId: v.string(),
    name: v.string(),
    email: v.string(),
    bio: v.optional(v.string()),
    favoriteMusic: v.optional(v.string()),
    favoriteMovies: v.optional(v.string()),
    summary: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index("by_user", ["userId"])
    .index("by_email", ["email"]),

  contacts: defineTable({
    userId: v.string(),
    name: v.string(),
    email: v.string(),
    nickname: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index("by_user", ["userId"])
    .index("by_email", ["email"]),

  notes: defineTable({
    userId: v.optional(v.string()),
    title: v.string(),
    content: v.string(),
    createdAt: v.number(),
    updatedAt: v.number(),
    tags: v.optional(v.array(v.string())),
  }).index("by_user", ["userId"]),
});