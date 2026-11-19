/**
 * Centralized gateway configuration.
 */
require('dotenv').config();

module.exports = {
  port: parseInt(process.env.PORT, 10) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  aiServiceUrl: process.env.AI_SERVICE_URL || 'http://127.0.0.1:8000',
  aiServiceTimeoutMs: parseInt(process.env.AI_SERVICE_TIMEOUT_MS, 10) || 45000,
  requireAuth: process.env.REQUIRE_AUTH === 'true',
  internalApiKey: process.env.INTERNAL_API_KEY || 'smartplot-internal-dev-key',
  corsOrigin: process.env.CORS_ORIGIN || '*',
};
