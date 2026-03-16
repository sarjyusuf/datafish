#!/bin/bash

###############################################################################
# DataFish - Deploy to EC2 from Local Machine
# Deploys all 8 services with systemd and DD_SERVICE tags
###############################################################################

set -e

# Usage
if [ $# -lt 2 ]; then
    echo "Usage: $0 <ec2-hostname> <pem-file> [ec2-user]"
    echo "  e.g. $0 ec2-18-224-17-137.us-east-2.compute.amazonaws.com ~/keys/my-key.pem"
    exit 1
fi

EC2_HOST="$1"
PEM_FILE="$2"
EC2_USER="${3:-ec2-user}"
SSH_OPTS="-i ${PEM_FILE} -o StrictHostKeyChecking=no -o ConnectTimeout=10"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           DataFish EC2 Deployment Script                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Target: ${GREEN}${EC2_USER}@${EC2_HOST}${NC}"
echo ""

# Validate PEM file
if [ ! -f "$PEM_FILE" ]; then
    echo -e "${RED}PEM file not found: ${PEM_FILE}${NC}"
    exit 1
fi
chmod 400 "$PEM_FILE"

# Test SSH
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} "echo ok" &>/dev/null; then
    echo -e "${RED}Cannot connect to EC2 instance. Check instance is running and security group allows SSH.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection successful${NC}"

# Get project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ─── Step 1: Upload project ────────────────────────────────────────────────
echo -e "\n${BLUE}[1/5] Uploading project to EC2...${NC}"
cd "$PROJECT_ROOT"
tar --exclude='node_modules' \
    --exclude='target' \
    --exclude='venv' \
    --exclude='.git' \
    --exclude='*.db' \
    --exclude='logs' \
    --exclude='dist' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    --exclude='.idea' \
    --exclude='.vscode' \
    -czf /tmp/datafish.tar.gz .

scp ${SSH_OPTS} /tmp/datafish.tar.gz ${EC2_USER}@${EC2_HOST}:/tmp/
rm /tmp/datafish.tar.gz

ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} << 'EOF'
rm -rf ~/DataFish
mkdir -p ~/DataFish
cd ~/DataFish
tar -xzf /tmp/datafish.tar.gz
rm /tmp/datafish.tar.gz
echo "✓ Project extracted"
EOF
echo -e "${GREEN}✓ Project uploaded${NC}"

# ─── Step 2: Install system dependencies ───────────────────────────────────
echo -e "\n${BLUE}[2/5] Installing system dependencies...${NC}"
ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} << 'EOF'
set -e

sudo dnf update -y -q 2>/dev/null

sudo dnf install -y --allowerasing git wget tar gzip gcc -q 2>/dev/null

# Java 17
if ! java -version 2>&1 | grep -q "17"; then
    sudo dnf install -y java-17-amazon-corretto-devel java-17-amazon-corretto-headless -q 2>/dev/null
fi
echo "  Java: $(java -version 2>&1 | head -1)"

# Maven
if ! command -v mvn &>/dev/null; then
    cd /tmp
    wget -q https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
    sudo tar -xzf apache-maven-3.9.5-bin.tar.gz -C /opt
    sudo ln -sf /opt/apache-maven-3.9.5/bin/mvn /usr/local/bin/mvn
fi
echo "  Maven: $(mvn -version 2>&1 | head -1)"

# Python 3
sudo dnf install -y python3 python3-pip python3-devel -q 2>/dev/null
echo "  Python: $(python3 --version)"

# Node.js 18
if ! command -v node &>/dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - 2>/dev/null
    sudo dnf install -y nodejs -q 2>/dev/null
fi
echo "  Node: $(node --version)"

# Go
GO_NEED="1.24"
GO_CUR=$(/usr/local/go/bin/go version 2>/dev/null | grep -oP '[\d]+\.[\d]+' | head -1 || echo "0")
if [ ! -f /usr/local/go/bin/go ] || [ "$(printf '%s\n' "$GO_NEED" "$GO_CUR" | sort -V | head -1)" != "$GO_NEED" ]; then
    cd /tmp
    wget -q https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin
