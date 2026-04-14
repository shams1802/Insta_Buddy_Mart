#!/bin/bash
set -e
source ~/.nvm/nvm.sh
nvm use 20

echo "=== Setup Environment Variables ==="
cd backend/API_Gateway && cp -n .env.example .env || true
cd ../IAM_Service && cp -n .env.example .env || true
cd ../Order_Service && cp -n .env.example .env || true
cd ../Payment_Service && cp -n .env.example .env || true

# Payment_Service requires an explicitly complete .env, so let's populate it
cat <<EOF > .env
PORT=3002
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5433/buddyup_payment_db
JWT_SECRET=your_jwt_secret_here
RAZORPAY_KEY_ID=test_id
RAZORPAY_KEY_SECRET=test_secret
RAZORPAY_WEBHOOK_SECRET=test_webhook
AUTO_RELEASE_POLL_CRON=* * * * *
AUTO_RELEASE_BATCH_SIZE=10
AUTO_RELEASE_MAX_ATTEMPTS=5
EOF

# Chat System .env
cd ../Chat_System
cat <<EOF > .env
PORT=3001
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
DATABASE_URL=postgresql://buddyup:buddyup_dev_123@localhost:5432/buddyup_db
REDIS_URL=redis://localhost:6379
REDIS_KEY_PREFIX=buddyup:
JWT_SECRET=your_jwt_secret_here
BULL_CONCURRENCY=5
EOF

cd ../..

echo "=== Start Dependencies (Docker) ==="
cd backend/IAM_Service && docker compose up -d postgres
cd ../Order_Service && docker compose up -d postgres
cd ../Payment_Service && docker compose up -d postgres
cd ../Chat_System && docker compose up -d postgres redis
cd ../..

echo "Waiting for databases to initialize..."
sleep 15

echo "=== Install Dependencies and Migrate ==="
for svc in API_Gateway IAM_Service Order_Service Payment_Service Chat_System; do
  echo "Setting up $svc..."
  cd backend/$svc
  npm install
  npm run migrate || true # API Gateway doesn't have migrate script
  cd ../..
done

echo "=== Start Services in Background ==="
cd backend/Chat_System && npm run dev &
CHAT_PID=$!
cd backend/IAM_Service && npm run dev &
IAM_PID=$!
cd backend/Order_Service && npm run dev &
ORDER_PID=$!
cd backend/Payment_Service && npm run dev &
PAYMENT_PID=$!
cd backend/Payment_Service && npm run start:worker &
WORKER_PID=$!
cd backend/API_Gateway && npm run dev &
GATEWAY_PID=$!

echo "Waiting for services to start..."
sleep 10

echo "=== Running Tests ==="
cd backend/IAM_Service && node test-iam-service.js
echo "-----------------------------------"
cd ../Order_Service && node test-order-service.js
echo "-----------------------------------"
cd ../Payment_Service && node test-payment-system.js
echo "-----------------------------------"
cd ../Payment_Service && node test-req9-escrow-auto-release.js
echo "-----------------------------------"
cd ../Chat_System && node test-chat-system.js
echo "-----------------------------------"
cd ../API_Gateway && node test-api-gateway.js

echo "=== Cleanup ==="
kill $CHAT_PID $IAM_PID $ORDER_PID $PAYMENT_PID $WORKER_PID $GATEWAY_PID
cd ../IAM_Service && docker compose down
cd ../Order_Service && docker compose down
cd ../Payment_Service && docker compose down
cd ../Chat_System && docker compose down
