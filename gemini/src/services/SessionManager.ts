import low from 'lowdb';
import FileSync from 'lowdb/adapters/FileSync';
import { v4 as uuidv4 } from 'uuid';
import { z } from 'zod';

// --- ZOD SCHEMA DEFINITION (Strict Typing) ---

export const LogEntrySchema = z.object({
  ts: z.string(),
  agent: z.string(),
  action: z.string(),
  details: z.any().optional()
});

export const RunStateSchema = z.object({
  id: z.string(),
  stage: z.enum(['clarification', 'research', 'decision', 'build', 'validate', 'complete', 'blocked']),
  user_request: z.string(),
  workflow_id: z.string().optional(),
  cycle_count: z.number().default(0),
  agent_log: z.array(LogEntrySchema),
  data: z.record(z.any()).default({}) // Flexible storage for agent artifacts
});

export type RunState = z.infer<typeof RunStateSchema>;

// Database Schema
interface DbSchema {
  sessions: Record<string, RunState>;
}

export class SessionManager {
  private db: low.LowdbSync<DbSchema>;
  private ready: boolean = false;

  constructor() {
      // Initialize with a dummy adapter to satisfy TS, actual init happens in init()
      const adapter = new FileSync<DbSchema>('db.json');
      this.db = low(adapter);
  }

  async init() {
    const adapter = new FileSync<DbSchema>('db.json');
    this.db = low(adapter);
    
    // Set defaults if empty
    this.db.defaults({ sessions: {} }).write();
    
    this.ready = true;
    console.log("[SessionManager] DB initialized (db.json)");
  }

  private checkReady() {
    if (!this.ready) throw new Error("SessionManager not initialized. Call init() first.");
  }

  async createSession(initialRequest: string): Promise<string> {
    this.checkReady();
    const id = uuidv4();
    
    const newState: RunState = {
      id,
      stage: 'clarification',
      user_request: initialRequest,
      cycle_count: 0,
      agent_log: [],
      data: {}
    };
    
    // Validate with Zod before saving (Runtime Safety)
    RunStateSchema.parse(newState);

    this.db.set(`sessions.${id}`, newState).write();
    return id;
  }

  async getSession(sessionId: string): Promise<RunState | null> {
    this.checkReady();
    const session = this.db.get(`sessions.${sessionId}`).value();
    return session || null;
  }

  async updateSession(sessionId: string, partial: Partial<RunState>): Promise<RunState> {
    this.checkReady();
    
    const current = this.db.get(`sessions.${sessionId}`).value();
    if (!current) throw new Error(`Session ${sessionId} not found`);
    
    const updated = { ...current, ...partial };
    
    // Validate again
    RunStateSchema.parse(updated);

    this.db.set(`sessions.${sessionId}`, updated).write();
    return updated;
  }

  async addLog(sessionId: string, agent: string, action: string, details: any) {
    const session = await this.getSession(sessionId);
    if (!session) throw new Error("Session missing");

    const entry = {
      ts: new Date().toISOString(),
      agent,
      action,
      details
    };

    // lowdb v1 push syntax
    this.db.get(`sessions.${sessionId}.agent_log`).push(entry).write();
  }
}