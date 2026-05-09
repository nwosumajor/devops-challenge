# Multi-stage Dockerfile for the DevOps challenge application.
#
# Stage 1 (deps):  installs production dependencies in isolation
# Stage 2 (test):  runs the test suite with dev dependencies present
# Stage 3 (final): produces a minimal runtime image with only what's needed
#
# Design choices:
# - Pinned base image digest would be ideal for full reproducibility;
#   for this challenge we pin to a specific minor version of node.
# - alpine for size; node:20 is ~190MB, node:20-alpine is ~45MB.
# - non-root user (node) at runtime — defense in depth against container escapes.
# - tini as PID 1 to handle SIGTERM correctly during ECS task stops.

# ============================================================================
# Stage 1: Install production dependencies
# ============================================================================
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only the dependency manifests — exploits Docker layer caching:
# layers above the application source code are reused across builds when
# package.json hasn't changed, even if server.js has.
COPY package.json package-lock.json* ./

# --omit=dev skips devDependencies (jest, supertest) — saves ~80MB
# --no-audit --no-fund silences npm noise that pollutes CI logs
RUN npm ci --omit=dev --no-audit --no-fund

# ============================================================================
# Stage 2: Run tests (with dev dependencies)
# ============================================================================
FROM node:20-alpine AS test

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --no-audit --no-fund

COPY . .

# If tests fail, the build fails. This is intentional — we never want
# to ship an image that has not passed its tests.
RUN npm test

# ============================================================================
# Stage 3: Final runtime image
# ============================================================================
FROM node:20-alpine AS runtime

# tini handles signal forwarding so the Node process receives SIGTERM
# correctly when ECS stops the task. Without it, Node may not shut down
# cleanly within the grace period and gets SIGKILLed.
RUN apk add --no-cache tini

WORKDIR /app

# Copy production dependencies from the deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source
COPY --chown=node:node server.js package.json ./

# Run as the non-root 'node' user that the official image provides
USER node

# Expose the application port for documentation purposes
# (does not actually publish the port — that's done at runtime by ECS)
EXPOSE 3000

# Use tini as PID 1 — guarantees correct signal handling for graceful shutdown
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]