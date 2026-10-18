# syntax=docker/dockerfile:1
# Multi-stage, non-root, with a healthcheck. Replace the demo app with your project.
# Tip: once you have verified a base image, pin it by digest (image@sha256:...).
# Dependabot's docker ecosystem keeps tags/digests current.

FROM node:26-alpine AS build
WORKDIR /app
COPY app/ ./
# Example for a project with dependencies:
#   COPY app/package*.json ./
#   RUN npm ci --omit=dev
#   COPY app/ ./

FROM node:26-alpine
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=build --chown=node:node /app ./
USER 1000
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:8080/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
CMD ["node", "server.js"]
