from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum
import os
import random
import time
import threading
from collections import defaultdict

# FastAPI app
app = FastAPI(
    title="Analytics Service",
    description="DataFish Analytics & Reporting Service - Tracks user behavior, generates reports, and provides insights",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Enums
class EventType(str, Enum):
    PAGE_VIEW = "page_view"
    PRODUCT_VIEW = "product_view"
    ADD_TO_CART = "add_to_cart"
    REMOVE_FROM_CART = "remove_from_cart"
    CHECKOUT_START = "checkout_start"
    PURCHASE = "purchase"
    SEARCH = "search"
    FILTER = "filter"
    LOGIN = "login"
    LOGOUT = "logout"
    SIGNUP = "signup"


# Pydantic models
class AnalyticsEvent(BaseModel):
    event_type: EventType
    session_id: str
    user_id: Optional[str] = None
    page: Optional[str] = None
    product_id: Optional[int] = None
    product_name: Optional[str] = None
    quantity: Optional[int] = None
    value: Optional[float] = None
    search_query: Optional[str] = None
    filters: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None


class EventResponse(BaseModel):
    event_id: str
    event_type: EventType
    timestamp: datetime
    processed: bool


class HealthResponse(BaseModel):
    status: str
    service: str
    time: int
    version: str
    events_processed: int


# In-memory storage
events_store: List[Dict] = []
aggregations = {
    "page_views": defaultdict(int),
    "product_views": defaultdict(int),
    "cart_additions": defaultdict(int),
    "purchases": defaultdict(int),
    "search_queries": defaultdict(int),
    "hourly_traffic": defaultdict(int),
    "daily_revenue": defaultdict(float),
    "conversion_funnel": {
        "page_views": 0,
        "product_views": 0,
        "add_to_cart": 0,
        "checkout": 0,
        "purchase": 0
    }
}
event_counter = 0
processing_lock = threading.Lock()


def generate_event_id():
    global event_counter
    event_counter += 1
    return f"EVT-{datetime.now().strftime('%Y%m%d')}-{event_counter:06d}"


def process_event_batch():
    """Background job to process and aggregate events"""
    global events_store, aggregations
    
    print("📊 [BATCH] Starting event aggregation job...")
    start_time = time.time()
    
    with processing_lock:
        unprocessed = [e for e in events_store if not e.get("aggregated")]
        
        for event in unprocessed:
            event_type = event["event_type"]
            
            # Update funnel
            if event_type == EventType.PAGE_VIEW:
                aggregations["conversion_funnel"]["page_views"] += 1
                aggregations["page_views"][event.get("page", "unknown")] += 1
            elif event_type == EventType.PRODUCT_VIEW:
                aggregations["conversion_funnel"]["product_views"] += 1
                aggregations["product_views"][event.get("product_id", 0)] += 1
            elif event_type == EventType.ADD_TO_CART:
                aggregations["conversion_funnel"]["add_to_cart"] += 1
                aggregations["cart_additions"][event.get("product_id", 0)] += 1
            elif event_type == EventType.CHECKOUT_START:
                aggregations["conversion_funnel"]["checkout"] += 1
            elif event_type == EventType.PURCHASE:
                aggregations["conversion_funnel"]["purchase"] += 1
                aggregations["purchases"][event.get("product_id", 0)] += 1
                aggregations["daily_revenue"][datetime.now().strftime("%Y-%m-%d")] += event.get("value", 0)
            elif event_type == EventType.SEARCH:
                aggregations["search_queries"][event.get("search_query", "")] += 1
            
            # Track hourly traffic
            hour_key = datetime.now().strftime("%Y-%m-%d-%H")
            aggregations["hourly_traffic"][hour_key] += 1
            
            event["aggregated"] = True
    
    elapsed = time.time() - start_time
    print(f"📊 [BATCH] Aggregation complete. Processed {len(unprocessed)} events in {elapsed:.2f}s")


def generate_synthetic_events():
    """Generate synthetic events for demo purposes"""
    pages = ["/", "/products", "/cart", "/orders", "/product/1", "/product/5", "/product/10"]
    products = [
        (1, "Clownfish", 24.99),
        (2, "Blue Tang", 34.99),
        (5, "Classic Goldfish", 5.99),
        (9, "Lionfish", 89.99),
        (13, "Neon Tetra", 3.99)
    ]
    
    for _ in range(random.randint(5, 20)):
        session_id = f"session-{random.randint(1000, 9999)}"
        
        # Page view
        track_event_internal({
            "event_type": EventType.PAGE_VIEW,
            "session_id": session_id,
            "page": random.choice(pages)
        })
        
        # Maybe view a product
        if random.random() > 0.3:
            product = random.choice(products)
            track_event_internal({
                "event_type": EventType.PRODUCT_VIEW,
                "session_id": session_id,
                "product_id": product[0],
                "product_name": product[1]
            })
            
            # Maybe add to cart
            if random.random() > 0.5:
                track_event_internal({
                    "event_type": EventType.ADD_TO_CART,
                    "session_id": session_id,
                    "product_id": product[0],
                    "product_name": product[1],
                    "quantity": random.randint(1, 3),
                    "value": product[2]
                })
                
                # Maybe purchase
                if random.random() > 0.6:
                    track_event_internal({
                        "event_type": EventType.PURCHASE,
                        "session_id": session_id,
                        "product_id": product[0],
                        "product_name": product[1],
                        "quantity": random.randint(1, 2),
                        "value": product[2] * random.randint(1, 2)
                    })


def track_event_internal(event_data: dict):
    """Internal event tracking without API overhead"""
    event = {
        "event_id": generate_event_id(),
        "timestamp": datetime.utcnow(),
        "aggregated": False,
        **event_data
    }
    events_store.append(event)
    
    # Keep only last 10000 events
    if len(events_store) > 10000:
        events_store.pop(0)


# Background scheduler
def start_background_jobs():
    """Start background processing jobs"""
    def run_jobs():
        while True:
            time.sleep(30)  # Every 30 seconds
            process_event_batch()
            
            # Generate synthetic data occasionally for demo
            if random.random() > 0.7:
                generate_synthetic_events()
    
    thread = threading.Thread(target=run_jobs, daemon=True)
    thread.start()
    print("📊 [ANALYTICS] Background jobs started")


# Start background jobs on startup
@app.on_event("startup")
async def startup_event():
    start_background_jobs()
    # Generate initial synthetic data
    generate_synthetic_events()
    process_event_batch()


# Routes
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "analytics-service",
        "time": int(datetime.utcnow().timestamp()),
        "version": "1.0.0",
        "events_processed": len(events_store)
    }


