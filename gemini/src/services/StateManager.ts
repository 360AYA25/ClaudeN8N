import { v4 as uuidv4 } from 'uuid';

// Interface mimicking the run-state.schema.json structure
export interface RunState {
  id: string;
  stage: 'clarification' | 'research' | 'decision' | 'build' | 'validate' | 'complete' | 'blocked';
  user_request: string;
  workflow_id?: string;
  agent_log: Array<{
    ts: string;
    agent: string;
    action: string;
    details: any;
  }>;
  data: Record<string, any>; // Flexible storage for research_findings, blueprint, etc.
}

export class StateManager {
  private state: RunState;

  constructor() {
    this.state = this.createInitialState();
  }

  private createInitialState(): RunState {
    return {
      id: uuidv4(),
      stage: 'clarification',
      user_request: '',
      agent_log: [],
      data: {}
    };
  }

  public getState(): RunState {
    return { ...this.state };
  }

  public updateState(partial: Partial<RunState>): RunState {
    this.state = { ...this.state, ...partial };
    return this.state;
  }

  public addLogEntry(agent: string, action: string, details: any): void {
    this.state.agent_log.push({
      ts: new Date().toISOString(),
      agent,
      action,
      details
    });
  }

  public setRequest(request: string): void {
    this.state.user_request = request;
  }
  
  public reset(): void {
    this.state = this.createInitialState();
  }
}
