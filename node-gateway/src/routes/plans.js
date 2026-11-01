/**
 * AI Layout Generation Routes per SP-AI-05, SP-AI-06, SP-AI-11, SP-AI-13.
 */
const express = require('express');
const axios = require('axios');
const config = require('../config');
const authMiddleware = require('../middleware/auth');
const { validatePlanGenerateRequest } = require('../middleware/validator');

const router = express.Router();

/**
 * POST /api/v1/plans/generate
 * Gateway proxy to Python/FastAPI AI Microservice
 */
router.post(
  '/generate',
  authMiddleware,
  validatePlanGenerateRequest,
  async (req, res, next) => {
    try {
      const response = await axios.post(
        `${config.aiServiceUrl}/api/v1/plans/generate`,
        req.body,
        {
          timeout: config.aiServiceTimeoutMs,
          headers: {
            'Content-Type': 'application/json',
            'X-Gateway-User-Id': req.user ? req.user.id : 'anonymous',
            'X-Gateway-User-Role': req.user ? req.user.role : 'Buyer/Client',
            'X-Internal-Key': config.internalApiKey,
          },
        }
      );

      return res.status(response.status).json(response.data);
    } catch (err) {
      return next(err);
    }
  }
);

module.exports = router;
