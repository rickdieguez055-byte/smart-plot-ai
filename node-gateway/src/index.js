/**
 * SmartPlot API Gateway Entrypoint
 */
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config');
const healthRoutes = require('./routes/health');
const plansRoutes = require('./routes/plans');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Security and utility middleware
app.use(helmet());
app.use(cors({ origin: config.corsOrigin }));
app.use(morgan(config.nodeEnv === 'development' ? 'dev' : 'combined'));
app.use(express.json({ limit: '10mb' }));

// Route Mounts
app.use('/', healthRoutes);
app.use('/api/v1/plans', plansRoutes);

// Catch-all 404
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    code: 'ROUTE_NOT_FOUND',
    message: `Resource not found on path: ${req.originalUrl}`,
  });
});

// Error handling middleware
app.use(errorHandler);

if (require.main === module) {
  app.listen(config.port, () => {
    console.log(`[SmartPlot Gateway] Server running on port ${config.port} (${config.nodeEnv})`);
    console.log(`[SmartPlot Gateway] Upstream AI Microservice: ${config.aiServiceUrl}`);
  });
}

module.exports = app;
