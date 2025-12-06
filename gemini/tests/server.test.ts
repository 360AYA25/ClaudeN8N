import request from 'supertest';
import { app } from '../src/server';

// Mock lowdb to prevent file IO
jest.mock('lowdb', () => {
  const mockData: any = { sessions: {} };
  return jest.fn().mockImplementation(() => ({
    defaults: jest.fn().mockReturnThis(),
    write: jest.fn(),
    get: jest.fn().mockImplementation((path: string) => {
      if (path.startsWith('sessions.')) {
        const id = path.split('.')[1];
        // Special handling for array push
        if (path.endsWith('.agent_log')) {
             return {
                 push: (item: any) => {
                     if (mockData.sessions[id]) mockData.sessions[id].agent_log.push(item);
                     return { write: jest.fn() }
                 },
                 write: jest.fn()
             }
        }
        return { value: () => mockData.sessions[id] };
      }
      return { value: () => undefined };
    }),
    set: jest.fn().mockImplementation((path: string, val: any) => {
        if (path.startsWith('sessions.')) {
            const id = path.split('.')[1];
            mockData.sessions[id] = val;
        }
        return { write: jest.fn() };
    })
  }));
});

jest.mock('lowdb/adapters/FileSync', () => jest.fn());

// Mock Gemini Adapter
jest.mock('../src/services/GeminiAdapter', () => {
  return {
    GeminiAdapter: jest.fn().mockImplementation(() => ({
      generateResponse: jest.fn().mockResolvedValue("Mock Gemini Response")
    }))
  };
});

describe('Gemini Agent System API', () => {
  it('GET /status should return production ready status', async () => {
    const res = await request(app).get('/status');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('mode', 'PRODUCTION_READY');
  });

  it('POST /session should create a persisted session', async () => {
    const res = await request(app).post('/session').send({ request: 'Test Project' });
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('sessionId');
  });

  it('POST /task should run an agent', async () => {
    const initRes = await request(app).post('/session').send({ request: 'Build a bot' });
    const sessionId = initRes.body.sessionId;

    const res = await request(app).post('/task').send({
      sessionId: sessionId,
      agent: 'architect',
      instruction: 'Clarify requirements'
    });
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('success');
  });
  
  it('POST /task should Enforce Gate 0', async () => {
    const initRes = await request(app).post('/session').send({ request: 'Start' });
    const sessionId = initRes.body.sessionId;
    
    const res = await request(app).post('/task').send({
      sessionId: sessionId,
      agent: 'builder',
      instruction: 'Build workflow now'
    });
    
    expect(res.statusCode).toEqual(400);
    expect(res.body.error).toContain('GATE VIOLATION');
  });
});
