import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { productAPI } from '../api/api';
import ProductCard from '../components/ProductCard';
import './Home.css';

function Home() {
  const [featuredProducts, setFeaturedProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadFeaturedProducts();
  }, []);

  const loadFeaturedProducts = async () => {
    try {
      const response = await productAPI.getFeatured();
      setFeaturedProducts(response.data);
    } catch (error) {
      console.error('Failed to load featured products:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="home">
      <section className="hero pixel-corners">
        <div className="hero-content">
          <h1 className="hero-title glitch">
            🐟 WELCOME TO DATAFISH 🐠
          </h1>
          <p className="hero-subtitle">
            YOUR PREMIUM ONLINE AQUARIUM STORE
          </p>
          <div className="hero-stats">
            <div className="stat-box">
              <div className="stat-value">500+</div>
              <div className="stat-label">HAPPY CUSTOMERS</div>
            </div>
            <div className="stat-box">
              <div className="stat-value">50+</div>
              <div className="stat-label">FISH SPECIES</div>
            </div>
            <div className="stat-box">
              <div className="stat-value">FREE</div>
              <div className="stat-label">SHIPPING $50+</div>
            </div>
          </div>
        </div>
        
        <div className="hero-fish-animation">
          <div className="fish-swim" style={{animationDelay: '0s'}}>🐠</div>
          <div className="fish-swim" style={{animationDelay: '1s'}}>🐟</div>
          <div className="fish-swim" style={{animationDelay: '2s'}}>🐡</div>
        </div>
      </section>

      <section className="featured-section">
        <h2 className="section-title text-primary">⭐ FEATURED FISH</h2>
        
        {loading ? (
          <div className="spinner"></div>
        ) : (
          <div className="products-grid">
            {featuredProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
        
        <div className="text-center mt-2">
          <Link to="/products">
            <button>VIEW ALL FISH</button>
          </Link>
        </div>
      </section>

      <section className="cta-section pixel-border">
        <h2 className="text-accent">🐟 NEW ARRIVALS WEEKLY!</h2>
        <p className="mt-1 mb-2">Fresh fish delivered straight from our trusted breeders. All fish are healthy, well-fed, and ready for their new home!</p>
        <div className="trust-badges" style={{display: 'flex', gap: '2rem', justifyContent: 'center', marginTop: '1rem', marginBottom: '1rem'}}>
          <span>✓ Live Arrival Guarantee</span>
          <span>✓ 30-Day Health Warranty</span>
          <span>✓ Expert Support</span>
        </div>
        <Link to="/products">
          <button className="success">START SHOPPING</button>
        </Link>
      </section>
    </div>
  );
}

export default Home;
