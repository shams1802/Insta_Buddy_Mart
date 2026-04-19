#!/usr/bin/env pwsh

# BuddyUp Backend - Start All Services (PowerShell)
# This script starts all backend services with Docker

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommandPath
$BackendDir = Join-Path $ScriptDir "backend"

Write-Host "`n" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "  BuddyUp Backend - All-in-One Service Starter" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "`nStarting all microservices:" -ForegroundColor Cyan
Write-Host "  - IAM_Service       (port 3003, PostgreSQL)" -ForegroundColor Gray
Write-Host "  - Order_Service     (port 3004, PostgreSQL)" -ForegroundColor Gray
Write-Host "  - Payment_Service   (port 3002, PostgreSQL)" -ForegroundColor Gray
Write-Host "  - Chat_System       (port 3001, PostgreSQL + Redis)" -ForegroundColor Gray
Write-Host "  - API_Gateway       (port 3000)" -ForegroundColor Gray
Write-Host "`nPress any key to continue, or Ctrl+C to cancel..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "`n[STEP 1] Stopping any existing containers..." -ForegroundColor Cyan
@(
  "IAM_Service",
  "Order_Service", 
  "Payment_Service",
  "Chat_System",
  "API_Gateway"
) | ForEach-Object {
  $servicePath = Join-Path $BackendDir $_
  if (Test-Path (Join-Path $servicePath "docker-compose.yml")) {
    Push-Location $servicePath
    docker compose down -v 2>$null | Out-Null
    Pop-Location
  }
}

Write-Host "`n[STEP 2] Starting all Docker containers..." -ForegroundColor Cyan

$services = @(
  @{ Name = "IAM_Service"; Dir = "$BackendDir\IAM_Service" },
  @{ Name = "Order_Service"; Dir = "$BackendDir\Order_Service" },
  @{ Name = "Payment_Service"; Dir = "$BackendDir\Payment_Service" },
  @{ Name = "Chat_System"; Dir = "$BackendDir\Chat_System" },
  @{ Name = "API_Gateway"; Dir = "$BackendDir\API_Gateway" }
)

foreach ($service in $services) {
  $name = $service.Name
  $dir = $service.Dir
  
  if (Test-Path (Join-Path $dir "docker-compose.yml")) {
    Write-Host "`nStarting $name..." -ForegroundColor Green
    Push-Location $dir
    docker compose up --build -d
    if ($LASTEXITCODE -ne 0) {
      Write-Host "ERROR: Failed to start $name" -ForegroundColor Red
      exit 1
    }
    Pop-Location
    Write-Host "✓ $name started" -ForegroundColor Green
  }
}

Write-Host "`n[STEP 3] Waiting for databases to initialize (15 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "`n[STEP 4] Running database migrations..." -ForegroundColor Cyan

$migrateServices = @(
  "IAM_Service",
  "Order_Service",
  "Payment_Service",
  "Chat_System"
)

foreach ($serviceName in $migrateServices) {
  $servicePath = Join-Path $BackendDir $serviceName
  $packageJsonPath = Join-Path $servicePath "package.json"
  
  if (Test-Path $packageJsonPath) {
    Write-Host "`nMigrating $serviceName..." -ForegroundColor Green
    Push-Location $servicePath
    npm run migrate 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) {
      Write-Host "  WARNING: Migration might have failed" -ForegroundColor Yellow
    }
    Pop-Location
    Write-Host "✓ $serviceName migration complete" -ForegroundColor Green
  }
}

Write-Host "`n[STEP 5] Checking service status..." -ForegroundColor Cyan
Write-Host ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  All Services Started Successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`nService Endpoints:" -ForegroundColor Cyan
Write-Host "  - IAM Service:       http://localhost:3003" -ForegroundColor Gray
Write-Host "  - Order Service:     http://localhost:3004" -ForegroundColor Gray
Write-Host "  - Payment Service:   http://localhost:3002" -ForegroundColor Gray
Write-Host "  - Chat System:       http://localhost:3001" -ForegroundColor Gray
Write-Host "  - API Gateway:       http://localhost:3000" -ForegroundColor Gray

Write-Host "`nQuick Commands:" -ForegroundColor Cyan
Write-Host "  docker ps                    - Show running containers" -ForegroundColor Gray
Write-Host "  docker logs -f buddyup_iam   - View IAM Service logs" -ForegroundColor Gray
Write-Host "  docker logs -f buddyup_order - View Order Service logs" -ForegroundColor Gray
Write-Host "  docker logs -f buddyup_payment - View Payment Service logs" -ForegroundColor Gray
Write-Host "  docker logs -f buddyup_chat  - View Chat System logs" -ForegroundColor Gray

Write-Host "`nTo stop all services:" -ForegroundColor Cyan
Write-Host "  docker compose down -v" -ForegroundColor Gray

Write-Host "`nTo run tests:" -ForegroundColor Cyan
Write-Host "  cd backend" -ForegroundColor Gray
Write-Host "  node test-runner.js --all" -ForegroundColor Gray

Write-Host "`n================================================`n" -ForegroundColor Green

Write-Host "`nShowing service logs (Ctrl+C to stop)..." -ForegroundColor Yellow
Push-Location $BackendDir
docker compose -f IAM_Service\docker-compose.yml -f Order_Service\docker-compose.yml -f Payment_Service\docker-compose.yml -f Chat_System\docker-compose.yml logs -f
Pop-Location
