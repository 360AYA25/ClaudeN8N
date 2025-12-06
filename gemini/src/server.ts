import express, { Request, Response } from 'express';
import { SessionManager } from './services/SessionManager';
import { AgentRunner } from './services/AgentRunner';
import { GeminiAdapter } from './services/GeminiAdapter';
import systemConfig from '../config/gemini-system.json';

const app = express();
const port = 3000;

app.use(express.json());

// Initialize Services
const sessionManager = new SessionManager();
const geminiAdapter = new GeminiAdapter(); // Reads env.GEMINI_API_KEY
const runner = new AgentRunner(sessionManager, geminiAdapter);

// Async Init Wrapper
(async () => {
    await sessionManager.init();
})();

// --- API ENDPOINTS ---

// GET /status - System Health
app.get('/status', (req: Request, res: Response) => {
  res.json({
    system: systemConfig.system_name,
    mode: "PRODUCTION_READY",
    db: "lowdb (json)",
    ai: process.env.GEMINI_API_KEY ? "online" : "offline (mock mode)"
  });
});

// POST /session - Start new session (Persistence!)
app.post('/session', async (req: Request, res: Response) => {
  try {
    const { request } = req.body;
    if (!request) throw new Error("User request is required");
    
    const sessionId = await sessionManager.createSession(request);
    res.json({ 
        message: "Session initialized", 
        sessionId,
        status: "clarification" 
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// GET /session/:id - Get State
app.get('/session/:id', async (req: Request, res: Response) => {
    const session = await sessionManager.getSession(req.params.id);
    if (!session) return res.status(404).json({ error: "Session not found" });
    res.json(session);
});

// POST /task - Run Agent
app.post('/task', async (req: Request, res: Response) => {
  const { sessionId, agent, instruction } = req.body;
  
  if (!sessionId || !agent) {
      return res.status(400).json({ error: "sessionId and agent are required" });
  }

  try {
    const result = await runner.runAgent(sessionId, agent, instruction);
    res.json(result);
  } catch (error: any) {
    console.error("Task Error:", error);
    res.status(400).json({ error: error.message });
  }
});

export const startServer = () => {
  app.listen(port, () => {
    console.log(`🚀 Gemini Agent System running on port ${port}`);
    console.log(`📁 DB: gemini/db.json`);
  });
};

export { app };