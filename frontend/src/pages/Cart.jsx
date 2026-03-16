import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { cartAPI, orderAPI } from '../api/api';
import './Cart.css';

function Cart({ sessionId }) {
  const navigate = useNavigate();
  const [cartItems, setCartItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [customerEmail, setCustomerEmail] = useState('');
  const [shippingAddress, setShippingAddress] = useState('');
  const [showCheckout, setShowCheckout] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    loadCart();
  }, []);

  const loadCart = async () => {
    try {
      const response = await cartAPI.getCart();
      setCartItems(response.data);
    } catch (error) {
      console.error('Failed to load cart:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = async (itemId) => {
    try {
      await cartAPI.removeFromCart(itemId);
      setCartItems(cartItems.filter(item => item.id !== itemId));
      setMessage('Item removed from cart');
      setTimeout(() => setMessage(''), 2000);
    } catch (error) {
      console.error('Failed to remove item:', error);
    }
  };

  const handleCheckout = async () => {
    if (!customerEmail.trim()) {
      setMessage('Please enter your email');
      return;
    }
    if (!shippingAddress.trim()) {
      setMessage('Please enter shipping address');
      return;
    }

    setProcessing(true);
    try {
      const orderData = {
        customer_email: customerEmail,
        items: cartItems.map(item => ({
          product_id: item.product_id || item.productId,
          product_name: item.product_name || item.productName,
          quantity: item.quantity,
          price: item.price,
        })),
        shipping_address: shippingAddress,
      };

      await orderAPI.createOrder(orderData);
      setMessage('✓ Order placed successfully! Your fish are on their way. Check your email for confirmation.');
      setTimeout(() => {
        navigate('/orders');
      }, 2000);
    } catch (error) {
      console.error('Failed to create order:', error);
      const errorMsg = error.response?.data?.detail || 'Failed to place order. Please try again.';
      setMessage('✗ ' + errorMsg);
      setTimeout(() => setMessage(''), 5000);
    } finally {
      setProcessing(false);
    }
  };

  const calculateTotal = () => {
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0).toFixed(2);
  };

  const calculateShipping = () => {
    const total = parseFloat(calculateTotal());
    return total >= 50 ? 0 : 9.99;
  };

  const calculateGrandTotal = () => {
    return (parseFloat(calculateTotal()) + calculateShipping()).toFixed(2);
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
      </div>
    );
  }

  if (cartItems.length === 0) {
    return (
      <div className="empty-cart card text-center">
        <div style={{ fontSize: '64px', marginBottom: '20px' }}>🛒</div>
        <h2>Your cart is empty</h2>
        <p className="mt-1 mb-2">Add some beautiful fish to get started! 🐟</p>
        <button onClick={() => navigate('/products')}>
          BROWSE FISH
        </button>
      </div>
    );
  }

  return (
    <div className="cart-page">
      <div className="page-header pixel-corners">
        <h1 className="page-title glitch">🛒 SHOPPING CART</h1>
        <p className="page-subtitle">{cartItems.length} {cartItems.length === 1 ? 'fish' : 'fish'} in your cart 🐠</p>
      </div>

      {message && (
        <div className={`message ${message.includes('Failed') || message.includes('Please') ? 'error' : 'success'}`}>
          {message}
        </div>
      )}

      <div className="cart-container">
        <div className="cart-items">
          {cartItems.map((item) => (
            <div key={item.id} className="cart-item card">
              <div className="cart-item-info">
                <h3>{item.product_name || item.productName}</h3>
                <div className="cart-item-details">
                  <span className="item-price">${item.price}</span>
                  <span className="item-quantity">x {item.quantity}</span>
                  <span className="item-total">
                    = ${(item.price * item.quantity).toFixed(2)}
                  </span>
                </div>
              </div>
              <button
                className="remove-button secondary"
                onClick={() => handleRemove(item.id)}
              >
                REMOVE
              </button>
            </div>
          ))}
        </div>

        <div className="cart-summary card">
          <h2 className="text-primary">ORDER SUMMARY 📋</h2>
          
          <div className="summary-row">
            <span>Subtotal:</span>
            <span>${calculateTotal()}</span>
          </div>
          <div className="summary-row">
            <span>Shipping:</span>
            <span className={calculateShipping() === 0 ? "text-success" : ""}>
              {calculateShipping() === 0 ? 'FREE' : `$${calculateShipping()}`}
            </span>
          </div>
          {calculateShipping() > 0 && (
            <p style={{fontSize: '0.7rem', opacity: 0.7, marginTop: '0.5rem'}}>
              Free shipping on orders over $50!
            </p>
          )}
          <div className="summary-divider"></div>
          <div className="summary-row total-row">
            <span>TOTAL:</span>
            <span className="text-success">${calculateGrandTotal()}</span>
          </div>

          {!showCheckout ? (
            <button
              className="checkout-button success"
              onClick={() => setShowCheckout(true)}
            >
              PROCEED TO CHECKOUT
            </button>
          ) : (
            <div className="checkout-form">
              <label>EMAIL ADDRESS</label>
              <input
                type="email"
                placeholder="your@email.com"
                value={customerEmail}
                onChange={(e) => setCustomerEmail(e.target.value)}
              />
              <label className="mt-1">SHIPPING ADDRESS</label>
              <textarea
                placeholder="Enter your complete shipping address..."
                value={shippingAddress}
                onChange={(e) => setShippingAddress(e.target.value)}
                rows="4"
              />
              <button
                className="success mt-1"
                onClick={handleCheckout}
                disabled={processing}
              >
                {processing ? 'PLACING ORDER...' : 'PLACE ORDER 🐟'}
              </button>
              <button
                className="secondary mt-1"
                onClick={() => setShowCheckout(false)}
                disabled={processing}
              >
                CANCEL
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Cart;
