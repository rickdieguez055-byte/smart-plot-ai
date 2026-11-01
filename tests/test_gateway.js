/**
 * Unit and integration tests for Node.js API Gateway.
 */
const assert = require('assert');
const http = require('http');
const app = require('../node-gateway/src/index');

let server;
const PORT = 5099;

function makeRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ statusCode: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ statusCode: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(JSON.stringify(postData));
    }
    req.end();
  });
}

async function runTests() {
  console.log('--- Running Node.js API Gateway Tests ---');
  server = app.listen(PORT);

  try {
    // Test 1: Health endpoint
    console.log('Test 1: GET /health');
    const healthRes = await makeRequest({
      hostname: '127.0.0.1',
      port: PORT,
      path: '/health',
      method: 'GET',
    });
    assert.strictEqual(healthRes.statusCode, 200);
    assert.strictEqual(healthRes.data.status, 'ok');
    assert.strictEqual(healthRes.data.gateway.name, 'smartplot-gateway');
    console.log('✓ Health endpoint test passed.');

    // Test 2: Validation on missing plot
    console.log('Test 2: POST /api/v1/plans/generate (missing plot)');
    const missingPlotRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/generate',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {}
    );
    assert.strictEqual(missingPlotRes.statusCode, 400);
    assert.strictEqual(missingPlotRes.data.code, 'MISSING_PLOT_PAYLOAD');
    console.log('✓ Missing plot payload validation passed.');

    // Test 3: Validation on negative dimensions
    console.log('Test 3: POST /api/v1/plans/generate (negative dimensions)');
    const negDimRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/generate',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: -50,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'North',
        },
      }
    );
    assert.strictEqual(negDimRes.statusCode, 400);
    assert.strictEqual(negDimRes.data.code, 'VALIDATION_FAILED');
    console.log('✓ Negative dimensions validation passed.');

    // Test 4: Validation on invalid orientation
    console.log('Test 4: POST /api/v1/plans/generate (invalid orientation)');
    const invOrientRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/generate',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: 50,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'InvalidSkyward',
        },
      }
    );
    assert.strictEqual(invOrientRes.statusCode, 400);
    assert.strictEqual(invOrientRes.data.code, 'VALIDATION_FAILED');
    console.log('✓ Invalid orientation validation passed.');

    console.log('\nAll Gateway unit tests passed successfully!');
  } finally {
    server.close();
  }
}

runTests().catch((err) => {
  console.error('Gateway tests failed:', err);
  if (server) server.close();
  process.exit(1);
});
