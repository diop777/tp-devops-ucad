// test/app.test.js - Tests unitaires de l'API
const request = require('supertest');
const app = require('../app');

describe('API Tests', () => {
  it('GET / doit retourner pong', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('pong');
  });

  it('GET /health doit retourner status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
