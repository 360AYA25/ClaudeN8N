import * as fs from 'fs';
import * as path from 'path';
import { SessionManager, RunState } from './SessionManager';
import { GeminiAdapter } from './GeminiAdapter';
import { MCPClient } from '../tools/MCPToolDefinitions';

export class AgentRunner {
  private mcpClient: MCPClient;

  constructor(
    private sessionManager: SessionManager,
    private ai: GeminiAdapter
  ) {
    this.mcpClient = new MCPClient();
  }

  private loadPrompt(agentName: string): string {
    // Robust path handling
    const promptPath = path.resolve(__dirname, `../prompts/agents/${agentName}.md`);
    if (!fs.existsSync(promptPath)) {
      throw new Error(`Prompt file not found for agent: ${agentName} at ${promptPath}`);
    }
    return fs.readFileSync(promptPath, 'utf-8');
  }

  private loadSystemPrompt(name: string): string {
    const promptPath = path.resolve(__dirname, `../prompts/core/${name}.md`);
    return fs.existsSync(promptPath) ? fs.readFileSync(promptPath, 'utf-8') : "";
  }

  public async runAgent(sessionId: string, agentName: string, inputTask: string): Promise<any> {
    // 1. Retrieve State (Thread-safe via SessionManager)
    const state = await this.sessionManager.getSession(sessionId);
    if (!state) throw new Error("Session not found");

    // 2. Check Gates (Gate 0 simulation)
    if (agentName === 'builder' && state.stage === 'clarification') {
        throw new Error("GATE VIOLATION (Gate 0): Cannot run Builder in Clarification stage. Research required.");
    }

    // 3. Prepare Context
    const agentPrompt = this.loadPrompt(agentName);
    const validationGates = this.loadSystemPrompt('validation-gates');
    
    console.log(`[AgentRunner] 🟢 Executing ${agentName} on session ${sessionId.substring(0,8)}...`);

    // 4. AI Execution
    // If we have an API key, we use Gemini. If not, we fallback to mock for testing stability.
    let output;
    if (process.env.GEMINI_API_KEY) {
        output = await this.ai.generateResponse(agentPrompt, inputTask, state);
    } else {
        // Mock behavior if no key (for initial testing)
        console.log("[AgentRunner] ⚠️ No API Key. Using Mock Logic.");
        output = await this.mockExecution(agentName, inputTask);
    }

    // 5. Log Execution
    await this.sessionManager.addLog(sessionId, agentName, 'execution_complete', {
        task: inputTask,
        output_summary: output.substring(0, 100) + "..."
    });

    return {
      status: "success",
      agent: agentName,
      output: output
    };
  }

  // Fallback mock logic for testing without costs
  private async mockExecution(agent: string, task: string): Promise<any> {
      if (agent === 'researcher') {
          return JSON.stringify({ 
              findings: "Mock research findings", 
              templates: ["template_1", "template_2"] 
          });
      }
      return `Mock response from ${agent} for task: ${task}`;
  }
}