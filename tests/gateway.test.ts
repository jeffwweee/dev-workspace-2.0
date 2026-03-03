import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawn, ChildProcess } from 'child_process';
import http from 'http';

describe('Gateway', () => {
  let server: ChildProcess;

  beforeAll(async () => {
    // Start gateway server
    server = spawn('npm', ['run', 'dev'], {
      cwd: '../gateway',
      stdio: 'pipe'
    });

    // Wait for server to start
    await new Promise(resolve => setTimeout(resolve, 2000));
  });

  afterAll(() => {
    server?.kill();
  });

  it('should respond to health check', async () => {
    const response = await fetch('http://localhost:3100/health');
    const data = await response.json();
    expect(data.status).toBe('ok');
  });

  it('should reject invalid webhook messages', async () => {
    const response = await fetch('http://localhost:3100/webhook/pichu', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    expect(response.status).toBe(400);
  });

  it('should reject reply without required fields', async () => {
    const response = await fetch('http://localhost:3100/reply', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    expect(response.status).toBe(400);
  });
});
