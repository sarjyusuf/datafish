#!/bin/bash

# DataFish - Service Status Check Script

echo "🐟 DataFish - Service Status Check"
echo "==================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
    local name=$1
    local url=$2
    
    if curl -s --max-time 2 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name is running${NC} - $url"
        return 0
    else
        echo -e "${RED}✗ $name is NOT responding${NC} - $url"
        return 1
    fi
}

echo ""
echo "Checking services..."
echo ""

check_service "Frontend            " "http://localhost:3000"
check_service "API Gateway         " "http://localhost:8080/health"
check_service "Product Service     " "http://localhost:8081/actuator/health"
check_service "Order Service       " "http://localhost:8082/health"
check_service "Notification Service" "http://localhost:8083/health"
check_service "Payment Service     " "http://localhost:8084/health"
check_service "Inventory Service   " "http://localhost:8085/health"
check_service "Analytics Service   " "http://localhost:8086/health"

echo ""
echo "==================================="
echo ""
echo "Service Summary:"
echo "  Frontend (React)           - http://localhost:3000"
echo "  API Gateway (Node.js)      - http://localhost:8080"
echo "  Product Service (Java)     - http://localhost:8081"
echo "  Order Service (Python)     - http://localhost:8082"
echo "  Notification Service (Go)  - http://localhost:8083"
echo "  Payment Service (Python)   - http://localhost:8084"
echo "  Inventory Service (Java)   - http://localhost:8085"
echo "  Analytics Service (Python) - http://localhost:8086"
echo ""
