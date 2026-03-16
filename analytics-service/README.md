# 📊 Analytics Service

Analytics and reporting microservice for DataFish, built with Python and FastAPI.

## Overview

The Analytics Service tracks user behavior and generates insights including:
- Event tracking (page views, product views, cart actions, purchases)
- Conversion funnel analysis
- Traffic statistics
- Product performance metrics
- Real-time dashboards

## Technology Stack

- **Language**: Python 3.8+
- **Framework**: FastAPI
- **Server**: Uvicorn

## Key Features

### Event Tracking
- Page views
- Product views
- Cart additions/removals
- Checkout events
- Purchases
- Search queries
- User authentication events

### Analytics & Reports
- Conversion funnel metrics
- Traffic analysis (hourly/daily)
- Product performance
- Revenue tracking
- Top searches

### Background Processing
- Batch event aggregation (every 30 seconds)
- Synthetic data generation for demos
- Real-time metric updates

## API Endpoints

### Health Check
```
GET /health
```

### Event Tracking

**Track Single Event**
```
POST /api/analytics/track
```
**Request Body:**
```json
{
  "event_type": "product_view",
  "session_id": "session-123",
  "user_id": "user-456",
  "product_id": 1,
  "product_name": "Clownfish"
}
```

**Track Batch Events**
```
POST /api/analytics/track/batch
```

**Get Events**
```
GET /api/analytics/events?event_type=purchase&limit=50
```

### Analytics & Reports

**Dashboard Summary**
```
GET /api/analytics/dashboard
```

**Conversion Funnel**
```
GET /api/analytics/funnel
```

**Product Analytics**
```
GET /api/analytics/products/{product_id}
```

**Traffic Statistics**
```
GET /api/analytics/traffic
```

**Summary Report**
```
GET /api/analytics/reports/summary
```

### Batch Operations

**Trigger Batch Processing**
```
POST /api/analytics/batch/process
```

**Clear Events (Testing)**
```
DELETE /api/analytics/events
```

## Event Types

| Type | Description |
|------|-------------|
| `page_view` | User viewed a page |
| `product_view` | User viewed a product |
| `add_to_cart` | User added item to cart |
| `remove_from_cart` | User removed item from cart |
| `checkout_start` | User started checkout |
| `purchase` | User completed purchase |
| `search` | User performed search |
| `filter` | User applied filter |
| `login` | User logged in |
| `logout` | User logged out |
| `signup` | User registered |

## Conversion Funnel

The service tracks a 5-step conversion funnel:
1. **Page Views** → Site visitors
2. **Product Views** → Interested shoppers
3. **Add to Cart** → Intent to buy
4. **Checkout** → Ready to purchase
5. **Purchase** → Converted customers

## Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the service
python main.py
```

The service will start on port 8086 by default.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 8086 | Server port |

## Background Jobs

### Event Aggregation
- **Interval**: Every 30 seconds
- **Purpose**: Process raw events into aggregated metrics
- **Updates**: Funnel, page views, product views, revenue

### Synthetic Data Generation
- **Purpose**: Demo data for testing
- **Generates**: Realistic user journeys with page views, product views, cart actions, and purchases

## Sample Dashboard Response

```json
{
  "summary": {
    "total_events": 1250,
    "events_today": 342,
    "unique_sessions": 89,
    "unique_sessions_today": 45
  },
  "conversion_funnel": {
    "page_views": 500,
    "product_views": 320,
    "add_to_cart": 85,
    "checkout": 42,
    "purchase": 28
  },
  "top_pages": {
    "/products": 180,
    "/": 150,
    "/product/1": 45
  },
  "revenue_today": 1245.50
}
```

## Port

- **Default**: 8086

## Notes

- Events are stored in-memory (max 10,000 events)
- Metrics are aggregated for performance
- Synthetic data is generated on startup for demo purposes




