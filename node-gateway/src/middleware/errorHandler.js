/**
 * Global error handling middleware for API Gateway.
 */

function errorHandler(err, req, res, next) {
  // Axios error from upstream AI microservice
  if (err.isAxiosError) {
    if (err.code === 'ECONNABORTED' || err.message.includes('timeout')) {
      return res.status(504).json({
        status: 'error',
        code: 'AI_SERVICE_TIMEOUT',
        message: 'The AI layout generation microservice exceeded the timeout limit. Please retry with simplified parameters (SP-AI-11).',
      });
    }

    if (err.code === 'ECONNREFUSED' || !err.response) {
      return res.status(503).json({
        status: 'error',
        code: 'AI_SERVICE_UNAVAILABLE',
        message: 'The AI layout microservice is currently unreachable. Please verify microservice status and retry (SP-AI-11).',
      });
    }

    // Forward upstream status and JSON response (e.g. 422 Infeasibility)
    return res.status(err.response.status).json(err.response.data);
  }

  // Fallback server error
  console.error('[Gateway Error]:', err);
  res.status(500).json({
    status: 'error',
    code: 'GATEWAY_INTERNAL_ERROR',
    message: 'An unexpected internal error occurred in the SmartPlot API gateway.',
    details: { error: err.message },
  });
}

module.exports = errorHandler;
