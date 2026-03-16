from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship, joinedload
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import os
import requests
import uuid

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./orders.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models
class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, nullable=False)
    customer_email = Column(String, nullable=False)
    status = Column(String, default="pending")
    total_amount = Column(Float, nullable=False)
    shipping_address = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, nullable=False)
    product_name = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    
    order = relationship("Order", back_populates="items")


class CartItem(Base):
    __tablename__ = "cart_items"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, nullable=False)
    product_id = Column(Integer, nullable=False)
    product_name = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# Create tables
Base.metadata.create_all(bind=engine)

# Pydantic models
class OrderItemCreate(BaseModel):
    product_id: int
    product_name: str
    quantity: int
    price: float


class OrderCreate(BaseModel):
    customer_email: str
    items: List[OrderItemCreate]
    shipping_address: str


class OrderItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: int
    price: float
    
    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    session_id: str
    customer_email: str
    status: str
    total_amount: float
    shipping_address: str
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse]
    
    class Config:
        from_attributes = True


class CartItemCreate(BaseModel):
    product_id: int
    product_name: str
    quantity: int
    price: float


class CartItemResponse(BaseModel):
    id: int
    session_id: str
    product_id: int
    product_name: str
    quantity: int
    price: float
    created_at: datetime
    
    class Config:
        from_attributes = True


class HealthResponse(BaseModel):
    status: str
    service: str
    time: int


