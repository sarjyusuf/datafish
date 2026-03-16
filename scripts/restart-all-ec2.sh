#!/bin/bash

# Restart all DataFish services on EC2 in one shot.
# Usage:
#   ./scripts/restart-all-ec2.sh \
#     --host <ec2-public-dns> \
#     --key <path-to-pem>

set -euo pipefail

HOST=""
KEY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="$2"; shift 2 ;;
    --key)
      KEY="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$HOST" || -z "$KEY" ]]; then
  echo "Usage: $0 --host <ec2-public-dns> --key <path-to-pem>" >&2
  exit 1
fi

ssh -i "$KEY" -o StrictHostKeyChecking=no "ec2-user@$HOST" <<'REMOTE'
set -euo pipefail

APP_DIR=~/DataFish
LOG_DIR=$APP_DIR/logs

mkdir -p "$LOG_DIR"

# Stop any existing processes
pkill -f 'product-service-1.0.0.jar' || true
pkill -f 'inventory-service-1.0.0.jar' || true
pkill -f 'notification-service' || true
pkill -f 'order-service/venv/bin/python main.py' || true
pkill -f 'payment-service/venv/bin/python main.py' || true
pkill -f 'analytics-service/venv/bin/python main.py' || true
pkill -f 'node server.js' || true
pkill -f 'npx serve dist -l 3000' || true
sleep 2

# Start services
cd "$APP_DIR/notification-service"
nohup ./notification-service > "$LOG_DIR/notification.log" 2>&1 &

cd "$APP_DIR/product-service"
nohup java -jar target/product-service-1.0.0.jar > "$LOG_DIR/product.log" 2>&1 &

cd "$APP_DIR/inventory-service"
nohup java -jar target/inventory-service-1.0.0.jar > "$LOG_DIR/inventory.log" 2>&1 &

cd "$APP_DIR/payment-service"
nohup "$APP_DIR/payment-service/venv/bin/python" main.py > "$LOG_DIR/payment.log" 2>&1 &

cd "$APP_DIR/order-service"
export PAYMENT_SERVICE_URL=http://localhost:8084 INVENTORY_SERVICE_URL=http://localhost:8085
export PRODUCT_SERVICE_URL=http://localhost:8081 NOTIFICATION_SERVICE_URL=http://localhost:8083
nohup "$APP_DIR/order-service/venv/bin/python" main.py > "$LOG_DIR/order.log" 2>&1 &

cd "$APP_DIR/analytics-service"
nohup "$APP_DIR/analytics-service/venv/bin/python" main.py > "$LOG_DIR/analytics.log" 2>&1 &

cd "$APP_DIR/api-gateway"
export NOTIFICATION_SERVICE_URL=http://localhost:8083 PRODUCT_SERVICE_URL=http://localhost:8081
export ORDER_SERVICE_URL=http://localhost:8082
nohup node server.js > "$LOG_DIR/gateway.log" 2>&1 &

cd "$APP_DIR/frontend"
nohup npx serve dist -l 3000 > "$LOG_DIR/frontend.log" 2>&1 &

sleep 3

# Quick health check summary
for p in 8080 8081 8082 8083 8084 8085 8086; do
  code=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://localhost:$p/health || echo ERR)
  echo "$p:$code"
done

frontend_code=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://localhost:3000 || echo ERR)
echo "3000:$frontend_code"
REMOTE
