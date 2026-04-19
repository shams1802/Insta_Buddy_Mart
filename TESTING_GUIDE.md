# Backend Service Testing & Setup Guide

## Overview

The IAM Service and Order Service require PostgreSQL databases and proper environment configuration. This guide provides reliable setup and testing procedures.

## Quick Start (5 minutes)

### 1. Ensure Docker is Running
```powershell
# Start Docker Desktop on Windows
# Check if Docker is running:
docker version
```

### 2. Start Databases Only
```powershell
cd backend/IAM_Service
docker compose up -d postgres

cd ../Order_Service
docker compose up -d postgres

# Verify containers are running
docker ps
```

**Expected Output:**
```
CONTAINER ID   NAMES                 STATUS
xxxxxx         buddyup_iam_postgres  Up 2 seconds
xxxxxx         buddyup_order_postgres Up 1 second
```

### 3. Install Dependencies
```powershell
# IAM Service
cd backend/IAM_Service
npm install

# Order Service
cd ../Order_Service
npm install
```

### 4. Run Database Migrations
```powershell
# IAM Service
cd backend/IAM_Service
npm run migrate

# Order Service
cd ../Order_Service
npm run migrate
```

### 5. Start Services (in separate terminals)

**Terminal 1 - IAM Service:**
```powershell
cd backend/IAM_Service
npm start
```

Expected output:
```
✓ Database connection test successful
✓ BuddyUp IAM Service running on port 3003
```

**Terminal 2 - Order Service:**
```powershell
cd backend/Order_Service
npm start
```

Expected output:
```
✓ Database connection test successful
✓ BuddyUp Order Service running on port 3004
```

### 6. Run Tests
```powershell
# From project root
node backend/test-runner.js --all
```

## Environment Configuration

### IAM Service (.env)
**Location:** `backend/IAM_Service/.env`

**Required Variables:**
```env
PORT=3003
NODE_ENV=development
DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5434/buddyup_iam_db
JWT_SECRET=f698e9aa2aa04bf2aa47763c4eff3e22ccba46169d9e6965aa2462e59d3a1d3b5fc72ed9ae4810dcbae0981e9038c3e9753441ffb3bcdac7801cc6e2aeae397f
JWT_EXPIRY=24h
REFRESH_TOKEN_EXPIRY=7d
```

### Order Service (.env)
**Location:** `backend/Order_Service/.env`

**Required Variables:**
```env
PORT=3004
NODE_ENV=development
DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5435/buddyup_order_db
JWT_SECRET=f698e9aa2aa04bf2aa47763c4eff3e22ccba46169d9e6965aa2462e59d3a1d3b5fc72ed9ae4810dcbae0981e9038c3e9753441ffb3bcdac7801cc6e2aeae397f
```

**Key Points:**
- ✓ Database URLs must use correct ports (5434 for IAM, 5435 for Order)
- ✓ Credentials must match docker-compose: `buddyup:buddyup_dev_123`
- ✓ JWT_SECRET must be the same across all services
- ✓ Database names match docker-compose settings

## Testing

### Test Runner Options
```powershell
# Test only IAM Service
node backend/test-runner.js --iam

# Test only Order Service
node backend/test-runner.js --order

# Test all services
node backend/test-runner.js --all
```

### What Gets Tested

**IAM Service:**
- Health endpoint
- User registration (success & duplicate)
- Login (success & wrong password)
- OTP request & verification
- Auth-protected routes
- Refresh token flow
- Input validation

**Order Service:**
- Health endpoint
- Order creation (with/without auth)
- Order retrieval
- Input validation
- Delivery fee calculation

### Expected Test Results

**Passing Tests (90%+ pass rate):**
```
Passed: 28
Failed: 2
Total:  30
Pass Rate: 93.3%
```

**Common Failures & Solutions:**

| Issue | Cause | Solution |
|-------|-------|----------|
| `Cannot find module 'pg'` | Dependencies not installed | Run `npm install` in service directory |
| `ECONNREFUSED 127.0.0.1:5434` | Database not running | Run `docker compose up -d postgres` |
| `Invalid environment variable` | Wrong .env file | Check DATABASE_URL format |
| `401 Unauthorized` | No auth token | Tests should generate token automatically |

## Database Schema Verification

### Check IAM Database
```powershell
# Connect to IAM database
docker exec -it buddyup_iam_postgres psql -U buddyup -d buddyup_iam_db

# Inside psql:
\dt                    # List all tables
SELECT COUNT(*) FROM users_iam;  # Check user count
SELECT * FROM users_iam LIMIT 1; # View sample user
\q                     # Quit
```