grep -q '/usr/local/go/bin' ~/.bashrc 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo "  Go: $(/usr/local/go/bin/go version)"
EOF
echo -e "${GREEN}✓ System dependencies ready${NC}"

# ─── Step 3: Build all services ────────────────────────────────────────────
echo -e "\n${BLUE}[3/5] Building all services...${NC}"
ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} << 'EOF'
set -e
export PATH=$PATH:/usr/local/go/bin
BASE=~/DataFish

# Notification Service (Go)
echo "  Building Notification Service (Go)..."
cd $BASE/notification-service && go mod tidy && go build -o notification-service && chmod +x notification-service

# Product Service (Java)
echo "  Building Product Service (Java)..."
cd $BASE/product-service && mvn clean package -DskipTests -q

# Inventory Service (Java)
echo "  Building Inventory Service (Java)..."
cd $BASE/inventory-service && mvn clean package -DskipTests -q

# Order Service (Python)
echo "  Setting up Order Service (Python)..."
cd $BASE/order-service && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip -q && pip install -r requirements.txt -q && deactivate

# Payment Service (Python)
echo "  Setting up Payment Service (Python)..."
cd $BASE/payment-service && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip -q && pip install -r requirements.txt -q && deactivate

# Analytics Service (Python)
echo "  Setting up Analytics Service (Python)..."
cd $BASE/analytics-service && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip -q && pip install -r requirements.txt -q && deactivate

# API Gateway (Node.js)
echo "  Setting up API Gateway (Node.js)..."
cd $BASE/api-gateway && npm install --silent 2>/dev/null

# Frontend (React)
echo "  Building Frontend (React)..."
cd $BASE/frontend

EC2_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null || echo "localhost")

cat > src/api/api.js << APIEOF
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://${EC2_HOSTNAME}:8080';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const sessionId = localStorage.getItem('sessionId');
  if (sessionId) {
    config.params = { ...config.params, session_id: sessionId };
  }
  return config;
});

