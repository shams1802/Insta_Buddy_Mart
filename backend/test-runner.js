#!/usr/bin/env node

/**
 * Comprehensive Backend Service Test Runner
 * Tests: IAM Service and Order Service
 * Mode: Mock database + real HTTP endpoints
 * 
 * Usage:
 *   node test-runner.js [--iam] [--order] [--all]
 * 
 * Default: runs all tests
 */

const http = require('http');
const path = require('path');

const args = process.argv.slice(2);
const runIAM = args.includes('--iam') || args.includes('--all') || args.length === 0;
const runOrder = args.includes('--order') || args.includes('--all') || args.length === 0;

// ═══════════════════════════════════════════════════════════════════════════
// Test Utilities
// ═══════════════════════════════════════════════════════════════════════════

let passed = 0;
let failed = 0;
let errors = [];

function request(baseUrl, method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      const startTime = Date.now();
      
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        const duration = Date.now() - startTime;
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
    errors.push(testName);
  }
}

function section(title) {
  console.log(`\n${title}`);
  console.log('─'.repeat(title.length));
}

// ═══════════════════════════════════════════════════════════════════════════
// IAM Service Tests
// ═══════════════════════════════════════════════════════════════════════════

async function testIAMService() {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║     IAM SERVICE TESTS                  ║');
  console.log('╚════════════════════════════════════════╝\n');

  const IAM_BASE = 'http://localhost:3003';
  const testEmail = `test_${Date.now()}@example.com`;
  const testPhone = `9${Math.floor(100000000 + Math.random() * 900000000)}`;
  let authToken = null;
  let authToken2 = null;

  try {
    // ─────────────────────────────────────────────────
    // Test 1: Health endpoint
    // ─────────────────────────────────────────────────
    section('Test 1: Health Endpoint');
    const health = await request('GET', IAM_BASE + '/health');
    assert('Returns 200', health.status === 200);
    assert('Has status: ok', health.body.status === 'ok');
    assert('Has service name', health.body.service === 'iam-service');
    assert('Has timestamp', !!health.body.timestamp);

    // ─────────────────────────────────────────────────
    // Test 2: User registration
    // ─────────────────────────────────────────────────
    section('Test 2: User Registration');
    const register = await request('POST', IAM_BASE + '/api/v1/auth/register', {
      fullName: 'Test User',
      email: testEmail,
      phone: testPhone,
      password: 'TestPassword123',
      role: 'runner',
    });
    assert('Returns 201', register.status === 201);
    assert('Returns user object', !!register.body.user);
    assert('User has id', !!register.body.user?.id);
    assert('User role is runner', register.body.user?.role === 'runner');
    assert('KYC not verified by default', register.body.user?.kyc_verified === false);

    // ─────────────────────────────────────────────────
    // Test 3: Duplicate registration fails
    // ─────────────────────────────────────────────────
    section('Test 3: Duplicate Registration');
    const duplicate = await request('POST', IAM_BASE + '/api/v1/auth/register', {
      fullName: 'Test User 2',
      email: testEmail,
      phone: `9${Math.floor(100000000 + Math.random() * 900000000)}`,
      password: 'TestPassword123',
      role: 'requester',
    });
    assert('Returns 409 for duplicate email', duplicate.status === 409);
    assert('Returns CONFLICT code', duplicate.body.error?.code === 'CONFLICT');

    // ─────────────────────────────────────────────────
    // Test 4: Login with credentials
    // ─────────────────────────────────────────────────
    section('Test 4: Login');
    const login = await request('POST', IAM_BASE + '/api/v1/auth/login', {
      email: testEmail,
      password: 'TestPassword123',
    });
    assert('Returns 200', login.status === 200);
    assert('Returns accessToken', !!login.body.accessToken);
    assert('Returns refreshToken', !!login.body.refreshToken);
    assert('Returns user object', !!login.body.user);
    authToken = login.body.accessToken;

    // ─────────────────────────────────────────────────
    // Test 5: Login with wrong password
    // ─────────────────────────────────────────────────
    section('Test 5: Wrong Password');
    const wrongLogin = await request('POST', IAM_BASE + '/api/v1/auth/login', {
      email: testEmail,
      password: 'WrongPassword',
    });
    assert('Returns 401 for wrong password', wrongLogin.status === 401);
    assert('Returns INVALID_CREDENTIALS', wrongLogin.body.error?.code === 'INVALID_CREDENTIALS');

    // ─────────────────────────────────────────────────
    // Test 6: OTP request
    // ─────────────────────────────────────────────────
    section('Test 6: OTP Request');
    const otpReq = await request('POST', IAM_BASE + '/api/v1/auth/otp/request', {
      email: testEmail,
    });
    assert('Returns 200', otpReq.status === 200);
    assert('Has expiresAt', !!otpReq.body.expiresAt);
    assert('Has devOtp in development', !!otpReq.body.devOtp);

    // ─────────────────────────────────────────────────
    // Test 7: OTP verify
    // ─────────────────────────────────────────────────
    if (otpReq.body.devOtp) {
      section('Test 7: OTP Verification');
      const otpVerify = await request('POST', IAM_BASE + '/api/v1/auth/otp/verify', {
        email: testEmail,
        code: otpReq.body.devOtp,
      });
      assert('Returns 200', otpVerify.status === 200);
      assert('Returns accessToken', !!otpVerify.body.accessToken);
      assert('Returns refreshToken', !!otpVerify.body.refreshToken);
      authToken2 = otpVerify.body.accessToken;
    }

    // ─────────────────────────────────────────────────
    // Test 8: Auth-protected route without token
    // ─────────────────────────────────────────────────
    section('Test 8: Protected Route (No Token)');
    const noAuth = await request('GET', IAM_BASE + '/api/v1/auth/me');
    assert('Returns 401 without token', noAuth.status === 401);

    // ─────────────────────────────────────────────────
    // Test 9: Auth-protected route with token
    // ─────────────────────────────────────────────────
    if (authToken) {
      section('Test 9: Protected Route (With Token)');
      const withAuth = await request('GET', IAM_BASE + '/api/v1/auth/me', null, {
        'Authorization': `Bearer ${authToken}`,
      });
      assert('Returns 200 with token', withAuth.status === 200);
      assert('Returns user data', !!withAuth.body.user);
    }

    // ─────────────────────────────────────────────────
    // Test 10: Refresh token
    // ─────────────────────────────────────────────────
    if (login.body.refreshToken) {
      section('Test 10: Refresh Token');
      const refresh = await request('POST', IAM_BASE + '/api/v1/auth/refresh-token', {
        refreshToken: login.body.refreshToken,
      });
      assert('Returns 200', refresh.status === 200);
      assert('Returns new accessToken', !!refresh.body.accessToken);
      assert('Returns new refreshToken', !!refresh.body.refreshToken);
    }

    // ─────────────────────────────────────────────────
    // Test 11: Validation error
    // ─────────────────────────────────────────────────
    section('Test 11: Validation Error');
    const invalid = await request('POST', IAM_BASE + '/api/v1/auth/register', {
      email: 'not-an-email',
      fullName: 'Test',
      password: 'Test@1234',
    });
    assert('Returns 400 for invalid data', invalid.status === 400);

  } catch (error) {
    console.error('\n✗ IAM Service Error:', error.message);
    failed++;
    errors.push(`IAM Service Connection: ${error.message}`);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Order Service Tests
// ═══════════════════════════════════════════════════════════════════════════

async function testOrderService() {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║     ORDER SERVICE TESTS                ║');
  console.log('╚════════════════════════════════════════╝\n');

  const ORDER_BASE = 'http://localhost:3004';
  const IAM_BASE = 'http://localhost:3003';
  let authToken = null;
  let createdOrderId = null;

  try {
    // ─────────────────────────────────────────────────
    // Test 1: Get auth token
    // ─────────────────────────────────────────────────
    section('Test 1: Get Auth Token');
    const testEmail = `ordertest_${Date.now()}@example.com`;
    const testPhone = `9${Math.floor(100000000 + Math.random() * 900000000)}`;

    try {
      await request('POST', IAM_BASE + '/api/v1/auth/register', {
        fullName: 'Order Test User',
        email: testEmail,
        phone: testPhone,
        password: 'TestPassword123',
        role: 'requester',
      });

      const login = await request('POST', IAM_BASE + '/api/v1/auth/login', {
        email: testEmail,
        password: 'TestPassword123',
      });

      if (login.body.accessToken) {
        authToken = login.body.accessToken;
        assert('Got auth token from IAM Service', !!authToken);
      }
    } catch (error) {
      console.warn('  ⚠ Could not get auth token from IAM Service');
      // Create a mock token for testing
      authToken = 'mock-token-for-testing';
    }

    // ─────────────────────────────────────────────────
    // Test 2: Health endpoint
    // ─────────────────────────────────────────────────
    section('Test 2: Health Endpoint');
    const health = await request('GET', ORDER_BASE + '/health');
    assert('Returns 200', health.status === 200);
    assert('Has status: ok', health.body.status === 'ok');
    assert('Has service name', health.body.service === 'order-service');

    // ─────────────────────────────────────────────────
    // Test 3: Create order without auth
    // ─────────────────────────────────────────────────
    section('Test 3: Create Order Without Auth');
    const noAuth = await request('POST', ORDER_BASE + '/api/v1/orders', {
      storeName: 'Test Store',
      deliveryAddress: '123, Main St',
      requesterLat: 12.9,
      requesterLng: 77.6,
      storeLat: 12.95,
      storeLng: 77.65,
      estimatedCost: 500,
      items: [{ itemName: 'Milk', quantity: 1, estimatedPrice: 60 }],
    });
    assert('Returns 401 without auth', noAuth.status === 401);

    // ─────────────────────────────────────────────────
    // Test 4: Create order with validation error
    // ─────────────────────────────────────────────────
    section('Test 4: Create Order With Invalid Data');
    const invalid = await request('POST', ORDER_BASE + '/api/v1/orders', {
      storeName: 'Test Store',
      // Missing required fields
    }, {
      'Authorization': `Bearer ${authToken}`,
    });
    assert('Returns 400 for invalid data', invalid.status === 400);

    // ─────────────────────────────────────────────────
    // Test 5: Create valid order
    // ─────────────────────────────────────────────────
    section('Test 5: Create Valid Order');
    const sampleOrder = {
      storeName: 'Reliance Fresh - Koramangala',
      deliveryAddress: '123, 4th Block, Koramangala, Bangalore 560034',
      requesterLat: 12.9352,
      requesterLng: 77.6245,
      storeLat: 12.9279,
      storeLng: 77.6271,
      estimatedCost: 500,
      items: [
        { itemName: 'Milk 1L (Nandini)', quantity: 2, estimatedPrice: 56 },
        { itemName: 'Bread - Whole Wheat', quantity: 1, estimatedPrice: 45 },
        { itemName: 'Eggs (12 pack)', quantity: 1, estimatedPrice: 84 },
        { itemName: 'Bananas', quantity: 6, estimatedPrice: 30 },
      ],
      notes: 'Please check expiry dates on the milk',
    };

    const create = await request('POST', ORDER_BASE + '/api/v1/orders', sampleOrder, {
      'Authorization': `Bearer ${authToken}`,
    });
    assert('Returns 201 for valid order', create.status === 201);
    assert('Returns order object', !!create.body.order);
    assert('Order has id', !!create.body.order?.id);
    assert('Order has delivery fee', create.body.order?.delivery_fee >= 30);
    createdOrderId = create.body.order?.id;

    // ─────────────────────────────────────────────────
    // Test 6: Get order by ID
    // ─────────────────────────────────────────────────
    if (createdOrderId) {
      section('Test 6: Get Order by ID');
      const getOrder = await request('GET', ORDER_BASE + `/api/v1/orders/${createdOrderId}`, null, {
        'Authorization': `Bearer ${authToken}`,
      });
      assert('Returns 200', getOrder.status === 200);
      assert('Returns order data', !!getOrder.body.order);
      assert('Order ID matches', getOrder.body.order?.id === createdOrderId);
    }

    // ─────────────────────────────────────────────────
    // Test 7: List orders
    // ─────────────────────────────────────────────────
    section('Test 7: List Orders');
    const list = await request('GET', ORDER_BASE + '/api/v1/orders', null, {
      'Authorization': `Bearer ${authToken}`,
    });
    assert('Returns 200', list.status === 200);
    assert('Returns orders array', Array.isArray(list.body.orders));

  } catch (error) {
    console.error('\n✗ Order Service Error:', error.message);
    failed++;
    errors.push(`Order Service Connection: ${error.message}`);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Main
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║           BACKEND SERVICE TEST SUITE                           ║');
  console.log('║  Testing: IAM Service, Order Service                           ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');

  if (runIAM) {
    await testIAMService();
  }

  if (runOrder) {
    await testOrderService();
  }

  // ─────────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────────
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║                      TEST SUMMARY                              ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(`Total:  ${passed + failed}`);

  if (failed > 0) {
    console.log('\nFailed Tests:');
    errors.forEach((e, i) => console.log(`  ${i + 1}. ${e}`));
  }

  const passRate = ((passed / (passed + failed)) * 100).toFixed(1);
  console.log(`\nPass Rate: ${passRate}%`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error('Fatal Error:', error);
  process.exit(1);
});
