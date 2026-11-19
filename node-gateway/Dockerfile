# ==============================================================================
# SmartPlot AI — Node.js Express API Gateway Container
# ==============================================================================
FROM node:20-alpine

ENV NODE_ENV=production \
    PORT=5000 \
    AI_SERVICE_URL=http://ai-service:8000 \
    AI_SERVICE_TIMEOUT_MS=45000

WORKDIR /app

# Install dependencies first for Docker caching
COPY node-gateway/package*.json ./
RUN npm ci --only=production

# Copy application source
COPY node-gateway/ ./

# Expose public gateway port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

# Start express gateway
CMD ["node", "src/index.js"]
