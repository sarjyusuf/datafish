# Notification Service (Go)

Email and notification service for DataFish.

## Features

- Order confirmation emails
- Low stock alerts
- Custom email notifications
- Notification logging
- Async email processing

## Setup

```bash
cd notification-service
go mod download
go build -o notification-service
./notification-service
```

## Environment Variables

- `PORT` - Service port (default: 8083)

## Endpoints

- `POST /api/notifications/order` - Send order confirmation
- `POST /api/notifications/low-stock` - Send low stock alert
- `POST /api/notifications/email` - Send custom email
- `GET /api/notifications/logs` - Get notification history
- `GET /health` - Health check

## Usage

### Order Confirmation
```bash
curl -X POST http://localhost:8083/api/notifications/order \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 123,
    "customerEmail": "customer@example.com",
    "totalAmount": 99.99,
    "itemCount": 3,
    "shippingAddress": "123 Ocean Dr"
  }'
```

### Low Stock Alert
```bash
curl -X POST http://localhost:8083/api/notifications/low-stock \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 5,
    "productName": "Clownfish",
    "stockLevel": 2
  }'
```

