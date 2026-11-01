/**
 * Health check route for API Gateway and upstream AI microservice.
 */
const express = require('express');
const axios = require('axios');
const config = require('../config');

const router = express.Router();

router.get('/health', async (req, res) => {
  let aiServiceStatus = 'unknown';
  let aiServiceLatencyMs = null;

  try {
    const startTime = Date.now();
    const response = await axios.get(`${config.aiServiceUrl}/health`, {
      timeout: 3000,
    });
    aiServiceLatencyMs = Date.now() - startTime;
    aiServiceStatus = response.data.status === 'ok' ? 'healthy' : 'degraded';
  } catch (err) {
    aiServiceStatus = 'unreachable';
  }

  res.json({
    status: 'ok',
    gateway: {
      name: 'smartplot-gateway',
      version: '1.0.0',
      uptime_seconds: Math.floor(process.uptime()),
    },
    ai_microservice: {
      url: config.aiServiceUrl,
      status: aiServiceStatus,
      latency_ms: aiServiceLatencyMs,
    },
  });
});

module.exports = router;