# FastAPI app
app = FastAPI(title="Order Service", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://localhost:8081")
NOTIFICATION_SERVICE_URL = os.getenv("NOTIFICATION_SERVICE_URL", "http://localhost:8083")
PAYMENT_SERVICE_URL = os.getenv("PAYMENT_SERVICE_URL", "http://localhost:8084")
INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://localhost:8085")
ANALYTICS_SERVICE_URL = os.getenv("ANALYTICS_SERVICE_URL", "http://localhost:8086")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_session_id(session_id: Optional[str] = None) -> str:
    """Get or create session ID"""
    if session_id:
        return session_id
    return str(uuid.uuid4())


def check_product_stock(product_id: int, quantity: int) -> dict:
    """Check if product has sufficient stock"""
    try:
        response = requests.post(
            f"{PRODUCT_SERVICE_URL}/api/products/{product_id}/check-stock",
            params={"quantity": quantity},
            timeout=5
        )
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(status_code=400, detail="Failed to check stock")
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Product service unavailable: {str(e)}")


def reduce_product_stock(product_id: int, quantity: int) -> dict:
    """Reduce product stock"""
    try:
        response = requests.post(
            f"{PRODUCT_SERVICE_URL}/api/products/{product_id}/reduce-stock",
            params={"quantity": quantity},
            timeout=5
        )
        if response.status_code == 200:
            return response.json()
        else:
            error_msg = response.json().get("error", "Failed to reduce stock")
            raise HTTPException(status_code=400, detail=error_msg)
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Product service unavailable: {str(e)}")


def send_order_notification(order: Order):
    """Send order confirmation notification"""
    try:
        requests.post(
            f"{NOTIFICATION_SERVICE_URL}/api/notifications/order",
            json={
                "orderId": order.id,
                "customerEmail": order.customer_email,
                "totalAmount": order.total_amount,
                "itemCount": len(order.items),
                "shippingAddress": order.shipping_address
            },
            timeout=5
        )
    except Exception as e:
        print(f"Failed to send notification: {e}")


def process_payment(order_id: int, amount: float, customer_email: str) -> dict:
    """Process payment through payment service"""
    try:
        response = requests.post(
            f"{PAYMENT_SERVICE_URL}/payments",
            json={
                "order_id": order_id,
                "amount": amount,
                "card_number": "4111111111111234",  # Demo card
                "card_holder": "Demo Customer",
                "expiry_date": "12/2025",
                "cvv": "123",
                "customer_email": customer_email
            },
            timeout=10
        )
        if response.status_code == 200:
            return response.json()
        error_detail = response.json().get("detail", "Payment processing failed")
        raise HTTPException(status_code=400, detail=error_detail)
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Payment service unavailable: {str(e)}")


def reserve_inventory(product_id: int, quantity: int, order_id: str) -> dict:
    """Reserve inventory through inventory service"""
    try:
        response = requests.post(
            f"{INVENTORY_SERVICE_URL}/api/inventory/{product_id}/reserve",
            params={"quantity": quantity, "orderId": order_id},
            timeout=5
        )
        if response.status_code == 200:
            return response.json()
        return None
    except requests.exceptions.RequestException as e:
        print(f"Inventory service unavailable: {e}")
        return None


def track_analytics_event(event_type: str, session_id: str, **kwargs):
    """Track analytics event"""
    try:
        requests.post(
            f"{ANALYTICS_SERVICE_URL}/api/analytics/track",
            json={
                "event_type": event_type,
                "session_id": session_id,
                **kwargs
            },
            timeout=3
        )
    except Exception as e:
        print(f"Failed to track analytics: {e}")


# Routes
@app.get("/health", response_model=HealthResponse)
async def health_check():
    return {
        "status": "healthy",
        "service": "order-service",
        "time": int(datetime.utcnow().timestamp())
    }


@app.post("/api/cart", response_model=CartItemResponse)
async def add_to_cart(
    item: CartItemCreate,
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Add item to shopping cart with stock validation"""
    session = get_session_id(session_id)
    
    # Check stock availability
    stock_check = check_product_stock(item.product_id, item.quantity)
    if not stock_check.get("available"):
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient stock. Available: {stock_check.get('currentStock')}, Requested: {item.quantity}"
        )
    
    # Check if item already in cart
    existing_item = db.query(CartItem).filter(
        CartItem.session_id == session,
        CartItem.product_id == item.product_id
    ).first()
    
    if existing_item:
        new_quantity = existing_item.quantity + item.quantity
        # Check stock for new total quantity
        stock_check = check_product_stock(item.product_id, new_quantity)
        if not stock_check.get("available"):
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock. Available: {stock_check.get('currentStock')}, Requested: {new_quantity}"
            )
        existing_item.quantity = new_quantity
        db.commit()
        db.refresh(existing_item)
        return existing_item
    
    cart_item = CartItem(
        session_id=session,
        product_id=item.product_id,
        product_name=item.product_name,
        quantity=item.quantity,
        price=item.price
    )
    db.add(cart_item)
    db.commit()
    db.refresh(cart_item)
    return cart_item


@app.get("/api/cart", response_model=List[CartItemResponse])
async def get_cart(
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get cart items"""
    if not session_id:
        return []
    items = db.query(CartItem).filter(CartItem.session_id == session_id).all()
    return items


@app.delete("/api/cart/{item_id}")
async def remove_from_cart(
    item_id: int,
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Remove item from cart"""
    item = db.query(CartItem).filter(
        CartItem.id == item_id,
        CartItem.session_id == session_id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")
    
    db.delete(item)
    db.commit()
    return {"message": "Item removed from cart"}


@app.delete("/api/cart")
async def clear_cart(
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Clear all items from cart"""
    if session_id:
        db.query(CartItem).filter(CartItem.session_id == session_id).delete()
        db.commit()
    return {"message": "Cart cleared"}


@app.post("/api/orders", response_model=OrderResponse)
async def create_order(
    order_data: OrderCreate,
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Create a new order with inventory management, payment processing, and analytics"""
    session = get_session_id(session_id)
    
    # Track checkout start analytics
    track_analytics_event("checkout_start", session, user_id=order_data.customer_email)
    
    # Validate stock for all items first
    for item in order_data.items:
        stock_check = check_product_stock(item.product_id, item.quantity)
        if not stock_check.get("available"):
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock for {item.product_name}. Available: {stock_check.get('currentStock')}"
            )
    
    # Calculate total
    total_amount = sum(item.price * item.quantity for item in order_data.items)
    
    # Create order (flush to get ID, but don't commit yet)
    order = Order(
        session_id=session,
        customer_email=order_data.customer_email,
        status="pending",
        total_amount=total_amount,
        shipping_address=order_data.shipping_address
    )
    db.add(order)
    db.flush()

    # Process payment before committing the order
    payment_result = process_payment(order.id, total_amount, order_data.customer_email)
    if payment_result.get("status") not in ["completed", "processing"]:
        db.rollback()
        raise HTTPException(status_code=400, detail="Payment failed")

    order.status = "paid"

    # Create order items and reduce stock
    for item in order_data.items:
        order_item = OrderItem(
            order_id=order.id,
            product_id=item.product_id,
            product_name=item.product_name,
            quantity=item.quantity,
            price=item.price
        )
        db.add(order_item)

        # Reserve inventory
        reserve_inventory(item.product_id, item.quantity, str(order.id))

        # Reduce stock in product service
        try:
            reduce_product_stock(item.product_id, item.quantity)
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=400, detail=f"Failed to process order: {str(e)}")

        # Track purchase analytics for each item
        track_analytics_event(
            "purchase",
            session,
            user_id=order_data.customer_email,
            product_id=item.product_id,
            product_name=item.product_name,
            quantity=item.quantity,
            value=item.price * item.quantity
        )

    db.commit()
    db.refresh(order)
    
    # Clear cart
    db.query(CartItem).filter(CartItem.session_id == session).delete()
    db.commit()
    
    # Send notification
    send_order_notification(order)
    
    return order


@app.get("/api/orders", response_model=List[OrderResponse])
async def get_orders(
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get orders"""
    if not session_id:
        return []
    orders = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.session_id == session_id)
        .order_by(Order.created_at.desc())
        .all()
    )
    return orders


@app.get("/api/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    session_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get order details"""
    order = db.query(Order).options(joinedload(Order.items)).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    return order


@app.put("/api/orders/{order_id}/status")
async def update_order_status(
    order_id: int,
    status: str,
    db: Session = Depends(get_db)
):
    """Update order status"""
    order = db.query(Order).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    order.status = status
    order.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Order status updated", "status": status}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8082"))
    print(f"🐟 Order Service starting on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
