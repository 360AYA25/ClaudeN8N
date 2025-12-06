# Gemini n8n Agent System

This is a self-contained, autonomous agent orchestration system for managing n8n workflows. It is designed to be "dropped in" to a new project and activated immediately.

## 🤖 AI "Bootloader" Instructions

**If you are an AI agent reading this:**
Your task is to initialize this system and become its operator. Follow these steps sequentially.

### Phase 1: System Initialization

1.  **Install Dependencies:**
    Execute the following command to install the required packages (Express, Zod, LowDB, Google AI SDK):
    ```bash
    npm install
    ```

2.  **Environment Configuration:**
    Create a `.env` file in this directory (`gemini/`). You must populate the following keys:
    ```env
    # Required for the "Brain"
    GEMINI_API_KEY=AIzaSy...

    # Required for the "Hands" (n8n interaction via MCP)
    # If using n8n-mcp via SSE or Stdio, ensure the server is running.
    # For this standalone version, mock tools are provided in src/tools/MCPToolDefinitions.ts.
    # To connect to real n8n, you will need to implement the real MCP client connection.
    ```

3.  **Compile:**
    Build the TypeScript source code:
    ```bash
    npm run build
    ```

4.  **Start Server:**
    Launch the agent orchestration API:
    ```bash
    npm start
    ```
    *The server runs on port 3000 by default.*

### Phase 2: MCP Connection (The "Hands")

The system currently uses a **Mock MCP Client** (`src/tools/MCPToolDefinitions.ts`) for safety and testing. To enable real n8n control:

1.  **Install n8n-mcp:**
    You need the Model Context Protocol server for n8n.
    ```bash
    npx -y @anthropic/n8n-mcp
    ```
    *Note: Ensure `N8N_API_URL` and `N8N_API_KEY` are set in your environment.*

2.  **Bridge Connection:**
    The `AgentRunner.ts` needs to be updated to connect to the running MCP server (via SSE or Stdio) instead of using the `mockExecution` method.

### Phase 3: Operational Protocol

Once the system is running, you interact with it via HTTP API.

**1. Start a Session:**
```http
POST /session
Content-Type: application/json

{
  "request": "Create a Telegram bot that saves messages to Supabase"
}
```
*Response: `{"sessionId": "uuid-..."}`*

**2. Run the Loop:**
The system is passive. You (the AI operator) must drive the loop by calling the `/task` endpoint, checking the state, and advancing the stage.

*   **Check State:** `GET /session/{sessionId}`
*   **Execute Agent:**
    ```http
    POST /task
    Content-Type: application/json

    {
      "sessionId": "...",
      "agent": "architect",  // or researcher, builder, qa, analyst
      "instruction": "Clarify requirements and create blueprint"
    }
    ```

### Phase 4: Knowledge Injection

The system is pre-loaded with expert skills in `src/prompts/skills/`:
- `n8n-code-javascript.md`
- `n8n-node-configuration.md`
- `n8n-workflow-patterns.md`
- `n8n-validation-expert.md`

**Do not modify these files unless you are the Analyst agent conducting a Post-Mortem.**

## Project Structure

```
gemini/
├── db.json                 # Persisted state (LowDB)
├── dist/                   # Compiled JS
├── src/
│   ├── server.ts           # API Entrypoint
│   ├── services/
│   │   ├── AgentRunner.ts  # Logic Engine (The "Loop")
│   │   ├── GeminiAdapter.ts# AI Connection (The "Brain")
│   │   └── SessionManager.ts # State DB (The "Memory")
│   ├── prompts/
│   │   ├── agents/         # Personas (Architect, Builder...)
│   │   ├── core/           # Governance (Strict Mode, Gates)
│   │   └── skills/         # Knowledge Base (JS, n8n internals)
│   └── tools/
│       └── MCPToolDefinitions.ts # Tool Interfaces
└── tests/                  # Unit tests
```

## Governance Rules (Immutable)

1.  **Strict Mode:** The Orchestrator never uses tools directly. Delegation only.
2.  **Validation Gates:**
    - No build without research (Gate 0).
    - No success without MCP proof (Gate 5).
    - No pass without real execution (Gate 3).
3.  **Persistence:** All state changes must be saved to `db.json` immediately.

---
*System Ready. Waiting for ignition.*