import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { productAPI, cartAPI } from '../api/api';
import './ProductDetail.css';

function ProductDetail({ sessionId }) {
  const { id } = useParams();
  const navigate = useNavigate();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [adding, setAdding] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    loadProduct();
  }, [id]);

  const loadProduct = async () => {
    try {
      const response = await productAPI.getById(id);
      setProduct(response.data);
    } catch (error) {
      console.error('Failed to load product:', error);
      setMessage('Failed to load product');
    } finally {
      setLoading(false);
    }
  };

  const handleAddToCart = async () => {
    setAdding(true);
    setMessage('');
    try {
      await cartAPI.addToCart({
        product_id: product.id,
        product_name: product.name,
        quantity: quantity,
        price: parseFloat(product.price),
      });
      setMessage('✓ Added to cart!');
      // Reload product to get updated stock
      loadProduct();
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      console.error('Failed to add to cart:', error);
      const errorMsg = error.response?.data?.detail || 'Failed to add to cart';
      setMessage('✗ ' + errorMsg);
      setTimeout(() => setMessage(''), 5000);
    } finally {
      setAdding(false);
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="error-container card text-center">
        <h2>Product not found</h2>
        <button onClick={() => navigate('/products')} className="mt-2">
          BACK TO SHOP
        </button>
      </div>
    );
  }

  return (
    <div className="product-detail">
      <button onClick={() => navigate('/products')} className="back-button secondary">
        ← BACK TO SHOP
      </button>

      <div className="product-detail-container card">
        <div className="product-detail-image pixel-corners">
          <img 
            src={product.imageUrl} 
            alt={product.name}
            className="detail-fish-image"
            onError={(e) => {
              e.target.style.display = 'none';
              e.target.nextSibling.style.display = 'flex';
            }}
          />
          <div className="detail-fish-icon swim" style={{display: 'none'}}>🐟</div>
          {product.featured && (
            <span className="featured-badge">★ FEATURED</span>
          )}
        </div>

        <div className="product-detail-info">
          <h1 className="detail-title">{product.name}</h1>
          
          <div className="detail-badges">
            <span className="category-badge">{product.category}</span>
            <span className="habitat-badge">{product.habitat}</span>
            <span className="size-badge">{product.size}</span>
          </div>

          <p className="detail-description">{product.description}</p>

          <div className="detail-specs card">
            <h3>SPECIFICATIONS</h3>
            <div className="specs-grid">
              <div className="spec-item">
                <span className="spec-label">Category:</span>
                <span className="spec-value">{product.category}</span>
              </div>
              <div className="spec-item">
                <span className="spec-label">Habitat:</span>
                <span className="spec-value">{product.habitat}</span>
              </div>
              <div className="spec-item">
                <span className="spec-label">Size:</span>
                <span className="spec-value">{product.size}</span>
              </div>
              <div className="spec-item">
                <span className="spec-label">Stock:</span>
                <span className="spec-value">{product.stock} available</span>
              </div>
            </div>
          </div>

          <div className="detail-price-section">
            <div className="price-box pixel-border">
              <span className="price-label">PRICE</span>
              <span className="price-value">${product.price}</span>
            </div>

            <div className="quantity-selector">
              <label>QUANTITY</label>
              <div className="quantity-controls">
                <button
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  disabled={quantity <= 1}
                >
                  -
                </button>
                <span className="quantity-display">{quantity}</span>
                <button
                  onClick={() => setQuantity(Math.min(product.stock, quantity + 1))}
                  disabled={quantity >= product.stock}
                >
                  +
                </button>
              </div>
            </div>

            <button
              className="add-to-cart-button success"
              onClick={handleAddToCart}
              disabled={product.stock === 0 || adding}
            >
              {adding ? 'ADDING...' : product.stock > 0 ? '🛒 ADD TO CART' : 'OUT OF STOCK'}
            </button>
          </div>

          {message && (
            <div className={`message ${message.includes('Failed') ? 'error' : 'success'}`}>
              {message}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default ProductDetail;
