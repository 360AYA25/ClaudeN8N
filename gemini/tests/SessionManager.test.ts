import { SessionManager } from '../src/services/SessionManager';

// Mock lowdb v1
jest.mock('lowdb', () => {
  return jest.fn().mockImplementation(() => ({
    defaults: jest.fn().mockReturnThis(),
    write: jest.fn().mockReturnThis(),
    get: jest.fn().mockImplementation((path) => {
      return {
        value: jest.fn(),
        push: jest.fn().mockReturnThis(),
        write: jest.fn()
      };
    }),
    set: jest.fn().mockReturnThis()
  }));
});

jest.mock('lowdb/adapters/FileSync', () => {
  return jest.fn().mockImplementation(() => ({}));
});

describe('SessionManager', () => {
  let sessionManager: SessionManager;

  beforeEach(async () => {
    // Clear mocks
    jest.clearAllMocks();
    sessionManager = new SessionManager();
    // We need to overwrite the db instance with a more functional mock for testing logic
    // Or we rely on integration tests. 
    // Since mocking the fluent API of lowdb v1 is complex in unit tests without a real library,
    // we will focus on verifying the method calls in a simplified way or use a real in-memory adapter if possible.
    // For this environment, let's mock the internal DB structure directly.
    
    // Re-mock for functional testing within this scope
    const mockDb = {
        defaults: jest.fn().mockReturnThis(),
        write: jest.fn(),
        set: jest.fn().mockReturnThis(),
        get: jest.fn()
    };
    
    (sessionManager as any).db = mockDb;
    (sessionManager as any).ready = true;
  });

  it('should call db.set when creating a session', async () => {
    await sessionManager.createSession('Test');
    expect((sessionManager as any).db.set).toHaveBeenCalled();
  });
});