/**
 * MCP Tool Definitions for Gemini Agent System
 *
 * This file defines the interfaces and mock implementations for the n8n-mcp tools.
 * In a real deployment, these would connect to the actual MCP server via stdio/SSE.
 */

export interface MCPTool {
  name: string;
  description: string;
  parameters: object;
}

export const n8nTools: MCPTool[] = [
  {
    name: "n8n_get_workflow",
    description: "Retrieve workflow JSON data. Use mode='structure' for large workflows.",
    parameters: {
      type: "object",
      properties: {
        id: { type: "string", description: "Workflow ID" },
        mode: { type: "string", enum: ["full", "structure", "minimal"], default: "full" }
      },
      required: ["id"]
    }
  },
  {
    name: "n8n_create_workflow",
    description: "Create a new workflow in n8n.",
    parameters: {
      type: "object",
      properties: {
        name: { type: "string" },
        nodes: { type: "array" },
        connections: { type: "object" },
        active: { type: "boolean" }
      },
      required: ["name", "nodes", "connections"]
    }
  },
  {
    name: "n8n_update_workflow",
    description: "Update an existing workflow.",
    parameters: {
      type: "object",
      properties: {
        id: { type: "string" },
        name: { type: "string" },
        nodes: { type: "array" },
        connections: { type: "object" }
      },
      required: ["id"]
    }
  },
  {
    name: "n8n_list_workflows",
    description: "List workflows in the n8n instance.",
    parameters: {
      type: "object",
      properties: {
        active: { type: "boolean" },
        tags: { type: "array", items: { type: "string" } },
        limit: { type: "number", default: 50 }
      }
    }
  },
  {
    name: "n8n_executions",
    description: "Retrieve execution logs for debugging.",
    parameters: {
      type: "object",
      properties: {
        action: { type: "string", enum: ["list", "get"] },
        workflowId: { type: "string" },
        id: { type: "string", description: "Execution ID (for get action)" },
        limit: { type: "number" },
        mode: { type: "string", enum: ["summary", "filtered", "full"] }
      }
    }
  },
  {
    name: "search_nodes",
    description: "Search for n8n nodes documentation.",
    parameters: {
      type: "object",
      properties: {
        query: { type: "string" }
      },
      required: ["query"]
    }
  },
  {
    name: "get_node_essentials",
    description: "Get essential configuration fields for a node type.",
    parameters: {
      type: "object",
      properties: {
        nodeType: { type: "string" }
      },
      required: ["nodeType"]
    }
  }
];

// Mock Client for standalone mode
export class MCPClient {
  private connected: boolean = false;

  constructor(private serverUrl?: string) {}

  async connect() {
    console.log("Connecting to MCP server...");
    this.connected = true;
  }

  async callTool(toolName: string, args: any): Promise<any> {
    if (!this.connected) await this.connect();

    console.log(`[MCP] Calling ${toolName} with args:`, JSON.stringify(args));

    // Mock Responses for "Clone" mode
    if (toolName === "n8n_list_workflows") {
      return {
        data: [
          { id: "workflow_1", name: "Telegram Bot", active: true },
          { id: "workflow_2", name: "Data Sync", active: false }
        ]
      };
    }

    if (toolName === "n8n_get_workflow") {
      return {
        id: args.id,
        name: "Mock Workflow",
        nodes: [],
        connections: {},
        active: true,
        versionId: "mock-version-1"
      };
    }

    if (toolName === "n8n_executions") {
      return {
        data: [],
        message: "No executions found in mock mode"
      };
    }

    return { status: "success", mock: true, tool: toolName };
  }
}
