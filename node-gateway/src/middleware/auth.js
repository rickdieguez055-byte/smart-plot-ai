/**
 * Authentication & Role-Based Access Control integration point per SP-AI-13 and SP-AUTH-06.
 * Prepares the integration point for Appwrite / JWT authentication.
 */
const config = require('../config');

function authMiddleware(req, res, next) {
  // If authentication is disabled for local dev/testing
  if (!config.requireAuth) {
    req.user = {
      id: req.headers['x-user-id'] || 'dev-buyer-001',
      role: req.headers['x-user-role'] || 'Buyer/Client',
      isDev: true,
    };
    return next();
  }

  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      status: 'error',
      code: 'UNAUTHORIZED',
      message: 'Authentication token required to access SmartPlot AI services.',
    });
  }

  const token = authHeader.split(' ')[1];

  // Simulation of Appwrite / JWT role decoding (Integration Point)
  // In production, token is verified against Appwrite session / JWT secret.
  const userRole = req.headers['x-user-role'] || (token.includes('company') ? 'Construction Company' : 'Buyer/Client');

  // Enforce SP-AI-13: Accept AI requests only from Buyer/Client
  if (userRole !== 'Buyer/Client' && userRole !== 'Platform Administrator') {
    return res.status(403).json({
      status: 'error',
      code: 'FORBIDDEN_ROLE',
      message: `Role '${userRole}' is not permitted to generate AI plot layouts. Only 'Buyer/Client' has access (SP-AI-13).`,
    });
  }

  req.user = {
    id: req.headers['x-user-id'] || 'auth-user',
    role: userRole,
    token: token,
  };

  next();
}

module.exports = authMiddleware;
