# BuddyUp Backend - Complete Startup Guide

## 🎯 What Was Fixed

### 1. **Database Connection Issues in Docker** 
All services had an issue: they were trying to connect to `localhost:port` from within Docker containers, which doesn't work. Containers need to use the internal Docker network service name.

**Fixed Services:**
- ✅ **IAM_Service** - docker-compose.yml updated with `DATABASE_URL` override
- ✅ **Order_Service** - docker-compose.yml updated with `DATABASE_URL` override  
- ✅ **Payment_Service** - .env file updated + docker-compose.yml with overrides
- ✅ **Chat_System** - .env file updated + docker-compose.yml with overrides for both DATABASE_URL and REDIS_URL
- ✅ **API_Gateway** - No database, docker-compose ready

### 2. **Environment Variables**
Added missing `DATABASE_URL` to service .env files (Payment_Service, Chat_System).

### 3. **Master Startup Scripts**
Created three ways to start all services:

#### **Option 1: Windows Batch (Easiest for Windows)**
```powershell
# From d:\Software\Insta_Buddy_Mart directory
START_ALL_SERVICES.bat
```

#### **Option 2: PowerShell (Modern Windows)**
```powershell
# From d:\Software\Insta_Buddy_Mart directory
.\START_ALL_SERVICES.ps1
```

#### **Option 3: Node.js (Cross-platform)**
```powershell
cd d:\Software\Insta_Buddy_Mart
npm run start:backend
```

---

## 🚀 Quick Start (3 Steps)

### Step 1: Start All Services
```powershell
cd d:\Software\Insta_Buddy_Mart
START_ALL_SERVICES.bat
```

### Step 2: Wait for Startup (30-60 seconds)
The script will:
- Stop any existing containers
- Start all Docker containers (IAM, Order, Payment, Chat, API Gateway)
- Wait 15 seconds for databases to initialize
- Run database migrations
- Show service status

### Step 3: Verify Services
All services should be running:
- ✅ API Gateway: http://localhost:3000
- ✅ Chat System: http://localhost:3001  
- ✅ Payment Service: http://localhost:3002
- ✅ IAM Service: http://localhost:3003
- ✅ Order Service: http://localhost:3004

---

## 📍 Service Details

### Database Connections (Inside Docker)
```
Service              Port    Docker DB URL                      Host Port
═══════════════════════════════════════════════════════════════════════════════
IAM_Service          3003    postgres:5432/buddyup_iam_db      localhost:5434
Order_Service        3004    postgres:5432/buddyup_order_db    localhost:5435
Payment_Service      3002    postgres:5432/buddyup_payment_db  localhost:5433
Chat_System          3001    postgres:5432/buddyup_db          localhost:5432
                             + redis:6379 (no external port)
API_Gateway          3000    (no database)                      -
```

### Credentials (All Services)
```
PostgreSQL User:     buddyup
PostgreSQL Password: buddyup_dev_123
```

---

## 🔧 Individual Service Commands

### Start Individual Services
```powershell
npm run start:iam       # IAM Service only
npm run start:order     # Order Service only
npm run start:payment   # Payment Service only
npm run start:chat      # Chat System only
npm run start:gateway   # API Gateway only
```

### View Logs
```powershell
npm run logs:iam       # IAM Service logs
npm run logs:order     # Order Service logs
npm run logs:payment   # Payment Service logs
npm run logs:chat      # Chat System logs
npm run logs:gateway   # API Gateway logs

# Or use docker directly:
docker logs -f buddyup_iam
docker logs -f buddyup_order
docker logs -f buddyup_payment
docker logs -f buddyup_chat
docker logs -f buddyup_gateway
```

### Stop All Services
```powershell
docker compose down -v
# Or from root:
npm run stop:all
```

### Check Service Status
```powershell
docker ps
# Or:
npm run status
```

---

## ✅ Testing Services

### Run All Tests
```powershell
cd d:\Software\Insta_Buddy_Mart
npm run test:all
```

### Run Individual Service Tests
```powershell
npm run test:iam       # Test IAM Service
npm run test:order     # Test Order Service
```

---

## 📋 Files Modified/Created

### Modified Files
1. **backend/IAM_Service/docker-compose.yml**
   - Added `environment:` section with `DATABASE_URL: postgresql://buddyup:buddyup_dev_123@postgres:5432/buddyup_iam_db`

2. **backend/Order_Service/docker-compose.yml**
   - Added `environment:` section with `DATABASE_URL: postgresql://buddyup:buddyup_dev_123@postgres:5432/buddyup_order_db`

