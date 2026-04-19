@echo off
REM BuddyUp Backend - Start All Services (Windows Batch)
REM This script starts all backend services with Docker

setlocal enabledelayedexpansion

set "BACKEND_DIR=%~dp0backend"
cd /d "%BACKEND_DIR%"

echo.
echo ====================================================
echo   BuddyUp Backend - All-in-One Service Starter
echo ====================================================
echo.
echo Starting all microservices:
echo   - IAM_Service       (port 3003, PostgreSQL)
echo   - Order_Service     (port 3004, PostgreSQL)
echo   - Payment_Service   (port 3002, PostgreSQL)
echo   - Chat_System       (port 3001, PostgreSQL + Redis)
echo   - API_Gateway       (port 3000)
echo.
echo Press any key to continue, or Ctrl+C to cancel...
pause > nul

echo.
echo [STEP 1] Stopping any existing containers...
docker compose -f IAM_Service\docker-compose.yml down -v 2>nul
docker compose -f Order_Service\docker-compose.yml down -v 2>nul
docker compose -f Payment_Service\docker-compose.yml down -v 2>nul
docker compose -f Chat_System\docker-compose.yml down -v 2>nul
docker compose -f API_Gateway\docker-compose.yml down -v 2>nul

echo.
echo [STEP 2] Starting all Docker containers...
echo.

REM Start IAM Service
echo Starting IAM_Service...
cd "%BACKEND_DIR%\IAM_Service"
docker compose up --build -d
if errorlevel 1 (
  echo ERROR: Failed to start IAM_Service
  exit /b 1
)

REM Start Order Service
echo Starting Order_Service...
cd "%BACKEND_DIR%\Order_Service"
docker compose up --build -d
if errorlevel 1 (
  echo ERROR: Failed to start Order_Service
  exit /b 1
)

REM Start Payment Service
echo Starting Payment_Service...
cd "%BACKEND_DIR%\Payment_Service"
docker compose up --build -d
if errorlevel 1 (
  echo ERROR: Failed to start Payment_Service
  exit /b 1
)

REM Start Chat System
echo Starting Chat_System...
cd "%BACKEND_DIR%\Chat_System"
docker compose up --build -d
if errorlevel 1 (
  echo ERROR: Failed to start Chat_System
  exit /b 1
)

REM Start API Gateway
echo Starting API_Gateway...
cd "%BACKEND_DIR%\API_Gateway"
docker compose up --build -d
if errorlevel 1 (
  echo ERROR: Failed to start API_Gateway
  exit /b 1
)

echo.
echo [STEP 3] Waiting for databases to initialize (15 seconds)...
timeout /t 15 /nobreak

echo.
echo [STEP 4] Running database migrations...

cd "%BACKEND_DIR%\IAM_Service"
echo Migrating IAM_Service...
call npm run migrate
if errorlevel 1 (
  echo WARNING: IAM_Service migration might have failed
)

cd "%BACKEND_DIR%\Order_Service"
echo Migrating Order_Service...
call npm run migrate
if errorlevel 1 (
  echo WARNING: Order_Service migration might have failed
)

cd "%BACKEND_DIR%\Payment_Service"
echo Migrating Payment_Service...
call npm run migrate
if errorlevel 1 (
  echo WARNING: Payment_Service migration might have failed
)

cd "%BACKEND_DIR%\Chat_System"
echo Migrating Chat_System...
call npm run migrate
if errorlevel 1 (
  echo WARNING: Chat_System migration might have failed
)

echo.
echo [STEP 5] Checking service status...
echo.
docker ps --filter "label=service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul || docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo ====================================================
echo        All Services Started Successfully!
echo ====================================================
echo.
echo Service Endpoints:
echo   - IAM Service:       http://localhost:3003
echo   - Order Service:     http://localhost:3004
echo   - Payment Service:   http://localhost:3002
echo   - Chat System:       http://localhost:3001
echo   - API Gateway:       http://localhost:3000
echo.
echo Quick Commands:
echo   docker ps                  - Show running containers
echo   docker logs -f buddyup_iam - View IAM Service logs
echo   docker logs -f buddyup_order - View Order Service logs
echo   docker logs -f buddyup_payment - View Payment Service logs
echo   docker logs -f buddyup_chat - View Chat System logs
echo.
echo To stop all services:
echo   docker compose down -v
echo.
echo To run tests:
echo   cd backend
echo   node test-runner.js --all
echo.
echo ====================================================
echo.

cd /d "%BACKEND_DIR%"

REM Keep the window open and show logs
echo.
echo Showing service logs (Ctrl+C to stop)...
echo.

docker compose -f IAM_Service\docker-compose.yml -f Order_Service\docker-compose.yml -f Payment_Service\docker-compose.yml -f Chat_System\docker-compose.yml logs -f

endlocal
