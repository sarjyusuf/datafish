import { Link } from 'react-router-dom';
import './ProductCard.css';

function ProductCard({ product }) {
  return (
    <div className="product-card card">
      <div className="product-image-container">
        <img 
          src={product.imageUrl} 
          alt={product.name}
          className="product-image"
          onError={(e) => {
            e.target.style.display = 'none';
            e.target.nextSibling.style.display = 'flex';
          }}
        />
        <div className="pixel-fish-icon fallback-icon" style={{display: 'none'}}>🐟</div>
        {product.featured && (
          <span className="featured-badge">★ FEATURED</span>
        )}
      </div>
      
      <div className="product-info">
        <h3 className="product-name">{product.name}</h3>
        
        <div className="product-meta">
          <span className="category-badge">{product.category}</span>
          <span className="habitat-badge">{product.habitat}</span>
        </div>
        
        <p className="product-description">{product.description}</p>
        
        <div className="product-footer">
          <div className="price-section">
            <span className="price">${product.price}</span>
            <span className="stock">
              {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
            </span>
          </div>
          
          <Link to={`/products/${product.id}`}>
            <button className={product.stock > 0 ? 'success' : ''} disabled={product.stock === 0}>
              {product.stock > 0 ? 'VIEW' : 'SOLD OUT'}
            </button>
          </Link>
        </div>
      </div>
    </div>
  );
}

export default ProductCard;