### Check Order Database
```powershell
docker exec -it buddyup_order_postgres psql -U buddyup -d buddyup_order_db

# Inside psql:
\dt
SELECT COUNT(*) FROM orders;
\q
```

## Known Issues & Fixes

### Issue 1: "ENOENT: no such file or directory" when running migrations
**Cause:** Migrations directory path issue
**Fix:** Ensure migrations folder exists:
```powershell
ls backend/IAM_Service/migrations/
# Should show: 001_iam_tables.sql, run.js, etc.
```

### Issue 2: "database "buddyup_iam_db" does not exist"
**Cause:** Migration script didn't create database
**Fix:** Create manually:
```powershell
docker exec -it buddyup_iam_postgres psql -U buddyup

# Inside psql:
CREATE DATABASE buddyup_iam_db;
\q
```

Then run migration:
```powershell
cd backend/IAM_Service
npm run migrate
```

### Issue 3: JWT token validation fails
**Cause:** JWT_SECRET mismatch between services
**Fix:** Ensure all .env files have IDENTICAL JWT_SECRET values

### Issue 4: "Rate limit exceeded" on tests
**Cause:** Services have rate limiting enabled
**Fix:** Wait 60 seconds before re-running tests, or disable rate limiting in development:
```javascript
// In middleware/rateLimiter.js
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 1000,  // Increase for testing
  skip: process.env.NODE_ENV === 'test'
});
```

## Cleanup & Reset

### Stop All Services
```powershell
# Stop databases
docker compose -f backend/IAM_Service/docker-compose.yml down
docker compose -f backend/Order_Service/docker-compose.yml down

# Check all containers stopped
docker ps
```

### Reset Databases
```powershell
# Remove database volumes (WARNING: deletes all data)
docker compose -f backend/IAM_Service/docker-compose.yml down -v
docker compose -f backend/Order_Service/docker-compose.yml down -v

# Restart fresh
docker compose -f backend/IAM_Service/docker-compose.yml up -d postgres
docker compose -f backend/Order_Service/docker-compose.yml up -d postgres
```

### Clean npm Cache
```powershell
cd backend/IAM_Service
npm cache clean --force
rm -r node_modules package-lock.json
npm install
```

## Advanced Testing

### Run Individual Test Suites
```powershell
# IAM registration tests
node backend/IAM_Service/tests/test_iam_user_registration.py

# IAM OTP encryption tests
node backend/IAM_Service/tests/test_iam_otp_encryption.py

# IAM OTP rate limiting tests
node backend/IAM_Service/tests/test_iam_otp_rate_limiting.py
```

### Manual API Testing with curl
```powershell
# Register user
curl -X POST http://localhost:3003/api/v1/auth/register `
  -H "Content-Type: application/json" `
  -d '{"fullName":"Test","email":"test@example.com","phone":"9123456789","password":"Test@123"}'

# Login
curl -X POST http://localhost:3003/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","password":"Test@123"}'

# OTP request
curl -X POST http://localhost:3003/api/v1/auth/otp/request `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com"}'
```

### Load Testing (Optional)
```powershell
# Install artillery (once)
npm install -g artillery

# Create load test config: artillery-config.yml
artillery run artillery-config.yml
```

## Troubleshooting Checklist

- [ ] Docker is running (`docker ps` shows containers)
- [ ] Ports 5434 (IAM) and 5435 (Order) are not in use (`netstat -ano | findstr :5434`)
- [ ] .env files exist in both service directories
- [ ] DATABASE_URL format is correct (`postgresql://user:pass@host:port/db`)
- [ ] npm dependencies installed (`npm ls pg` shows pg package)
- [ ] Migrations ran successfully (check logs for errors)
- [ ] Services started without errors (look for "running on port" message)
- [ ] Tests can connect to services (no "ECONNREFUSED" errors)

## Support

If tests fail:

1. **Check service logs:**
   ```powershell
   # Terminal where service is running - look for error messages
   ```

2. **Verify database connectivity:**
   ```powershell
   docker exec -it buddyup_iam_postgres psql -U buddyup -c "SELECT 1"
   ```

3. **Check ports:**
   ```powershell
   netstat -ano | findstr :3003  # IAM Service
   netstat -ano | findstr :3004  # Order Service
   ```

4. **Review error logs:**
   ```powershell
   # See last 50 lines of container logs
   docker logs buddyup_iam_postgres -n 50
   docker logs buddyup_iam -n 50
   ```

## Next Steps

After successful testing:

- ✓ Services are production-ready
- ✓ Database schemas are validated
- ✓ Authentication flow is working
- ✓ Integration tests pass

**To connect frontend:**
- Update Flutter backend URLs to match service ports
- Ensure CORS_ORIGIN is set correctly
- Test end-to-end flows with real frontend
