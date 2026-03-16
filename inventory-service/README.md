# 📦 Inventory Service

Inventory management microservice for DataFish, built with Java and Spring Boot.

## Overview

The Inventory Service handles warehouse-level inventory management including:
- Stock tracking and management
- Reservation system for orders
- Batch synchronization with warehouse
- Low stock alerts
- Transaction history

## Technology Stack

- **Language**: Java 17+
- **Framework**: Spring Boot 3.2
- **Database**: H2 (in-memory)
- **Build Tool**: Maven

## Key Features

### Stock Management
- Track quantity and reserved quantity per product
- Automatic available quantity calculation
- Reorder level monitoring

### Batch Processing
- Scheduled warehouse sync (configurable interval)
- Low stock check and alerting
- Transaction logging

### Transaction Types
- `RECEIVED` - Stock received from supplier
- `SOLD` - Stock sold to customer
- `RESERVED` - Stock reserved for pending order
- `RELEASED` - Reserved stock released (order cancelled)
- `ADJUSTED` - Manual stock adjustment
- `RETURNED` - Stock returned by customer
- `DAMAGED` - Stock marked as damaged
- `SYNCED` - Batch sync operation

## API Endpoints

### Health Check
```
GET /health
```

### Inventory Operations

**Get All Inventory**
```
GET /api/inventory
```

**Get Inventory by Product**
```
GET /api/inventory/{productId}
```

**Get Low Stock Items**
```
GET /api/inventory/low-stock
```

**Create/Update Inventory**
```
POST /api/inventory
```

### Stock Operations

**Receive Stock**
```
POST /api/inventory/{productId}/receive?quantity=50&notes=Shipment%20123
```

**Reserve Stock (for order)**
```
POST /api/inventory/{productId}/reserve?quantity=2&orderId=ORD-123
```

**Release Reservation**
```
POST /api/inventory/{productId}/release?quantity=2&orderId=ORD-123
```

**Confirm Sale**
```
POST /api/inventory/{productId}/confirm-sale?quantity=2&orderId=ORD-123
```

**Adjust Stock**
```
POST /api/inventory/{productId}/adjust?newQuantity=100&reason=Inventory%20count
```

### Transaction History

**Get Product Transaction History**
```
GET /api/inventory/{productId}/transactions
```

**Get Recent Transactions**
```
GET /api/inventory/transactions/recent?hours=24
```

### Statistics & Batch Operations

**Get Inventory Stats**
```
GET /api/inventory/stats
```

**Trigger Batch Sync**
```
POST /api/inventory/batch/sync
```

## Configuration

| Property | Default | Description |
|----------|---------|-------------|
| `server.port` | 8085 | Server port |
| `inventory.batch.sync-interval-ms` | 60000 | Warehouse sync interval (ms) |
| `inventory.low-stock-threshold` | 10 | Low stock alert threshold |

## Running Locally

```bash
# Build the service
mvn clean package -DskipTests

# Run the service
java -jar target/inventory-service-1.0.0.jar

# Or with Maven
mvn spring-boot:run
```

The service will start on port 8085 by default.

## Pre-loaded Data

The service initializes with inventory for all 15 fish products:
- Warehouse locations (A-1 through E-3)
- Multiple suppliers
- Initial stock quantities
- Default reorder levels

## Batch Jobs

### Warehouse Sync
- **Interval**: Every 60 seconds (configurable)
- **Purpose**: Sync inventory with external warehouse system
- **Logs**: Transaction with type `SYNCED`

### Low Stock Check
- **Interval**: Every 2 minutes
- **Purpose**: Check for items below reorder level
- **Action**: Logs warnings to console

## Port

- **Default**: 8085