export const productAPI = {
  getAll: (params) => api.get('/api/products', { params }),
  getById: (id) => api.get(\`/api/products/\${id}\`),
  search: (query) => api.get('/api/products', { params: { search: query } }),
  getByCategory: (category) => api.get('/api/products', { params: { category } }),
  getFeatured: () => api.get('/api/products', { params: { featured: true } }),
};

export const cartAPI = {
  getCart: () => api.get('/api/cart'),
  addToCart: (item) => api.post('/api/cart', item),
  removeFromCart: (itemId) => api.delete(\`/api/cart/\${itemId}\`),
  clearCart: () => api.delete('/api/cart'),
};

export const orderAPI = {
  createOrder: (orderData) => api.post('/api/orders', orderData),
  getOrders: () => api.get('/api/orders'),
  getOrderById: (id) => api.get(\`/api/orders/\${id}\`),
};

export default api;
APIEOF

cat > vite.config.js << VITEEOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: '0.0.0.0',
    allowedHosts: ['${EC2_HOSTNAME}', 'localhost', '127.0.0.1']
  },
  preview: {
    port: 3000,
    host: '0.0.0.0',
    allowedHosts: ['${EC2_HOSTNAME}', 'localhost', '127.0.0.1']
  },
})
VITEEOF

npm install --silent 2>/dev/null
npm run build
cd ..

echo "✓ All services built"
EOF
echo -e "${GREEN}✓ All services built${NC}"

# ─── Step 4: Install and start systemd services ───────────────────────────
echo -e "\n${BLUE}[4/5] Installing systemd services with DD_SERVICE tags...${NC}"
ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} << 'EOF'
set -e

# Stop and disable any existing services
for svc in datafish-frontend datafish-gateway datafish-analytics datafish-inventory datafish-payment datafish-order datafish-product datafish-notification datafish-auth; do
    sudo systemctl stop $svc 2>/dev/null || true
    sudo systemctl disable $svc 2>/dev/null || true
done
sudo rm -f /etc/systemd/system/datafish-auth.service

# Also kill any leftover nohup processes
for port in 3000 8080 8081 8082 8083 8084 8085 8086; do
    pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pid" ]; then
        kill $pid 2>/dev/null || true
    fi
done
sleep 2

# Copy systemd service files
SERVICES="datafish-notification datafish-product datafish-inventory datafish-order datafish-payment datafish-analytics datafish-gateway datafish-frontend"
for svc in $SERVICES; do
    sudo cp ~/DataFish/scripts/systemd/${svc}.service /etc/systemd/system/
    sudo systemctl enable $svc
done
sudo systemctl daemon-reload

echo "✓ Systemd services installed"
echo ""
echo "DD_SERVICE tags:"
for svc in $SERVICES; do
    dd_val=$(grep DD_SERVICE /etc/systemd/system/${svc}.service | sed 's/.*DD_SERVICE=//' | tr -d '"')
    printf "  %-30s DD_SERVICE=%s\n" "$svc" "$dd_val"
done
EOF
echo -e "${GREEN}✓ Systemd services installed${NC}"

# ─── Step 5: Start services and health check ──────────────────────────────
echo -e "\n${BLUE}[5/5] Starting services...${NC}"
ssh ${SSH_OPTS} ${EC2_USER}@${EC2_HOST} << 'EOF'
set -e

# Tier 1: Independent services
for svc in datafish-notification datafish-product datafish-payment datafish-inventory datafish-analytics; do
    sudo systemctl start $svc
    echo "  Started $svc"
done
sleep 5

# Tier 2: Order (depends on product, notification, payment, inventory)
sudo systemctl start datafish-order
echo "  Started datafish-order"
sleep 3

# Tier 3: Gateway (depends on product, order, notification)
sudo systemctl start datafish-gateway
echo "  Started datafish-gateway"
sleep 3

# Tier 4: Frontend (depends on gateway)
sudo systemctl start datafish-frontend
echo "  Started datafish-frontend"
sleep 5

echo ""
echo "Health Checks:"
echo "──────────────────────────────────────────────"

check() {
    local name=$1 port=$2 path=$3
    if curl -sf -o /dev/null --connect-timeout 3 "http://localhost:${port}${path}"; then
        printf "  ✓ %-25s port %-5s Running\n" "$name" "$port"
    else
        printf "  ✗ %-25s port %-5s NOT responding\n" "$name" "$port"
    fi
}

check "Notification Service" 8083 "/health"
check "Product Service"      8081 "/actuator/health"
check "Order Service"        8082 "/health"
check "Payment Service"      8084 "/health"
check "Inventory Service"    8085 "/health"
check "Analytics Service"    8086 "/health"
check "API Gateway"          8080 "/health"
check "Frontend"             3000 "/"
EOF

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           DataFish Deployment Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Application:${NC} http://${EC2_HOST}:3000"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo "  Frontend:              http://${EC2_HOST}:3000   DD_SERVICE=datafish-frontend"
echo "  API Gateway:           http://${EC2_HOST}:8080   DD_SERVICE=datafish-api-gateway"
echo "  Product Service:       http://${EC2_HOST}:8081   DD_SERVICE=datafish-product-service"
echo "  Order Service:         http://${EC2_HOST}:8082   DD_SERVICE=datafish-order-service"
echo "  Notification Service:  http://${EC2_HOST}:8083   DD_SERVICE=datafish-notification-service"
echo "  Payment Service:       http://${EC2_HOST}:8084   DD_SERVICE=datafish-payment-service"
echo "  Inventory Service:     http://${EC2_HOST}:8085   DD_SERVICE=datafish-inventory-service"
echo "  Analytics Service:     http://${EC2_HOST}:8086   DD_SERVICE=datafish-analytics-service"
echo ""
echo -e "${YELLOW}Security Group:${NC} Ensure ports 3000 and 8080 are open for inbound traffic."
echo ""
echo -e "${YELLOW}SSH:${NC} ssh -i \"${PEM_FILE}\" ${EC2_USER}@${EC2_HOST}"
echo -e "${YELLOW}Logs:${NC} journalctl -u datafish-<service> -f"
echo -e "${YELLOW}Status:${NC} sudo systemctl status 'datafish-*'"
echo ""