3. **backend/Payment_Service/.env**
   - Added `DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5433/buddyup_payment_db`

4. **backend/Payment_Service/docker-compose.yml**
   - Added `environment:` section to both `payment-service` and `payment-worker` with Docker-internal DATABASE_URL

5. **backend/Chat_System/.env**
   - Added `DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5432/buddyup_db`

6. **backend/Chat_System/docker-compose.yml**
   - Added `environment:` section with DATABASE_URL and REDIS_URL overrides

### Created Files
1. **START_ALL_SERVICES.bat** - Windows batch script to start all services
2. **START_ALL_SERVICES.ps1** - PowerShell script to start all services
3. **backend/start-all-services.js** - Node.js master startup script
4. **package.json** (root) - NPM scripts for convenience commands

---

## 🔍 Why These Changes Were Needed

### The Docker Networking Problem
When services run in Docker containers, they exist on an isolated network. Each container can communicate with other containers using the **service name** (defined in docker-compose.yml) as the hostname, not `localhost`.

**Before (❌ Didn't work):**
```
Inside Container: CONNECTION TO "localhost:5434"
↓
Docker Network: "localhost" doesn't exist inside the container
↓
CONNECTION FAILED
```

**After (✅ Works):**
```
Inside Container: CONNECTION TO "postgres:5432"
↓
Docker Network: Routes to the "postgres" service in the same network
↓
CONNECTION SUCCESSFUL
```

### The Solution: Environment Variable Overrides
The `docker-compose.yml` uses the `environment:` section to override variables set in `.env` files. This allows:
- **Local development** (.env files) to use `localhost` for direct database access
- **Docker environment** to override with internal service names automatically

---

## 🚨 Troubleshooting

### Services Won't Start
1. **Clean up everything:**
   ```powershell
   docker compose down -v
   docker system prune -a --volumes
   ```
2. **Restart Docker Desktop** (if on Windows)
3. **Try again:**
   ```powershell
   START_ALL_SERVICES.bat
   ```

### Database Connection Errors
- Ensure PostgreSQL containers are running: `docker ps | grep postgres`
- Wait longer before running migrations (databases take time to initialize)
- Check database logs: `docker logs buddyup_iam_postgres`

### Port Already in Use
- Ensure all previous containers are stopped: `docker compose down -v`
- Check what's using the port:
  ```powershell
  netstat -ano | findstr ":3000"  # Check port 3000
  ```

### Logs Show Empty Response
- Services might still be initializing (wait 10-15 seconds)
- Check health status: `docker ps` (look for "health: healthy")

---

## 📊 Architecture Summary

```
┌─────────────────────────────────────────────────────┐
│            BuddyUp Microservices                    │
│                (All in Docker)                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  API Gateway (3000)                                │
│      ↓                                              │
│  ┌─────────────┬──────────────┬────────────────┐  │
│  │ IAM (3003)  │ Order (3004) │ Payment (3002) │  │
│  └─────┬───────┴──────┬───────┴────────┬───────┘  │
│        │              │                │           │
│        ↓              ↓                ↓           │
│    ┌─────────────────────────────────────┐        │
│    │     PostgreSQL Databases            │        │
│    │  (5 separate instances)             │        │
│    └─────────────────────────────────────┘        │
│                                                     │
│  Chat System (3001)                               │
│      ↓                                              │
│  ┌─────────────┐   ┌──────────────┐              │
│  │ PostgreSQL  │   │ Redis Cache  │              │
│  │ (5432)      │   │ (6379)       │              │
│  └─────────────┘   └──────────────┘              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## ✨ What This Enables

- ✅ **One-Command Startup**: All services start together
- ✅ **Automatic Migrations**: Database tables created automatically
- ✅ **Health Checks**: Services verify database connectivity before reporting ready
- ✅ **Development Ready**: Local .env files work for direct development
- ✅ **Production Ready**: Docker environment overrides work for containerized deployment
- ✅ **Comprehensive Testing**: Full test suite available across all services
- ✅ **Clear Diagnostics**: Service logs and status easily accessible

---

## 📞 Support

If services don't start:
1. Check Docker is running: `docker ps`
2. View service logs: `docker logs buddyup_iam` (replace service name)
3. Check database logs: `docker logs buddyup_iam_postgres`
4. Verify ports aren't in use: `netstat -ano`
5. Try clean restart: Stop all, `docker system prune -a`, restart

---

**Last Updated**: April 19, 2026
**Status**: ✅ All 5 backend services configured and tested
