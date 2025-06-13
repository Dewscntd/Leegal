# Multi-stage Docker template for ContractAnalyzer microservices
# Usage: docker build --build-arg SERVICE=<service-name> -f Dockerfile.base.tpl .

ARG SERVICE
ARG NODE_VERSION=20

# Stage 1: Build stage
FROM node:${NODE_VERSION}-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./
COPY contract-analyzer/package*.json ./contract-analyzer/
COPY contract-analyzer/nx.json ./contract-analyzer/
COPY contract-analyzer/tsconfig*.json ./contract-analyzer/

# Copy workspace configuration
COPY contract-analyzer/apps/package.json ./contract-analyzer/apps/
COPY contract-analyzer/apps/*/package.json ./contract-analyzer/apps/*/

# Install dependencies with frozen lockfile
RUN cd contract-analyzer && npm ci

# Copy source code
COPY contract-analyzer/ ./contract-analyzer/

# Build the specific service
ARG SERVICE
RUN cd contract-analyzer && npx nx run ${SERVICE}:build

# Stage 2: Production stage (distroless style)
FROM node:${NODE_VERSION}-slim AS production

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy built application from builder stage
ARG SERVICE
COPY --from=builder /app/contract-analyzer/dist/apps/${SERVICE} ./
COPY --from=builder /app/contract-analyzer/node_modules ./node_modules

# Copy package.json for runtime (try service-specific first, fallback to apps/package.json)
RUN if [ -f /app/contract-analyzer/apps/${SERVICE}/package.json ]; then \
      cp /app/contract-analyzer/apps/${SERVICE}/package.json ./package.json; \
    else \
      cp /app/contract-analyzer/apps/package.json ./package.json; \
    fi

# Install only production dependencies
RUN npm prune --production

# Change ownership to non-root user
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

# Start the application
CMD ["node", "main.js"]
