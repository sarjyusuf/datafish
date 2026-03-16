# API Gateway (Node.js/Express)

Central API gateway that routes requests to appropriate microservices.

## Setup

```bash
cd api-gateway
npm install
npm start
```

## Development

```bash
npm run dev  # Uses nodemon for auto-reload
```

## Environment Variables

Create a `.env` file based on `.env.example`:

```
PORT=8080
AUTH_SERVICE_URL=http://localhost:8083
PRODUCT_SERVICE_URL=http://localhost:8081
ORDER_SERVICE_URL=http://localhost:8082
```

## Routes

All requests are proxied to appropriate backend services:

- `/api/auth/*` → Auth Service (Port 8083)
- `/api/products/*` → Product Service (Port 8081)
- `/api/orders/*` → Order Service (Port 8082)
- `/api/cart/*` → Order Service (Port 8082)

## Features

- Request routing and load balancing
- CORS handling
- Request logging
- Error handling
- Health checks
- Service discovery