@app.post("/api/analytics/track", response_model=EventResponse)
async def track_event(event: AnalyticsEvent):
    """Track a user analytics event"""
    event_id = generate_event_id()
    
    event_data = {
        "event_id": event_id,
        "event_type": event.event_type,
        "session_id": event.session_id,
        "user_id": event.user_id,
        "page": event.page,
        "product_id": event.product_id,
        "product_name": event.product_name,
        "quantity": event.quantity,
        "value": event.value,
        "search_query": event.search_query,
        "filters": event.filters,
        "metadata": event.metadata,
        "timestamp": datetime.utcnow(),
        "aggregated": False
    }
    
    events_store.append(event_data)
    
    # Keep only last 10000 events
    if len(events_store) > 10000:
        events_store.pop(0)
    
    return EventResponse(
        event_id=event_id,
        event_type=event.event_type,
        timestamp=event_data["timestamp"],
        processed=True
    )


@app.post("/api/analytics/track/batch")
async def track_events_batch(events: List[AnalyticsEvent]):
    """Track multiple events at once"""
    results = []
    for event in events:
        event_id = generate_event_id()
        event_data = {
            "event_id": event_id,
            "event_type": event.event_type,
            "session_id": event.session_id,
            "timestamp": datetime.utcnow(),
            "aggregated": False,
            **event.dict(exclude_none=True)
        }
        events_store.append(event_data)
        results.append({"event_id": event_id, "status": "tracked"})
    
    return {"tracked": len(results), "events": results}


@app.get("/api/analytics/events")
async def get_events(
    event_type: Optional[EventType] = None,
    session_id: Optional[str] = None,
    limit: int = 100
):
    """Get tracked events with optional filtering"""
    filtered = events_store
    
    if event_type:
        filtered = [e for e in filtered if e.get("event_type") == event_type]
    
    if session_id:
        filtered = [e for e in filtered if e.get("session_id") == session_id]
    
    # Return most recent first
    return sorted(filtered, key=lambda x: x.get("timestamp", datetime.min), reverse=True)[:limit]


@app.get("/api/analytics/dashboard")
async def get_dashboard():
    """Get dashboard summary data"""
    now = datetime.utcnow()
    today = now.strftime("%Y-%m-%d")
    
    # Calculate metrics
    today_events = [e for e in events_store if e.get("timestamp", datetime.min).strftime("%Y-%m-%d") == today]
    
    return {
        "summary": {
            "total_events": len(events_store),
            "events_today": len(today_events),
            "unique_sessions": len(set(e.get("session_id") for e in events_store)),
            "unique_sessions_today": len(set(e.get("session_id") for e in today_events))
        },
        "conversion_funnel": aggregations["conversion_funnel"],
        "top_pages": dict(sorted(aggregations["page_views"].items(), key=lambda x: x[1], reverse=True)[:10]),
        "top_products": dict(sorted(aggregations["product_views"].items(), key=lambda x: x[1], reverse=True)[:10]),
        "top_searches": dict(sorted(aggregations["search_queries"].items(), key=lambda x: x[1], reverse=True)[:10]),
        "revenue_today": aggregations["daily_revenue"].get(today, 0)
    }


