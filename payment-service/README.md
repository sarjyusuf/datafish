# 💳 Payment Service

Payment processing microservice for DataFish, built with Python and FastAPI.

## Overview

The Payment Service handles all payment-related operations including:
- Card validation
- Payment processing
- Refund handling
- Payment statistics

## Technology Stack

- **Language**: Python 3.8+
- **Framework**: FastAPI
- **Server**: Uvicorn

## API Endpoints

### Health Check
```
GET /health
```

### Card Validation
```
POST /api/payments/validate-card
```
Validates card information without processing a payment.

### Process Payment
```
POST /api/payments/process
```
Processes a payment for an order.

**Request Body:**
```json
{
  "order_id": 1,
  "amount": 99.99,
  "currency": "USD",
  "payment_method": "credit_card",
  "card_info": {
    "card_number": "4111111111111111",
    "expiry_month": 12,
    "expiry_year": 2025,
    "cvv": "123",
    "cardholder_name": "John Doe"
  },
  "customer_email": "customer@example.com",
  "billing_address": "123 Main St"
}
```

### Get Payment Status
```
GET /api/payments/{transaction_id}
```

### Get Payments by Order
```
GET /api/payments/order/{order_id}
```

### Process Refund
```
POST /api/payments/refund
```
**Request Body:**
```json
{
  "transaction_id": "TXN-ABC123",
  "amount": 50.00,
  "reason": "Customer requested refund"
}
```

### Payment Statistics
```
GET /api/payments/stats/summary
```

## Payment Methods Supported

- `credit_card` - Credit card payments
- `debit_card` - Debit card payments
- `paypal` - PayPal payments
- `bank_transfer` - Bank transfer payments

## Payment Statuses

- `pending` - Payment initiated
- `processing` - Payment being processed
- `completed` - Payment successful
- `failed` - Payment failed
- `refunded` - Payment refunded

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the service
python main.py
```

The service will start on port 8084 by default.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 8084 | Server port |

## Test Cards

For testing purposes:
- **Success**: Any valid card number
- **Declined (Insufficient Funds)**: Card ending in `0000`
- **Declined (Fraud)**: Card ending in `1111`

## Port

- **Default**: 8084




