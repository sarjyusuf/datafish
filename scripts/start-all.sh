#!/bin/bash

# DataFish - Start All Services Script
# For development

set -e

echo "🐟 DataFish - Starting All Services"
echo "===================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create logs directory
mkdir -p logs

# Function to start service
start_service() {
    local name=$1
    local command=$2
    local port=$3
    
    echo -e "${BLUE}Starting $name on port $port...${NC}"
    nohup $command > logs/$name.log 2>&1 &
    echo $! > logs/$name.pid
    echo -e "${GREEN}✓ $name started (PID: $(cat logs/$name.pid))${NC}"
}

# Start Notification Service (Go)
cd notification-service
if [ ! -f "notification-service" ]; then
    echo "Building notification service..."
    go build -o notification-service
fi
start_service "notification-service" "./notification-service" "8083"
cd ..

# Start Product Service (Java)
cd product-service
if [ ! -f "target/product-service-1.0.0.jar" ]; then
    echo "Building product service..."
    mvn clean package -DskipTests
fi
start_service "product-service" "java -jar target/product-service-1.0.0.jar" "8081"
cd ..

# Start Order Service (Python)
cd order-service
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi
export PAYMENT_SERVICE_URL=http://localhost:8084 INVENTORY_SERVICE_URL=http://localhost:8085
start_service "order-service" "python main.py" "8082"
deactivate
cd ..

# Start Payment Service (Python)
cd payment-service
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment for payment-service..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi
start_service "payment-service" "python main.py" "8084"
deactivate
cd ..

# Start Inventory Service (Java)
cd inventory-service
if [ ! -f "target/inventory-service-1.0.0.jar" ]; then
    echo "Building inventory service..."
    mvn clean package -DskipTests
fi
start_service "inventory-service" "java -jar target/inventory-service-1.0.0.jar" "8085"
cd ..

# Start Analytics Service (Python)
cd analytics-service
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment for analytics-service..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi
start_service "analytics-service" "python main.py" "8086"
deactivate
cd ..

# Start API Gateway (Node.js)
cd api-gateway
start_service "api-gateway" "node server.js" "8080"
cd ..

# Start Frontend (Node.js)
cd frontend
if [ ! -d "dist" ]; then
    echo "Building frontend..."
    npm run build
fi
start_service "frontend" "npm start" "3000"
cd ..

echo ""
echo -e "${GREEN}===================================="
echo "✓ All services started!"
echo "====================================${NC}"
echo ""
echo "Service URLs:"
echo "  Frontend:            http://localhost:3000"
echo "  API Gateway:         http://localhost:8080"
echo "  Product Service:     http://localhost:8081"
echo "  Order Service:       http://localhost:8082"
echo "  Notification Service: http://localhost:8083"
echo "  Payment Service:     http://localhost:8084"
echo "  Inventory Service:   http://localhost:8085"
echo "  Analytics Service:   http://localhost:8086"
echo ""
echo "Logs are available in: ./logs/"
echo ""
echo "To stop all services:"
echo "  ./scripts/stop-all.sh"
echo ""
