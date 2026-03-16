# Order Service (Python/FastAPI)

Shopping cart and order management service.

## Setup

```bash
cd order-service
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

## Environment Variables

- `PORT` - Service port (default: 8082)
- `AUTH_SERVICE_URL` - Auth service URL (default: http://localhost:8083)

## Endpoints

### Cart Management
- `POST /api/cart` - Add item to cart (requires auth)
- `GET /api/cart` - Get cart items (requires auth)
- `DELETE /api/cart/{id}` - Remove item from cart (requires auth)
- `DELETE /api/cart` - Clear cart (requires auth)

### Order Management
- `POST /api/orders` - Create order (requires auth)
- `GET /api/orders` - Get user's orders (requires auth)
- `GET /api/orders/{id}` - Get order details (requires auth)
- `PUT /api/orders/{id}/status` - Update order status (requires auth)

### Health
- `GET /health` - Health check

## Order Statuses

- `pending` - Order placed
- `processing` - Order being prepared
- `shipped` - Order shipped
- `delivered` - Order delivered
- `cancelled` - Order cancelled

