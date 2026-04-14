#!/usr/bin/env node

/**
 * Basic Payment Service health check test
 * Run: node test-payment-system.js
 */

const http = require('http');

const BASE_URL = 'http://localhost:3002';
let passed = 0;
let failed = 0;
const metrics = {};

function recordMetric(category, duration) {
  if (!metrics[category]) metrics[category] = [];
  metrics[category].push(duration);
}

function request(method, path, body) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method,
      headers: { 'Content-Type': 'application/json' },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        const duration = Date.now() - start;
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data), duration });
        } catch {
          resolve({ status: res.statusCode, body: data, duration });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

function assert(testName, condition) {
  if (condition) {
    console.log(`  ✓ ${testName}`);
    passed++;
  } else {
    console.log(`  ✗ ${testName}`);
    failed++;
  }
}

async function runTests() {
  console.log('\n=== Payment Service Health Check Tests ===\n');

  try {
    // Test 1: Health endpoint (Loop 10x for metrics)
    console.log('GET /health (10 requests)');
    let health;
    for (let i = 0; i < 10; i++) {
      health = await request('GET', '/health');
      recordMetric('Health Check', health.duration);
    }
    assert('Returns 200', health.status === 200);
    assert('Has status: ok', health.body.status === 'ok');
    assert('Has service name', health.body.service === 'payment-service');
    assert('Has timestamp', !!health.body.timestamp);

    // Test 2: Auth required on protected routes
    console.log('\nPOST /api/v1/payments/create-order (no auth)');
    const noAuth = await request('POST', '/api/v1/payments/create-order', {});
    recordMetric('Protected Route Access (Auth Block)', noAuth.duration);
    assert('Returns 401 without auth', noAuth.status === 401);
    assert('Returns AUTH_REQUIRED code', noAuth.body.error?.code === 'AUTH_REQUIRED');

  } catch (error) {
    console.error(`\n✗ Connection failed: ${error.message}`);
    console.error('Make sure the payment service is running on port 3002');
    process.exit(1);
  }

  console.log('\n=== Latency Benchmark Summary ===');
  console.log('| Operation                 | Average | Min | Max | Samples |');
  console.log('|---------------------------|---------|-----|-----|---------|');
  for (const [cat, lats] of Object.entries(metrics)) {
    const avg = Math.round(lats.reduce((a, b) => a + b, 0) / lats.length);
    const min = Math.min(...lats);
    const max = Math.max(...lats);
    console.log(`| ${cat.padEnd(25)} | ${String(avg).padStart(3)}ms  | ${String(min).padStart(3)} | ${String(max).padStart(3)} | ${String(lats.length).padStart(7)} |`);
  }

  console.log(`\n--- Results: ${passed} passed, ${failed} failed ---\n`);
  process.exit(failed > 0 ? 1 : 0);
}

runTests();