@app.get("/api/analytics/funnel")
async def get_conversion_funnel():
    """Get conversion funnel metrics"""
    funnel = aggregations["conversion_funnel"]
    
    # Calculate conversion rates
    rates = {}
    if funnel["page_views"] > 0:
        rates["view_to_product"] = round(funnel["product_views"] / funnel["page_views"] * 100, 2)
    if funnel["product_views"] > 0:
        rates["product_to_cart"] = round(funnel["add_to_cart"] / funnel["product_views"] * 100, 2)
    if funnel["add_to_cart"] > 0:
        rates["cart_to_checkout"] = round(funnel["checkout"] / funnel["add_to_cart"] * 100, 2)
    if funnel["checkout"] > 0:
        rates["checkout_to_purchase"] = round(funnel["purchase"] / funnel["checkout"] * 100, 2)
    if funnel["page_views"] > 0:
        rates["overall_conversion"] = round(funnel["purchase"] / funnel["page_views"] * 100, 2)
    
    return {
        "funnel": funnel,
        "conversion_rates": rates
    }


@app.get("/api/analytics/products/{product_id}")
async def get_product_analytics(product_id: int):
    """Get analytics for a specific product"""
    product_events = [e for e in events_store if e.get("product_id") == product_id]
    
    views = len([e for e in product_events if e.get("event_type") == EventType.PRODUCT_VIEW])
    cart_adds = len([e for e in product_events if e.get("event_type") == EventType.ADD_TO_CART])
    purchases = len([e for e in product_events if e.get("event_type") == EventType.PURCHASE])
    
    revenue = sum(e.get("value", 0) for e in product_events if e.get("event_type") == EventType.PURCHASE)
    
    return {
        "product_id": product_id,
        "views": views,
        "cart_additions": cart_adds,
        "purchases": purchases,
        "revenue": round(revenue, 2),
        "view_to_cart_rate": round(cart_adds / views * 100, 2) if views > 0 else 0,
        "cart_to_purchase_rate": round(purchases / cart_adds * 100, 2) if cart_adds > 0 else 0
    }


@app.get("/api/analytics/traffic")
async def get_traffic_stats():
    """Get traffic statistics"""
    now = datetime.utcnow()
    
    # Last 24 hours by hour
    hourly = {}
    for i in range(24):
        hour = (now - timedelta(hours=i)).strftime("%Y-%m-%d-%H")
        hourly[hour] = aggregations["hourly_traffic"].get(hour, 0)
    
    # Last 7 days
    daily = {}
    for i in range(7):
        day = (now - timedelta(days=i)).strftime("%Y-%m-%d")
        day_events = [e for e in events_store if e.get("timestamp", datetime.min).strftime("%Y-%m-%d") == day]
        daily[day] = len(day_events)
    
    return {
        "hourly": dict(sorted(hourly.items())),
        "daily": dict(sorted(daily.items())),
        "peak_hour": max(hourly.items(), key=lambda x: x[1]) if hourly else None
    }


@app.get("/api/analytics/reports/summary")
async def generate_summary_report():
    """Generate a summary analytics report"""
    now = datetime.utcnow()
    today = now.strftime("%Y-%m-%d")
    
    today_events = [e for e in events_store if e.get("timestamp", datetime.min).strftime("%Y-%m-%d") == today]
    
    # Event type breakdown
    event_breakdown = defaultdict(int)
    for event in today_events:
        event_breakdown[event.get("event_type", "unknown")] += 1
    
    return {
        "report_generated": now.isoformat(),
        "period": "today",
        "metrics": {
            "total_events": len(today_events),
            "unique_sessions": len(set(e.get("session_id") for e in today_events)),
            "page_views": event_breakdown.get(EventType.PAGE_VIEW, 0),
            "product_views": event_breakdown.get(EventType.PRODUCT_VIEW, 0),
            "cart_additions": event_breakdown.get(EventType.ADD_TO_CART, 0),
            "purchases": event_breakdown.get(EventType.PURCHASE, 0),
            "revenue": aggregations["daily_revenue"].get(today, 0)
        },
        "event_breakdown": dict(event_breakdown),
        "top_products": dict(sorted(aggregations["product_views"].items(), key=lambda x: x[1], reverse=True)[:5])
    }


@app.post("/api/analytics/batch/process")
async def trigger_batch_processing(background_tasks: BackgroundTasks):
    """Manually trigger batch event processing"""
    background_tasks.add_task(process_event_batch)
    return {"message": "Batch processing triggered", "status": "started"}


@app.delete("/api/analytics/events")
async def clear_events():
    """Clear all events (for testing)"""
    global events_store
    count = len(events_store)
    events_store = []
    return {"message": f"Cleared {count} events"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8086"))
    print(f"📊 Analytics Service starting on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)




