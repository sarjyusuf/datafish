import { useEffect, useState } from 'react';
import { productAPI } from '../api/api';
import ProductCard from '../components/ProductCard';
import './Products.css';

function Products() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState({ category: '', habitat: '', search: '' });

  useEffect(() => {
    loadProducts();
  }, [filter]);

  const loadProducts = async () => {
    setLoading(true);
    try {
      const params = {};
      if (filter.category) params.category = filter.category;
      if (filter.habitat) params.habitat = filter.habitat;
      if (filter.search) params.search = filter.search;
      
      const response = await productAPI.getAll(params);
      setProducts(response.data);
    } catch (error) {
      console.error('Failed to load products:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key, value) => {
    setFilter(prev => ({ ...prev, [key]: value }));
  };

  return (
    <div className="products-page">
      <div className="page-header pixel-corners">
        <h1 className="page-title glitch">🐟 FISH CATALOG 🐠</h1>
        <p className="page-subtitle">Browse our collection of beautiful aquarium fish</p>
      </div>

      <div className="filters-section card">
        <div className="filters-grid">
          <div className="filter-group">
            <label>SEARCH</label>
            <input
              type="text"
              placeholder="Search fish..."
              value={filter.search}
              onChange={(e) => handleFilterChange('search', e.target.value)}
            />
          </div>

          <div className="filter-group">
            <label>CATEGORY</label>
            <select
              value={filter.category}
              onChange={(e) => handleFilterChange('category', e.target.value)}
            >
              <option value="">All Categories</option>
              <option value="APM">APM & Tracing</option>
              <option value="Metrics">Metrics</option>
              <option value="Logs">Logs & Events</option>
              <option value="SLO">SLO & Performance</option>
              <option value="Alerting">Alerting</option>
              <option value="Profiling">Profiling</option>
            </select>
          </div>

          <div className="filter-group">
            <label>HABITAT</label>
            <select
              value={filter.habitat}
              onChange={(e) => handleFilterChange('habitat', e.target.value)}
            >
              <option value="">All Habitats</option>
              <option value="freshwater">Freshwater</option>
              <option value="saltwater">Saltwater</option>
            </select>
          </div>

          <div className="filter-group">
            <button 
              onClick={() => setFilter({ category: '', habitat: '', search: '' })}
              className="secondary"
            >
              CLEAR
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="loading-container">
          <div className="spinner"></div>
          <p className="text-primary mt-2">Loading fish... 🐟</p>
        </div>
      ) : (
        <>
          <div className="results-info">
            <p>🐠 Showing {products.length} fish</p>
          </div>
          
          {products.length === 0 ? (
            <div className="no-results card text-center">
              <div style={{ fontSize: '48px', marginBottom: '20px' }}>🔍</div>
              <h2>No fish found</h2>
              <p className="mt-1">Try adjusting your filters</p>
            </div>
          ) : (
            <div className="products-grid">
              {products.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default Products;
