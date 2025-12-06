import { StateManager, RunState } from './StateManager';
import systemConfig from '../../config/gemini-system.json';

export class AgentOrchestrator {
  private stateManager: StateManager;

  constructor(stateManager: StateManager) {
    this.stateManager = stateManager;
  }

  public getSystemStatus(): any {
    const state = this.stateManager.getState();
    return {
      system: systemConfig.system_name,
      mode: systemConfig.strict_mode ? "STRICT" : "LAX",
      current_run: {
        id: state.id,
        stage: state.stage,
        request: state.user_request || "(idle)",
        logs: state.agent_log.length
      },
      available_agents: Object.keys(systemConfig.agents)
    };
  }

  // Simulates the "Task" delegation command
  public async delegateTask(agentName: string, taskDescription: string): Promise<any> {
    const state = this.stateManager.getState();
    
    // Gate Checks (Simulation of VALIDATION-GATES.md)
    if (agentName === 'builder' && state.stage === 'clarification') {
      throw new Error("GATE VIOLATION: Cannot call Builder in Clarification stage. Gate 0.");
    }

    // Log the delegation
    this.stateManager.addLogEntry('orchestrator', 'delegate', { to: agentName, task: taskDescription });

    // In a real implementation, this would invoke the LLM or specific agent logic
    // For this clone, we return a simulation of the agent accepting the task
    return {
      status: "accepted",
      agent: agentName,
      timestamp: new Date().toISOString(),
      message: `Agent ${agentName} received task: ${taskDescription}`
    };
  }
}
