#!/bin/bash

# DataFish - Stop All Services Script

echo "🐟 DataFish - Stopping All Services"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to stop service
stop_service() {
    local name=$1
    local pidfile="logs/$name.pid"
    
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if ps -p $pid > /dev/null 2>&1; then
            echo "Stopping $name (PID: $pid)..."
            kill $pid
            sleep 1
            if ps -p $pid > /dev/null 2>&1; then
                echo "Force killing $name..."
                kill -9 $pid
            fi
            rm "$pidfile"
            echo -e "${GREEN}✓ $name stopped${NC}"
        else
            echo -e "${RED}$name is not running${NC}"
            rm "$pidfile"
        fi
    else
        echo "$name: no PID file found"
    fi
}

# Stop all services
stop_service "frontend"
stop_service "api-gateway"
stop_service "analytics-service"
stop_service "inventory-service"
stop_service "payment-service"
stop_service "order-service"
stop_service "product-service"
stop_service "notification-service"

echo ""
echo -e "${GREEN}All services stopped!${NC}"
