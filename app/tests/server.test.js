/**
 * Basic smoke tests for the application.
 *
 * The challenge brief allows for "basic" testing. These tests verify that
 * the two endpoints respond correctly and return the expected shape.
 * In a real production codebase this would be expanded with input validation,
 * error handling, and integration tests.
 */

const request = require('supertest');
const app = require('../server');

describe('GET /', () => {
  it('returns service metadata with status 200', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('service', 'devops-challenge-api');
    expect(response.body).toHaveProperty('version');
    expect(response.body).toHaveProperty('timestamp');
  });

  it('returns valid JSON', async () => {
    const response = await request(app).get('/');
    expect(response.headers['content-type']).toMatch(/json/);
  });
});

describe('GET /health', () => {
  it('returns status 200 and healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'healthy' });
  });
});