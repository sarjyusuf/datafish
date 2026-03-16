import { useEffect, useState } from 'react';
import { orderAPI } from '../api/api';
import './Orders.css';

function Orders({ sessionId }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expandedOrder, setExpandedOrder] = useState(null);

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      const response = await orderAPI.getOrders();
      setOrders(response.data);
    } catch (error) {
      console.error('Failed to load orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'text-accent',
      processing: 'text-primary',
      shipped: 'text-secondary',
      delivered: 'text-success',
      cancelled: 'text-danger',
    };
    return colors[status] || 'text-dim';
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
      </div>
    );
  }

  if (orders.length === 0) {
    return (
      <div className="empty-orders card text-center">
        <div style={{ fontSize: '64px', marginBottom: '20px' }}>📦</div>
        <h2>No orders yet</h2>
        <p className="mt-1">Your order history will appear here</p>
      </div>
    );
  }

  return (
    <div className="orders-page">
      <div className="page-header pixel-corners">
        <h1 className="page-title glitch">📦 MY ORDERS</h1>
        <p className="page-subtitle">Track and manage your orders</p>
      </div>

      <div className="orders-list">
        {orders.map((order) => (
          <div key={order.id} className="order-card card">
            <div className="order-header">
              <div className="order-info">
                <h3>Order #{order.id}</h3>
                <span className="order-date">{formatDate(order.created_at || order.createdAt)}</span>
              </div>
              <div className="order-status-section">
                <span className={`order-status ${getStatusColor(order.status)}`}>
                  {order.status.toUpperCase()}
                </span>
                <span className="order-total">${order.total_amount || order.totalAmount}</span>
              </div>
            </div>

            <div className="order-meta">
              <div className="meta-item">
                <span className="meta-label">Email:</span>
                <span>{order.user_email || order.userEmail}</span>
              </div>
              <div className="meta-item">
                <span className="meta-label">Address:</span>
                <span>{order.shipping_address || order.shippingAddress}</span>
              </div>
            </div>

            <button
              className="toggle-items-button secondary"
              onClick={() => setExpandedOrder(expandedOrder === order.id ? null : order.id)}
            >
              {expandedOrder === order.id ? '▼ HIDE ITEMS' : '▶ SHOW ITEMS'}
            </button>

            {expandedOrder === order.id && (
              <div className="order-items">
                <h4>Order Items:</h4>
                {order.items && order.items.map((item, index) => (
                  <div key={index} className="order-item">
                    <span className="item-name">
                      {item.product_name || item.productName}
                    </span>
                    <span className="item-quantity">x{item.quantity}</span>
                    <span className="item-price">${item.price}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default Orders;

