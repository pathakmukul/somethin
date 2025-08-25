/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";
import type * as commands from "../commands.js";
import type * as http from "../http.js";
import type * as lib_dedalus from "../lib/dedalus.js";
import type * as notes from "../notes.js";
import type * as realtime from "../realtime.js";
import type * as settings from "../settings.js";
import type * as tools from "../tools.js";
import type * as vapi_toolHandler from "../vapi/toolHandler.js";

/**
 * A utility for referencing Convex functions in your app's API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
declare const fullApi: ApiFromModules<{
  commands: typeof commands;
  http: typeof http;
  "lib/dedalus": typeof lib_dedalus;
  notes: typeof notes;
  realtime: typeof realtime;
  settings: typeof settings;
  tools: typeof tools;
  "vapi/toolHandler": typeof vapi_toolHandler;
}>;
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;
