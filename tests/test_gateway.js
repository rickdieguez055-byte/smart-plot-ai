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

    // Test 5: Validation on unsupported multi-floor requests (> 2 floors)
    console.log('Test 5: POST /api/v1/plans/generate (unsupported floors > 2)');
    const multiFloorRes = await makeRequest(
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
          entrance_orientation: 'North',
        },
        requirements: {
          floors: 3,
        },
      }
    );
    assert.strictEqual(multiFloorRes.statusCode, 400);
    assert.strictEqual(multiFloorRes.data.code, 'VALIDATION_FAILED');
    assert.ok(JSON.stringify(multiFloorRes.data).includes('Multi-floor generation'));
    console.log('✓ Unsupported floors > 2 validation passed.');

    // Test 6: Supported Phase 6 Multi-Floor request (floors = 2)
    console.log('Test 6: POST /api/v1/plans/generate (supported floors = 2)');
    const validMultiFloorRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/generate',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: 45,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'South',
        },
        requirements: {
          bedrooms: 3,
          bathrooms: 3,
          parking: true,
          floors: 2,
        },
      }
    );
    assert.strictEqual(validMultiFloorRes.statusCode, 200);
    assert.strictEqual(validMultiFloorRes.data.floors_count, 2);
    assert.strictEqual(validMultiFloorRes.data.floor_layouts.length, 2);
    assert.ok(validMultiFloorRes.data.svg_ground_floor);
    assert.ok(validMultiFloorRes.data.svg_first_floor);
    assert.strictEqual(validMultiFloorRes.data.alternatives[0].staircase_aligned, true);
    console.log('✓ Supported multi-floor generation passed (floors=2, stair aligned, SVGs present).');

    // Test 7: Independent ground_floor and first_floor specifications
    console.log('Test 7: POST /api/v1/plans/generate (independent floor requirements)');
    const floorSpecificRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/generate',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: 45,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'South',
        },
        requirements: {
          floors: 2,
          bedrooms: 3,
          bathrooms: 3,
          ground_floor: {
            bedrooms: 1,
            bathrooms: 1,
            kitchen: true,
            drawing_room: true,
          },
          first_floor: {
            bedrooms: 2,
            bathrooms: 2,
            living_room: true,
            terrace: true,
          },
        },
      }
    );
    assert.strictEqual(floorSpecificRes.statusCode, 200);
    assert.strictEqual(floorSpecificRes.data.floors_count, 2);
    assert.ok(floorSpecificRes.data.staircase_validation);
    assert.strictEqual(floorSpecificRes.data.staircase_validation.is_valid, true);
    console.log('✓ Independent floor-specific requirements passed.');

    // Test 8: Validate Plan Edit Proxy Endpoint
    console.log('Test 8: POST /api/v1/plans/validate-edit');
    const validateEditRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/validate-edit',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: 45,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'South',
          unit: 'feet',
        },
        floor: 1,
        floors_count: 1,
        rooms: [
          { id: 'porch_gf', name: 'Car Porch & Parking', category: 'parking', x: 0.0, y: 0.0, width: 11.5, length: 14.4, floor: 1 },
          { id: 'stair_gf', name: 'Staircase Core', category: 'staircase', x: 0.0, y: 14.4, width: 6.5, length: 11.5, floor: 1 },
          { id: 'drawing_gf', name: 'Drawing Room', category: 'drawing', x: 11.5, y: 0.0, width: 13.5, length: 14.4, floor: 1 },
          { id: 'living_gf', name: 'Living Room', category: 'living', x: 6.5, y: 14.4, width: 18.5, length: 15.6, floor: 1 },
          { id: 'kitchen_gf', name: 'Kitchen', category: 'kitchen', x: 0.0, y: 25.9, width: 6.5, length: 9.1, floor: 1 },
          { id: 'bed_gf', name: 'Master Bedroom', category: 'bedroom', x: 0.0, y: 35.0, width: 13.5, length: 10.0, floor: 1 },
          { id: 'bath_gf', name: 'Attached Bath', category: 'bathroom', x: 13.5, y: 35.0, width: 11.5, length: 10.0, floor: 1 },
        ],
      }
    );
    assert.strictEqual(validateEditRes.statusCode, 200);
    assert.strictEqual(validateEditRes.data.is_valid, true);
    assert.ok(validateEditRes.data.recalculated_layout);
    console.log('✓ Validate Plan Edit proxy test passed.');

    // Test 9: Apply Plan Edit Proxy Endpoint (rejecting invalid collision)
    console.log('Test 9: POST /api/v1/plans/apply-edit (detecting invalid collision)');
    const applyEditRes = await makeRequest(
      {
        hostname: '127.0.0.1',
        port: PORT,
        path: '/api/v1/plans/apply-edit',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        plot: {
          plot_length: 45,
          plot_width: 25,
          front_width: 25,
          entrance_orientation: 'South',
          unit: 'feet',
        },
        floor: 1,
        floors_count: 1,
        rooms: [
          { id: 'porch_gf', name: 'Car Porch & Parking', category: 'parking', x: 0.0, y: 0.0, width: 11.5, length: 14.4, floor: 1 },
          { id: 'drawing_gf', name: 'Drawing Room', category: 'drawing', x: 2.0, y: 2.0, width: 13.5, length: 14.4, floor: 1 }, // COLLISION!
        ],
      }
    );
    assert.strictEqual(applyEditRes.statusCode, 200);
    assert.strictEqual(applyEditRes.data.is_valid, false);
    assert.strictEqual(applyEditRes.data.error_code, 'ROOM_OVERLAP');
    console.log('✓ Apply Plan Edit collision rejection test passed.');

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
