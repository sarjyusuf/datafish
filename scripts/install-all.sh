#!/bin/bash

# DataFish - Install All Dependencies Script
# For development setup

set -e

echo "🐟 DataFish - Installing All Dependencies"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root for development setup"
    exit 1
fi

# 1. Install Go Dependencies
echo -e "\n${BLUE}[1/7] Installing Go dependencies (Notification Service)...${NC}"
cd notification-service
if command -v go &> /dev/null; then
    go mod download
    echo -e "${GREEN}✓ Go dependencies installed${NC}"
else
    echo "Go is not installed. Please install Go 1.19+"
    exit 1
fi
cd ..

# 2. Install Java/Maven Dependencies (Product Service)
echo -e "\n${BLUE}[2/7] Installing Java dependencies (Product Service)...${NC}"
cd product-service
if command -v mvn &> /dev/null; then
    mvn clean install -DskipTests
    echo -e "${GREEN}✓ Product Service dependencies installed${NC}"
elif command -v ./mvnw &> /dev/null; then
    ./mvnw clean install -DskipTests
    echo -e "${GREEN}✓ Product Service dependencies installed${NC}"
else
    echo "Maven is not installed. Please install Maven or use the Maven wrapper"
    exit 1
fi
cd ..

# 3. Install Java/Maven Dependencies (Inventory Service)
echo -e "\n${BLUE}[3/7] Installing Java dependencies (Inventory Service)...${NC}"
cd inventory-service
if command -v mvn &> /dev/null; then
    mvn clean install -DskipTests
    echo -e "${GREEN}✓ Inventory Service dependencies installed${NC}"
elif command -v ./mvnw &> /dev/null; then
    ./mvnw clean install -DskipTests
    echo -e "${GREEN}✓ Inventory Service dependencies installed${NC}"
else
    echo "Maven is not installed. Please install Maven or use the Maven wrapper"
    exit 1
fi
cd ..

# 4. Install Python Dependencies (Order Service)
echo -e "\n${BLUE}[4/7] Installing Python dependencies (Order Service)...${NC}"
cd order-service
if command -v python3 &> /dev/null; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    echo -e "${GREEN}✓ Order Service dependencies installed${NC}"
else
    echo "Python 3 is not installed. Please install Python 3.8+"
    exit 1
fi
cd ..

# 5. Install Python Dependencies (Payment Service)
echo -e "\n${BLUE}[5/7] Installing Python dependencies (Payment Service)...${NC}"
cd payment-service
if command -v python3 &> /dev/null; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    echo -e "${GREEN}✓ Payment Service dependencies installed${NC}"
else
    echo "Python 3 is not installed. Please install Python 3.8+"
    exit 1
fi
cd ..

# 6. Install Python Dependencies (Analytics Service)
echo -e "\n${BLUE}[6/7] Installing Python dependencies (Analytics Service)...${NC}"
cd analytics-service
if command -v python3 &> /dev/null; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    echo -e "${GREEN}✓ Analytics Service dependencies installed${NC}"
else
    echo "Python 3 is not installed. Please install Python 3.8+"
    exit 1
fi
cd ..

# 7. Install Node.js Dependencies
echo -e "\n${BLUE}[7/7] Installing Node.js dependencies...${NC}"

# API Gateway
cd api-gateway
if command -v npm &> /dev/null; then
    npm install
    echo -e "${GREEN}✓ API Gateway dependencies installed${NC}"
else
    echo "Node.js/npm is not installed. Please install Node.js 18+"
    exit 1
fi
cd ..

# Frontend
cd frontend
npm install
echo -e "${GREEN}✓ Frontend dependencies installed${NC}"
cd ..

echo -e "\n${GREEN}=========================================="
echo "✓ All dependencies installed successfully!"
echo "==========================================${NC}"
echo ""
echo "Services installed:"
echo "  • Notification Service (Go)     - Port 8083"
echo "  • Product Service (Java)        - Port 8081"
echo "  • Inventory Service (Java)      - Port 8085"
echo "  • Order Service (Python)        - Port 8082"
echo "  • Payment Service (Python)      - Port 8084"
echo "  • Analytics Service (Python)    - Port 8086"
echo "  • API Gateway (Node.js)         - Port 8080"
echo "  • Frontend (React)              - Port 3000"
echo ""
echo "To start all services, run:"
echo "  ./scripts/start-all.sh"
echo ""
