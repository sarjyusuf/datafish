from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import os
import random
import uuid

app = FastAPI(title="DataFish Payment Service")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory payment storage
payments = {}
refunds = {}

# Models
class PaymentRequest(BaseModel):
    order_id: int
    amount: float
    card_number: str
    card_holder: str
    expiry_date: str
    cvv: str
    customer_email: str

class RefundRequest(BaseModel):
    payment_id: str
    amount: float
    reason: Optional[str] = None

class PaymentResponse(BaseModel):
    payment_id: str
    status: str
    transaction_id: str
    amount: float
    timestamp: str
    message: Optional[str] = None

# Health check
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "payment-service",
        "timestamp": datetime.utcnow().isoformat()
    }

# Process payment
@app.post("/payments", response_model=PaymentResponse)
def process_payment(payment: PaymentRequest):
    """Process a payment transaction"""
    
    # Basic card validation
    if len(payment.card_number.replace(" ", "")) < 13:
        raise HTTPException(status_code=400, detail="Invalid card number")
    
    if len(payment.cvv) < 3:
        raise HTTPException(status_code=400, detail="Invalid CVV")
    
    # Simulate payment processing
    payment_id = str(uuid.uuid4())
    transaction_id = f"TXN-{random.randint(100000, 999999)}"
    
    # Configurable failure rate for demos (default 0%).
    fail_rate = float(os.getenv("PAYMENT_FAIL_RATE", "0"))
    success = random.random() >= fail_rate
    
    payment_record = {
        "payment_id": payment_id,
        "order_id": payment.order_id,
        "amount": payment.amount,
        "status": "completed" if success else "failed",
        "transaction_id": transaction_id,
        "timestamp": datetime.utcnow().isoformat(),
        "customer_email": payment.customer_email,
        "card_last_4": payment.card_number[-4:],
    }
    
    payments[payment_id] = payment_record
    
    if not success:
        raise HTTPException(
            status_code=402,
            detail="Payment declined. Please try another card."
        )
    
    return PaymentResponse(
        payment_id=payment_id,
        status="completed",
        transaction_id=transaction_id,
        amount=payment.amount,
        timestamp=payment_record["timestamp"],
        message="Payment processed successfully"
    )

# Get payment status
@app.get("/payments/{payment_id}")
def get_payment(payment_id: str):
    """Get payment details by ID"""
    if payment_id not in payments:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    return payments[payment_id]

# Process refund
@app.post("/refunds")
def process_refund(refund: RefundRequest):
    """Process a refund for a payment"""
    
    if refund.payment_id not in payments:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    payment = payments[refund.payment_id]
    
    if payment["status"] != "completed":
        raise HTTPException(status_code=400, detail="Cannot refund incomplete payment")
    
    if refund.amount > payment["amount"]:
        raise HTTPException(status_code=400, detail="Refund amount exceeds payment amount")
    
    refund_id = str(uuid.uuid4())
    refund_record = {
        "refund_id": refund_id,
        "payment_id": refund.payment_id,
        "amount": refund.amount,
        "reason": refund.reason,
        "status": "completed",
        "timestamp": datetime.utcnow().isoformat()
    }
    
    refunds[refund_id] = refund_record
    payment["refunded_amount"] = payment.get("refunded_amount", 0) + refund.amount
    
    return refund_record

# Get payment statistics
@app.get("/stats")
def get_payment_stats():
    """Get payment statistics"""
    total_payments = len(payments)
    completed_payments = sum(1 for p in payments.values() if p["status"] == "completed")
    total_amount = sum(p["amount"] for p in payments.values() if p["status"] == "completed")
    total_refunds = len(refunds)
    refund_amount = sum(r["amount"] for r in refunds.values())
    
    return {
        "total_payments": total_payments,
        "completed_payments": completed_payments,
        "failed_payments": total_payments - completed_payments,
        "total_amount": round(total_amount, 2),
        "total_refunds": total_refunds,
        "refund_amount": round(refund_amount, 2),
        "net_amount": round(total_amount - refund_amount, 2)
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8084))
    uvicorn.run(app, host="0.0.0.0", port=port)
