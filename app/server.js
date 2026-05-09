/**
 * DevOps Challenge — Sample Application
 *
 * A minimal Express server that exposes:
 *   GET /        — returns service metadata as JSON
 *   GET /health  — health check endpoint used by the ALB target group
 *
 * Kept deliberately simple. The interesting engineering in this project
 * is the infrastructure around it, not the application itself.
 *
 * Module structure:
 *   - The Express `app` is exported so the test suite can mount it without
 *     starting an HTTP listener (which would cause EADDRINUSE in tests).
 *   - The HTTP server only starts when this file is the entry point —
 *     i.e. when invoked as `node server.js`, not when required.
 */

const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';
const ENVIRONMENT = process.env.ENVIRONMENT || 'development';

// Service metadata endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'devops-challenge-api',
    version: VERSION,
    environment: ENVIRONMENT,
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname(),
  });
});

// Health check endpoint — used by the ALB target group health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Only start the HTTP listener when this file is the entry point.
// When the test suite requires this module, it gets `app` (the request
// handler) without starting a listener — supertest mounts it directly.
if (require.main === module) {
  const server = app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT} (env: ${ENVIRONMENT}, version: ${VERSION})`);
  });

  // Graceful shutdown — ECS sends SIGTERM when stopping a task; we want
  // in-flight requests to drain before the process exits.
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
      console.log('HTTP server closed');
      process.exit(0);
    });
  });
}

module.exports = app;